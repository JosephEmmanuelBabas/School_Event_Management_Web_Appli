-- Catering Management - 04_cluster_hardening.sql
-- Run as a superuser/DBA ONCE per cluster (safe to repeat). By default PUBLIC can CONNECT
-- to the 'postgres' and 'template1' databases, so any login role (including each catering
-- account) could connect there.
-- NOTE: other apps' DBs on the same cluster need the same REVOKE ... FROM PUBLIC.
-- NOTE: backend/scripts/setup-db.js connects to 'postgres' to create the database; run it
--       as a superuser (the default DB_USER=postgres), which is unaffected by this REVOKE.
REVOKE CONNECT ON DATABASE postgres  FROM PUBLIC;
REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;
