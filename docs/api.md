# REST API reference

Base path: `/api`. All bodies are JSON unless stated. In development the browser reaches the API through the Vite proxy on `http://localhost:5173`; the backend itself listens on `http://localhost:8080`.

## Conventions

**Authentication.** Log in once; the server answers with a session cookie (`JSESSIONID`, HttpOnly, SameSite=Lax, 30-minute timeout). Send the cookie on every request. An anonymous request to a protected path returns `401` with an empty body.

**CSRF.** Every `POST`, `PUT` and `DELETE` (including login and logout) must carry a CSRF token:

1. `GET /api/auth/csrf` returns `{ "headerName": "X-CSRF-TOKEN", "token": "..." }`.
2. Send the token in that header on the write request.
3. The token changes at login and logout, so fetch a new one afterwards.

A write without a valid token returns `403`.

**Dates and times.** Dates are `yyyy-MM-dd`. Times are sent as `HH:mm` and come back as `HH:mm:ss`. Timestamps are local date-times without a zone (`2027-01-15T15:05:03.123456`), in the server's time.

**Errors.** Errors from the application use one shape:

```json
{
  "timestamp": "2027-01-15T07:05:03.123Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed.",
  "fieldErrors": { "venueName": "Venue name is required." }
}
```

`fieldErrors` is `null` unless the request failed validation; its keys are the request field names.

| Status | Meaning |
|---|---|
| 400 | Validation failed, or the request breaks a business rule (the message says which) |
| 401 | Not logged in, session expired, or the account was deactivated |
| 403 | Logged in, but the role may not do this, or the CSRF token is missing or invalid |
| 404 | The record does not exist (or does not belong to the event in the path) |
| 409 | Conflict: a unique value already exists, a venue is double-booked, or the record is still in use |

A `403` produced by Spring Security does not always use the error shape above.

**Paged lists.** `GET /api/events`, `/api/participants` and `/api/audit-logs` accept `page` (zero-based, default 0) and `size` (default 50, maximum 100). The response body is a plain JSON array of that page, and the total number of matching records is in the response header `X-Total-Count`.

## Access summary

| Paths | Read (GET) | Write (POST, PUT, DELETE) |
|---|---|---|
| `/api/auth/csrf`, `/api/auth/login` | Anyone | Anyone (CSRF token still required) |
| `/api/auth/me`, `/api/account/**` | Any logged-in user | Any logged-in user |
| `/api/venues/**`, `/api/events/**`, `/api/participants/**` | Super Admin, Event Organizer | Event Organizer |
| `/api/users/**`, `/api/dashboard`, `/api/reports/**`, `/api/audit-logs` | Super Admin | Super Admin |

Every create, update and delete below also writes one row to the audit log, in the same database transaction.

---

## Authentication

### `GET /api/auth/csrf`
Anyone. Returns the CSRF header name and token (see Conventions).

### `POST /api/auth/login`
Anyone, with a CSRF token. Content type `application/x-www-form-urlencoded` with the fields `username` and `password`.
- `204`: logged in; the session cookie is set.
- `401`: `{ "status": 401, "error": "Unauthorized", "message": "Invalid username or password." }`. The same answer is given for an unknown user, a wrong password and a deactivated account.

### `POST /api/auth/logout`
Logged in, with a CSRF token. `204`; the session is ended.

### `GET /api/auth/me`
Logged in. `200`: `{ "userId": 4, "username": "admin", "role": "Super Admin" }`.

---

## My account

### `GET /api/account/me`
Logged in. `200`: a user record:

```json
{ "userId": 5, "username": "organizer1", "firstName": "Ana", "lastName": "Cruz",
  "email": "ana@example.com", "roleName": "Event Organizer", "accountStatus": "Active" }
```

The password hash is never returned.

### `PUT /api/account/me`
Logged in. Edits your own name and email; username and role can only be changed by a Super Admin.

Body: `{ "firstName": "Ana", "lastName": "Cruz", "email": "ana@example.com" }`
- `firstName`, `lastName`: required, at most 50 characters.
- `email`: optional, valid address, at most 100 characters.

