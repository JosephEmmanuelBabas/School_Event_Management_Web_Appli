-- PAWPAW (Group 03) - 02_privileges.sql
-- Run as the account that OWNS the tables (the one that ran `npm run migrate`, e.g. postgres),
-- connected to the group3_Pawpaw database.

-- 1. Remove default PUBLIC access
REVOKE ALL ON DATABASE "group3_Pawpaw" FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- 2. Connect + schema usage
GRANT CONNECT ON DATABASE "group3_Pawpaw"
  TO pawpaw_runtime_grp, pawpaw_readonly_grp, pawpaw_auditor_grp;
GRANT USAGE ON SCHEMA public
  TO pawpaw_runtime_grp, pawpaw_readonly_grp, pawpaw_auditor_grp;

-- 3. Runtime (app): only the DML the code actually performs.
--    Observed in server/routes: DELETE only on prescription, vaccination,
--    password_reset_code. auth_session is not used by the routes -> no access.
GRANT SELECT, INSERT, UPDATE ON
  user_account, owner, veterinarian, service, pet, appointment,
  appointment_service, medical_record, notification
  TO pawpaw_runtime_grp;
GRANT SELECT, INSERT, UPDATE, DELETE ON prescription, vaccination, password_reset_code
  TO pawpaw_runtime_grp;
GRANT SELECT, INSERT ON audit_log TO pawpaw_runtime_grp;   -- append-only
-- Identity sequences (needed for INSERT)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO pawpaw_runtime_grp;

-- 4. Read-only / reporting: non-sensitive tables only
--    (no user_account, auth_session, password_reset_code, audit_log)
GRANT SELECT ON owner, veterinarian, service, pet, appointment,
  appointment_service, medical_record, prescription, vaccination
  TO pawpaw_readonly_grp;
-- Hide credential columns even though table is excluded; owner contact data is kept.

-- 5. Auditor: audit trail + read of core records, nothing else
GRANT SELECT ON audit_log, appointment, appointment_service, medical_record,
  prescription, vaccination, service TO pawpaw_auditor_grp;

-- 6. Future objects created by the account running this script
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE ON SEQUENCES TO pawpaw_runtime_grp;
