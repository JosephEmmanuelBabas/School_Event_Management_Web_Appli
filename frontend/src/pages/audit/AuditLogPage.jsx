import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { api } from '../../api/client'
import DataTable from '../../components/DataTable'
import Pagination from '../../components/Pagination'
import { formatDateTime } from '../../utils/format'

const PAGE_SIZE = 25

const columns = [
  { key: 'logTimestamp', header: 'When', render: (row) => formatDateTime(row.logTimestamp) },
  { key: 'username', header: 'User' },
  { key: 'actionPerformed', header: 'Action' },
  { key: 'affectedTable', header: 'Table' },
  {
    key: 'record',
    header: 'Record',
    render: (row) =>
      row.affectedTable === 'event' && row.actionPerformed !== 'Deleted' ? (
        <Link to={`/events/${row.affectedRecordId}`}>#{row.affectedRecordId}</Link>
      ) : (
        `#${row.affectedRecordId}`
      ),
  },
]

export default function AuditLogPage() {
  const [rows, setRows] = useState([])
  const [totalCount, setTotalCount] = useState(0)
  const [page, setPage] = useState(0) // zero-based, like the backend
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reloadCount, setReloadCount] = useState(0)

  useEffect(() => {
    let cancelled = false
    api.getPage('/audit-logs', { page, size: PAGE_SIZE })
      .then(({ items, totalCount: total }) => {
        if (cancelled) return
        setRows(items)
        setTotalCount(total)
        setError('')
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [page, reloadCount])

  return (
    <main className="page">
      <div className="page-header">
        <h1>Audit log</h1>
        <button
          type="button"
          className="button button-secondary"
          onClick={() => setReloadCount((count) => count + 1)}
        >
          Refresh
        </button>
      </div>
      <p className="note">
        Every create, update and delete is recorded with the user who made it, newest first.
        Entries can only be added: the database refuses any change or deletion by the application.
        Signing in and out is not recorded.
      </p>

      {loading ? (
        <p className="muted" role="status">Loading the audit log…</p>
      ) : error ? (
        <div className="alert alert-error" role="alert">
          <p>{error}</p>
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => setReloadCount((count) => count + 1)}
          >
            Try again
          </button>
        </div>
      ) : (
        <>
          <DataTable
            caption="Audit log"
            columns={columns}
            rows={rows}
            rowKey={(row) => row.logId}
            emptyMessage="No activity recorded yet."
          />
          <Pagination
            page={page}
            pageSize={PAGE_SIZE}
            totalCount={totalCount}
            onPageChange={setPage}
          />
        </>
      )}
    </main>
  )
}