`200`: the updated user record. `400` validation. `409` the email belongs to another account.

### `POST /api/account/me/password`
Logged in.

Body: `{ "currentPassword": "...", "newPassword": "..." }`
- The new password must be at least 10 characters and at most 72 bytes, and must differ from the current one.

`204` on success. `400` if the current password is wrong or the new password breaks a rule (the message says which).

---

## Users (Super Admin)

User record: as in `GET /api/account/me`.

### `GET /api/users`
`200`: all accounts, ordered by username.

### `GET /api/users/{id}`
`200`: one user record. `404` unknown id.

### `POST /api/users`
Body:

```json
{ "username": "organizer2", "password": "a-long-password", "firstName": "Ben",
  "lastName": "Reyes", "email": null, "roleName": "Event Organizer" }
```

- `username`: 3 to 50 characters from letters, digits, dot, underscore, hyphen. Unique, ignoring case.
- `password`: 10 characters or more, at most 72 bytes. Stored only as a bcrypt hash.
- `roleName`: `Super Admin` or `Event Organizer`.
- New accounts start as `Active`.

`201` with a `Location` header and the user record. `400` validation or unknown role. `409` username or email already exists.

### `PUT /api/users/{id}`
Body: `{ "username", "firstName", "lastName", "email", "roleName", "accountStatus" }` where `accountStatus` is `Active`, `Inactive` or `Suspended`.

Rules:
- You cannot change your own role or status (`400`).
- The last active Super Admin cannot be demoted or deactivated (`400`).
- A deactivated user's open session ends on their next request, and they cannot log in.

`200`: the updated record. `404`, `409` as above. Accounts are never deleted, only deactivated.

### `POST /api/users/{id}/reset-password`
Body: `{ "newPassword": "..." }` (same password rules). `204`. The user's open sessions stay valid until they expire.

---

## Venues

Venue record: `{ "venueId": 1, "venueName": "Main Gym", "location": "Building A", "capacity": 200 }`. `capacity` may be `null`.

### `GET /api/venues`
Both roles. `200`: all venues ordered by name (not paged).

### `GET /api/venues/{id}`
Both roles. `200` or `404`.

### `POST /api/venues`
Event Organizer. Body: `{ "venueName", "location", "capacity" }`
- `venueName`: required, at most 100 characters, unique (exact match).
- `location`: required, at most 150 characters.
- `capacity`: optional; if given, greater than zero.

`201` with `Location` header and the record. `400` validation. `409` name already exists.

### `PUT /api/venues/{id}`
Event Organizer. Same body. `200`, `400`, `404`, `409`.

### `DELETE /api/venues/{id}`
Event Organizer. `204`. `409` if events still use the venue.

---

## Events

Event record:

```json
{ "eventId": 12, "eventName": "Assembly", "description": null, "eventDate": "2027-01-15",
  "startTime": "09:00:00", "endTime": "11:00:00", "eventStatus": "Upcoming",
  "organizerId": 5, "organizerName": "Ana Cruz", "venueId": 1, "venueName": "Main Gym" }
```

### `GET /api/events`
Both roles. Paged. Query parameters, all optional:

| Parameter | Meaning |
|---|---|
| `status` | `Upcoming`, `Ongoing`, `Completed` or `Cancelled` |
| `venueId` | Only this venue |
| `search` | Part of the event name, ignoring case |
| `from`, `to` | Event date range, inclusive (`yyyy-MM-dd`) |
| `sort` | `eventDate` (default), `eventName` or `eventStatus` |
| `direction` | `desc` (default) or `asc` |
| `page`, `size` | Paging (see Conventions) |

`200` with `X-Total-Count`. `400` for an unknown status or when `to` is before `from`.

### `GET /api/events/{id}`
Both roles. `200` or `404`.

### `POST /api/events`
Event Organizer. Body:

```json
{ "eventName": "Assembly", "description": "Optional", "eventDate": "2027-01-15",
  "startTime": "09:00", "endTime": "11:00", "venueId": 1 }
```

