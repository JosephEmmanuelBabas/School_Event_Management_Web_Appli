import { Link } from 'react-router'
import DataTable from '../../components/DataTable'
import { useApiResource } from '../../hooks/useApiResource'
import { formatDate, formatDateTime, formatPercent, formatTime } from '../../utils/format'

function StatCard({ label, value, detail }) {
  return (
    <div className="stat-card">
      <p className="stat-label">{label}</p>
      <p className="stat-value">{value}</p>
      {detail && <p className="stat-detail">{detail}</p>}
    </div>
  )
}

// Each bar also shows its number as text, so nothing depends on seeing the bar.
function BarList({ items, total, label }) {
  return (
    <ul className="bar-list" aria-label={label}>
      {items.map((item) => {
        const percent = total === 0 ? 0 : Math.round((item.value * 100) / total)
        return (
          <li key={item.label} className="bar-row">
            <span>{item.label}</span>
            <span className="bar-track" aria-hidden="true">
              <span
                className={`bar-fill bar-${item.label.toLowerCase()}`}
                style={{ width: `${percent}%` }}
              />
            </span>
            <span className="bar-count">{item.value}</span>
          </li>
        )
      })}
    </ul>
  )
}

const activityColumns = [
  { key: 'logTimestamp', header: 'When', render: (row) => formatDateTime(row.logTimestamp) },
  { key: 'username', header: 'User' },
  { key: 'actionPerformed', header: 'Action' },
  { key: 'record', header: 'Record', render: (row) => `${row.affectedTable} #${row.affectedRecordId}` },
]

export default function DashboardPage() {
  const { data, loading, error, reload } = useApiResource('/dashboard')

  if (loading) {
    return (
      <main className="page">
        <p className="muted" role="status">Loading dashboard…</p>
      </main>
    )
  }
  if (error || !data) {
    return (
      <main className="page">
        <div className="alert alert-error" role="alert">
          <p>{error || 'Could not load the dashboard.'}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      </main>
    )
  }

  const { events, users, attendance, venues, participants, upcomingEvents, recentActivity } = data
  const rate =
    attendance.total === 0
      ? null
      : Math.round(((attendance.present + attendance.late) * 1000) / attendance.total) / 10

  return (
    <main className="page">
      <div className="page-header">
        <h1>Dashboard</h1>
        <button type="button" className="button button-secondary" onClick={reload}>
          Refresh
        </button>
      </div>
      <p className="note">
        These numbers are read live from the database. Event counts follow the status that
        organizers set.
      </p>

      <div className="stat-grid">
        <StatCard
          label="Events"
          value={events.total}
          detail={`${events.upcoming} upcoming · ${events.ongoing} ongoing`}
        />
        <StatCard
          label="Active users"
          value={users.active}
          detail={`${users.total} accounts in total`}
        />
        <StatCard label="Venues" value={venues} />
        <StatCard label="Participants" value={participants} />
        <StatCard
          label="Attendance records"
          value={attendance.total}
          detail={`Attendance rate: ${formatPercent(rate)}`}
        />
      </div>

      <div className="two-column">
        <section className="card" aria-labelledby="events-by-status">
          <h2 id="events-by-status">Events by status</h2>
          <BarList
            label="Events by status"
            total={events.total}
            items={[
              { label: 'Upcoming', value: events.upcoming },
              { label: 'Ongoing', value: events.ongoing },
              { label: 'Completed', value: events.completed },
              { label: 'Cancelled', value: events.cancelled },
            ]}
          />
        </section>

        <section className="card" aria-labelledby="attendance-breakdown">
          <h2 id="attendance-breakdown">Attendance records</h2>
          <BarList
            label="Attendance records"
            total={attendance.total}
            items={[
              { label: 'Present', value: attendance.present },
              { label: 'Late', value: attendance.late },
              { label: 'Absent', value: attendance.absent },
            ]}
          />
          <p className="note">
            Attendance rate: <strong>{formatPercent(rate)}</strong> (Present and Late, out of the
            records saved).
          </p>
        </section>
      </div>

      <section className="card" aria-labelledby="next-events">
        <h2 id="next-events">Next upcoming events</h2>
        {upcomingEvents.length === 0 ? (
          <p className="muted">No upcoming events.</p>
        ) : (
          <ul className="plain-list">
            {upcomingEvents.map((event) => (
              <li key={event.eventId}>
                <Link to={`/events/${event.eventId}`}>{event.eventName}</Link>
                <span className="muted">
                  {formatDate(event.eventDate)} · {formatTime(event.startTime)} –{' '}
                  {formatTime(event.endTime)} · {event.venueName}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="card" aria-labelledby="recent-activity">
        <h2 id="recent-activity">Recent activity</h2>
        <DataTable
          caption="Recent activity"
          columns={activityColumns}
          rows={recentActivity}
          rowKey={(row) => row.logId}
          emptyMessage="No activity yet."
        />
      </section>
    </main>
  )
}