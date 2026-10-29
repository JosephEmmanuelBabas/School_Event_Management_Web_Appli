import { useEffect, useRef, useState } from 'react'
import { api } from '../../api/client'
import { useAuth } from '../../auth/useAuth'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import Pagination from '../../components/Pagination'
import ParticipantFormDialog from './ParticipantFormDialog'

const PAGE_SIZE = 10
const FILTER_DELAY_MS = 350

export default function ParticipantsPage() {
  const { isOrganizer } = useAuth()
  const notify = useNotify()

  const [rows, setRows] = useState([])
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [reloadCount, setReloadCount] = useState(0)

  // What the user has typed (changes on every keystroke) ...
  const [searchText, setSearchText] = useState('')
  const [gradeText, setGradeText] = useState('')
  // ... and what is actually sent to the server (changes after a short pause).
  const [filters, setFilters] = useState({ search: '', gradeLevel: '' })
  const [page, setPage] = useState(0) // zero-based, like the backend
  const timer = useRef(null)

  const [form, setForm] = useState({ open: false, participant: null })
  const [deleting, setDeleting] = useState(null)
  const [deleteBusy, setDeleteBusy] = useState(false)

  // Ask the server for one page whenever the filters, the page or the reload counter change.
  useEffect(() => {
    let cancelled = false
    api.getPage('/participants', {
      search: filters.search,
      gradeLevel: filters.gradeLevel,
      page,
      size: PAGE_SIZE,
    })
      .then(({ items, totalCount: total }) => {
        if (cancelled) return // a newer request has replaced this one
        if (items.length === 0 && total > 0 && page > 0) {
          // This page no longer exists (for example its last row was deleted): step back.
          setPage(Math.ceil(total / PAGE_SIZE) - 1)
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
  }, [filters, page, reloadCount])

  // Stop a pending filter update if the page is closed.
  useEffect(() => () => clearTimeout(timer.current), [])

  function reload() {
    setReloadCount((count) => count + 1)
  }

  // Wait a moment after the last keystroke, then apply both filters and return to page 1.
  function applyFiltersSoon(nextSearch, nextGrade) {
    clearTimeout(timer.current)
    timer.current = setTimeout(() => {
      setFilters({ search: nextSearch.trim(), gradeLevel: nextGrade.trim() })
      setPage(0)
    }, FILTER_DELAY_MS)
  }

  function handleSearchChange(value) {
    setSearchText(value)
    applyFiltersSoon(value, gradeText)
  }

  function handleGradeChange(value) {
    setGradeText(value)
    applyFiltersSoon(searchText, value)
  }

  function handleSaved(kind, name) {
    setForm({ open: false, participant: null })
    notify.success(`Participant "${name}" was ${kind}.`)
    reload()
  }

  async function confirmDelete() {
    const target = deleting
    setDeleteBusy(true)
    try {
      await api.delete(`/participants/${target.participantId}`)
      setDeleting(null)
      notify.success(`Participant "${target.lastName}, ${target.firstName}" was deleted.`)
    } catch (err) {
      setDeleting(null)
      notify.error(err.message) // for a 409 the server explains: attendance records exist
    } finally {
      setDeleteBusy(false)
      reload()
    }
  }

  const columns = [
    { key: 'studentNumber', header: 'Student number' },
    { key: 'name', header: 'Name', render: (p) => `${p.lastName}, ${p.firstName}` },
    { key: 'gradeLevel', header: 'Grade', render: (p) => p.gradeLevel ?? '—' },
  ]
  if (isOrganizer) {
    columns.push({
      key: 'actions',
      header: <span className="visually-hidden">Actions</span>,
      className: 'num',
      render: (p) => (
        <div className="row-actions">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => setForm({ open: true, participant: p })}
            aria-label={`Edit ${p.firstName} ${p.lastName}`}
          >
            Edit
          </button>
          <button
            type="button"
            className="button button-danger-outline button-small"
            onClick={() => setDeleting(p)}
            aria-label={`Delete ${p.firstName} ${p.lastName}`}
          >
            Delete
          </button>
        </div>
      ),
    })
  }

  const filtering = filters.search !== '' || filters.gradeLevel !== ''
  const emptyMessage = filtering
    ? 'No participants match your search.'
    : isOrganizer
      ? 'No participants yet. Use "Add participant" to create one.'
      : 'No participants yet.'

  return (
    <main className="page">
      <div className="page-header">
        <h1>Participants</h1>
        {isOrganizer && (
          <button
            type="button"
            className="button"
            onClick={() => setForm({ open: true, participant: null })}
          >
            Add participant
          </button>
        )}
      </div>

      {loading ? (
        <p className="muted" role="status">Loading participants…</p>
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
            <label htmlFor="participant-search" className="visually-hidden">Search participants</label>
            <input
              id="participant-search"
              type="search"
              placeholder="Search by name or student number"
              value={searchText}
              onChange={(event) => handleSearchChange(event.target.value)}
            />
            <label htmlFor="participant-grade-filter" className="visually-hidden">Filter by grade</label>
            <input
              id="participant-grade-filter"
              type="text"
              className="input-narrow"
              placeholder="Grade"
              value={gradeText}
              onChange={(event) => handleGradeChange(event.target.value)}
            />
          </div>

          <DataTable
            caption="Participants"
            columns={columns}
            rows={rows}
            rowKey={(p) => p.participantId}
            emptyMessage={emptyMessage}
          />
          <Pagination
            page={page}
            pageSize={PAGE_SIZE}
            totalCount={totalCount}
            onPageChange={setPage}
          />
        </>
      )}

      <ParticipantFormDialog
        open={form.open}
        participant={form.participant}
        onClose={() => setForm({ open: false, participant: null })}
        onSaved={handleSaved}
      />

      <ConfirmDialog
        open={deleting !== null}
        title="Delete participant?"
        message={
          deleting
            ? `"${deleting.lastName}, ${deleting.firstName}" (${deleting.studentNumber}) will be permanently deleted. This cannot be undone.`
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