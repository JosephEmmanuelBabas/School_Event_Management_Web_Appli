-- Group 11 - ReserveIT: Activity 4 roles.
-- Run once as the PostgreSQL superuser (postgres), connected to any database:
--     psql -U postgres -h localhost -f 01_roles.sql
-- No password is stored in this file. Set each login password afterwards with \password (see the end).
-- Roles are cluster-wide, so these names (a4_*) are different from the owners' own accounts (reserveit_*).

DO $$
BEGIN
    -- Group roles: hold privileges, cannot log in
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_runtime_grp')   THEN CREATE ROLE a4_runtime_grp   NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_readonly_grp')  THEN CREATE ROLE a4_readonly_grp  NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_dataentry_grp') THEN CREATE ROLE a4_dataentry_grp NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_auditor_grp')   THEN CREATE ROLE a4_auditor_grp   NOLOGIN; END IF;

    -- Login accounts: no elevated attributes
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_app')    THEN CREATE ROLE a4_app    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_report') THEN CREATE ROLE a4_report LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_entry')  THEN CREATE ROLE a4_entry  LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'a4_audit')  THEN CREATE ROLE a4_audit  LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE; END IF;
END
$$;

-- Memberships: each login account belongs to exactly one group role
GRANT a4_runtime_grp   TO a4_app;
GRANT a4_readonly_grp  TO a4_report;
GRANT a4_dataentry_grp TO a4_entry;
GRANT a4_auditor_grp   TO a4_audit;

-- Set the four passwords now, by hand. Each command asks you to type the password twice, and nothing is saved in a file:
--     \password a4_app
--     \password a4_report
--     \password a4_entry
--     \password a4_audit
