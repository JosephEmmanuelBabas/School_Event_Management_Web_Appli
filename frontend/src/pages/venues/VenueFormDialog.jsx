import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'

// Client-side checks that mirror the server's rules. The server always has the last word.
function validate({ venueName, location, capacity }) {
  const errors = {}
  const name = venueName.trim()
  const place = location.trim()
  const cap = capacity.trim()

  if (!name) errors.venueName = 'Venue name is required.'
  else if (name.length > 100) errors.venueName = 'Venue name must be at most 100 characters.'

  if (!place) errors.location = 'Location is required.'
  else if (place.length > 150) errors.location = 'Location must be at most 150 characters.'

  if (cap && (!/^\d+$/.test(cap) || Number(cap) < 1 || Number(cap) > 2147483647)) {
    errors.capacity = 'Capacity must be a whole number greater than zero.'
  }
  return errors
}

function VenueForm({ venue, onCancel, onSaved, onSavingChange }) {
  const [venueName, setVenueName] = useState(venue?.venueName ?? '')
  const [location, setLocation] = useState(venue?.location ?? '')
  const [capacity, setCapacity] = useState(venue?.capacity == null ? '' : String(venue.capacity))
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    const found = validate({ venueName, location, capacity })
    setErrors(found)
    if (Object.keys(found).length > 0) return

    const body = {
      venueName: venueName.trim(),
      location: location.trim(),
      capacity: capacity.trim() ? Number(capacity.trim()) : null,
    }

    setSaving(true)
    onSavingChange(true)
    try {
      if (venue) {
        await api.put(`/venues/${venue.venueId}`, body)
      } else {
        await api.post('/venues', body)
      }
      onSaved(venue ? 'updated' : 'created', body.venueName)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) {
        setErrors(err.fieldErrors) // keys match the field names: venueName, location, capacity
      } else if (err.status === 409) {
        setErrors({ venueName: err.message }) // duplicate venue name
      } else {
        setFormError(err.message)
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
        id="venue-name"
        label="Venue name"
        required
        autoFocus
        value={venueName}
        onChange={(event) => setVenueName(event.target.value)}
        error={errors.venueName}
      />
      <Field
        id="venue-location"
        label="Location"
        required
        value={location}
        onChange={(event) => setLocation(event.target.value)}
        error={errors.location}
      />
      <Field
        id="venue-capacity"
        label="Capacity"
        inputMode="numeric"
        hint="Optional. The maximum number of people."
        value={capacity}
        onChange={(event) => setCapacity(event.target.value)}
        error={errors.capacity}
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

// venue = null means "add a new venue"; otherwise the venue being edited.
export default function VenueFormDialog({ open, venue, onClose, onSaved }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal
      open={open}
      title={venue ? 'Edit venue' : 'Add venue'}
      onClose={saving ? () => {} : onClose}
    >
      <VenueForm
        venue={venue}
        onCancel={onClose}
        onSaved={onSaved}
        onSavingChange={setSaving}
      />
    </Modal>
  )
}