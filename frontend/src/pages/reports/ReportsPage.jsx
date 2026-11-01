import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { api } from '../../api/client'
import DataTable from '../../components/DataTable'
import StatusBadge from '../../components/StatusBadge'
import { useApiList } from '../../hooks/useApiList'
import { ALL_STATUSES } from '../../utils/eventStatus'
import { formatDate, formatPercent } from '../../utils/format'

const EMPTY_FILTERS = { from: '', to: '', venueId: '', status: '' }

// Adds up the visible rows. The rate matches the server's rounding (one decimal place).
function totals(rows) {
  const sum = rows.reduce(
    (acc, row) => ({
      present: acc.present + row.present,
      late: acc.late + row.late,
      absent: acc.absent + row.absent,
    }),
    { present: 0, late: 0, absent: 0 },
  )
  const total = sum.present + sum.late + sum.absent
  const rate = total === 0 ? null : Math.round(((sum.present + sum.late) * 1000) / total) / 10
  return { ...sum, total, rate }
}

function TotalsLine({ rows }) {
  if (rows.length === 0) return null
  const sum = totals(rows)
  return (
    <p className="report-totals">
      Totals: Present {sum.present} · Late {sum.late} · Absent {sum.absent} · Recorded {sum.total} ·
      Rate {formatPercent(sum.rate)}
    </p>
  )
}

const eventColumns = [
  { key: 'eventDate', header: 'Date', render: (row) => formatDate(row.eventDate) },
  {
    key: 'eventName',
    header: 'Event',
    render: (row) => <Link to={`/events/${row.eventId}`}>{row.eventName}</Link>,
  },
  { key: 'venueName', header: 'Venue' },
  { key: 'eventStatus', header: 'Status', render: (row) => <StatusBadge status={row.eventStatus} /> },
  { key: 'present', header: 'Present', className: 'num' },
  { key: 'late', header: 'Late', className: 'num' },
  { key: 'absent', header: 'Absent', className: 'num' },
  { key: 'totalRecorded', header: 'Recorded', className: 'num' },
  {
    key: 'rate',
    header: 'Rate',
    className: 'num',
    render: (row) => formatPercent(row.attendanceRatePercent),
  },
]

const gradeColumns = [
  { key: 'gradeLevel', header: 'Grade level' },
  { key: 'present', header: 'Present', className: 'num' },
  { key: 'late', header: 'Late', className: 'num' },
  { key: 'absent', header: 'Absent', className: 'num' },
  { key: 'totalRecorded', header: 'Recorded', className: 'num' },
  {
    key: 'rate',
    header: 'Rate',
    className: 'num',
    render: (row) => formatPercent(row.attendanceRatePercent),
  },
]

export default function ReportsPage() {
  const { items: venues } = useApiList('/venues')
  const [filters, setFilters] = useState(EMPTY_FILTERS)
  const [reloadCount, setReloadCount] = useState(0)
  const [result, setResult] = useState({ key: '', events: [], grades: [] })
  const [error, setError] = useState('')

  const rangeInvalid = Boolean(filters.from && filters.to && filters.to < filters.from)
  // Identifies which filters a result belongs to, so stale results are recognizable.
  const key = `${filters.from}|${filters.to}|${filters.venueId}|${filters.status}|${reloadCount}`

  useEffect(() => {
    if (rangeInvalid) return undefined
    let cancelled = false
    Promise.all([
      api.get('/reports/attendance-by-event', filters),
      api.get('/reports/attendance-by-grade', { from: filters.from, to: filters.to }),
    ])
      .then(([events, grades]) => {
        if (cancelled) return
        setResult({ key, events, grades })
        setError('')
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [filters, key, rangeInvalid])

  function updateFilter(name, value) {
    setFilters((current) => ({ ...current, [name]: value }))
  }

  const hasData = result.key !== ''
  const loading = !rangeInvalid && !error && result.key !== key
  const filtering = Object.values(filters).some((value) => value !== '')

  return (
    <main className="page">
      <h1>Attendance reports</h1>
      <p className="note">
        Dates refer to the event date. The rate is Present and Late out of the attendance records
        saved, so an event with no records shows "—".
      </p>

      <div className="filters" role="search" aria-label="Filter reports">
        <div className="filter">
          <label htmlFor="report-from">From</label>
          <input
            id="report-from"
            type="date"
            value={filters.from}
            onChange={(e) => updateFilter('from', e.target.value)}
          />
        </div>
        <div className="filter">
          <label htmlFor="report-to">To</label>
          <input
            id="report-to"
            type="date"
            value={filters.to}
            onChange={(e) => updateFilter('to', e.target.value)}
          />
        </div>
        <div className="filter">
          <label htmlFor="report-venue">Venue (by event)</label>
          <select
            id="report-venue"
            value={filters.venueId}
            onChange={(e) => updateFilter('venueId', e.target.value)}
          >
            <option value="">All venues</option>
            {venues.map((venue) => (
              <option key={venue.venueId} value={String(venue.venueId)}>{venue.venueName}</option>
            ))}
          </select>
        </div>
        <div className="filter">
          <label htmlFor="report-status">Status (by event)</label>
          <select
            id="report-status"
            value={filters.status}
            onChange={(e) => updateFilter('status', e.target.value)}
          >
            <option value="">All statuses</option>
            {ALL_STATUSES.map((status) => (
              <option key={status} value={status}>{status}</option>
            ))}
          </select>
        </div>
        <div className="filter filter-clear">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => setFilters(EMPTY_FILTERS)}
            disabled={!filtering}
          >
            Clear filters
          </button>
        </div>
      </div>

      {rangeInvalid && (
        <p className="alert alert-error" role="alert">
          The "To" date cannot be before the "From" date.
        </p>
      )}

      {error && (
        <div className="alert alert-error" role="alert">
          <p>{error}</p>
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => setReloadCount((count) => count + 1)}
          >
            Try again
          </button>
        </div>
      )}

      {loading && (
        <p className="muted" role="status">
          {hasData ? 'Updating…' : 'Loading reports…'}
        </p>
      )}

      {hasData && (
        <>
          <section className="card" aria-labelledby="report-by-event">
            <h2 id="report-by-event">Attendance by event</h2>
            <DataTable
              caption="Attendance by event"
              columns={eventColumns}
              rows={result.events}
              rowKey={(row) => row.eventId}
              emptyMessage="No events match these filters."
            />
            <TotalsLine rows={result.events} />
          </section>

          <section className="card" aria-labelledby="report-by-grade">
            <h2 id="report-by-grade">Attendance by grade level</h2>
            <DataTable
              caption="Attendance by grade level"
              columns={gradeColumns}
              rows={result.grades}
              rowKey={(row) => row.gradeLevel}
              emptyMessage="No attendance recorded for these dates."
            />
            <TotalsLine rows={result.grades} />
          </section>
        </>
      )}
    </main>
  )
}