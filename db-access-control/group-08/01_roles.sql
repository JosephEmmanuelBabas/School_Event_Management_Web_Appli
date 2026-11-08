-- Catering Management System - 01_roles.sql
-- Run as postgres (or any account allowed to create roles), connected to the 'postgres' DB:
--   psql -U postgres -d postgres -f 01_roles.sql
-- Passwords: NOT stored in this file. Either type them when psql prompts (\password),
-- or pass them as variables (plain text, no extra quotes):
--   psql -U postgres -d postgres -v api_pw=... -v report_pw=... -v ops_pw=... -f 01_roles.sql
-- Role names use the catering_ prefix with distinct login names so they never clash with
-- the repo's optional database/roles.sql (catering_app, app_*_grp), which is far broader.
-- Safe to re-run: existing roles are kept and their attributes are re-enforced.

-- Group roles (NOLOGIN): privileges only, nobody connects as these
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['catering_runtime_grp','catering_readonly_grp','catering_ops_grp'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE', r);
    END IF;
  END LOOP;
END $$;

-- Login accounts (no password yet; set below)
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['catering_api','catering_report','catering_ops'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE', r);
    END IF;
  END LOOP;
END $$;

-- Re-enforce attributes and limits (also corrects a role that already existed)
ALTER ROLE catering_api    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 20;
ALTER ROLE catering_report LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 3;
ALTER ROLE catering_ops    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 3;

-- Read-only accounts get a statement timeout so a careless report query cannot hog the server
ALTER ROLE catering_report SET statement_timeout = '30s';
ALTER ROLE catering_ops    SET statement_timeout = '30s';

GRANT catering_runtime_grp  TO catering_api;
GRANT catering_readonly_grp TO catering_report;
GRANT catering_ops_grp      TO catering_ops;

-- Passwords (prompt unless supplied with -v)
\if :{?api_pw}
  ALTER ROLE catering_api PASSWORD :'api_pw';
\else
  \echo 'Set password for catering_api'
  \password catering_api
\endif

\if :{?report_pw}
  ALTER ROLE catering_report PASSWORD :'report_pw';
\else
  \echo 'Set password for catering_report'
  \password catering_report
\endif

\if :{?ops_pw}
  ALTER ROLE catering_ops PASSWORD :'ops_pw';
\else
  \echo 'Set password for catering_ops'
  \password catering_ops
\endif
