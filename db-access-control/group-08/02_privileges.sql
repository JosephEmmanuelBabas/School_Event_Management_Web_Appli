-- Catering Management System - 02_privileges.sql
-- Run as the account that OWNS the tables (the one that ran schema.sql / setup-db.js, e.g. postgres),
-- connected to catering_management_db:
--   psql -U postgres -d catering_management_db -f 02_privileges.sql
-- Based on the backend code (Express + node-postgres, plain SQL, no ORM):
--   * DELETE is used by 10 admin routes (not on admin, not on any table outside the 10 below)
--   * SELECT ... FOR UPDATE (reservation, cancellation) needs UPDATE privilege
--   * the admin table is READ-ONLY for the app: login does SELECT; accounts are created
--     only by backend/create-admin.js, which must be run as the owner account
--   * tables use GENERATED ... AS IDENTITY, so INSERT works with no sequence grants
--   * connect-pg-simple stores admin sessions in a "session" table (INSERT/UPDATE/DELETE/SELECT)
-- Safe to re-run: every grant to the three groups is revoked first, then re-applied.

-- 0. The session table normally gets created by the app at first start (createTableIfMissing).
--    Create it here as owner so the app account never needs CREATE on the schema.
--    DDL matches connect-pg-simple's own table.sql.
CREATE TABLE IF NOT EXISTS "session" (
  "sid"    varchar NOT NULL COLLATE "default",
  "sess"   json NOT NULL,
  "expire" timestamp(6) NOT NULL,
  CONSTRAINT "session_pkey" PRIMARY KEY ("sid")
);
CREATE INDEX IF NOT EXISTS "IDX_session_expire" ON "session" ("expire");

-- 1. Remove default PUBLIC access
REVOKE ALL ON DATABASE catering_management_db FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- 1b. Reset the three groups so re-running this file never leaves stale grants behind
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM catering_runtime_grp, catering_readonly_grp, catering_ops_grp;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM catering_runtime_grp, catering_readonly_grp, catering_ops_grp;

-- 2. Connect + schema usage (no CREATE on schema for anyone)
GRANT CONNECT ON DATABASE catering_management_db
  TO catering_runtime_grp, catering_readonly_grp, catering_ops_grp;
GRANT USAGE ON SCHEMA public
  TO catering_runtime_grp, catering_readonly_grp, catering_ops_grp;

-- 3. Application runtime (Express API)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO catering_runtime_grp;
-- INSERT / DELETE: the 10 business tables the routes write + the session store.
-- Not granted: admin (accounts are created only by create-admin.js run as owner).
GRANT INSERT, DELETE ON
  cancellation, customer, employee, event_assignment, inventory, menu_item,
  package, payment, reservation, reservation_menu, "session"
  TO catering_runtime_grp;
-- UPDATE: every table the code updates or row-locks with FOR UPDATE.
-- customer is column-limited: no code path ever changes password_hash or customer_id.
GRANT UPDATE ON
  cancellation, employee, event_assignment, inventory, menu_item,
  package, payment, reservation, reservation_menu, "session"
  TO catering_runtime_grp;
GRANT UPDATE (first_name, last_name, email, phone, address) ON customer TO catering_runtime_grp;

-- 4. Read-only / reporting: no password hashes, contact details, payment references, admin or sessions
GRANT SELECT ON
  cancellation, event_assignment, inventory, menu_item, package, reservation, reservation_menu
  TO catering_readonly_grp;
GRANT SELECT (customer_id, first_name, last_name)
  ON customer TO catering_readonly_grp;
GRANT SELECT (employee_id, first_name, last_name, role)
  ON employee TO catering_readonly_grp;
GRANT SELECT (payment_id, reservation_id, payment_amount, payment_date, payment_status, payment_method)
  ON payment TO catering_readonly_grp;

-- 5. Catering operations / staff (proposed role from docs/roles-and-privileges.md; read-only):
--    event details, menus, assignments, inventory; no money, no cancellations, no credentials
GRANT SELECT ON
  event_assignment, inventory, menu_item, package, reservation, reservation_menu
  TO catering_ops_grp;
GRANT SELECT (customer_id, first_name, last_name)
  ON customer TO catering_ops_grp;
GRANT SELECT (employee_id, first_name, last_name, role, phone)
  ON employee TO catering_ops_grp;

-- 6. Future objects: new tables get NO automatic access (identity columns need no sequence grants)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC;
