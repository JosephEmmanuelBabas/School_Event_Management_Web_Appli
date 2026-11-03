# High School Event Management System

A web-based system that centralizes school event information that is usually scattered across paper forms, spreadsheets and messaging apps: events, schedules, venues, staff assignments, participant attendance and an audit trail, in one place.

Group 2 project for the Database Administration course. The design (requirements, business rules, ERD, schema, constraints, architecture) was planned first in the project blueprint; this repository is the implementation.

## Features

| Area | What it does |
|---|---|
| Login and roles | Session login, bcrypt-hashed passwords, two roles (Super Admin, Event Organizer) enforced on the server |
| Events | Create, view, update, filter, sort and page events; statuses Upcoming, Ongoing, Completed, Cancelled |
| Scheduling | Several schedule entries per event; a venue cannot be double-booked (checked in the form, in the service, and by a PostgreSQL exclusion constraint) |
| Venues and staff | Venue records with capacity; staff assigned to an event as plain records (not user accounts) |
| Participants and attendance | Student records; one attendance record per student per event (Present, Late, Absent); per-event summary |
| Dashboard and reports | Super Admin overview and attendance reports by event and by grade level, all computed from live data |
| User management | Super Admin creates, edits, deactivates and re-activates accounts; users change their own profile and password |
| Audit log | Every create, update and delete is recorded with the user, written in the same transaction as the change; append-only |

### Who can do what

| | Super Admin | Event Organizer |
|---|---|---|
| View events, venues, participants, attendance | Yes | Yes |
| Create, edit, delete them | No | Yes |
| Dashboard, reports, audit log, user management | Yes | No |
| Own profile and password | Yes | Yes |

The React app hides buttons a role cannot use, but that is only a convenience. The server checks the role on every request.

## Technology

| Layer | Technology |
|---|---|
| Frontend | React 19, React Router 8, Vite 8, plain CSS, oxlint |
| Backend | Java 25, Spring Boot 4.1 (Web MVC, Data JPA / Hibernate, Security, Validation), Maven wrapper |
| Database | PostgreSQL 18, Flyway 12 migrations |

```
Browser (React + Vite, port 5173)
   |   /api/*   (Vite dev proxy)
   v
Spring Boot REST API (port 8080)      controller -> service -> repository
   |   JDBC as user event_app          Security: session cookie, CSRF token, roles
   v
PostgreSQL 18
   database grp02_event_management_db, schema school_event_management_db
   (the schema changes only through Flyway migrations, run as event_owner)
```

The browser never talks to PostgreSQL. The application user (`event_app`) can read and write data but cannot change the schema, and it can only read and append to `audit_log`.

## Setup from a clean clone

### Prerequisites

- JDK 25 (`java -version`)
- Node.js 20.19+ or 22.12+ (developed on 24) with npm (`node -v`)
- PostgreSQL 18 with the `psql` client (`psql --version`)
- Git

Maven does not need to be installed: the project includes the Maven wrapper.

### 1. Create the database

Run the one-time setup as the PostgreSQL superuser. It creates the database, the two database users, the schema and the `btree_gist` extension, and asks you to choose a password for each user:

```
psql -U postgres -h localhost -f docs/database-setup.sql
```

Remember the two passwords. Nothing else is created here: the tables come from the migrations in step 3.

### 2. Configure the backend

In `school_event_management/src/main/resources/`, copy `application-local.properties.example` to `application-local.properties` and fill it in:

```properties
spring.datasource.password=<the event_app password from step 1>
spring.flyway.password=<the event_owner password from step 1>

app.bootstrap.admin.username=admin
app.bootstrap.admin.password=<a password of at least 10 characters>
```

`application-local.properties` is ignored by Git and must never be committed. The two `app.bootstrap.*` admin lines create the first Super Admin when the application starts and no Super Admin exists yet. An Event Organizer can be created later on the Users page (or with the optional `app.bootstrap.organizer.*` lines from the example file).

### 3. Start the backend

```
cd school_event_management
./mvnw spring-boot:run            # on Windows PowerShell: .\mvnw.cmd spring-boot:run
```

