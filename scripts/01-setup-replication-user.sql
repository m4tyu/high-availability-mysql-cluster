-- Run on ALL nodes after MySQL is installed and configured.
-- For nodes that already have repl_user (e.g., Ablay who was previously a slave),
-- use ALTER USER instead of CREATE USER.

-- Nodes 1, 2, 3 (first-time setup):
CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_pass';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;

-- Node 4 / any node that already has the user:
-- ALTER USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_pass';
-- GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
-- FLUSH PRIVILEGES;
