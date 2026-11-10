-- SHIORI Cafe (Group 5) - 01_roles.sql
-- Run as postgres (or any account that can create roles), connected to the 'postgres' DB.
-- Passwords are PLACEHOLDERS: replace locally, never commit real ones.
-- NOTE: if these roles already exist on the server, skip the CREATE ROLE lines.

-- Group roles (NOLOGIN, no elevated attributes)
CREATE ROLE app_runtime_grp   NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE app_readonly_grp  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE app_migration_grp NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- Login roles
CREATE ROLE shioricafe_app_login       LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_app';
CREATE ROLE shioricafe_readonly_login  LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_readonly';
CREATE ROLE shioricafe_migration_login LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_migration';

-- Memberships
GRANT app_runtime_grp   TO shioricafe_app_login;
GRANT app_readonly_grp  TO shioricafe_readonly_login;
GRANT app_migration_grp TO shioricafe_migration_login;
