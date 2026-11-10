-- HealthBridge (Group 4) - 02_privileges.sql
-- Run as the account that OWNS the tables (e.g. postgres), connected to grp03_projectdb.

-- 0. Make sure the login role is linked to its group role (harmless if already linked)
GRANT hb_staff TO hb_app;

-- 1. Remove default PUBLIC access
REVOKE ALL ON DATABASE grp03_projectdb FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;

-- 2. Connect + schema usage
GRANT CONNECT ON DATABASE grp03_projectdb TO hb_admin, hb_staff, hb_app;
GRANT USAGE ON SCHEMA public TO hb_admin, hb_staff, hb_app;

-- 3. Admin: full data privileges (does not own the tables, so it cannot DROP them)
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO hb_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hb_admin;

-- 4. Staff: the backend only DELETEs from these tables (see backend/staff_delete.php, backup.php)
GRANT SELECT, INSERT, UPDATE, DELETE ON
  patients, appointments, medical_notes, prescriptions, billing, deleted_records
  TO hb_staff;

-- 5. Staff: reference data is read-only
GRANT SELECT ON doctors, specialties TO hb_staff;

-- 6. Login and password-reset tables used by the PHP backend
GRANT SELECT, UPDATE ON staff_users TO hb_staff;
GRANT SELECT, INSERT, UPDATE ON staff_password_resets, patient_password_resets TO hb_staff;

-- 7. Sequences (needed for INSERT)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hb_staff;

-- 8. Future objects created by the account running this script
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO hb_admin;
