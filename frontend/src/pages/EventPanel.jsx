import { Link } from 'react-router'
import StatusBadge from '../components/StatusBadge'
import { useApiPage } from '../hooks/useApiPage'
import { formatDate, formatTime } from '../utils/format'

// A card listing events from the API. With hideWhenEmpty, the card disappears when there are none.
export default function EventPanel({ id, title, note, params, emptyMessage, hideWhenEmpty = false }) {
  const { items, totalCount, loading, error } = useApiPage('/events', params)

  if (hideWhenEmpty && !loading && !error && items.length === 0) return null

  return (
    <section className="card" aria-labelledby={id}>
      <h2 id={id}>{title}</h2>
      {note && <p className="note">{note}</p>}

      {loading ? (
        <p className="muted" role="status">Loading…</p>
      ) : error ? (
        <p className="alert alert-error" role="alert">{error}</p>
      ) : items.length === 0 ? (
        <p className="muted">{emptyMessage}</p>
      ) : (
        <>
          <ul className="plain-list">
            {items.map((event) => (
              <li key={event.eventId}>
                <Link to={`/events/${event.eventId}`}>{event.eventName}</Link>{' '}
                <StatusBadge status={event.eventStatus} />
                <span className="muted">
                  {formatDate(event.eventDate)} · {formatTime(event.startTime)} –{' '}
                  {formatTime(event.endTime)} · {event.venueName}
                </span>
              </li>
            ))}
          </ul>
          {totalCount > items.length && (
            <p className="note">
              Showing {items.length} of {totalCount}. <Link to="/events">See all events</Link>
            </p>
          )}
        </>
      )}
    </section>
  )
}