- `eventName` required, at most 100 characters; `description` optional, at most 5000.
- The end time must be after the start time, and the date cannot be in the past.
- The organizer is always the logged-in user, and the status always starts as `Upcoming`.

`201` with `Location` header and the record. `400` validation, past date, end before start, or unknown venue. `409` the venue is already booked for an overlapping time on that date (cancelled events do not count, and back-to-back events are allowed).

### `PUT /api/events/{id}`
Event Organizer. Same body. Only `Upcoming` and `Ongoing` events can be edited. Also refused with `400`: moving the date into the past, or shrinking the times so existing schedule entries fall outside them. `409` for a venue overlap.

### `POST /api/events/{id}/status`
Event Organizer. Body: `{ "status": "Ongoing" }`. Allowed changes: `Upcoming` to `Ongoing` or `Cancelled`; `Ongoing` to `Completed` or `Cancelled`. `Completed` and `Cancelled` are final. `200` with the record; `400` for any other change.

### `DELETE /api/events/{id}`
Event Organizer. `204`; the event's schedule entries and staff are removed with it. `409` if the event has attendance records (cancel it instead).

---

## Schedule entries

Entry record: `{ "scheduleId": 3, "eventId": 12, "activityName": "Opening", "startTime": "09:00:00", "endTime": "09:30:00" }`

### `GET /api/events/{eventId}/schedules`
Both roles. `200`: entries ordered by start time. `404` unknown event.

### `POST /api/events/{eventId}/schedules`
Event Organizer. Body: `{ "activityName", "startTime", "endTime" }`
- `activityName` required, at most 100 characters.
- The end must be after the start, and the entry must fall inside the event's own start and end time.
- Entries may overlap each other (parallel activities).
- The event must be `Upcoming` or `Ongoing`.

`201`, `400`, `404`.

### `PUT /api/events/{eventId}/schedules/{scheduleId}`
Event Organizer. Same body and rules. `200`, `400`, `404`.

### `DELETE /api/events/{eventId}/schedules/{scheduleId}`
Event Organizer. `204`. `400` if the event is no longer `Upcoming` or `Ongoing`; `404`.

---

## Staff assignments

Staff are plain records, not user accounts. Record: `{ "assignmentId": 2, "eventId": 12, "staffName": "Juan Dela Cruz", "staffRole": "Usher", "assignmentStatus": "Pending" }`

### `GET /api/events/{eventId}/assignments`
Both roles. `200`: records ordered by name. `404` unknown event.

### `POST /api/events/{eventId}/assignments`
Event Organizer. Body: `{ "staffName", "staffRole", "assignmentStatus" }`
- `staffName` required, at most 100 characters; `staffRole` optional, at most 50.
- `assignmentStatus` is `Confirmed`, `Pending` or `Cancelled`; when omitted it is `Pending`.
- The event must be `Upcoming` or `Ongoing`.

`201`, `400`, `404`.

### `PUT /api/events/{eventId}/assignments/{assignmentId}`
Event Organizer. Same body and rules. `200`, `400`, `404`.

### `DELETE /api/events/{eventId}/assignments/{assignmentId}`
Event Organizer. `204`, `400`, `404`.

---

## Participants

Record: `{ "participantId": 7, "studentNumber": "2024-001", "firstName": "Ana", "lastName": "Cruz", "gradeLevel": "10" }`. `gradeLevel` may be `null`.

### `GET /api/participants`
Both roles. Paged, ordered by last name then first name. Optional parameters: `search` (part of the student number, first name or last name, ignoring case), `gradeLevel` (exact match), `page`, `size`. `200` with `X-Total-Count`.

### `GET /api/participants/{id}`
Both roles. `200` or `404`.

### `POST /api/participants`
Event Organizer. Body: `{ "studentNumber", "firstName", "lastName", "gradeLevel" }`
- `studentNumber` required, at most 20 characters, unique ignoring case.
- `firstName`, `lastName` required, at most 50 characters. `gradeLevel` optional, at most 10.

`201`, `400`, `409` student number already exists.

