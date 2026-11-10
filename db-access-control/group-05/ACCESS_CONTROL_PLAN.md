# Access-Control Plan - Project: SHIORI Café Study Café Reservation and Ordering System (Group 5)

Database: `grp10_shioricafedb` (PostgreSQL), schema `shioricafe_schema`. 17 tables, 3 views, `btree_gist` extension, identity keys.
Roles source: `docs/USER_ROLE_SETUP.md`. Passwords are placeholders in the scripts and are never stored in the repository.

## Accounts and group roles

| Login account | Group role | App role served | Responsibility | Required privileges |
|---|---|---|---|---|
| `shioricafe_app_login` | `app_runtime_grp` | Guest, Customer, Cashier, Manager (through the backend) | Normal application operations | SELECT/INSERT/UPDATE on all tables in `shioricafe_schema`; sequence USAGE and SELECT; no DELETE |
| `shioricafe_readonly_login` | `app_readonly_grp` | Reporting | Read non-sensitive records | SELECT on category, menu_item, table, reservation, order, order_item, payment_transaction, payment_refund |
| `shioricafe_migration_login` | `app_migration_grp` | Database maintainers | Approved migrations only | Not used by the application at runtime |

## Justifications (from reading the app code and docs)
- The backend code contains no DELETE statements, so the runtime role has no DELETE. This protects reservation and payment history from accidental deletion.
- The read-only role cannot read `customer` or `staff` (personal data and credentials) or `provider_event` (payment-provider data).
- End users never receive PostgreSQL logins. The backend connects with one dedicated runtime account, and the application checks each user's role itself.
- The runtime and read-only accounts are not superusers and do not own the schema, so they cannot DROP tables or create objects.
- All PUBLIC privileges on the database, the schema, tables and sequences are revoked.
- The migration role is kept separate so the normal application never has structure-changing rights.
- Cluster-level: PUBLIC CONNECT on `postgres`/`template1` revoked (see 04).

## Run order
1. `01_roles.sql` (maintenance DB). Skip if the roles already exist.
2. `02_privileges.sql` (as the table owner, connected to `grp10_shioricafedb`).
3. `04_cluster_hardening.sql` (superuser, once per cluster, only if PUBLIC can still connect to `postgres`).
4. Point the app's `.env` at `shioricafe_app_login` (local only, never committed).
5. `03_verify.ps1` and screenshot the output.

## Verification run (15 checks)
Checks run as each role using `SET ROLE`, each inside BEGIN/ROLLBACK so no data changes. Covers the runtime login (read, update and insert allowed; DELETE on category and payment_transaction denied; DROP, CREATE TABLE, CREATE DATABASE, CREATE ROLE denied) and the read-only login (reservation read allowed; insert, update, delete denied; customer and staff tables unreadable).

Result: PASS=15 FAIL=0 (second run, after the fixes below).

Findings:
1. The first run showed 13 PASS and 2 FAIL. The read-only group role (`app_readonly_grp`) could still read the `customer` and `staff` tables because of a pre-existing grant. `02_privileges.sql` was updated to clear the group roles' existing grants before applying the least-privilege grants, and the rerun passed all 15 checks.
2. Any login role (including `shioricafe_app_login`) could connect to the `postgres` database, because PUBLIC has CONNECT on it by default. This was fixed by `04_cluster_hardening.sql` (REVOKE CONNECT on `postgres` and `template1` from PUBLIC). The check now returns false.
