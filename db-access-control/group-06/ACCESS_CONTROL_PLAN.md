# Access-Control Plan - Car Rental Management System (ByaheRentals)

Database: `car_rental_db` (PostgreSQL). Backend: Spring Boot + JdbcTemplate (plain SQL, no ORM entities).
17 tables, sequence-backed integer keys, no views, no custom functions or triggers.
Sources: `Docs/User_and_Role_Documantation.md` (Activity 3) and a review of the Java code in `Application/src`.
Passwords in all scripts are placeholders.

## Accounts and group roles

| Login account | Group role | App role served | Responsibility | Required privileges |
|---|---|---|---|---|
| existing table owner (e.g. `postgres`) | - | Provisioning | Created DB and tables, ran migrations; used only for setup | Ownership of `car_rental_db` objects |
| `carrental_app` | `carrental_runtime_grp` | Customer / Staff / Finance / Admin / System Admin (enforced by the Spring Boot backend) | The only login the running app uses | SELECT on all tables; INSERT on 17 tables; UPDATE on 13 tables; DELETE on `vehicle` only; sequence USAGE/SELECT; no UPDATE/DELETE on `audit_log` |
| `carrental_report` | `carrental_readonly_grp` | Reporting / inspection | Read non-sensitive records | SELECT on 12 operational tables; column-level SELECT on `staff`, `customer`, `driver_license`, `payment`; no `audit_log` |
| `carrental_auditor` | `carrental_auditor_grp` | Oversight | Review audit trail without changing it | SELECT on `audit_log`, `rental`, `cancellation`, `damage_fee`, `damage_incident`, `vehicle_inspection`, `vehicle_maintenance`; limited columns of `staff`, `payment` |

## Justifications (from the code)
- The only DELETE in the application is `DELETE FROM vehicle` (CatalogController), so DELETE is granted on `vehicle` only.
- UPDATE is granted only on the 13 tables the code updates, plus tables locked with `SELECT ... FOR UPDATE` (needs UPDATE) or upserted with `ON CONFLICT DO UPDATE` (`rental_terms`).
- `audit_log` is insert-only for the app, so history cannot be edited from the application account.
- Password hashes (`customer`, `staff`), license numbers and photo paths, and payment proof/reference data are hidden from read-only and auditor roles using column-level grants.
- All PUBLIC privileges on the database, schema, tables, sequences and functions are revoked; nobody gets CREATE on the schema.
- New tables get no automatic access; new sequences are usable by the app.
- Application roles (Customer, Staff, Finance, Admin, System Admin) are enforced by the backend, not by PostgreSQL, as the project's own roles document states.

## Run order
1. `01_roles.sql` (as postgres, connected to `postgres`)
2. Project setup already done: `schema.sql` plus the migration files
3. `02_privileges.sql` (as the table owner, connected to `car_rental_db`)
4. `04_cluster_hardening.sql` (as postgres, once per cluster; safe to repeat)
5. Run the app as `carrental_app` without editing the owners' repo (see "Connecting the app")
6. `.\03_verify.ps1` and screenshot the output

## Connecting the app (without changing the owners' repository)
`application.properties` hard-codes the username `app_runtime`. Spring Boot lets environment variables override it, so in the PowerShell window that starts the app:
```
$env:SPRING_DATASOURCE_USERNAME = "carrental_app"
$env:SPRING_DATASOURCE_PASSWORD = "<your local password>"
```

## Verification (31 checks)
Result on PostgreSQL 16 test copy: 31 PASS, 0 FAIL. Replace with your own screenshots from the real run (PostgreSQL 18).
