# Access-Control Plan - Project: PAWPAW Clinic (Group 03)

Database: `group3_Pawpaw` (PostgreSQL). 14 tables, identity (sequence-backed) keys, 1 trigger function.
Roles source: `docs/PAWPAW_App_User_Roles.md` (Activity 3). Passwords are placeholders in the scripts.

## Accounts and group roles

| Login account | Group role | App role served | Responsibility | Required privileges |
|---|---|---|---|---|
| `group3_Pawpawa` | (owner; CREATEDB, CREATEROLE, not superuser) | Provisioning | Owns DB and tables; runs `migrate`, `create-admin`, `seed` | Ownership of `group3_Pawpaw` objects |
| `pawpaw_app` | `pawpaw_runtime_grp` | Admin / Staff / Vet / Pet Owner (the Express server) | Normal app operations | SELECT/INSERT/UPDATE on core tables; DELETE only on `prescription`, `vaccination`, `password_reset_code`; SELECT+INSERT only on `audit_log`; sequence USAGE; no `auth_session` |
| `pawpaw_report` | `pawpaw_readonly_grp` | Reporting | Read non-sensitive records | SELECT on owner, veterinarian, service, pet, appointment, appointment_service, medical_record, prescription, vaccination |
| `pawpaw_auditor` | `pawpaw_auditor_grp` | Admin oversight (audit logs) | Inspect without modifying | SELECT on audit_log, appointment, appointment_service, medical_record, prescription, vaccination, service |

## Justifications (from reading the app code)
- Only 3 tables are ever DELETEd by the code, so the runtime role gets DELETE on only those.
- `audit_log` is append-only for the app: tampering with history is blocked at the DB.
- `auth_session` is not referenced by any route, so the runtime role has no access to it.
- `user_account` (password hashes) and `password_reset_code` are excluded from read-only/auditor roles.
- All PUBLIC privileges on the DB, `public` schema, tables, sequences and functions are revoked.
- Cluster-level: PUBLIC CONNECT on `postgres`/`template1` revoked (see 04).

## Run order
1. `01_roles.sql` (maintenance DB) -> create DB `group3_Pawpaw OWNER group3_Pawpawa`
2. Run the project's `npm run migrate` / `create-admin` as `group3_Pawpawa` (so it owns the tables)
3. `02_privileges.sql` (as `group3_Pawpawa`, connected to `group3_Pawpaw`)
4. `04_cluster_hardening.sql` (superuser, once per cluster)
5. Point the app's `DATABASE_URL` at `pawpaw_app` (local `.env`, never committed)
6. `03_verify.sh` and screenshot the output

## Verification run (25 checks) - result: 25 PASS, 0 FAIL
Before `04`, 1 check FAILED: `pawpaw_app` could connect to the `postgres` database because PUBLIC has CONNECT by default. Fixed by `04_cluster_hardening.sql`.
An early version of the CREATE DATABASE test was "denied" only because it ran inside a transaction block; it now runs standalone and is denied with `permission denied to create database`.
Tested with PostgreSQL 16. Replace this with your own screenshots from the real run for the PDF.
