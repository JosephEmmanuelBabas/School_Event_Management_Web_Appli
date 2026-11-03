import { Link } from 'react-router'
import { useAuth } from '../auth/useAuth'
import { useApiResource } from '../hooks/useApiResource'
import { addDaysIso, todayIso } from '../utils/format'
import EventPanel from './EventPanel'

export default function HomePage() {
  const { user, isAdmin } = useAuth()
  const { data: account } = useApiResource('/account/me')

  return (
    <main className="page">
      <h1>Welcome{account ? `, ${account.firstName}` : ''}</h1>
      <p className="muted">Signed in as {user.role}.</p>

      <nav className="quick-links" aria-label="Quick links">
        <Link to="/events" className="quick-link">Events</Link>
        {isAdmin ? (
          <>
            <Link to="/dashboard" className="quick-link">Dashboard</Link>
            <Link to="/reports" className="quick-link">Attendance reports</Link>
            <Link to="/users" className="quick-link">Users</Link>
            <Link to="/audit" className="quick-link">Audit log</Link>
          </>
        ) : (
          <>
            <Link to="/venues" className="quick-link">Venues</Link>
            <Link to="/participants" className="quick-link">Participants</Link>
          </>
        )}
        <Link to="/account" className="quick-link">My account</Link>
      </nav>

      <EventPanel
        id="home-ongoing"
        title="Happening now"
        note={isAdmin ? undefined : 'Open an event to record attendance.'}
        params={{ status: 'Ongoing', size: 10, sort: 'eventDate', direction: 'asc' }}
        emptyMessage="No events are ongoing."
      />

      <EventPanel
        id="home-upcoming"
        title="Coming up"
        params={{ status: 'Upcoming', from: todayIso(), size: 5, sort: 'eventDate', direction: 'asc' }}
        emptyMessage="No upcoming events."
      />

      <EventPanel
        id="home-attention"
        title="Needs attention"
        note="These events are still marked Upcoming, but their date has passed. Open each one to start it (and complete it later) or to cancel it."
        params={{ status: 'Upcoming', to: addDaysIso(-1), size: 10, sort: 'eventDate', direction: 'asc' }}
        emptyMessage=""
        hideWhenEmpty
      />
    </main>
  )
}