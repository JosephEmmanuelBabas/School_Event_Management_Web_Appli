-- One-time database setup for the High School Event Management System.
--
-- Run as the PostgreSQL superuser, from the repository root:
--     psql -U postgres -h localhost -f docs/database-setup.sql
--
-- It is safe to run again: every step checks whether the object already exists.
-- It asks you to choose a password for each of the two database users. Passwords are
-- typed at the prompt, so they are never stored in this file or in your shell history.
--
-- It does NOT create any tables. The tables come from the Flyway migrations in
-- school_event_management/src/main/resources/db/migration, which the backend applies
-- when it starts.
--
-- Note: these steps mirror the setup used during development; they were not
-- run again as a single script when this file was written.

-- 1. The database (CREATE DATABASE cannot run inside a function, so psql's \gexec is used).
SELECT 'CREATE DATABASE grp02_event_management_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'grp02_event_management_db')
\gexec

\connect grp02_event_management_db

-- 2. The two database users.
--    event_owner : owns the schema and runs the Flyway migrations.
--    event_app   : used by the running application. It gets only the privileges the
--                  migration V3__app_privileges.sql grants (it can read and write data,
--                  but it cannot change the schema and it can only append to audit_log).
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'event_owner') THEN
        CREATE ROLE event_owner LOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'event_app') THEN
        CREATE ROLE event_app LOGIN;
    END IF;
END
$$;

-- 3. Choose a password for each (you are prompted; nothing is echoed).
\password event_owner
\password event_app

-- 4. The schema, owned by event_owner.
CREATE SCHEMA IF NOT EXISTS school_event_management_db AUTHORIZATION event_owner;

-- 5. The extension that lets the venue-overlap rule combine "same venue" with
--    "overlapping time range" in one exclusion constraint. It is installed in the
--    public schema on purpose, so the project schema stays empty for Flyway.
CREATE EXTENSION IF NOT EXISTS btree_gist SCHEMA public;

-- 6. Check the result.
\echo
\echo '--- users (expect event_owner and event_app) ---'
\du event_owner
\du event_app
\echo '--- schemas (expect school_event_management_db owned by event_owner) ---'
\dn school_event_management_db
\echo '--- extensions (expect btree_gist in schema public) ---'
\dx btree_gist
