-- Group 11 - ReserveIT: Activity 4 cluster hardening.
-- By default PostgreSQL lets every login role connect to the postgres and template1 databases.
-- Run once per cluster as the superuser (safe to repeat):
--     psql -U postgres -h localhost -f 04_cluster_hardening.sql
REVOKE CONNECT ON DATABASE postgres  FROM PUBLIC;
REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;
