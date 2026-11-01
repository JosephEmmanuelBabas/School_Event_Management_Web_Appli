import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'
import { formatTime, todayIso, trimTime } from '../../utils/format'

// Client-side checks that mirror the server's rules. The server always has the last word.
function validate(values, editing) {
  const errors = {}
  const name = values.eventName.trim()

  if (!name) errors.eventName = 'Event name is required.'
  else if (name.length > 100) errors.eventName = 'Event name must be at most 100 characters.'

  if (values.description.length > 5000) errors.description = 'Description must be at most 5000 characters.'
  if (!values.venueId) errors.venueId = 'Choose a venue.'

  if (!values.eventDate) {
    errors.eventDate = 'Event date is required.'
  } else if (values.eventDate < todayIso() && (!editing || values.eventDate !== editing.eventDate)) {
    errors.eventDate = editing
      ? 'Event date cannot be moved into the past.'
      : 'Event date cannot be in the past.'
  }

  if (!values.startTime) errors.startTime = 'Start time is required.'
  if (!values.endTime) errors.endTime = 'End time is required.'
  else if (values.startTime && values.endTime <= values.startTime) {
    errors.endTime = 'End time must be after start time.'
  }
  return errors
}

function EventForm({ event, venues, onCancel, onSaved, onSavingChange }) {
  const [eventName, setEventName] = useState(event?.eventName ?? '')
  const [description, setDescription] = useState(event?.description ?? '')
  const [venueId, setVenueId] = useState(event ? String(event.venueId) : '')
  const [eventDate, setEventDate] = useState(event?.eventDate ?? '')
  const [startTime, setStartTime] = useState(trimTime(event?.startTime))
  const [endTime, setEndTime] = useState(trimTime(event?.endTime))
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  // The chosen venue's events on the chosen date, used for the live conflict warning.
  const [bookings, setBookings] = useState({ key: '', events: [] })

  useEffect(() => {
    let cancelled = false
    let timer
    if (venueId && eventDate) {
      const key = `${venueId}|${eventDate}`
      timer = setTimeout(() => {
        api.get('/events', { venueId, from: eventDate, to: eventDate, size: 100 })
          .then((list) => {
            if (!cancelled) setBookings({ key, events: list })
          })
          .catch(() => {
            if (!cancelled) setBookings({ key, events: [] })
          })
      }, 300)
    }
    return () => {
      cancelled = true
      clearTimeout(timer)
    }
  }, [venueId, eventDate])

  const bookingKey = venueId && eventDate ? `${venueId}|${eventDate}` : ''
  const timesReady = startTime && endTime && endTime > startTime
  const conflicts =
    bookingKey && timesReady && bookings.key === bookingKey
      ? bookings.events.filter(
          (other) =>
            other.eventStatus !== 'Cancelled' &&
            other.eventId !== event?.eventId &&
            trimTime(other.startTime) < endTime &&
            trimTime(other.endTime) > startTime,
        )
      : []

  async function handleSubmit(submitEvent) {
    submitEvent.preventDefault()
    setFormError('')

    const found = validate({ eventName, description, venueId, eventDate, startTime, endTime }, event)
    setErrors(found)
    if (Object.keys(found).length > 0) return

    const body = {
      eventName: eventName.trim(),
      description: description.trim() || null,
      eventDate,
      startTime,
      endTime,
      venueId: Number(venueId),
    }

    setSaving(true)
    onSavingChange(true)
    try {
      if (event) {
        await api.put(`/events/${event.eventId}`, body)
      } else {
        await api.post('/events', body)
      }
      onSaved(event ? 'updated' : 'created', body.eventName)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) {
        setErrors(err.fieldErrors) // keys match the field names
      } else {
        setFormError(err.message) // for example the 409 "venue is already booked" message
      }
    } finally {
      setSaving(false)
      onSavingChange(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      {formError && <p className="alert alert-error" role="alert">{formError}</p>}

      <Field
        id="event-name"
        label="Event name"
        required
        autoFocus
        value={eventName}
        onChange={(e) => setEventName(e.target.value)}
        error={errors.eventName}
      />

      <Field
        id="event-venue"
        label="Venue"
        required
        as="select"
        value={venueId}
        onChange={(e) => setVenueId(e.target.value)}
        error={errors.venueId}
        hint={venues.length === 0 ? 'There are no venues yet.' : undefined}
      >
        <option value="">Select a venue…</option>
        {venues.map((venue) => (
          <option key={venue.venueId} value={String(venue.venueId)}>
            {venue.venueName} — {venue.location}
          </option>
        ))}
      </Field>
      {venues.length === 0 && (
        <p className="field-hint"><Link to="/venues">Add a venue first</Link>, then come back.</p>
      )}

      <Field
        id="event-date"
        label="Date"
        type="date"
        required
        value={eventDate}
        onChange={(e) => setEventDate(e.target.value)}
        error={errors.eventDate}
      />

      <div className="field-row">
        <Field
          id="event-start"
          label="Start time"
          type="time"
          required
          value={startTime}
          onChange={(e) => setStartTime(e.target.value)}
          error={errors.startTime}
        />
        <Field
          id="event-end"
          label="End time"
          type="time"
          required
          value={endTime}
          onChange={(e) => setEndTime(e.target.value)}
          error={errors.endTime}
        />
      </div>

      {conflicts.length > 0 && (
        <p className="alert alert-warning" role="status">
          This venue is already booked at that time by{' '}
          {conflicts
            .map((c) => `"${c.eventName}" (${formatTime(c.startTime)} – ${formatTime(c.endTime)})`)
            .join(', ')}
          . Choose another time or venue.
        </p>
      )}

      <Field
        id="event-description"
        label="Description"
        as="textarea"
        rows={3}
        hint="Optional."
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        error={errors.description}
      />

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

// event = null means "add a new event"; otherwise the event being edited.
export default function EventFormDialog({ open, event, venues, onClose, onSaved }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal
      open={open}
      title={event ? 'Edit event' : 'Add event'}
      onClose={saving ? () => {} : onClose}
    >
      <EventForm
        event={event}
        venues={venues}
        onCancel={onClose}
        onSaved={onSaved}
        onSavingChange={setSaving}
      />
    </Modal>
  )
}