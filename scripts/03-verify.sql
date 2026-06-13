-- Run on each node to verify the circular replication is healthy.

-- 1. Check replication status — both should show YES and Seconds_Behind_Source = 0
SHOW REPLICA STATUS\G

-- 2. Confirm the online_store database replicated to this node
SHOW DATABASES;

-- 3. Confirm all 11 tables are present
USE online_store;
SHOW TABLES;

-- 4. Verify row counts are identical across all nodes
SELECT 'Barangays'  AS Table_Name, COUNT(*) AS row_count FROM tbl_barangay
UNION ALL
SELECT 'Customers',                COUNT(*)               FROM tbl_customer
UNION ALL
SELECT 'Orders',                   COUNT(*)               FROM tbl_order;

-- 5. Quick data check
SELECT COUNT(*) FROM tbl_customer;

-- 6. Fix if Replica_SQL_Running is No
-- STOP REPLICA;
-- SET GLOBAL SQL_REPLICA_SKIP_COUNTER = 1;
-- START REPLICA;
-- SHOW REPLICA STATUS\G
