# Frontend

The React app of the High School Event Management System, built with Vite. For the whole project (database, backend, setup), see the [main README](../README.md).

## Run it

The backend must be running on port 8080 first.

```
npm install
npm run dev
```

Open <http://localhost:5173>. The dev server forwards every `/api/...` request to `http://localhost:8080` (see `vite.config.js`), so the browser only talks to one address and the session cookie and CSRF token work without any CORS setup.

On Windows PowerShell, if `npm` says running scripts is disabled, use Command Prompt or Git Bash, or type `npm.cmd`.

## Scripts

| Command | What it does |
|---|---|
| `npm run dev` | Development server with hot reload (port 5173) |
| `npm run build` | Production build into `dist/` |
| `npm run lint` | oxlint over the source |

## Source layout

| Folder | Contents |
|---|---|
| `src/api/client.js` | The only place that calls the backend: adds the CSRF token to writes, turns error responses into `ApiError`, reads the `X-Total-Count` header for paged lists |
| `src/auth/` | Login state (`AuthProvider`, `useAuth`) and `RequireAuth` for protected routes |
| `src/components/` | Reusable parts: `DataTable`, `Pagination`, `Modal`, `ConfirmDialog`, `Field`, `StatusBadge`, notifications, `AppLayout` |
| `src/hooks/` | Small data-loading hooks (`useApiList`, `useApiResource`, `useApiPage`) |
| `src/pages/` | One folder per screen: events, venues, participants, reports, dashboard, users, account, audit |
| `src/utils/` | Date and time formatting, status rules, password check |

## Notes

- Hiding a button by role is only a convenience. The server decides what each role may do, on every request.
- Client-side validation mirrors the server's rules, but the server's answer always wins: error messages from the API are shown under the matching form field.
- Written in plain JavaScript; the only routing dependency is `react-router`.
