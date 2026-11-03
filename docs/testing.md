# Testing

The project is tested in layers. Each layer catches a different kind of mistake, and one layer (the API script) is run by hand, not by `mvnw test`.

| Layer | What it proves | How it runs |
|---|---|---|
| 1. SQL constraint tests | The database itself refuses bad data | By hand, in psql |
| 2. Backend unit tests (44) | The business rules in the service classes | `./mvnw test` |
| 3. Application start-up test | Flyway, Hibernate schema validation and every query are valid against the real database | Part of `./mvnw test` |
| 4. End-to-end API script | The running backend: login, CSRF, roles, validation, rules, audit rows, paging | By hand, against a running backend |
| 5. Frontend build and lint | The React app compiles and passes lint | `npm run build`, `npm run lint` |
| 6. Manual screen checks | Every screen, in a browser, as each role | By hand |

## 1. Database constraint tests

`test_constraints.sql` runs inside a transaction that is rolled back at the end, so it leaves no data behind. Run it as the superuser against the project database:

```
psql -U postgres -h localhost -d grp02_event_management_db -f school_event_management/script/test_constraints.sql
```

Expected results:

| Test | Expected |
|---|---|
| T1 valid event | inserted |
| T2 back-to-back event at the same venue (11:00 end, 11:00 start) | inserted |
| T3 overlapping event at the same venue | refused by `ex_event_venue_no_overlap` |
| T4 cancelled event in an occupied time slot | inserted (cancelled events release the venue) |
| T5 end time before start time | refused by `ck_event_time_order` |
| T6 invalid event status | refused by `ck_event_status` |
| T7 second attendance record for the same participant and event | refused by `uq_attendance_event_participant` |
| T8 username that differs only in letter case | refused by `uq_user_account_username_lower` |
| Row count after the final ROLLBACK | 0 |

The privileges of the application user are checked by logging in as `event_app` and trying to change the audit log and the schema (`UPDATE` and `DELETE` on `audit_log`, and `CREATE TABLE`). All three must fail with `permission denied`, while a `SELECT` on `role` succeeds.

## 2. Backend unit tests

```
cd school_event_management
./mvnw test            # Windows PowerShell: .\mvnw.cmd test
```

The service classes are tested with Mockito: the repositories are replaced by fakes, so these tests need no database and run in about a second.

| Test class | Tests | Covers |
|---|---|---|
| `VenueServiceTest` | 4 | duplicate names, trimming, audit entry on create and delete, not found |
| `EventServiceTest` | 10 | end before start, past date, venue overlap, starts as Upcoming, status transitions, locked events, schedule entries outside new times, paging totals, reversed date range |
| `ScheduleServiceTest` | 4 | entry outside the event's time, end before start, completed event locked, trimmed save with audit entry |
| `AssignmentServiceTest` | 2 | status defaults to Pending, cancelled event locked |
| `ParticipantServiceTest` | 4 | duplicate student number, trimming, delete refused when attendance exists, paging totals |
| `AttendanceServiceTest` | 7 | event not started, cancelled event, unknown participant, duplicate record, server-set time, status change, summary counts |
| `UserServiceTest` | 5 | short password, duplicate username, only the hash is stored, no self-lockout, last active Super Admin protected |
| `AuditServiceTest` | 2 | refuses to log without a logged-in user, records the logged-in user's id |
| `DashboardServiceTest` | 1 | assembles the numbers from the repositories |
| `ReportServiceTest` | 4 | totals and rate, `null` rate when nothing is recorded, reversed date range, grade labels and ordering |

Most of these also check that a refused operation writes **no** audit entry.

Not covered by a unit test: the self-service account methods (profile edit, password change), the session re-check filter, the first-account setup, and the role matrix in the security configuration. These are covered by the API script (layer 4).

## 3. Start-up test

`SchoolEventManagementApplicationTests.contextLoads` starts the whole application against the real database. It needs PostgreSQL running and `application-local.properties` filled in. A pass means:

- Flyway applied (or recognized) all migrations;
- Hibernate's `ddl-auto=validate` found every entity matching its table;
- every `@Query` in the repositories parsed.

## 4. End-to-end API script

Start the backend, then, from the repository root:

```
powershell -ExecutionPolicy Bypass -File school_event_management/script/test_api.ps1
```

It asks for the Super Admin and Event Organizer usernames and passwords (the passwords are not echoed and are not stored). It needs one account of each role.

Each line prints `PASS` or `FAIL` with the expected and actual HTTP status. The script covers:

| Section | Checks |
|---|---|
| Anonymous | no access without login, login refused without a CSRF token, wrong password |
| Super Admin | login, `/me`, may read but not create venues, logout ends the session |
| Event Organizer | venue create, duplicate, invalid body, update, get, delete, get after delete |
| Audit log | Super Admin can read, Organizer cannot, entries show the organizer |
| User management | create, duplicate username in another case, weak password, no password in responses, self-service profile and password change, old password stops working, deactivation cuts off an open session, no self-deactivation |
| Events | create, back-to-back and overlapping bookings, invalid times, past date, unknown venue, role rules, update into an overlap, filters, status transitions, locked events, cancelled events release the venue, delete rules |
| Schedules and staff | entries inside and outside the event's time, overlapping entries allowed, event shrink refused, staff default status, locked events |
| Participants and attendance | validation, duplicate student number, search, recording rules by event status, duplicates, summary counts, delete rules |
| Dashboard and reports | role rules, dashboard counts move when data changes, exact report figures, filters, error cases |
| Paging totals | page sizes, `X-Total-Count`, pages beyond the end, filters changing the total |

The script creates its own temporary venues, events and participants and deletes them again. User accounts cannot be deleted by design, so every run leaves two inactive `tmpuser...` accounts behind.

## 5. Frontend build and lint

```
cd frontend
npm run build
npm run lint
```

Expected: a successful production build, and `Found 0 warnings and 0 errors.`

## 6. Manual screen checks

Each screen was checked in the browser, as an Event Organizer and as a Super Admin, with these steps:

| Screen | Checked |
|---|---|
| Login | wrong password message, redirect to the requested page, session survives a reload, logout, Back button after logout |
| Venues | validation, duplicate name under the field, edit, delete with confirmation, search, paging, hidden buttons for Super Admin |
| Participants | server-side paging and `X-Total-Count`, search and grade filter, duplicate student number, stepping back a page after deleting the last row |
| Events | sorting, filters, date-range check, live venue-conflict warning, server refusal on save, status changes, locked events, delete |
| Event detail | schedule rules, staff, recording attendance for several students in one dialog, summary matching the table, status dropdown and removal, behaviour per event status, unknown event address |
| Dashboard and reports | figures compared with SQL queries on the database, report filters, "no data" shown as a dash |
| Users and My account | create, duplicate checks, edit, deactivate and re-activate, password reset, self-service changes, own row protected |
| Audit log | newest first, paging total matches `count(*)` |
| Home, titles, keyboard | per-role panels, "Needs attention" panel, tab titles, skip link, focus after navigation, 360 px width, 200% zoom |

Not done: an automated accessibility scan (for example Lighthouse or axe), a screen reader walk-through, and automated frontend tests.

## Results at the time of writing

| Check | Result |
|---|---|
| Backend unit and start-up tests | 44 run, 0 failures, 0 errors |
| API script | every line `PASS` |
| Frontend build | succeeds |
| Frontend lint | 0 warnings, 0 errors |
