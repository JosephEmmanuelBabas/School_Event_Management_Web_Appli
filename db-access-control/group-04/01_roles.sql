-- HealthBridge (Group 4) - 01_roles.sql
-- Run as postgres (or any account that can create roles), connected to the 'postgres' DB.
-- Passwords are PLACEHOLDERS: replace locally, never commit real ones.
-- NOTE: if these roles already exist on the server, skip this file.

-- Group roles (NOLOGIN, no elevated attributes)
CREATE ROLE hb_admin NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE hb_staff NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- Login role used by the PHP backend
CREATE ROLE hb_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'CHANGE_ME_app';

-- Membership: the backend connects as hb_app, which inherits hb_staff
GRANT hb_staff TO hb_app;
