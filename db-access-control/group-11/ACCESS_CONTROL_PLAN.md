# Access-control plan: Group 11, ReserveIT

Database: `ReserveIT` (PostgreSQL), schema `public`, 8 tables, 7 ID sequences, no views.
Application roles come from the owners' `docs/user-roles.md`: Requester (student or faculty), Staff, Administrator, plus report viewers outside the web app.

| Login account | Group role | Application role served | Responsibility | Privileges and reason |
|---|---|---|---|---|
| a4_app | a4_runtime_grp | Requester, Staff, Administrator (the web app uses one account) | Run the web app | SELECT, INSERT on the main tables; UPDATE only on the status and payment columns the code changes; DELETE only on room and material; USAGE on the 7 ID sequences. No DELETE on reservations or penalties, because they are history |
| a4_report | a4_readonly_grp | Report viewer | View usage and penalty data | SELECT on reporting tables; SELECT on only the safe columns of app_user and staff, so no email and no password hash |
| a4_entry | a4_dataentry_grp | Front-desk staff encoding requests | Add new requests | SELECT on department, room, material; SELECT and INSERT on reservation and reservation_material; no UPDATE or DELETE |
| a4_audit | a4_auditor_grp | Auditor | Inspect without changing | SELECT on all tables, but not the password_hash columns |

## Design decisions
- No account is a superuser and none has CREATEDB or CREATEROLE.
- Passwords are set with `\password`, so none appear in a script, the repository or the PDF.
- `REVOKE ALL ... FROM PUBLIC` on the database, the tables and the sequences, so only granted groups have access.
- Table privileges do not cover sequences, so the ID sequences are granted separately.
- Verification showed that every login role could connect to the `postgres` database by default. `04_cluster_hardening.sql` revokes that.
- The a4_* names differ from the owners' reserveit_* accounts because roles are cluster-wide.
