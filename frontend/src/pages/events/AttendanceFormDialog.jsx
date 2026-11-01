import { useEffect, useState } from 'react'
import { api } from '../../api/client'
import Modal from '../../components/Modal'

const PAGE_SIZE = 25
const STATUSES = ['Present', 'Late', 'Absent']

function AttendanceForm({ event, recordedIds, onClose, onRecorded }) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState({ items: [], totalCount: 0 })
  const [searching, setSearching] = useState(true)
  const [searchError, setSearchError] = useState('')
  const [selectedId, setSelectedId] = useState(null)
  const [status, setStatus] = useState('Present')
  const [justRecorded, setJustRecorded] = useState(() => new Set())
  const [message, setMessage] = useState('')
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  // Search the participants on the server, a moment after the last keystroke.
  useEffect(() => {
    let cancelled = false
    const timer = setTimeout(
      () => {
        setSearching(true)
        api.getPage('/participants', { search: query.trim(), size: PAGE_SIZE })
          .then(({ items, totalCount }) => {
            if (cancelled) return
            setResults({ items, totalCount })
            setSearchError('')
          })
          .catch((err) => {
            if (!cancelled) setSearchError(err.message)
          })
          .finally(() => {
            if (!cancelled) setSearching(false)
          })
      },
      query === '' ? 0 : 300,
    )
    return () => {
      cancelled = true
      clearTimeout(timer)
    }
  }, [query])

  // Hide people who already have a record for this event.
  const available = results.items.filter(
    (p) => !recordedIds.has(p.participantId) && !justRecorded.has(p.participantId),
  )
  const selected = available.find((p) => p.participantId === selectedId) ?? null

  async function handleSubmit(submitEvent) {
    submitEvent.preventDefault()
    if (!selected) return
    const person = selected

    setSaving(true)
    setFormError('')
    setMessage('')
    try {
      await api.post(`/events/${event.eventId}/attendance`, {
        participantId: person.participantId,
        attendanceStatus: status,
      })
      setJustRecorded((previous) => new Set(previous).add(person.participantId))
      setSelectedId(null)
      setMessage(`Recorded ${person.firstName} ${person.lastName} as ${status}.`)
      onRecorded()
    } catch (err) {
      setFormError(err.message) // for example: already recorded, or the event is not open
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      {formError && <p className="alert alert-error" role="alert">{formError}</p>}
      {message && <p className="alert alert-success" role="status">{message}</p>}

      <label htmlFor="attendance-search">Find a participant</label>
      <input
        id="attendance-search"
        type="search"
        autoFocus
        placeholder="Name or student number"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      <fieldset className="choices choices-scroll">
        <legend>Participant</legend>
        {searchError && <p className="field-error">{searchError}</p>}
        {!searchError && searching && available.length === 0 && (
          <p className="muted" role="status">Searching…</p>
        )}
        {!searchError && !searching && available.length === 0 && (
          <p className="muted">
            {results.totalCount === 0
              ? 'No participants found. Add participants on the Participants page first.'
              : 'No unrecorded participants match.'}
          </p>
        )}
        {available.map((p) => (
          <label key={p.participantId} className="choice">
            <input
              type="radio"
              name="attendance-participant"
              checked={selectedId === p.participantId}
              onChange={() => setSelectedId(p.participantId)}
            />
            <span>
              {p.lastName}, {p.firstName}{' '}
              <span className="muted">
                {p.studentNumber}
                {p.gradeLevel ? ` · Grade ${p.gradeLevel}` : ''}
              </span>
            </span>
          </label>
        ))}
      </fieldset>
      {results.totalCount > PAGE_SIZE && (
        <p className="field-hint">
          Showing the first {PAGE_SIZE} matches. Type more of the name or student number to narrow the list.
        </p>
      )}

      <fieldset className="choices">
        <legend>Status</legend>
        {STATUSES.map((option) => (
          <label key={option} className="choice">
            <input
              type="radio"
              name="attendance-status"
              value={option}
              checked={status === option}
              onChange={() => setStatus(option)}
            />
            {option}
          </label>
        ))}
      </fieldset>

      <div className="modal-actions">
        <button type="button" className="button button-secondary" onClick={onClose} disabled={saving}>
          Done
        </button>
        <button type="submit" className="button" disabled={!selected || saving}>
          {saving ? 'Saving…' : 'Record'}
        </button>
      </div>
    </form>
  )
}

// The dialog stays open after each save, so a whole class can be recorded in one go.
export default function AttendanceFormDialog({ open, event, recordedIds, onClose, onRecorded }) {
  return (
    <Modal open={open} title="Record attendance" onClose={onClose}>
      <AttendanceForm
        event={event}
        recordedIds={recordedIds}
        onClose={onClose}
        onRecorded={onRecorded}
      />
    </Modal>
  )
}