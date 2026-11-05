# High School Event Management System

A web-based system that centralizes school event information that is usually scattered across paper forms, spreadsheets and messaging apps: events, schedules, venues, staff assignments, participant attendance and an audit trail, in one place.

Group 2 DBA project Web App for the Database Administration course. The design (requirements, business rules, ERD, schema, constraints, architecture) was planned first in the project blueprint; this repository is the implementation.

## Contents

- [Features](#features)
- [Technology](#technology)
- [Quick start](#quick-start)
- [Setup step by step](#setup-step-by-step)
- [Using it day to day](#using-it-day-to-day)
- [Starting over from scratch](#starting-over-from-scratch)
- [Tests](#tests)
- [Documentation](#documentation)
- [Project structure](#project-structure)
- [Database](#database)
- [Troubleshooting](#troubleshooting)

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

## Quick start

For people who have done this before. Every step is explained in detail in the next section.

```
git clone https://github.com/JosephEmmanuelBabas/School_Event_Management_Web_Appli.git
cd School_Event_Management_Web_Appli

psql -U postgres -h localhost -f docs/database-setup.sql          # choose 2 passwords when asked
cp school_event_management/src/main/resources/application-local.properties.example \
   school_event_management/src/main/resources/application-local.properties
# edit application-local.properties: the 2 database passwords + the admin login

cd school_event_management && ./mvnw spring-boot:run             # terminal 1 (Windows: .\mvnw.cmd ...)
cd frontend && npm install && npm run dev                        # terminal 2
# open http://localhost:5173 and log in with the admin from application-local.properties
```

## Setup step by step

The whole setup takes about 20 to 30 minutes the first time, mostly downloads. Follow the steps in order, and do the **check** at the end of each step before moving on. If a check fails, the [Troubleshooting](#troubleshooting) section lists the usual causes.

### Before you begin

#### The tools you need

| Tool | Version | Where to get it | Check it with | You should see something like |
|---|---|---|---|---|
| JDK (Java) | 25 | Eclipse Temurin or Oracle JDK | `java -version` | `java version "25.0.2"` (any 25.x) |
| Node.js (includes npm) | 20.19+, 22.12+ or 24 | nodejs.org (LTS) | `node -v` | `v24.22.0` |
| PostgreSQL (includes `psql`) | 18 | postgresql.org (the Windows installer is from EDB) | `psql --version` | `psql (PostgreSQL) 18.6` |
| Git | any recent | git-scm.com | `git --version` | `git version 2.51.0.windows.2` |

You do **not** need to install Maven: the project includes the Maven wrapper (`mvnw`), which downloads the right Maven by itself. The first run needs an internet connection.

When you install PostgreSQL, the installer asks you to choose a password for the `postgres` superuser. Write it down. You need it in step 2. It is not the same as the two passwords you create later.

If `psql` is "not recognized" after installing PostgreSQL, see [Troubleshooting](#troubleshooting).

#### Which terminal to use

Any of these works: Git Bash, Windows PowerShell, Command Prompt, macOS Terminal, or the terminal inside VS Code (**Terminal > New Terminal**). The commands in this README are the same everywhere except where a table says otherwise. If you use PowerShell, two things differ:

| Task | Git Bash, macOS, Linux | Windows PowerShell |
|---|---|---|
| Start the backend | `./mvnw spring-boot:run` | `.\mvnw.cmd spring-boot:run` |
| Copy a file | `cp from to` | `Copy-Item from to` |
| `npm` says "running scripts is disabled" | not an issue | type `npm.cmd` instead of `npm`, or use Git Bash |

On macOS or Linux, if `./mvnw` says "permission denied", run `chmod +x mvnw` once.

You will use **three windows** over the course of the setup. Keep them separate:

| Window | Used for | Stays open? |
|---|---|---|
| Terminal 1 | Running the backend | Yes, while you use the app |
| Terminal 2 | Running the frontend | Yes, while you use the app |
| A `psql` session | Typing SQL when a step asks for it | No, close it with `\q` |

#### Two kinds of prompts: do not mix them up

Most problems in setup come from typing a command in the wrong kind of window.

| You see this | You are in | You can type |
|---|---|---|
| `C:\Users\Anna>` or `PS C:\Users\Anna>` or `anna@laptop ~ $` | An ordinary terminal | `git`, `npm`, `java`, `./mvnw`, `psql ...` |
| `postgres=#` or `grp02_event_management_db=#` | Inside `psql` | SQL statements ending in `;`, and commands that start with a backslash such as `\dt` and `\q` |

SQL typed into an ordinary terminal does nothing useful, and `npm` typed inside `psql` is an error. To leave `psql` and go back to the terminal, type `\q` and press Enter.

---

### Step 1. Get the code

Open a terminal in the folder where you keep projects (for example `Documents`), then:

```
git clone https://github.com/JosephEmmanuelBabas/School_Event_Management_Web_Appli.git
cd School_Event_Management_Web_Appli
```

Everything from here on is run from inside this folder (called the **repository root**), unless a step says otherwise.

**Check:** list the folder.

```
ls
```

(On Command Prompt, use `dir`.) You should see these three items:

```
README.md   docs   frontend   school_event_management
```

---

### Step 2. Create the database and the two database users

The application uses two PostgreSQL users so that the running app has the least power it needs:

| User | Used by | Can do |
|---|---|---|
| `event_owner` | The migrations, when the backend starts | Create and change tables |
| `event_app` | The running application | Read and write data. It cannot change tables, and on the audit log it can only read and add rows |

The setup script creates both users, the database, the schema and one PostgreSQL extension. It does **not** create the tables; the backend does that in step 4.

From the repository root, run (use the `postgres` superuser):

```
psql -U postgres -h localhost -f docs/database-setup.sql
```

What happens, in order:

1. `Password for user postgres:` appears. Type the superuser password you chose when you installed PostgreSQL. Nothing is shown while you type, which is normal. Press Enter. (It may ask again once more partway through; type it again.)
2. The script creates the database `grp02_event_management_db`.
3. It creates the users and then prompts you to choose a password for each. You will see this pair of prompts twice, once per user:

```
Enter new password for user "event_owner":
Enter it again:
Enter new password for user "event_app":
Enter it again:
```

Choose two **different** passwords, and write them down. Example passwords that look like what you want (do not reuse these, make your own):

```
event_owner  ->  Owner-Pass-2027-x
event_app    ->  App-Pass-2027-y
```

Avoid the characters `\` and spaces at the start or end of a password, because they cause trouble in the settings file in step 3.

4. The script finishes by printing a short check. Your output will look similar to this:

```
--- users (expect event_owner and event_app) ---
              List of roles
 Role name   | Attributes
-------------+------------
 event_owner |

--- schemas (expect school_event_management_db owned by event_owner) ---
              List of schemas
            Name            |    Owner
----------------------------+-------------
 school_event_management_db | event_owner

--- extensions (expect btree_gist in schema public) ---
  Name     | Version | Schema | Description
-----------+---------+--------+-------------
 btree_gist | 1.8     | public | ...
```

**Check:** make sure you can log in as each new user with the password you just chose. Run each line, type the password when asked, then leave with `\q`:

```
psql -U event_app -h localhost -d grp02_event_management_db
psql -U event_owner -h localhost -d grp02_event_management_db
```

You should land on a prompt that looks like `grp02_event_management_db=>` (it ends in `>`, not `#`, because these users are not superusers). If a login fails with `password authentication failed`, you mistyped a password in step 2. Fix it without redoing everything: log in as `postgres` and set it again:

```
psql -U postgres -h localhost -d grp02_event_management_db
```
```
\password event_app
\password event_owner
\q
```

**Prefer a graphical tool, or `psql` is not on your PATH?** You can run the script from the **SQL Shell (psql)** program that came with PostgreSQL. Accept the defaults for server, database, port and username (press Enter), type the superuser password, then run:

```
Example change it to the directory path you have in your laptop.
\i 'C:/Users/Anna/School_Event_Management_Web_Appli/docs/database-setup.sql'
```

Use forward slashes in the path, and change it to wherever you cloned the project.

---

### Step 3. Tell the backend how to reach the database

Passwords must never be stored in Git, so they go in a local settings file that Git ignores. You create it by copying a template.

**3a. Copy the template.** From the repository root:

Git Bash, macOS, Linux:

```
cp school_event_management/src/main/resources/application-local.properties.example school_event_management/src/main/resources/application-local.properties
```

Windows PowerShell:

```
Copy-Item school_event_management\src\main\resources\application-local.properties.example school_event_management\src\main\resources\application-local.properties
```

**Check:** the folder `school_event_management/src/main/resources/` now contains these files:

```
application.properties
application-local.properties            <- the one you just created (ignored by Git)
application-local.properties.example    <- the template (stays in Git)
db/
```

**3b. Fill it in.** Open `application-local.properties` in any editor. In VS Code: `code school_event_management/src/main/resources/application-local.properties`. The file contains placeholder values:

# Example
```properties
spring.datasource.password=change-me
spring.flyway.password=change-me

app.bootstrap.admin.username=admin
app.bootstrap.admin.password=change-me-at-least-10-chars
app.bootstrap.organizer.username=organizer1
app.bootstrap.organizer.password=change-me-at-least-10-chars
```

Replace them. Here is a filled-in **example** (these are sample values, not defaults: choose your own):

```properties
# The event_app password you chose in step 2
spring.datasource.password=App-Pass-2027-y
# The event_owner password you chose in step 2
spring.flyway.password=Owner-Pass-2027-x

# The first Super Admin, created automatically on the first start
app.bootstrap.admin.username=admin
app.bootstrap.admin.password=Admin-Pass-2027-z

# Optional: a first Event Organizer (you can also add one later in the app)
app.bootstrap.organizer.username=organizer1
app.bootstrap.organizer.password=Organizer-Pass-2027
```

Rules for this file:

| Rule | Why |
|---|---|
| One `key=value` per line, no spaces around `=` and no quotes | Quotes would become part of the password |
| Both database passwords must match what you typed in step 2 | Otherwise the backend cannot connect |
| The admin and organizer passwords must be at least **10 characters** | The backend refuses to start with a shorter one |
| If you do not want a first organizer, delete the two `organizer` lines | The Super Admin can add organizers in the app |
| Never commit this file or paste it in a chat or an email | It contains passwords |

---

### Step 4. Start the backend

Open **Terminal 1**, go into the backend folder, and start it:

```
cd school_event_management
./mvnw spring-boot:run
```
If you see an error that jdk is not found use this code in powershell: `$env:JAVA_HOME = "C:\Program Files\Java\jdk-25"`.
Then run again with this command `.\mvnw.cmd spring-boot:run`

(Windows PowerShell: `.\mvnw.cmd spring-boot:run`.)

The first start takes a few minutes: it downloads Maven and the libraries, then starts the application. Later starts take about 15 seconds. Lots of text scrolls past. Look for these lines (the timestamps and numbers will differ):

```
Migrating schema "school_event_management_db" to version "1 - create tables"
Migrating schema "school_event_management_db" to version "2 - seed roles"
Migrating schema "school_event_management_db" to version "3 - app privileges"
Successfully applied 3 migrations to schema "school_event_management_db"
...
Tomcat started on port 8080 (http) with context path '/'
Started SchoolEventManagementApplication in 12.6 seconds
Created first Super Admin account 'admin'.
Created first Event Organizer account 'organizer1'.
```

**Leave this window open and running.** The backend stops when you close it or press Ctrl+C.

**Check 1: the server answers.** Open a **new** window (not Terminal 1) and run:

```
curl http://localhost:8080/api/auth/csrf
```

(In Windows PowerShell, type `curl.exe` instead of `curl`.) You should get a short piece of JSON like:

```
You will see this output
{"headerName":"X-CSRF-TOKEN","token":"7f3e...long random text..."}
```

**Check 2: the tables exist.** Open `psql` as the superuser:

```
psql -U postgres -h localhost -d grp02_event_management_db
```

then run these two statements:

```
\dt school_event_management_db.*
```
```
SELECT role_name FROM school_event_management_db.role;
```

You should see ten tables (the nine below plus `flyway_schema_history`) and two roles:

```
 attendance, audit_log, event, event_assignment, event_schedule,
 flyway_schema_history, participant, role, user_account, venue

   role_name
-----------------
 Super Admin
 Event Organizer
```

Leave `psql` with `\q`.

---

### Step 5. Start the frontend

Open **Terminal 2**. From the repository root:

```
cd frontend
npm install
npm run dev
```

if npm install or npm run dev is not working use this just add `'.cmd'` after `'npm'`
```
npm.cmd install
npm.cmd run dev
```

`npm install` downloads the libraries (about a minute, only needed once; you can ignore messages about "funding" and "audit"). `npm run dev` then prints something like:

```
  VITE v8.3.5  ready in 350 ms

  ➜  Local:   http://localhost:5173/
```

(The version and timing will differ.) **Leave this window open too.**

**Check:** open <http://localhost:5173> in your browser. You should see a white card titled **School Event Management** with a Username box, a Password box and a **Log in** button. The button is pale (disabled) until you type both.

---

### Step 6. Log in and do the first-time steps

1. Log in with the admin from your settings file (in the example: `admin` and `Admin-Pass-2027-z`). You land on the Home page, which greets you by name and shows a **Super Admin** badge in the top right. The menu has Dashboard, Events, Venues, Participants, Reports, Users and Audit log.
2. Open **Users**. You see your admin account (marked "You") and `organizer1` if you kept those lines. Click **Add user** to create an Event Organizer: for example username `ana.cruz`, a password of at least 10 characters, first name `Ana`, last name `Cruz`, role **Event Organizer**.
3. Open **My account** (click your username at the top right). Under **Change password**, enter the current password and a new one that only you know.
4. Now remove the `app.bootstrap.*` lines from `application-local.properties`, then stop the backend (click Terminal 1 and press Ctrl+C) and start it again. The accounts live in the database, so they are no longer needed, and the file no longer holds the first passwords. After the restart you should see this in the log instead:

```
Skipped setup account for 'Super Admin': an account with that role already exists.
```

   (If you removed the lines, you will not see that message at all. Either way, your accounts still work.)

5. Log out (top right) and log in again with the **new** password to confirm.

**Try it out.** Log in as the Event Organizer and follow this path, which touches every part of the system:

| Step | Where | What to do |
|---|---|---|
| 1 | Venues | **Add venue**: `Main Gym`, location `Building A`, capacity `200` |
| 2 | Participants | **Add participant** (use made-up data): student number `2027-001`, `Ana`, `Cruz`, grade `10` |
| 3 | Events | **Add event**: name `Welcome Assembly`, venue `Main Gym`, a future date, 9:00 AM to 11:00 AM |
| 4 | Events | Add a second event at the same venue, same date, 10:00 AM to 12:00 PM. A yellow warning appears, and Save is refused |
| 5 | Open `Welcome Assembly` | **Add activity**: `Opening`, 9:00 AM to 9:30 AM. **Add staff member**: `Juan Dela Cruz`, role `Usher` |
| 6 | Same page | **Change status**, choose **Start the event**. Then **Record attendance** for Ana as Present |
| 7 | Log in as the Super Admin | **Dashboard** shows the new counts, **Reports** shows the attendance rate, **Audit log** lists everything you just did |

---

### Step 7 (optional). Run the automated tests

With the database set up and the settings file filled in, from `school_event_management`:

```
./mvnw test
```

(Windows PowerShell: `.\mvnw.cmd test`.) The last lines should read:

```
Tests run: 44, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

One of the 44 tests starts the whole application, so the database and the settings file must be ready. You can run this while the backend is running or stopped.

---

### Setup checklist

- [ ] `java -version`, `node -v`, `psql --version` and `git --version` all print a version
- [ ] The setup script ran, and both `event_app` and `event_owner` can log in
- [ ] `application-local.properties` exists, with your own passwords
- [ ] The backend log shows `Successfully applied 3 migrations` and `Started SchoolEventManagementApplication`
- [ ] `curl http://localhost:8080/api/auth/csrf` returns JSON
- [ ] <http://localhost:5173> shows the login page and you can log in
- [ ] You changed the admin password on **My account**

## Using it day to day

Once everything is set up, starting the system again takes two windows and two commands.

| Window | Folder | Command | Stop with |
|---|---|---|---|
| Terminal 1 | `school_event_management` | `./mvnw spring-boot:run` | Ctrl+C |
| Terminal 2 | `frontend` | `npm run dev` | Ctrl+C |

Then open <http://localhost:5173>. PostgreSQL itself keeps running in the background as a Windows service (or on macOS and Linux as a system service); you do not start it each time. If the backend says it cannot connect to the database, check that the PostgreSQL service is running.

After you update the code with `git pull`:

| What changed | What to do |
|---|---|
| Backend code or a new database migration | Stop Terminal 1 and start it again. New migrations are applied automatically on start |
| Frontend code | Nothing; the browser refreshes by itself. If `package.json` changed, run `npm install` again |

## Starting over from scratch

Use this if the database is in a bad state and you want a clean one. **It permanently deletes all data**, so use it only on a development machine.

1. Stop the backend (Terminal 1, Ctrl+C), so nothing is connected to the database.
2. Open `psql` as the superuser and run each statement:

```
psql -U postgres -h localhost
```
```
DROP DATABASE IF EXISTS grp02_event_management_db;
DROP ROLE IF EXISTS event_app;
DROP ROLE IF EXISTS event_owner;
\q
```

3. Repeat **step 2** (the setup script), then start the backend again (step 4). Flyway rebuilds all the tables.
4. If you removed the `app.bootstrap.*` lines from `application-local.properties`, put the admin lines back, because the new database has no accounts yet.

## Tests

| Command | What it runs |
|---|---|
| `cd school_event_management && ./mvnw test` | 44 backend tests (needs PostgreSQL and the local settings, because one test starts the whole application) |
| `cd frontend && npm run lint` | oxlint over the frontend source |
| `cd frontend && npm run build` | Production build of the frontend |
| `powershell -ExecutionPolicy Bypass -File school_event_management/script/test_api.ps1` | End-to-end API checks against the running backend (prompts for the two logins) |

For the API script: start the backend first, and have one Super Admin and one Event Organizer account. It asks for both usernames and passwords (nothing is echoed or saved), runs about 170 checks, and prints `PASS` or `FAIL` for each. It cleans up the data it creates, but every run leaves two inactive `tmpuser...` accounts, because user accounts are never deleted by design.

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

Find the message you see in the left column.

### Tools and installation

| Symptom | Likely cause and fix |
|---|---|
| `'psql' is not recognized` (Windows) | PostgreSQL's `bin` folder is not on your PATH. Either use the **SQL Shell (psql)** program from the Start menu, or add the folder (for example `C:\Program Files\PostgreSQL\18\bin`) to your PATH and open a new terminal |
| `java` is not recognized, or `java -version` shows a version below 25 | Install JDK 25 and open a new terminal. Maven errors such as `release version 25 not supported` or `invalid target release: 25` mean the same thing |
| `The JAVA_HOME environment variable is not defined correctly` | Set `JAVA_HOME` to your JDK 25 folder, or remove a wrong `JAVA_HOME` so `mvnw` uses the one on your PATH |
| `npm : File ...npm.ps1 cannot be loaded because running scripts is disabled` | A Windows PowerShell setting, not a project problem. Use Git Bash or Command Prompt, or type `npm.cmd` instead of `npm` |
| `npm` warns about `EBADENGINE` or Vite says it requires a newer Node | Install Node.js 20.19+ or 22.12+ (the LTS version from nodejs.org) |
| `./mvnw: Permission denied` (macOS, Linux) | Run `chmod +x mvnw` once |

### Database setup (step 2)

| Symptom | Likely cause and fix |
|---|---|
| `password authentication failed for user "postgres"` | The superuser password is the one you chose when installing PostgreSQL. If you forgot it, it has to be reset in PostgreSQL (see its documentation) |
| `could not connect to server` or `Connection refused` | The PostgreSQL service is not running. Start it (Windows: Services, `postgresql-x64-18`) |
| `role "event_owner" already exists` | The script was run before. That is fine: it checks first and continues |
| No password prompts appear for the two new users | Set them by hand: open `psql` as `postgres`, connect with `\c grp02_event_management_db`, then run `\password event_owner` and `\password event_app` |

### Starting the backend (step 4)

| Symptom | Likely cause and fix |
|---|---|
| `password authentication failed for user "event_app"` or `"event_owner"` | A password in `application-local.properties` does not match the one set in step 2. Fix the file, or reset the password with `\password` |
| `permission denied for schema school_event_management_db` | The schema was not created with `AUTHORIZATION event_owner`. Run the setup script again |
| `Found non-empty schema(s) ... but no schema history table` | Tables were created by hand. Flyway must be the only thing that creates them: follow [Starting over from scratch](#starting-over-from-scratch) |
| `Migration checksum mismatch` | Someone edited a migration file that was already applied. Restore the file with `git checkout -- <file>`; add changes as a new migration instead |
| `data type integer has no default operator class for access method "gist"` | The `btree_gist` extension is missing. Run the setup script again |
| `The setup account for role 'Super Admin' needs a username and a password of at least 10 characters` | The admin password in `application-local.properties` is too short or missing |
| `Port 8080 was already in use` | Another program uses port 8080. Close it, or a second copy of the backend that is still running |
| `FATAL: database "grp02_event_management_db" does not exist` | The setup script did not finish. Run it again |
| Maven cannot download anything | The first run needs internet access. Check your connection or proxy |

### Starting the frontend and logging in (steps 5 and 6)

| Symptom | Likely cause and fix |
|---|---|
| The login page says "Could not log in. Check that the server is running" | The backend is not running on port 8080. The frontend terminal will also print `http proxy error ... ECONNREFUSED` |
| `Port 5173 is already in use` | Another Vite process is running. Close it |
| "Invalid username or password" for the admin | Check the backend log from its first start. If it says `Created first Super Admin account`, the password in your settings file is the one to use. If the log never said that, the admin lines were missing: add them and restart. If a different message says an account already exists, use that account's password |
| You mistyped the admin password in the settings file on the very first start | On a **new, empty database only**: stop the backend, run `DELETE FROM school_event_management_db.user_account WHERE username = 'admin';` in `psql`, fix the file, and start the backend again. Do not do this on a database that already has activity |
| A page shows a red error box | Open the browser's developer tools (F12), go to the **Network** tab, click the failed request, and read its status and response |
| Everything returns 401 after a while | The session expired (30 minutes); log in again |
| A button you expect is missing | Your role may not allow that action. The Super Admin cannot create or edit events, venues or participants; the Event Organizer cannot see the Dashboard, Reports, Users or Audit log |
