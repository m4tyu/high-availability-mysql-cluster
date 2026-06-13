-- Circular ring handshake commands.
-- Run the block for YOUR node. Replace SOURCE_LOG_FILE and SOURCE_LOG_POS
-- with the values from SHOW MASTER STATUS on the source node.

-- ─── NODE 2 (Ella) → replicates from Node 1 (Matt: 100.65.253.91) ─────────
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST     = '100.65.253.91',
  SOURCE_USER     = 'repl_user',
  SOURCE_PASSWORD = 'repl_pass',
  SOURCE_LOG_FILE = 'mysql-bin.000004',   -- replace with actual value
  SOURCE_LOG_POS  = 157;                  -- replace with actual value
START REPLICA;

-- ─── NODE 3 (Migol) → replicates from Node 2 (Ella: 100.113.126.37) ────────
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST     = '100.113.126.37',
  SOURCE_USER     = 'repl_user',
  SOURCE_PASSWORD = 'repl_pass',
  SOURCE_LOG_FILE = 'mysql-bin.000006',   -- replace with actual value
  SOURCE_LOG_POS  = 852;                  -- replace with actual value
START REPLICA;

-- ─── NODE 4 (Ablay) → replicates from Node 3 (Migol: 100.87.253.15) ────────
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST     = '100.87.253.15',
  SOURCE_USER     = 'repl_user',
  SOURCE_PASSWORD = 'repl_pass',
  SOURCE_LOG_FILE = 'mysql-bin.000002',   -- replace with actual value
  SOURCE_LOG_POS  = 157;                  -- replace with actual value
START REPLICA;

-- ─── NODE 1 (Matt) → replicates from Node 4 (Ablay: 100.123.175.41) ────────
-- This closes the ring.
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST     = '100.123.175.41',
  SOURCE_USER     = 'repl_user',
  SOURCE_PASSWORD = 'repl_pass',
  SOURCE_LOG_FILE = 'mysql-bin.000001',   -- replace with actual value
  SOURCE_LOG_POS  = 851;                  -- replace with actual value
START REPLICA;
