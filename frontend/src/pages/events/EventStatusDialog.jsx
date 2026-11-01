import { useState } from 'react'
import { api } from '../../api/client'
import Modal from '../../components/Modal'
import StatusBadge from '../../components/StatusBadge'
import { NEXT_STATUSES } from '../../utils/eventStatus'

const LABELS = {
  Ongoing: 'Start the event (Ongoing)',
  Completed: 'Mark as Completed',
  Cancelled: 'Cancel the event',
}

const HINTS = {
  Ongoing: 'Attendance can be recorded once an event is ongoing.',
  Completed: 'A completed event can no longer be edited. Attendance corrections are still allowed.',
  Cancelled:
    'A cancelled event cannot be changed again. It releases its venue, and no attendance can be recorded for it.',
}

function StatusForm({ event, onClose, onChanged }) {
  const [choice, setChoice] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(submitEvent) {
    submitEvent.preventDefault()
    if (!choice) return
    setSaving(true)
    setError('')
    try {
      await api.post(`/events/${event.eventId}/status`, { status: choice })
      onChanged(choice)
    } catch (err) {
      setError(err.message)
      setSaving(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <p>
        <strong>{event.eventName}</strong> is currently <StatusBadge status={event.eventStatus} />.
      </p>

      {error && <p className="alert alert-error" role="alert">{error}</p>}

      <fieldset className="choices">
        <legend>Change status to</legend>
        {NEXT_STATUSES[event.eventStatus].map((status) => (
          <label key={status} className="choice">
            <input
              type="radio"
              name="new-status"
              value={status}
              checked={choice === status}
              onChange={() => setChoice(status)}
            />
            {LABELS[status]}
          </label>
        ))}
      </fieldset>
      {choice && <p className="field-hint">{HINTS[choice]}</p>}

      <div className="modal-actions">
        <button type="button" className="button button-secondary" onClick={onClose} disabled={saving}>
          Close
        </button>
        <button
          type="submit"
          className={choice === 'Cancelled' ? 'button button-danger' : 'button'}
          disabled={!choice || saving}
        >
          {saving ? 'Saving…' : 'Apply'}
        </button>
      </div>
    </form>
  )
}

// event = the event whose status is being changed, or null when the dialog is closed.
export default function EventStatusDialog({ event, onClose, onChanged }) {
  return (
    <Modal open={event !== null} title="Change event status" onClose={onClose}>
      {event && <StatusForm event={event} onClose={onClose} onChanged={onChanged} />}
    </Modal>
  )
}