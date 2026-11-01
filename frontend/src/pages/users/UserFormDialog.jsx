import { useState } from 'react'
import { api } from '../../api/client'
import Field from '../../components/Field'
import Modal from '../../components/Modal'
import { ACCOUNT_STATUSES, ROLE_NAMES, checkPassword } from '../../utils/accounts'

const USERNAME_PATTERN = /^[A-Za-z0-9._-]{3,50}$/
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

// Client-side checks that mirror the server's rules. The server always has the last word.
function validate(values, isNew) {
  const errors = {}
  const username = values.username.trim()
  const first = values.firstName.trim()
  const last = values.lastName.trim()
  const email = values.email.trim()

  if (!username) errors.username = 'Username is required.'
  else if (!USERNAME_PATTERN.test(username)) {
    errors.username = 'Username must be 3-50 characters: letters, digits, dot, underscore or hyphen.'
  }

  if (isNew) {
    const problem = checkPassword(values.password)
    if (problem) errors.password = problem
    else if (values.password !== values.confirmPassword) {
      errors.confirmPassword = 'The passwords do not match.'
    }
  }

  if (!first) errors.firstName = 'First name is required.'
  else if (first.length > 50) errors.firstName = 'First name must be at most 50 characters.'

  if (!last) errors.lastName = 'Last name is required.'
  else if (last.length > 50) errors.lastName = 'Last name must be at most 50 characters.'

  if (email) {
    if (email.length > 100) errors.email = 'Email must be at most 100 characters.'
    else if (!EMAIL_PATTERN.test(email)) errors.email = 'Email is not valid.'
  }

  if (!values.roleName) errors.roleName = 'Choose a role.'
  return errors
}

function UserForm({ user, isSelf, onCancel, onSaved, onSavingChange }) {
  const isNew = user === null
  const [username, setUsername] = useState(user?.username ?? '')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [firstName, setFirstName] = useState(user?.firstName ?? '')
  const [lastName, setLastName] = useState(user?.lastName ?? '')
  const [email, setEmail] = useState(user?.email ?? '')
  const [roleName, setRoleName] = useState(user?.roleName ?? 'Event Organizer')
  const [accountStatus, setAccountStatus] = useState(user?.accountStatus ?? 'Active')
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    const found = validate(
      { username, password, confirmPassword, firstName, lastName, email, roleName },
      isNew,
    )
    setErrors(found)
    if (Object.keys(found).length > 0) return

    const common = {
      username: username.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim() || null,
      roleName,
    }

    setSaving(true)
    onSavingChange(true)
    try {
      if (isNew) {
        await api.post('/users', { ...common, password })
      } else {
        await api.put(`/users/${user.userId}`, { ...common, accountStatus })
      }
      onSaved(isNew ? 'created' : 'updated', common.username)
    } catch (err) {
      if (err.status === 400 && err.fieldErrors) {
        setErrors(err.fieldErrors) // keys match the field names
      } else if (err.status === 409) {
        // "A user with email ..." belongs under the email field, anything else under username.
        setErrors(
          err.message.startsWith('A user with email')
            ? { email: err.message }
            : { username: err.message },
        )
      } else {
        setFormError(err.message) // for example "At least one active Super Admin must remain."
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
        id="user-username"
        label="Username"
        required
        autoFocus
        autoComplete="off"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        error={errors.username}
      />

      {isNew && (
        <>
          <Field
            id="user-password"
            label="Password"
            type="password"
            required
            autoComplete="new-password"
            hint="At least 10 characters. Give it to the person through a secure channel; they can change it on My account."
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={errors.password}
          />
          <Field
            id="user-confirm-password"
            label="Confirm password"
            type="password"
            required
            autoComplete="new-password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            error={errors.confirmPassword}
          />
        </>
      )}

      <div className="field-row">
        <Field
          id="user-first-name"
          label="First name"
          required
          value={firstName}
          onChange={(e) => setFirstName(e.target.value)}
          error={errors.firstName}
        />
        <Field
          id="user-last-name"
          label="Last name"
          required
          value={lastName}
          onChange={(e) => setLastName(e.target.value)}
          error={errors.lastName}
        />
      </div>

      <Field
        id="user-email"
        label="Email"
        type="email"
        autoComplete="off"
        hint="Optional."
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={errors.email}
      />

      <Field
        id="user-role"
        label="Role"
        required
        as="select"
        disabled={isSelf}
        value={roleName}
        onChange={(e) => setRoleName(e.target.value)}
        error={errors.roleName}
      >
        {ROLE_NAMES.map((name) => (
          <option key={name} value={name}>{name}</option>
        ))}
      </Field>

      {!isNew && (
        <Field
          id="user-status"
          label="Account status"
          required
          as="select"
          disabled={isSelf}
          value={accountStatus}
          onChange={(e) => setAccountStatus(e.target.value)}
          error={errors.accountStatus}
        >
          {ACCOUNT_STATUSES.map((status) => (
            <option key={status} value={status}>{status}</option>
          ))}
        </Field>
      )}
      {isSelf && (
        <p className="field-hint">You cannot change your own role or account status.</p>
      )}

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

// user = null means "add a new user"; otherwise the user being edited.
export default function UserFormDialog({ open, user, isSelf, onClose, onSaved }) {
  const [saving, setSaving] = useState(false)

  return (
    <Modal
      open={open}
      title={user ? 'Edit user' : 'Add user'}
      onClose={saving ? () => {} : onClose}
    >
      <UserForm
        user={user}
        isSelf={isSelf}
        onCancel={onClose}
        onSaved={onSaved}
        onSavingChange={setSaving}
      />
    </Modal>
  )
}