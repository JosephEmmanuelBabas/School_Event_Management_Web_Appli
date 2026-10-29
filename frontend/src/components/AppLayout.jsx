import { NavLink, Outlet, useNavigate } from 'react-router'
import { useAuth } from '../auth/useAuth'

export default function AppLayout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout().catch(() => {})
    navigate('/login', { replace: true })
  }

  return (
    <div className="app-shell">
      <header className="app-header">
        <div className="brand">School Event Management</div>
        <nav aria-label="Main">
          <NavLink to="/" end>Home</NavLink>
          <NavLink to="/venues">Venues</NavLink>
        </nav>
        <div className="header-user">
          <span>
            {user.username} <span className="badge">{user.role}</span>
          </span>
          <button type="button" className="button button-secondary" onClick={handleLogout}>
            Log out
          </button>
        </div>
      </header>
      <Outlet />
    </div>
  )
}