On the first start Flyway creates the nine tables and seeds the two roles. In the log, look for `Successfully applied 3 migrations` and `Created first Super Admin account`.

### 4. Start the frontend

```
cd frontend
npm install
npm run dev
```

On Windows PowerShell, if `npm` says running scripts is disabled, use Command Prompt or Git Bash, or type `npm.cmd`.

Open <http://localhost:5173>. Log in with the Super Admin from step 2.

### 5. First steps in the app

1. Open **Users** and add an Event Organizer.
2. Open **My account** and change the Super Admin password to one only you know.
3. Delete the `app.bootstrap.*` lines from `application-local.properties`. The accounts live in the database, so the lines are no longer needed.

## Tests

| Command | What it runs |
|---|---|
| `cd school_event_management && ./mvnw test` | 44 backend tests (needs PostgreSQL and the local settings, because one test starts the whole application) |
| `cd frontend && npm run lint` | oxlint over the frontend source |
| `cd frontend && npm run build` | Production build of the frontend |
| `powershell -ExecutionPolicy Bypass -File school_event_management/script/test_api.ps1` | End-to-end API checks against the running backend (prompts for the two logins) |

See [docs/testing.md](docs/testing.md) for what each layer covers.

## Documentation

| File | Contents |
|---|---|
| [docs/api.md](docs/api.md) | Every REST endpoint: role, request, responses, errors |
| [docs/database-setup.sql](docs/database-setup.sql) | One-time database and user setup |
| [docs/testing.md](docs/testing.md) | Test layers, how to run them, what was verified |
| [docs/limitations.md](docs/limitations.md) | Known limitations and the checklist for a real deployment |

## Project structure

```
.
├── README.md
├── docs/                                  documentation and the database setup script
├── frontend/                              React app (Vite)
│   └── src/
│       ├── api/                           fetch wrapper: CSRF token, errors, paging header
│       ├── auth/                          login state, protected routes
│       ├── components/                    table, dialogs, form field, notifications, layout
│       ├── hooks/                         small data-loading hooks
│       ├── pages/                         one folder per screen
│       └── utils/                         date/time formatting, status rules
└── school_event_management/               Spring Boot backend
    ├── script/test_api.ps1                end-to-end API test script
    └── src/main/
        ├── java/com/school_event/school_event_management/
        │   ├── config/                    security configuration
        │   ├── security/                  login lookup, session re-check, first-account setup
        │   ├── controller/                REST endpoints
        │   ├── service/                   business rules and transactions
        │   ├── repository/                database access (Spring Data)
        │   ├── entity/                    table mappings
        │   ├── dto/                       request and response shapes
        │   ├── exception/                 error handling
        │   └── audit/                     audit logging
        └── resources/db/migration/        Flyway migrations V1 to V3
```

## Database

Nine tables: `role`, `user_account`, `venue`, `event`, `event_schedule`, `event_assignment`, `participant`, `attendance`, `audit_log` (plus Flyway's own `flyway_schema_history`). Highlights:

- Every foreign key is enforced; required columns are NOT NULL; status columns have CHECK constraints.
- `event`: an exclusion constraint prevents two non-cancelled events from overlapping at the same venue, and a CHECK requires the end time to be after the start time.
- `attendance`: `UNIQUE (event_id, participant_id)`.
- `user_account`: unique username and email, compared without regard to case.
- Hibernate runs with `ddl-auto=validate`, so it can never change the schema. Add changes as a new migration (`V4__...sql`) and never edit an applied one.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `password authentication failed for user ...` | A password in `application-local.properties` does not match the one set in step 1 |
| `permission denied for schema` | The schema was not created with `AUTHORIZATION event_owner`; rerun the setup script |
| `Found non-empty schema(s) ... but no schema history table` | Tables were created by hand; Flyway must be the only thing that creates them |
| Login page says it cannot reach the server | The backend is not running on port 8080 |
| `Port 5173 is already in use` | Another Vite process is running; close it |
| Everything returns 401 after a while | The session expired (30 minutes); log in again |
