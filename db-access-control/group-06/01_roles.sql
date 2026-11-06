-- Car Rental Management System (ByaheRentals) - 01_roles.sql
-- Run as postgres (or any account allowed to create roles), connected to the 'postgres' DB:
--   psql -U postgres -d postgres -f 01_roles.sql
-- Passwords are PLACEHOLDERS. Replace them locally; never commit real passwords.
-- Role names use the carrental_ prefix so they never clash with the project's own app_*_grp roles.

CREATE ROLE carrental_runtime_grp  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE carrental_readonly_grp NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE carrental_auditor_grp  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;

CREATE ROLE carrental_app     LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'pass123';
CREATE ROLE carrental_report  LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'pass1234';
CREATE ROLE carrental_auditor LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'pass12345';

GRANT carrental_runtime_grp  TO carrental_app;
GRANT carrental_readonly_grp TO carrental_report;
GRANT carrental_auditor_grp  TO carrental_auditor;
