import { useEffect, useRef, useState } from 'react'
import { api } from '../../api/client'
import { useAuth } from '../../auth/useAuth'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import Pagination from '../../components/Pagination'
import StatusBadge from '../../components/StatusBadge'
import { ALL_STATUSES, isOpenStatus } from '../../utils/eventStatus'
import { formatDate, formatTime } from '../../utils/format'
import EventFormDialog from './EventFormDialog'
import EventStatusDialog from './EventStatusDialog'

const PAGE_SIZE = 10
const FILTER_DELAY_MS = 350
const EMPTY_FILTERS = { status: '', venueId: '', search: '', from: '', to: '' }

export default function EventsPage() {
  const { isOrganizer } = useAuth()
  const notify = useNotify()

  const [rows, setRows] = useState([])
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [reloadCount, setReloadCount] = useState(0)
  const [venues, setVenues] = useState([])

  const [searchText, setSearchText] = useState('') // what is typed
  const [filters, setFilters] = useState(EMPTY_FILTERS) // what is sent to the server
  const [sort, setSort] = useState({ key: 'eventDate', direction: 'desc' })
  const [page, setPage] = useState(0) // zero-based, like the backend
  const timer = useRef(null)

  const [form, setForm] = useState({ open: false, event: null })
  const [statusTarget, setStatusTarget] = useState(null)
  const [deleting, setDeleting] = useState(null)
  const [deleteBusy, setDeleteBusy] = useState(false)

  const rangeInvalid = Boolean(filters.from && filters.to && filters.to < filters.from)

  // The venues, for the filter and for the form's dropdown.
  useEffect(() => {
    let cancelled = false
    api.get('/venues')
      .then((list) => {
        if (!cancelled) setVenues(list)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [])

  // Ask the server for one page whenever the filters, sort, page or reload counter change.
  useEffect(() => {
    if (rangeInvalid) return undefined
    let cancelled = false
    api.getPage('/events', {
      status: filters.status,
      venueId: filters.venueId,
      search: filters.search,
      from: filters.from,
      to: filters.to,
      page,
      size: PAGE_SIZE,
      sort: sort.key,
      direction: sort.direction,
    })
      .then(({ items, totalCount: total }) => {
        if (cancelled) return // a newer request has replaced this one
        if (items.length === 0 && total > 0 && page > 0) {
          setPage(Math.ceil(total / PAGE_SIZE) - 1) // this page no longer exists: step back
          return
        }
        setRows(items)
        setTotalCount(total)
        setLoadError('')
      })
      .catch((err) => {
        if (!cancelled) setLoadError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [filters, sort, page, reloadCount, rangeInvalid])

  // Stop a pending search update if the page is closed.
  useEffect(() => () => clearTimeout(timer.current), [])

  function reload() {
    setReloadCount((count) => count + 1)
  }

  function updateFilter(name, value) {
    setFilters((current) => ({ ...current, [name]: value }))
    setPage(0)
  }

  // Search waits a moment after the last keystroke before asking the server.
  function handleSearchChange(value) {
    setSearchText(value)
    clearTimeout(timer.current)
    timer.current = setTimeout(() => {
      setFilters((current) => ({ ...current, search: value.trim() }))
      setPage(0)
    }, FILTER_DELAY_MS)
  }

  function clearFilters() {
    clearTimeout(timer.current)
    setSearchText('')
    setFilters(EMPTY_FILTERS)
    setPage(0)
  }

  function handleSort(key) {
    setSort((current) =>
      current.key === key
        ? { key, direction: current.direction === 'asc' ? 'desc' : 'asc' }
        : { key, direction: key === 'eventDate' ? 'desc' : 'asc' },
    )
    setPage(0)
  }

  function handleSaved(kind, name) {
    setForm({ open: false, event: null })
    notify.success(`Event "${name}" was ${kind}.`)
    reload()
  }

  function handleStatusChanged(newStatus) {
    notify.success(`"${statusTarget.eventName}" is now ${newStatus}.`)
    setStatusTarget(null)
    reload()
  }

  async function confirmDelete() {
    const target = deleting
    setDeleteBusy(true)
    try {
      await api.delete(`/events/${target.eventId}`)
      setDeleting(null)
      notify.success(`Event "${target.eventName}" was deleted.`)
    } catch (err) {
      setDeleting(null)
      notify.error(err.message) // for a 409 the server explains: cancel the event instead
    } finally {
      setDeleteBusy(false)
      reload()
    }
  }

  const columns = [
    { key: 'eventDate', header: 'Date', sortable: true, render: (e) => formatDate(e.eventDate) },
    { key: 'time', header: 'Time', render: (e) => `${formatTime(e.startTime)} – ${formatTime(e.endTime)}` },
    { key: 'eventName', header: 'Event', sortable: true },
    { key: 'venueName', header: 'Venue' },
    { key: 'eventStatus', header: 'Status', sortable: true, render: (e) => <StatusBadge status={e.eventStatus} /> },
    { key: 'organizerName', header: 'Organizer' },
  ]
  if (isOrganizer) {
    columns.push({
      key: 'actions',
      header: <span className="visually-hidden">Actions</span>,
      className: 'num',
      render: (e) => (
        <div className="row-actions">
          {isOpenStatus(e.eventStatus) && (
            <>
              <button
                type="button"
                className="button button-secondary button-small"
                onClick={() => setForm({ open: true, event: e })}
                aria-label={`Edit ${e.eventName}`}
              >
                Edit
              </button>
              <button
                type="button"
                className="button button-secondary button-small"
                onClick={() => setStatusTarget(e)}
                aria-label={`Change status of ${e.eventName}`}
              >
                Status
              </button>
            </>
          )}
          <button
            type="button"
            className="button button-danger-outline button-small"
            onClick={() => setDeleting(e)}
            aria-label={`Delete ${e.eventName}`}
          >
            Delete
          </button>
        </div>
      ),
    })
  }

  const filtering = Object.values(filters).some((value) => value !== '')
  const emptyMessage = filtering
    ? 'No events match your filters.'
    : isOrganizer
      ? 'No events yet. Use "Add event" to create one.'
      : 'No events yet.'

  return (
    <main className="page">
      <div className="page-header">
        <h1>Events</h1>
        {isOrganizer && (
          <button
            type="button"
            className="button"
            onClick={() => setForm({ open: true, event: null })}
          >
            Add event
          </button>
        )}
      </div>

      <div className="filters" role="search" aria-label="Filter events">
        <div className="filter">
          <label htmlFor="event-search">Search</label>
          <input
            id="event-search"
            type="search"
            placeholder="Event name"
            value={searchText}
            onChange={(e) => handleSearchChange(e.target.value)}
          />
        </div>
        <div className="filter">
          <label htmlFor="filter-status">Status</label>
          <select
            id="filter-status"
            value={filters.status}
            onChange={(e) => updateFilter('status', e.target.value)}
          >
            <option value="">All statuses</option>
            {ALL_STATUSES.map((status) => (
              <option key={status} value={status}>{status}</option>
            ))}
          </select>
        </div>
        <div className="filter">
          <label htmlFor="filter-venue">Venue</label>
          <select
            id="filter-venue"
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
          <label htmlFor="filter-from">From</label>
          <input
            id="filter-from"
            type="date"
            value={filters.from}
            onChange={(e) => updateFilter('from', e.target.value)}
          />
        </div>
        <div className="filter">
          <label htmlFor="filter-to">To</label>
          <input
            id="filter-to"
            type="date"
            value={filters.to}
            onChange={(e) => updateFilter('to', e.target.value)}
          />
        </div>
        <div className="filter filter-clear">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={clearFilters}
            disabled={!filtering && searchText === ''}
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

      {loading ? (
        <p className="muted" role="status">Loading events…</p>
      ) : loadError ? (
        <div className="alert alert-error" role="alert">
          <p>{loadError}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      ) : (
        <>
          <DataTable
            caption="Events"
            columns={columns}
            rows={rows}
            rowKey={(e) => e.eventId}
            emptyMessage={emptyMessage}
            sort={sort}
            onSort={handleSort}
          />
          <Pagination
            page={page}
            pageSize={PAGE_SIZE}
            totalCount={totalCount}
            onPageChange={setPage}
          />
        </>
      )}

      <EventFormDialog
        open={form.open}
        event={form.event}
        venues={venues}
        onClose={() => setForm({ open: false, event: null })}
        onSaved={handleSaved}
      />

      <EventStatusDialog
        event={statusTarget}
        onClose={() => setStatusTarget(null)}
        onChanged={handleStatusChanged}
      />

      <ConfirmDialog
        open={deleting !== null}
        title="Delete event?"
        message={
          deleting
            ? `"${deleting.eventName}" on ${formatDate(deleting.eventDate)} will be permanently deleted, together with its schedule and staff list. Events with attendance records cannot be deleted; cancel them instead.`
            : ''
        }
        confirmLabel="Delete"
        danger
        busy={deleteBusy}
        onConfirm={confirmDelete}
        onCancel={() => setDeleting(null)}
      />
    </main>
  )
}