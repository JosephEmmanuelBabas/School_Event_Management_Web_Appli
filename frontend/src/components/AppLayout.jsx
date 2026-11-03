import { useEffect, useRef } from 'react'
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router'
import { useAuth } from '../auth/useAuth'

const APP_NAME = 'Eventer:School Event Management'

function titleFor(pathname) {
  if (pathname === '/') return 'Home'
  if (pathname === '/dashboard') return 'Dashboard'
  if (pathname === '/events') return 'Events'
  if (pathname.startsWith('/events/')) return 'Event details'
  if (pathname === '/venues') return 'Venues'
  if (pathname === '/participants') return 'Participants'
  if (pathname === '/reports') return 'Attendance reports'
  if (pathname === '/users') return 'Users'
  if (pathname === '/audit') return 'Audit log'
  if (pathname === '/account') return 'My account'
  return 'Page not found'
}

export default function AppLayout() {
  const { user, logout, isAdmin } = useAuth()
  const navigate = useNavigate()
  const { pathname } = useLocation()
  const contentRef = useRef(null)
  const firstRender = useRef(true)

  // On every page change: update the browser tab title and move keyboard focus to the content,
  // so keyboard and screen reader users do not have to tab through the header again.
  useEffect(() => {
    document.title = `${titleFor(pathname)} · ${APP_NAME}`
    if (firstRender.current) {
      firstRender.current = false
      return
    }
    contentRef.current?.focus({ preventScroll: true })
  }, [pathname])

  async function handleLogout() {
    await logout().catch(() => {})
    navigate('/login', { replace: true })
  }

  return (
    <div className="app-shell">
      <a href="#main-content" className="skip-link">Skip to main content</a>
      <header className="app-header">
        <div className="brand">{APP_NAME}</div>
        <nav aria-label="Main">
          <NavLink to="/" end>Home</NavLink>
          {isAdmin && <NavLink to="/dashboard">Dashboard</NavLink>}
          <NavLink to="/events">Events</NavLink>
          <NavLink to="/venues">Venues</NavLink>
          <NavLink to="/participants">Participants</NavLink>
          {isAdmin && <NavLink to="/reports">Reports</NavLink>}
          {isAdmin && <NavLink to="/users">Users</NavLink>}
          {isAdmin && <NavLink to="/audit">Audit log</NavLink>}
        </nav>
        <div className="header-user">
          <span>
            <Link to="/account" className="user-link">{user.username}</Link>
            <span className="badge">{user.role}</span>
          </span>
          <button type="button" className="button button-secondary" onClick={handleLogout}>
            Log out
          </button>
        </div>
      </header>
      <div id="main-content" ref={contentRef} tabIndex={-1} className="main-content">
        <Outlet />
      </div>
    </div>
  )
}