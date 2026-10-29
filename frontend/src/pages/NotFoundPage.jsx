import { Link } from 'react-router'

export default function NotFoundPage() {
  return (
    <main className="page">
      <h1>Page not found</h1>
      <p>That page does not exist.</p>
      <p><Link to="/">Back to Home</Link></p>
    </main>
  )
}