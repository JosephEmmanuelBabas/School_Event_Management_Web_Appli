import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'
import { formatTime, trimTime } from '../../utils/format'

// Client-side checks that mirror the server's rules. The server always has the last word.
function validate({ activityName, startTime, endTime }, event) {
  const errors = {}
  const name = activityName.trim()
  const windowText = `${formatTime(event.startTime)} to ${formatTime(event.endTime)}`

  if (!name) errors.activityName = 'Activity name is required.'
  else if (name.length > 100) errors.activityName = 'Activity name must be at most 100 characters.'

  if (!startTime) errors.startTime = 'Start time is required.'
  else if (startTime < trimTime(event.startTime)) {
    errors.startTime = `The activity cannot start before the event (${windowText}).`
  }

  if (!endTime) errors.endTime = 'End time is required.'
  else if (startTime && endTime <= startTime) errors.endTime = 'End time must be after start time.'
  else if (endTime > trimTime(event.endTime)) {
    errors.endTime = `The activity cannot end after the event (${windowText}).`
  }
  return errors
}

function ScheduleForm({ event, entry, onCancel, onSaved, onSavingChange }) {
  const [activityName, setActivityName] = useState(entry?.activityName ?? '')
  const [startTime, setStartTime] = useState(trimTime(entry?.startTime))
  const [endTime, setEndTime] = useState(trimTime(entry?.endTime))
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(submitEvent) {
    submitEvent.preventDefault()
    setFormError('')

    const found = validate({ activityName, startTime, endTime }, event)
    setErrors(found)
    if (Object.keys(found).length > 0) return

    const body = { activityName: activityName.trim(), startTime, endTime }

    setSaving(true)
    onSavingChange(true)
    try {
      if (entry) {
        await api.put(`/events/${event.eventId}/schedules/${entry.scheduleId}`, body)
      } else {
        await api.post(`/events/${event.eventId}/schedules`, body)
      }
      onSaved(entry ? 'updated' : 'added', body.activityName)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) {
        setErrors(err.fieldErrors) // keys match the field names
      } else {
        setFormError(err.message) // for example "must fall within the event's time"
      }
    } finally {
      setSaving(false)
      onSavingChange(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      {formError && <p className="alert alert-error" role="alert">{formError}</p>}

      <p className="note">
        The event runs {formatTime(event.startTime)} – {formatTime(event.endTime)}. Activities must
        fall inside that time.
      </p>

      <Field
        id="schedule-name"
        label="Activity"
        required
        autoFocus
        value={activityName}
        onChange={(e) => setActivityName(e.target.value)}
        error={errors.activityName}
      />

      <div className="field-row">
        <Field
          id="schedule-start"
          label="Start time"
          type="time"
          required
          value={startTime}
          onChange={(e) => setStartTime(e.target.value)}
          error={errors.startTime}
        />
        <Field
          id="schedule-end"
          label="End time"
          type="time"
          required
          value={endTime}
          onChange={(e) => setEndTime(e.target.value)}
          error={errors.endTime}
        />
      </div>

      <div className="modal-actions">
        <button type="button" className="button button-secondary" onClick={onCancel} disabled={saving}>
          Cancel
        </button>
        <button type="submit" className="button" disabled={saving}>
          {saving ? 'Saving…' : 'Save'}
        </button>
      </div>
    </form>
  )
}

// entry = null means "add a new activity"; otherwise the activity being edited.
export default function ScheduleFormDialog({ open, event, entry, onClose, onSaved }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal
      open={open}
      title={entry ? 'Edit activity' : 'Add activity'}
      onClose={saving ? () => {} : onClose}
    >
      <ScheduleForm
        event={event}
        entry={entry}
        onCancel={onClose}
        onSaved={onSaved}
        onSavingChange={setSaving}
      />
    </Modal>
  )
}