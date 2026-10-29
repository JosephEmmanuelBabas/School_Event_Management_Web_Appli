import { useEffect, useState } from 'react'
import { api } from '../api/client'
import { useAuth } from '../auth/useAuth'

export default function HomePage() {
  const { user } = useAuth()
  const [account, setAccount] = useState(null)
  const [venueCount, setVenueCount] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false
    Promise.all([api.get('/account/me'), api.get('/venues')])
      .then(([me, venues]) => {
        if (cancelled) return
        setAccount(me)
        setVenueCount(venues.length)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <main className="page">
      <h1>Welcome{account ? `, ${account.firstName}` : ''}</h1>

      {error && <p className="alert alert-error" role="alert">{error}</p>}

      <section className="card" aria-label="Your account">
        <h2>Your account</h2>
        {account ? (
          <dl className="details">
            <dt>Name</dt>
            <dd>{account.firstName} {account.lastName}</dd>
            <dt>Username</dt>
            <dd>{account.username}</dd>
            <dt>Role</dt>
            <dd>{user.role}</dd>
            <dt>Email</dt>
            <dd>{account.email || 'Not set'}</dd>
            <dt>Status</dt>
            <dd>{account.accountStatus}</dd>
          </dl>
        ) : (
          !error && <p className="muted" role="status">Loading…</p>
        )}
      </section>

      <section className="card" aria-label="Connection check">
        <h2>Connection check</h2>
        <p>
          Venues in the database:{' '}
          <strong>{venueCount === null ? '…' : venueCount}</strong>
        </p>
        <p className="muted">
          This number comes from PostgreSQL through the Spring Boot API.
          The real pages (events, attendance, dashboard) are added one step at a time.
        </p>
      </section>
    </main>
  )
}