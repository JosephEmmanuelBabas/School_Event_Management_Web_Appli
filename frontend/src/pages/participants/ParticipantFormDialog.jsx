import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'

// Client-side checks that mirror the server's rules. The server always has the last word.
function validate({ studentNumber, firstName, lastName, gradeLevel }) {
  const errors = {}
  const number = studentNumber.trim()
  const first = firstName.trim()
  const last = lastName.trim()
  const grade = gradeLevel.trim()

  if (!number) errors.studentNumber = 'Student number is required.'
  else if (number.length > 20) errors.studentNumber = 'Student number must be at most 20 characters.'

  if (!first) errors.firstName = 'First name is required.'
  else if (first.length > 50) errors.firstName = 'First name must be at most 50 characters.'

  if (!last) errors.lastName = 'Last name is required.'
  else if (last.length > 50) errors.lastName = 'Last name must be at most 50 characters.'

  if (grade.length > 10) errors.gradeLevel = 'Grade level must be at most 10 characters.'
  return errors
}

function ParticipantForm({ participant, onCancel, onSaved, onSavingChange }) {
  const [studentNumber, setStudentNumber] = useState(participant?.studentNumber ?? '')
  const [firstName, setFirstName] = useState(participant?.firstName ?? '')
  const [lastName, setLastName] = useState(participant?.lastName ?? '')
  const [gradeLevel, setGradeLevel] = useState(participant?.gradeLevel ?? '')
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    const found = validate({ studentNumber, firstName, lastName, gradeLevel })
    setErrors(found)
    if (Object.keys(found).length > 0) return

    const body = {
      studentNumber: studentNumber.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      gradeLevel: gradeLevel.trim() || null,
    }

    setSaving(true)
    onSavingChange(true)
    try {
      if (participant) {
        await api.put(`/participants/${participant.participantId}`, body)
      } else {
        await api.post('/participants', body)
      }
      onSaved(participant ? 'updated' : 'created', `${body.lastName}, ${body.firstName}`)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) {
        setErrors(err.fieldErrors) // keys match the field names
      } else if (err.status === 409) {
        setErrors({ studentNumber: err.message }) // duplicate student number
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
        id="participant-number"
        label="Student number"
        required
        autoFocus
        value={studentNumber}
        onChange={(event) => setStudentNumber(event.target.value)}
        error={errors.studentNumber}
      />
      <Field
        id="participant-first-name"
        label="First name"
        required
        value={firstName}
        onChange={(event) => setFirstName(event.target.value)}
        error={errors.firstName}
      />
      <Field
        id="participant-last-name"
        label="Last name"
        required
        value={lastName}
        onChange={(event) => setLastName(event.target.value)}
        error={errors.lastName}
      />
      <Field
        id="participant-grade"
        label="Grade level"
        hint="Optional. For example: 10"
        value={gradeLevel}
        onChange={(event) => setGradeLevel(event.target.value)}
        error={errors.gradeLevel}
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

// participant = null means "add a new participant"; otherwise the one being edited.
export default function ParticipantFormDialog({ open, participant, onClose, onSaved }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal
      open={open}
      title={participant ? 'Edit participant' : 'Add participant'}
      onClose={saving ? () => {} : onClose}
    >
      <ParticipantForm
        participant={participant}
        onCancel={onClose}
        onSaved={onSaved}
        onSavingChange={setSaving}
      />
    </Modal>
  )
}