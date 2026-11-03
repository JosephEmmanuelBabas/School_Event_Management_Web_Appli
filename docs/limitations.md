# Known limitations

This system is built and verified for development and classroom use. This page lists what it does not do, and what must change before it is used for real school data.

## Scope (from the project blueprint)

Out of scope by design: native mobile apps, AI or predictive features, academic records (grades, subjects, enrollment), financial features (budgets, payments, tickets), and replacing the school's regular classroom attendance. Attendance here is limited to participation in events. The system supports only the two roles Super Admin and Event Organizer.

## Security

| Limitation | Detail |
|---|---|
| No login rate limiting or lockout | Someone can try passwords repeatedly. Add throttling or a lockout before exposing the system to a network |
| Password rule is length only | 10 characters minimum, 72 bytes maximum; no complexity rules or breached-password check |
| Session cookie is not marked `Secure` | Development runs over HTTP. Over HTTPS, set `server.servlet.session.cookie.secure=true` |
| No `Content-Security-Policy` header | Spring Security's default headers are used; a CSP is not configured |
| A password reset does not end open sessions | The affected user stays signed in until the session expires (30 minutes). Deactivating the account ends access at once |
| Role and status changes apply on the next request | There is no instant push to an open browser tab |
| Student data is personal data | Names, student numbers and grade levels are visible to both roles; there is no export control or per-event restriction. Use made-up data in development |
| CORS is not configured | The browser reaches the API through the Vite proxy (same origin). A deployment must serve the built frontend and the API from the same address, for example behind a reverse proxy |

What is in place: bcrypt password hashes (never returned by the API), server-side role checks on every request, CSRF protection, validation on the server, parameterized database access, a least-privilege database user, no stack traces in responses, and an append-only audit log.

## Data and audit

| Limitation | Detail |
|---|---|
| Audit entries do not store old and new values | Each row records the user, action, table, record id and time |
| Logging in and out is not audited | The blueprint asks for create, update and delete only |
| The first accounts created at start-up are not audited | Nobody is logged in at that moment |
| Deleting an event removes its schedule entries and staff without separate audit rows | Only the event's own `Deleted` row is written |
| Event status is set by hand | An event can stay `Upcoming` after its date has passed. The Home page's "Needs attention" panel lists such events |
| The attendance rate is not measured against an invited list | It is (Present + Late) divided by the attendance records saved |
| Venue capacity is not compared with attendance | It is not in the documented rules |
| Users cannot be deleted | They are deactivated, so audit history stays valid. Test accounts therefore remain in the table |
| Reports cannot be exported | There is no CSV or PDF export |

## Before a real deployment

1. Serve everything over HTTPS and set the session cookie to `Secure`.
2. Build the frontend (`npm run build`) and serve the result from the same address as the API.
3. Choose strong, unique passwords for the two database users, and keep them out of the repository (`application-local.properties` is ignored by Git).
4. Remove the `app.bootstrap.*` lines after the first start, and change the first accounts' passwords.
5. Let PostgreSQL listen only on the addresses it needs, and restrict who can connect.
6. Add login throttling and a `Content-Security-Policy` header.
7. Set up regular database backups, and test restoring one.
8. Plan archiving for completed events of past school years (the event, attendance and audit tables grow every year).
