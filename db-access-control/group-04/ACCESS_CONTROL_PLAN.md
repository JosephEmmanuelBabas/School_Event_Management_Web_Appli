# Access-Control Plan - Project: HealthBridge Clinic Management System (Group 4)

Database: `grp03_projectdb` (PostgreSQL). 11 tables, 2 views, identity (sequence-backed) keys, `pgcrypto` extension.
Roles source: `database/roles.sql` and the later update scripts in the project. Passwords are placeholders in the scripts.

## Accounts and group roles

| Login account | Group role | App role served | Responsibility | Required privileges |
|---|---|---|---|---|
| `hb_app` | inherits `hb_staff` | PHP backend (all clinic users) | Normal application operations | Same as `hb_staff` |
| (none, NOLOGIN) | `hb_staff` | Clinic staff operations | Manage clinical records | SELECT/INSERT/UPDATE/DELETE on patients, appointments, medical_notes, prescriptions, billing, deleted_records; SELECT on doctors, specialties; SELECT/UPDATE on staff_users; SELECT/INSERT/UPDATE on staff_password_resets and patient_password_resets; sequence USAGE and SELECT |
| (none, NOLOGIN) | `hb_admin` | Administration | Full data access | ALL privileges on all tables and sequences (does not own the tables) |

## Justifications (from reading the app code)
- The backend only DELETEs from patients, appointments, medical_notes, prescriptions, billing and deleted_records (`staff_delete.php`, `backup.php`), so staff get DELETE on those tables only.
- doctors and specialties are reference data: staff can read them but not modify or delete them.
- Every clinical delete is copied into `deleted_records` first, so an accidental delete can be restored.
- The application connects as `hb_app`, never as the `postgres` superuser.
- `hb_admin` has full data privileges but does not own the tables, so it cannot DROP them.
- All PUBLIC privileges on the database, the `public` schema, tables and sequences are revoked. Only the three project roles keep explicit CONNECT and USAGE.
- Function privileges were left unchanged because the project uses the `pgcrypto` extension.
- Cluster-level: PUBLIC CONNECT on `postgres`/`template1` revoked (see 04).

## Run order
1. `01_roles.sql` (maintenance DB). Skip if the roles already exist.
2. `02_privileges.sql` (as the table owner, connected to `grp03_projectdb`).
3. `04_cluster_hardening.sql` (superuser, once per cluster, only if PUBLIC can still connect to `postgres`).
4. Point the app's `config.php` at `hb_app` (local only, never committed).
5. `03_verify.ps1` and screenshot the output.

## Verification run (15 checks)
Checks run as each role using `SET ROLE`, each inside BEGIN/ROLLBACK so no data changes. Covers staff (read, update, delete allowed on clinical tables; update/delete denied on reference tables; DROP, CREATE TABLE, CREATE DATABASE, CREATE ROLE denied), `hb_app` (inherits staff rights), and `hb_admin` (full data access, DROP denied because it is not the owner).

Result: PASS=15 FAIL=0.

Finding: The verification run showed that any login role (including `hb_app`) could connect to the `postgres` database, because PUBLIC has CONNECT on it by default. This was fixed by `04_cluster_hardening.sql` (REVOKE CONNECT on `postgres` and `template1` from PUBLIC). The check `has_database_privilege('hb_app','postgres','CONNECT')` now returns false.