### `PUT /api/participants/{id}`
Event Organizer. Same body. `200`, `400`, `404`, `409`.

### `DELETE /api/participants/{id}`
Event Organizer. `204`. `409` if the participant has attendance records.

---

## Attendance

Record:

```json
{ "attendanceId": 9, "eventId": 12, "participantId": 7, "studentNumber": "2024-001",
  "participantName": "Ana Cruz", "attendanceStatus": "Present",
  "timeRecorded": "2027-01-15T09:05:41.123456" }
```

`timeRecorded` is always set by the server.

### `GET /api/events/{eventId}/attendance`
Both roles. Optional `status` (`Present`, `Late`, `Absent`). `200`: records ordered by participant name. `400` unknown status; `404` unknown event.

### `GET /api/events/{eventId}/attendance/summary`
Both roles. `200`: `{ "eventId": 12, "present": 3, "late": 1, "absent": 2, "totalRecorded": 6 }`.

### `POST /api/events/{eventId}/attendance`
Event Organizer. Body: `{ "participantId": 7, "attendanceStatus": "Present" }`
- The event must be `Ongoing` or `Completed` (completed events still accept corrections).
- A participant can have only one record per event.

`201`; `400` event not open for attendance, unknown participant, or invalid status; `404`; `409` the participant already has a record for this event.

### `PUT /api/events/{eventId}/attendance/{attendanceId}`
Event Organizer. Body: `{ "attendanceStatus": "Late" }`. Changing the status also refreshes `timeRecorded`. `200`, `400`, `404`.

### `DELETE /api/events/{eventId}/attendance/{attendanceId}`
Event Organizer. Removes a mistaken record. `204`, `400`, `404`.

---

## Dashboard (Super Admin)

### `GET /api/dashboard`
`200`:

```json
{
  "events":   { "upcoming": 4, "ongoing": 1, "completed": 10, "cancelled": 2, "total": 17 },
  "users":    { "active": 3, "inactive": 2, "suspended": 0, "total": 5 },
  "venues": 5,
  "participants": 120,
  "attendance": { "present": 80, "late": 10, "absent": 20, "total": 110 },
  "upcomingEvents": [ /* up to 5 event records, soonest first */ ],
  "recentActivity": [ /* the 5 newest audit log entries */ ]
}
```

Counts follow the status that organizers set. `upcomingEvents` lists only `Upcoming` events dated today or later.

---

## Reports (Super Admin)

The attendance rate is `(present + late) / totalRecorded * 100`, rounded to one decimal place, and `null` when nothing is recorded.

### `GET /api/reports/attendance-by-event`
Optional parameters: `from`, `to` (event date, inclusive), `venueId`, `status` (event status). `200`: one row per event, including events with no attendance (counts 0, rate `null`), newest event first:

```json
{ "eventId": 12, "eventName": "Assembly", "eventDate": "2027-01-15", "venueName": "Main Gym",
  "eventStatus": "Completed", "present": 6, "late": 2, "absent": 2,
  "totalRecorded": 10, "attendanceRatePercent": 80.0 }
```

`400` if `to` is before `from` or the status is unknown.

### `GET /api/reports/attendance-by-grade`
Optional `from`, `to`. `200`: one row per grade level, numeric grades in numeric order, grades without a value labelled `Unspecified` last:

```json
{ "gradeLevel": "10", "present": 2, "late": 0, "absent": 1,
  "totalRecorded": 3, "attendanceRatePercent": 66.7 }
```

---

## Audit log (Super Admin)

### `GET /api/audit-logs`
Paged (`page`, `size`), newest first. `200` with `X-Total-Count`:

```json
{ "logId": 352, "userId": 14, "username": "zz.test2", "actionPerformed": "Updated",
  "affectedTable": "user_account", "affectedRecordId": 14,
  "logTimestamp": "2027-01-15T10:20:30.123456" }
```

`actionPerformed` is `Created`, `Updated` or `Deleted`. The API is read-only, and the database user the application uses is also refused any update or delete on this table. Logging in and out is not recorded.
