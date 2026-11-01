import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'

const STAFF_STATUSES = ['Pending', 'Confirmed', 'Cancelled']

// Client-side checks that mirror the server's rules. The server always has the last word.
function validate({ staffName, staffRole }) {
  const errors = {}
  const name = staffName.trim()

  if (!name) errors.staffName = 'Staff name is required.'
  else if (name.length > 100) errors.staffName = 'Staff name must be at most 100 characters.'

  if (staffRole.trim().length > 50) errors.staffRole = 'Staff role must be at most 50 characters.'
  return errors
}

function StaffForm({ event, entry, onCancel, onSaved, onSavingChange }) {
  const [staffName, setStaffName] = useState(entry?.staffName ?? '')
  const [staffRole, setStaffRole] = useState(entry?.staffRole ?? '')
  const [assignmentStatus, setAssignmentStatus] = useState(entry?.assignmentStatus ?? 'Pending')
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(submitEvent) {
    submitEvent.preventDefault()
    setFormError('')

    const found = validate({ staffName, staffRole })
    setErrors(found)
    if (Object.keys(found).length > 0) return

    const body = {
      staffName: staffName.trim(),
      staffRole: staffRole.trim() || null,
      assignmentStatus,
    }

    setSaving(true)
    onSavingChange(true)
    try {
      if (entry) {
        await api.put(`/events/${event.eventId}/assignments/${entry.assignmentId}`, body)
      } else {
        await api.post(`/events/${event.eventId}/assignments`, body)
      }
      onSaved(entry ? 'updated' : 'added', body.staffName)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) {
        setErrors(err.fieldErrors) // keys match the field names
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
        id="staff-name"
        label="Name"
        required
        autoFocus
        value={staffName}
        onChange={(e) => setStaffName(e.target.value)}
        error={errors.staffName}
      />
      <Field
        id="staff-role"
        label="Role"
        hint="Optional. For example: Usher, Sound team, Coordinator."
        value={staffRole}
        onChange={(e) => setStaffRole(e.target.value)}
        error={errors.staffRole}
      />
      <Field
        id="staff-status"
        label="Status"
        as="select"
        value={assignmentStatus}
        onChange={(e) => setAssignmentStatus(e.target.value)}
        error={errors.assignmentStatus}
      >
        {STAFF_STATUSES.map((status) => (
          <option key={status} value={status}>{status}</option>
        ))}
      </Field>

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

// entry = null means "add a new person"; otherwise the record being edited.
export default function StaffFormDialog({ open, event, entry, onClose, onSaved }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal
      open={open}
      title={entry ? 'Edit staff member' : 'Add staff member'}
      onClose={saving ? () => {} : onClose}
    >
      <StaffForm
        event={event}
        entry={entry}
        onCancel={onClose}
        onSaved={onSaved}
        onSavingChange={setSaving}
      />
    </Modal>
  )
}