import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'
import { checkPassword } from '../../utils/accounts'

function ResetForm({ user, onCancel, onDone, onSavingChange }) {
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    const found = {}
    const problem = checkPassword(newPassword)
    if (problem) found.newPassword = problem
    else if (newPassword !== confirmPassword) found.confirmPassword = 'The passwords do not match.'
    setErrors(found)
    if (Object.keys(found).length > 0) return

    setSaving(true)
    onSavingChange(true)
    try {
      await api.post(`/users/${user.userId}/reset-password`, { newPassword })
      onDone(user)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) setErrors(err.fieldErrors)
      else if (err.status === 400) setErrors({ newPassword: err.message })
      else setFormError(err.message)
    } finally {
      setSaving(false)
      onSavingChange(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      {formError && <p className="alert alert-error" role="alert">{formError}</p>}

      <p>
        Set a new password for <strong>{user.username}</strong>. Give it to them through a secure
        channel.
      </p>
      <p className="note">
        If they are signed in right now, they stay signed in until their session expires (up to 30
        minutes). To end their access at once, deactivate the account instead.
      </p>

      <Field
        id="reset-password"
        label="New password"
        type="password"
        required
        autoFocus
        autoComplete="new-password"
        hint="At least 10 characters."
        value={newPassword}
        onChange={(e) => setNewPassword(e.target.value)}
        error={errors.newPassword}
      />
      <Field
        id="reset-confirm"
        label="Confirm new password"
        type="password"
        required
        autoComplete="new-password"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        error={errors.confirmPassword}
      />

      <div className="modal-actions">
        <button type="button" className="button button-secondary" onClick={onCancel} disabled={saving}>
          Cancel
        </button>
        <button type="submit" className="button" disabled={saving}>
          {saving ? 'Saving…' : 'Set password'}
        </button>
      </div>
    </form>
  )
}

// user = the account whose password is being reset, or null when the dialog is closed.
export default function ResetPasswordDialog({ user, onClose, onDone }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal open={user !== null} title="Reset password" onClose={saving ? () => {} : onClose}>
      {user && <ResetForm user={user} onCancel={onClose} onDone={onDone} onSavingChange={setSaving} />}
    </Modal>
  )
}