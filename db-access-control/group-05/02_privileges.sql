-- SHIORI Cafe (Group 5) - 02_privileges.sql
-- Run as the account that OWNS the tables (e.g. postgres), connected to grp10_shioricafedb.

-- 0. Make sure each login role is linked to its group role (harmless if already linked)
GRANT app_runtime_grp   TO shioricafe_app_login;
GRANT app_readonly_grp  TO shioricafe_readonly_login;
GRANT app_migration_grp TO shioricafe_migration_login;

-- 1. Remove default PUBLIC access
REVOKE ALL ON DATABASE grp10_shioricafedb FROM PUBLIC;
REVOKE ALL ON SCHEMA shioricafe_schema FROM PUBLIC;
REVOKE ALL ON ALL TABLES    IN SCHEMA shioricafe_schema FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA shioricafe_schema FROM PUBLIC;

-- 1b. Clear any pre-existing grants held by the two group roles, so only the grants below remain.
--     (Found by verification: app_readonly_grp could already SELECT customer and staff.)
REVOKE ALL ON ALL TABLES    IN SCHEMA shioricafe_schema FROM app_runtime_grp, app_readonly_grp;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA shioricafe_schema FROM app_runtime_grp, app_readonly_grp;

-- 2. Connect + schema usage
GRANT CONNECT ON DATABASE grp10_shioricafedb
  TO app_runtime_grp, app_readonly_grp, app_migration_grp;
GRANT USAGE ON SCHEMA shioricafe_schema TO app_runtime_grp, app_readonly_grp;

-- 3. Runtime (app): the backend code contains no DELETE statements -> no DELETE granted.
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA shioricafe_schema TO app_runtime_grp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA shioricafe_schema TO app_runtime_grp;

-- 4. Read-only / reporting: non-sensitive tables only
--    (no customer, staff, provider_event: personal data, credentials, provider data)
GRANT SELECT ON
  shioricafe_schema.category,
  shioricafe_schema.menu_item,
  shioricafe_schema."table",
  shioricafe_schema.reservation,
  shioricafe_schema."order",
  shioricafe_schema.order_item,
  shioricafe_schema.payment_transaction,
  shioricafe_schema.payment_refund
  TO app_readonly_grp;

-- 5. Future objects created by the account running this script
ALTER DEFAULT PRIVILEGES IN SCHEMA shioricafe_schema REVOKE ALL ON TABLES FROM PUBLIC;
