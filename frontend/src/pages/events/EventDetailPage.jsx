import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router'
import { api } from '../../api/client'
import { useAuth } from '../../auth/useAuth'
import { useNotify } from '../../components/notifications/useNotify'
import StatusBadge from '../../components/StatusBadge'
import { useApiList } from '../../hooks/useApiList'
import { isOpenStatus } from '../../utils/eventStatus'
import { formatDate, formatTime } from '../../utils/format'
import AttendanceSection from './AttendanceSection'
import EventFormDialog from './EventFormDialog'
import EventStatusDialog from './EventStatusDialog'
import ScheduleSection from './ScheduleSection'
import StaffSection from './StaffSection'

export default function EventDetailPage() {
  const { eventId } = useParams()
  const id = /^\d+$/.test(eventId ?? '') ? Number(eventId) : null
  const { isOrganizer } = useAuth()
  const notify = useNotify()
  const { items: venues } = useApiList('/venues')

  const [state, setState] = useState({ event: null, loading: true, notFound: false, error: '' })
  const [reloadCount, setReloadCount] = useState(0)
  const [editOpen, setEditOpen] = useState(false)
  const [statusOpen, setStatusOpen] = useState(false)

  useEffect(() => {
    if (id === null) return undefined
    let cancelled = false
    api.get(`/events/${id}`)
      .then((event) => {
        if (!cancelled) setState({ event, loading: false, notFound: false, error: '' })
      })
      .catch((err) => {
        if (!cancelled) {
          setState({ event: null, loading: false, notFound: err.status === 404, error: err.message })
        }
      })
    return () => {
      cancelled = true
    }
  }, [id, reloadCount])

  function reloadEvent() {
    setReloadCount((count) => count + 1)
  }

  if (id === null || state.notFound) {
    return (
      <main className="page">
        <h1>Event not found</h1>
        <p>That event does not exist, or it was deleted.</p>
        <p><Link to="/events">Back to events</Link></p>
      </main>
    )
  }
  if (state.loading) {
    return (
      <main className="page">
        <p className="muted" role="status">Loading event…</p>
      </main>
    )
  }
  if (state.error || !state.event) {
    return (
      <main className="page">
        <div className="alert alert-error" role="alert">
          <p>{state.error || 'Could not load the event.'}</p>
          <button type="button" className="button button-secondary button-small" onClick={reloadEvent}>
            Try again
          </button>
        </div>
        <p><Link to="/events">Back to events</Link></p>
      </main>
    )
  }

  const { event } = state
  const open = isOpenStatus(event.eventStatus)

  return (
    <main className="page">
      <Link to="/events" className="back-link">← Back to events</Link>

      <div className="page-header">
        <h1>
          {event.eventName} <StatusBadge status={event.eventStatus} />
        </h1>
        {isOrganizer && open && (
          <div className="row-actions">
            <button type="button" className="button button-secondary" onClick={() => setEditOpen(true)}>
              Edit
            </button>
            <button type="button" className="button button-secondary" onClick={() => setStatusOpen(true)}>
              Change status
            </button>
          </div>
        )}
      </div>

      <section className="card" aria-label="Event details">
        <dl className="details">
          <dt>Date</dt>
          <dd>{formatDate(event.eventDate)}</dd>
          <dt>Time</dt>
          <dd>{formatTime(event.startTime)} – {formatTime(event.endTime)}</dd>
          <dt>Venue</dt>
          <dd>{event.venueName}</dd>
          <dt>Organizer</dt>
          <dd>{event.organizerName}</dd>
          <dt>Description</dt>
          <dd>{event.description || '—'}</dd>
        </dl>
      </section>

      <ScheduleSection event={event} isOrganizer={isOrganizer} />
      <StaffSection event={event} isOrganizer={isOrganizer} />
      <AttendanceSection event={event} isOrganizer={isOrganizer} />

      <EventFormDialog
        open={editOpen}
        event={event}
        venues={venues}
        onClose={() => setEditOpen(false)}
        onSaved={(kind, name) => {
          setEditOpen(false)
          notify.success(`Event "${name}" was ${kind}.`)
          reloadEvent()
        }}
      />

      <EventStatusDialog
        event={statusOpen ? event : null}
        onClose={() => setStatusOpen(false)}
        onChanged={(newStatus) => {
          setStatusOpen(false)
          notify.success(`"${event.eventName}" is now ${newStatus}.`)
          reloadEvent()
        }}
      />
    </main>
  )
}