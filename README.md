# High-Availability MySQL Cluster

A 4-node **Circular Master-Master MySQL replication** setup using **Tailscale VPN** for distributed database management. Every node can both read and write; changes propagate around the ring to all other nodes automatically.

---

## Architecture

```
  Matt (Node 1)
  100.65.253.91
       ↓  ↑
  Ella (Node 2)       Circular ring — every node
  100.113.126.37      is both a Master and a Replica
       ↓  ↑
  Migol (Node 3)
  100.87.253.15
       ↓  ↑
  Ablay (Node 4)
  100.123.175.41
```

**Replication chain:** Matt → Ella → Migol → Ablay → Matt

---

## Node Configuration

| Node  | Member | Tailscale IP    | server-id | auto_increment_offset |
|-------|--------|-----------------|-----------|----------------------|
| Node 1 | Matt  | 100.65.253.91   | 1         | 1                    |
| Node 2 | Ella  | 100.113.126.37  | 2         | 2                    |
| Node 3 | Migol | 100.87.253.15   | 3         | 3                    |
| Node 4 | Ablay | 100.123.175.41  | 4         | 4                    |

---

## Key Technical Settings

| Setting | Value | Purpose |
|---|---|---|
| `server-id` | 1–4 (unique per node) | Identifies each node in the ring |
| `log_bin` | `/var/log/mysql/mysql-bin.log` | Enables binary logging for replication |
| `log_slave_updates` | `1` | Forwards received changes to the next node |
| `auto_increment_increment` | `4` | Prevents duplicate primary key conflicts |
| `auto_increment_offset` | 1/2/3/4 | Each node uses a different ID sequence |
| `binlog_do_db` | `online_store` | Only replicates the project database |
| `slave_skip_errors` | `1062` | Skips duplicate-entry errors to keep the ring moving |

---

## Database: `online_store`

### Tables

| Table | Description |
|---|---|
| `tbl_customer` | Customer records |
| `tbl_address` | Customer addresses |
| `tbl_barangay` | Barangay lookup |
| `tbl_municipality` | Municipality lookup |
| `tbl_product` | Product catalog |
| `tbl_unit` | Units of measurement |
| `tbl_order` | Customer orders |
| `tbl_order_details` | Line items per order |
| `tbl_payment` | Payment records |
| `tbl_phone_number` | Customer phone numbers |
| `tbl_social_media` | Customer social media handles |

---

## Setup Guide

### 1. Install MySQL & Tailscale (all nodes)

```bash
sudo apt update
sudo apt install mysql-server
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale ip -4   # note your Tailscale IP
```

### 2. Configure MySQL (all nodes)

Edit `/etc/mysql/mysql.conf.d/mysqld.cnf` with your node-specific settings. See [`config/`](config/) for each node's configuration file.

```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# (apply your node config, then save)
sudo systemctl restart mysql
sudo ufw allow 3306/tcp
sudo ufw enable
```

### 3. Create the Replication User (all nodes)

```sql
sudo mysql

CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_pass';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;
```

### 4. Get Binary Log Position (all nodes)

```sql
SHOW MASTER STATUS;
-- Note the File and Position values — you'll need them for the next node's handshake
```

### 5. Link Each Node to Its Source

Each node points to the **previous** node in the ring. See [`scripts/02-link-nodes.sql`](scripts/02-link-nodes.sql) for the exact commands per node.

```sql
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='<previous_node_tailscale_ip>',
  SOURCE_USER='repl_user',
  SOURCE_PASSWORD='repl_pass',
  SOURCE_LOG_FILE='mysql-bin.XXXXXX',
  SOURCE_LOG_POS=XXX;
START REPLICA;
```

### 6. Verify Replication

```sql
SHOW REPLICA STATUS\G
-- Both must show YES:
-- Replica_IO_Running: Yes
-- Replica_SQL_Running: Yes
-- Seconds_Behind_Source: 0
```

If `Replica_SQL_Running: No`:

```sql
STOP REPLICA;
SET GLOBAL SQL_REPLICA_SKIP_COUNTER = 1;
START REPLICA;
SHOW REPLICA STATUS\G
```

### 7. Import Database (Matt / Node 1 only)

```bash
sudo mysql online_store < /home/<your_username>/dbms_final.sql
```

### 8. Enable Auto-Start (all nodes)

```bash
sudo systemctl enable mysql
sudo systemctl enable tailscaled
```

---

## Verification Queries

```sql
USE online_store;
SHOW TABLES;

-- Record counts should be identical on all nodes
SELECT 'Barangays' AS Table_Name, COUNT(*) FROM tbl_barangay
UNION SELECT 'Customers', COUNT(*) FROM tbl_customer
UNION SELECT 'Orders',    COUNT(*) FROM tbl_order;
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `SHOW MASTER STATUS` returns empty | `log_bin` is commented out in config — uncomment and restart MySQL |
| `Replica_SQL_Running: No` | Run `SET GLOBAL SQL_REPLICA_SKIP_COUNTER = 1` then restart replica |
| Node offline in Tailscale | Run `sudo tailscale up` and re-authenticate |
| Duplicate ID errors | Verify `auto_increment_increment = 4` and offsets are unique per node |
| Replication breaks mid-ring | Check that the offline node's Tailscale IP is reachable before restarting replica |


## Team
| Name | Role |
|---|---|
| Matthew Malto - Project Lead | Raphael Tizon |  Node 1 |
| Ella Lumawag | Kimberly Isip |Node 2 |
| Lorenzo Discutido | Derick Herrera | Node 3 |
| John Carlo Ablay | Michael Gregorio | Node 4 |