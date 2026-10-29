import { useEffect, useMemo, useState } from 'react'
import { api } from '../../api/client'
import { useAuth } from '../../auth/useAuth'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import Pagination from '../../components/Pagination'
import VenueFormDialog from './VenueFormDialog'

const PAGE_SIZE = 10

export default function VenuesPage() {
  const { isOrganizer } = useAuth()
  const notify = useNotify()

  const [venues, setVenues] = useState([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [reloadCount, setReloadCount] = useState(0)

  const [search, setSearch] = useState('')
  const [page, setPage] = useState(0)

  const [form, setForm] = useState({ open: false, venue: null })
  const [deleting, setDeleting] = useState(null)
  const [deleteBusy, setDeleteBusy] = useState(false)

  // Load the venues on first render and again whenever reload() is called.
  useEffect(() => {
    let cancelled = false
    api.get('/venues')
      .then((data) => {
        if (cancelled) return
        setVenues(data)
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
  }, [reloadCount])

  function reload() {
    setReloadCount((count) => count + 1)
  }

  // The backend returns every venue (a short list), so search and paging happen here.
  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase()
    if (!query) return venues
    return venues.filter(
      (venue) =>
        venue.venueName.toLowerCase().includes(query) ||
        venue.location.toLowerCase().includes(query),
    )
  }, [venues, search])

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const currentPage = Math.min(page, totalPages - 1)
  const pageRows = filtered.slice(currentPage * PAGE_SIZE, (currentPage + 1) * PAGE_SIZE)

  function handleSearch(value) {
    setSearch(value)
    setPage(0)
  }

  function handleSaved(kind, name) {
    setForm({ open: false, venue: null })
    notify.success(`Venue "${name}" was ${kind}.`)
    reload()
  }

  async function confirmDelete() {
    const target = deleting
    setDeleteBusy(true)
    try {
      await api.delete(`/venues/${target.venueId}`)
      setDeleting(null)
      notify.success(`Venue "${target.venueName}" was deleted.`)
    } catch (err) {
      setDeleting(null)
      notify.error(
        err.status === 409
          ? 'This venue is still used by one or more events, so it cannot be deleted.'
          : err.message,
      )
    } finally {
      setDeleteBusy(false)
      reload()
    }
  }

  const columns = [
    { key: 'venueName', header: 'Name' },
    { key: 'location', header: 'Location' },
    { key: 'capacity', header: 'Capacity', className: 'num', render: (venue) => venue.capacity ?? '—' },
  ]
  if (isOrganizer) {
    columns.push({
      key: 'actions',
      header: <span className="visually-hidden">Actions</span>,
      className: 'num',
      render: (venue) => (
        <div className="row-actions">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => setForm({ open: true, venue })}
            aria-label={`Edit ${venue.venueName}`}
          >
            Edit
          </button>
          <button
            type="button"
            className="button button-danger-outline button-small"
            onClick={() => setDeleting(venue)}
            aria-label={`Delete ${venue.venueName}`}
          >
            Delete
          </button>
        </div>
      ),
    })
  }

  const emptyMessage =
    venues.length === 0
      ? isOrganizer
        ? 'No venues yet. Use "Add venue" to create one.'
        : 'No venues yet.'
      : 'No venues match your search.'

  return (
    <main className="page">
      <div className="page-header">
        <h1>Venues</h1>
        {isOrganizer && (
          <button
            type="button"
            className="button"
            onClick={() => setForm({ open: true, venue: null })}
          >
            Add venue
          </button>
        )}
      </div>

      {loading ? (
        <p className="muted" role="status">Loading venues…</p>
      ) : loadError ? (
        <div className="alert alert-error" role="alert">
          <p>{loadError}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      ) : (
        <>
          <div className="toolbar">
            <label htmlFor="venue-search" className="visually-hidden">Search venues</label>
            <input
              id="venue-search"
              type="search"
              placeholder="Search by name or location"
              value={search}
              onChange={(event) => handleSearch(event.target.value)}
            />
          </div>

          <DataTable
            caption="Venues"
            columns={columns}
            rows={pageRows}
            rowKey={(venue) => venue.venueId}
            emptyMessage={emptyMessage}
          />
          <Pagination
            page={currentPage}
            pageSize={PAGE_SIZE}
            totalCount={filtered.length}
            onPageChange={setPage}
          />
        </>
      )}

      <VenueFormDialog
        open={form.open}
        venue={form.venue}
        onClose={() => setForm({ open: false, venue: null })}
        onSaved={handleSaved}
      />

      <ConfirmDialog
        open={deleting !== null}
        title="Delete venue?"
        message={deleting ? `"${deleting.venueName}" will be permanently deleted. This cannot be undone.` : ''}
        confirmLabel="Delete"
        danger
        busy={deleteBusy}
        onConfirm={confirmDelete}
        onCancel={() => setDeleting(null)}
      />
    </main>
  )
}