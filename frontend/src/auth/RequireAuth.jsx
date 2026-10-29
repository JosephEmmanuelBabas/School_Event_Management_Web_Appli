import { Navigate, Outlet, useLocation } from 'react-router'
import { useAuth } from './useAuth'

// Wraps pages that need a login. Pass roles={['Super Admin']} to also limit by role.
// This only decides what to SHOW. The server enforces the real permissions.
export default function RequireAuth({ roles }) {
  const { user, loading } = useAuth()
  const location = useLocation()

  if (loading) {
    return <p className="status-message" role="status">Loading…</p>
  }
  if (!user) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }
  if (roles && !roles.includes(user.role)) {
    return (
      <main className="page">
        <h1>Not allowed</h1>
        <p>Your role does not have access to this page.</p>
      </main>
    )
  }
  return <Outlet />
}