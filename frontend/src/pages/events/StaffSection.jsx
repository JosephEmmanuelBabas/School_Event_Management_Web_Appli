import { useState } from 'react'
import { api } from '../../api/client'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import StatusBadge from '../../components/StatusBadge'
import { useApiList } from '../../hooks/useApiList'
import { isOpenStatus } from '../../utils/eventStatus'
import StaffFormDialog from './StaffFormDialog'

export default function StaffSection({ event, isOrganizer }) {
  const notify = useNotify()
  const { items, loading, error, reload } = useApiList(`/events/${event.eventId}/assignments`)

  const [form, setForm] = useState({ open: false, entry: null })
  const [deleting, setDeleting] = useState(null)
  const [deleteBusy, setDeleteBusy] = useState(false)

  const open = isOpenStatus(event.eventStatus)
  const canEdit = isOrganizer && open

  function handleSaved(kind, name) {
    setForm({ open: false, entry: null })
    notify.success(`"${name}" was ${kind}.`)
    reload()
  }

  async function confirmDelete() {
    const target = deleting
    setDeleteBusy(true)
    try {
      await api.delete(`/events/${event.eventId}/assignments/${target.assignmentId}`)
      setDeleting(null)
      notify.success(`"${target.staffName}" was removed from the staff list.`)
    } catch (err) {
      setDeleting(null)
      notify.error(err.message)
    } finally {
      setDeleteBusy(false)
      reload()
    }
  }

  const columns = [
    { key: 'staffName', header: 'Name' },
    { key: 'staffRole', header: 'Role', render: (s) => s.staffRole ?? '—' },
    { key: 'assignmentStatus', header: 'Status', render: (s) => <StatusBadge status={s.assignmentStatus} /> },
  ]
  if (canEdit) {
    columns.push({
      key: 'actions',
      header: <span className="visually-hidden">Actions</span>,
      className: 'num',
      render: (s) => (
        <div className="row-actions">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => setForm({ open: true, entry: s })}
            aria-label={`Edit ${s.staffName}`}
          >
            Edit
          </button>
          <button
            type="button"
            className="button button-danger-outline button-small"
            onClick={() => setDeleting(s)}
            aria-label={`Remove ${s.staffName}`}
          >
            Remove
          </button>
        </div>
      ),
    })
  }

  return (
    <section className="card" aria-labelledby="staff-heading">
      <div className="section-header">
        <h2 id="staff-heading">Staff</h2>
        {canEdit && (
          <button
            type="button"
            className="button"
            onClick={() => setForm({ open: true, entry: null })}
          >
            Add staff member
          </button>
        )}
      </div>

      <p className="note">
        Staff here are plain records of who is helping with the event. They are not system users.
      </p>
      {isOrganizer && !open && (
        <p className="note">
          This event is {event.eventStatus.toLowerCase()}, so its staff list can no longer be changed.
        </p>
      )}

      {loading ? (
        <p className="muted" role="status">Loading staff…</p>
      ) : error ? (
        <div className="alert alert-error" role="alert">
          <p>{error}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      ) : (
        <DataTable
          caption="Staff"
          columns={columns}
          rows={items}
          rowKey={(s) => s.assignmentId}
          emptyMessage={canEdit ? 'No staff assigned yet. Use "Add staff member".' : 'No staff assigned.'}
        />
      )}

      <StaffFormDialog
        open={form.open}
        event={event}
        entry={form.entry}
        onClose={() => setForm({ open: false, entry: null })}
        onSaved={handleSaved}
      />

      <ConfirmDialog
        open={deleting !== null}
        title="Remove staff member?"
        message={deleting ? `"${deleting.staffName}" will be removed from this event's staff list.` : ''}
        confirmLabel="Remove"
        danger
        busy={deleteBusy}
        onConfirm={confirmDelete}
        onCancel={() => setDeleting(null)}
      />
    </section>
  )
}