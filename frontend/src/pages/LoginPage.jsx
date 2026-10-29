import { useState } from 'react'
import { Navigate, useLocation } from 'react-router'
import { useAuth } from '../auth/useAuth'

export default function LoginPage() {
  const { user, loading, login } = useAuth()
  const location = useLocation()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const destination = location.state?.from || '/'

  // Already logged in (or just logged in): go to the page the user wanted.
  if (!loading && user) {
    return <Navigate to={destination} replace />
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await login(username.trim(), password)
    } catch (err) {
      setError(
        err.status === 401
          ? 'Invalid username or password.'
          : 'Could not log in. Check that the server is running and try again.',
      )
      setPassword('')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <main className="login-page">
      <form className="card login-card" onSubmit={handleSubmit} noValidate>
        <h1>School Event Management</h1>
        <p className="muted">Log in to continue.</p>

        {error && <p className="alert alert-error" role="alert">{error}</p>}

        <label htmlFor="username">Username</label>
        <input
          id="username"
          name="username"
          type="text"
          autoComplete="username"
          autoFocus
          value={username}
          onChange={(event) => setUsername(event.target.value)}
        />

        <label htmlFor="password">Password</label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />

        <button
          type="submit"
          className="button"
          disabled={submitting || !username.trim() || !password}
        >
          {submitting ? 'Logging in…' : 'Log in'}
        </button>
      </form>
    </main>
  )
}