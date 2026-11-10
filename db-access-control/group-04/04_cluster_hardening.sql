-- HealthBridge (Group 4) - 04_cluster_hardening.sql
-- Run as a superuser/DBA ONCE per cluster. By default PUBLIC can CONNECT to the
-- 'postgres' and 'template1' databases, so any login role (incl. hb_app) could connect.
-- NOTE: other apps' DBs on the same cluster need the same REVOKE ... FROM PUBLIC.
REVOKE CONNECT ON DATABASE postgres  FROM PUBLIC;
REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;
