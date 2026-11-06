-- PAWPAW (Group 03) - 01_roles.sql
-- Run as postgres (or any account that can create roles), connected to the 'postgres' DB.
-- Tables are assumed to be owned by the account that ran `npm run migrate` (e.g. postgres).
-- Passwords are PLACEHOLDERS: replace locally, never commit real ones.

-- Group roles (NOLOGIN, no elevated attributes)
CREATE ROLE pawpaw_runtime_grp  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE pawpaw_readonly_grp NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE pawpaw_auditor_grp  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- Login roles
CREATE ROLE pawpaw_app     LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_app';
CREATE ROLE pawpaw_report  LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_report';
CREATE ROLE pawpaw_auditor LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_auditor';

-- Memberships
GRANT pawpaw_runtime_grp  TO pawpaw_app;
GRANT pawpaw_readonly_grp TO pawpaw_report;
GRANT pawpaw_auditor_grp  TO pawpaw_auditor;
