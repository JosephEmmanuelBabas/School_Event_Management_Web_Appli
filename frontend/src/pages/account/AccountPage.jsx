import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import { useNotify } from '../../components/notifications/useNotify'
import { useApiResource } from '../../hooks/useApiResource'
import { checkPassword } from '../../utils/accounts'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function ProfileForm({ account, onSaved }) {
  const notify = useNotify()
  const [firstName, setFirstName] = useState(account.firstName)
  const [lastName, setLastName] = useState(account.lastName)
  const [email, setEmail] = useState(account.email ?? '')
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    const found = {}
    if (!firstName.trim()) found.firstName = 'First name is required.'
    else if (firstName.trim().length > 50) found.firstName = 'First name must be at most 50 characters.'
    if (!lastName.trim()) found.lastName = 'Last name is required.'
    else if (lastName.trim().length > 50) found.lastName = 'Last name must be at most 50 characters.'
    if (email.trim()) {
      if (email.trim().length > 100) found.email = 'Email must be at most 100 characters.'
      else if (!EMAIL_PATTERN.test(email.trim())) found.email = 'Email is not valid.'
    }
    setErrors(found)
    if (Object.keys(found).length > 0) return

    setSaving(true)
    try {
      await api.put('/account/me', {
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim() || null,
      })
      notify.success('Your profile was updated.')
      onSaved()
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) setErrors(err.fieldErrors)
      else if (err.status === 409) setErrors({ email: err.message }) // email already used
      else setFormError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      {formError && <p className="alert alert-error" role="alert">{formError}</p>}
      <div className="field-row">
        <Field
          id="profile-first-name"
          label="First name"
          required
          value={firstName}
          onChange={(e) => setFirstName(e.target.value)}
          error={errors.firstName}
        />
        <Field
          id="profile-last-name"
          label="Last name"
          required
          value={lastName}
          onChange={(e) => setLastName(e.target.value)}
          error={errors.lastName}
        />
      </div>
      <Field
        id="profile-email"
        label="Email"
        type="email"
        autoComplete="email"
        hint="Optional."
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={errors.email}
      />
      <button type="submit" className="button" disabled={saving}>
        {saving ? 'Saving…' : 'Save profile'}
      </button>
    </form>
  )
}

function PasswordForm() {
  const notify = useNotify()
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    const found = {}
    if (!currentPassword) found.currentPassword = 'Current password is required.'
    const problem = checkPassword(newPassword)
    if (problem) found.newPassword = problem
    else if (newPassword === currentPassword) {
      found.newPassword = 'New password must be different from the current one.'
    } else if (newPassword !== confirmPassword) {
      found.confirmPassword = 'The passwords do not match.'
    }
    setErrors(found)
    if (Object.keys(found).length > 0) return

    setSaving(true)
    try {
      await api.post('/account/me/password', { currentPassword, newPassword })
      notify.success('Your password was changed.')
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) setErrors(err.fieldErrors)
      else if (err.status === 400) {
        // A wrong current password is reported under that field, every other rule under the new one.
        setErrors(
          err.message.startsWith('Current password')
            ? { currentPassword: err.message }
            : { newPassword: err.message },
        )
      } else setFormError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      {formError && <p className="alert alert-error" role="alert">{formError}</p>}
      <Field
        id="password-current"
        label="Current password"
        type="password"
        required
        autoComplete="current-password"
        value={currentPassword}
        onChange={(e) => setCurrentPassword(e.target.value)}
        error={errors.currentPassword}
      />
      <Field
        id="password-new"
        label="New password"
        type="password"
        required
        autoComplete="new-password"
        hint="At least 10 characters."
        value={newPassword}
        onChange={(e) => setNewPassword(e.target.value)}
        error={errors.newPassword}
      />
      <Field
        id="password-confirm"
        label="Confirm new password"
        type="password"
        required
        autoComplete="new-password"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        error={errors.confirmPassword}
      />
      <button type="submit" className="button" disabled={saving}>
        {saving ? 'Saving…' : 'Change password'}
      </button>
    </form>
  )
}

export default function AccountPage() {
  const { data, loading, error, reload } = useApiResource('/account/me')

  if (loading) {
    return (
      <main className="page">
        <p className="muted" role="status">Loading your account…</p>
      </main>
    )
  }
  if (error || !data) {
    return (
      <main className="page">
        <div className="alert alert-error" role="alert">
          <p>{error || 'Could not load your account.'}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      </main>
    )
  }

  return (
    <main className="page">
      <h1>My account</h1>

      <section className="card" aria-labelledby="account-details">
        <h2 id="account-details">Account</h2>
        <dl className="details">
          <dt>Username</dt>
          <dd>{data.username}</dd>
          <dt>Role</dt>
          <dd>{data.roleName}</dd>
          <dt>Status</dt>
          <dd>{data.accountStatus}</dd>
        </dl>
        <p className="note">Your username and role can only be changed by a Super Admin.</p>
      </section>

      <section className="card" aria-labelledby="account-profile">
        <h2 id="account-profile">Profile</h2>
        <ProfileForm account={data} onSaved={reload} />
      </section>

      <section className="card" aria-labelledby="account-password">
        <h2 id="account-password">Change password</h2>
        <PasswordForm />
      </section>
    </main>
  )
}