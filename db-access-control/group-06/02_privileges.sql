-- Car Rental Management System (ByaheRentals) - 02_privileges.sql
-- Run as the account that OWNS the tables (the one that ran schema.sql, e.g. postgres),
-- connected to car_rental_db:
--   psql -U postgres -d car_rental_db -f 02_privileges.sql
-- Based on the app's code: it uses JdbcTemplate with plain SQL; the only DELETE is
-- "DELETE FROM vehicle" (CatalogController); SELECT ... FOR UPDATE needs UPDATE privilege.

-- 1. Remove default PUBLIC access
REVOKE ALL ON DATABASE car_rental_db FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- 2. Connect + schema usage (no CREATE on schema for anyone)
GRANT CONNECT ON DATABASE car_rental_db
  TO carrental_runtime_grp, carrental_readonly_grp, carrental_auditor_grp;
GRANT USAGE ON SCHEMA public
  TO carrental_runtime_grp, carrental_readonly_grp, carrental_auditor_grp;

-- 3. Application runtime (Spring Boot)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO carrental_runtime_grp;
GRANT INSERT ON
  audit_log, cancellation, customer, damage_fee, damage_incident, driver_license,
  inspection_item, inspection_photo, payment, rental, rental_rate, rental_terms,
  staff, vehicle, vehicle_category, vehicle_inspection, vehicle_maintenance
  TO carrental_runtime_grp;
-- UPDATE only where the code updates (or locks rows with FOR UPDATE / ON CONFLICT DO UPDATE).
-- Not granted: audit_log (append-only), inspection_item, inspection_photo, vehicle_category.
GRANT UPDATE ON
  cancellation, customer, damage_fee, damage_incident, driver_license, payment, rental,
  rental_rate, rental_terms, staff, vehicle, vehicle_inspection, vehicle_maintenance
  TO carrental_runtime_grp;
GRANT DELETE ON vehicle TO carrental_runtime_grp;      -- the only DELETE in the code
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO carrental_runtime_grp;

-- 4. Read-only / reporting: no password hashes, license numbers, payment proof or audit log
GRANT SELECT ON
  cancellation, damage_fee, damage_incident, inspection_item, inspection_photo, rental,
  rental_rate, rental_terms, vehicle, vehicle_category, vehicle_inspection, vehicle_maintenance
  TO carrental_readonly_grp;
GRANT SELECT (staff_id, first_name, last_name, role, account_status, created_at)
  ON staff TO carrental_readonly_grp;
GRANT SELECT (customer_id, first_name, last_name, account_status, created_at)
  ON customer TO carrental_readonly_grp;
GRANT SELECT (license_id, customer_id, license_type, expiration_date, verification_status)
  ON driver_license TO carrental_readonly_grp;
GRANT SELECT (payment_id, rental_id, damage_fee_id, amount, payment_date, payment_method, payment_status)
  ON payment TO carrental_readonly_grp;

-- 5. Auditor: audit trail plus the records it describes; never credentials or payment proof
GRANT SELECT ON audit_log, rental, cancellation, damage_fee, damage_incident,
  vehicle_inspection, vehicle_maintenance TO carrental_auditor_grp;
GRANT SELECT (staff_id, first_name, last_name, role, account_status, created_at)
  ON staff TO carrental_auditor_grp;
GRANT SELECT (payment_id, rental_id, damage_fee_id, amount, payment_date, payment_method, payment_status)
  ON payment TO carrental_auditor_grp;

-- 6. Future objects: sequences usable by the app; new tables get NO automatic access
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO carrental_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC;
