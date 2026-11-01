import { useState } from 'react'
import { api } from '../../api/client'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import { useApiList } from '../../hooks/useApiList'
import { isOpenStatus } from '../../utils/eventStatus'
import { formatTime } from '../../utils/format'
import ScheduleFormDialog from './ScheduleFormDialog'

// Times arrive as 'HH:mm:ss' strings, which compare correctly as text.
function overlapsAnother(entry, all) {
  return all.some(
    (other) =>
      other.scheduleId !== entry.scheduleId &&
      other.startTime < entry.endTime &&
      other.endTime > entry.startTime,
  )
}

export default function ScheduleSection({ event, isOrganizer }) {
  const notify = useNotify()
  const { items, loading, error, reload } = useApiList(`/events/${event.eventId}/schedules`)

  const [form, setForm] = useState({ open: false, entry: null })
  const [deleting, setDeleting] = useState(null)
  const [deleteBusy, setDeleteBusy] = useState(false)

  const open = isOpenStatus(event.eventStatus)
  const canEdit = isOrganizer && open

  function handleSaved(kind, name) {
    setForm({ open: false, entry: null })
    notify.success(`Activity "${name}" was ${kind}.`)
    reload()
  }

  async function confirmDelete() {
    const target = deleting
    setDeleteBusy(true)
    try {
      await api.delete(`/events/${event.eventId}/schedules/${target.scheduleId}`)
      setDeleting(null)
      notify.success(`Activity "${target.activityName}" was deleted.`)
    } catch (err) {
      setDeleting(null)
      notify.error(err.message)
    } finally {
      setDeleteBusy(false)
      reload()
    }
  }

  const columns = [
    {
      key: 'time',
      header: 'Time',
      render: (s) => (
        <>
          {formatTime(s.startTime)} – {formatTime(s.endTime)}
          {overlapsAnother(s, items) && <span className="tag">Overlaps another activity</span>}
        </>
      ),
    },
    { key: 'activityName', header: 'Activity' },
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
            aria-label={`Edit ${s.activityName}`}
          >
            Edit
          </button>
          <button
            type="button"
            className="button button-danger-outline button-small"
            onClick={() => setDeleting(s)}
            aria-label={`Delete ${s.activityName}`}
          >
            Delete
          </button>
        </div>
      ),
    })
  }

  return (
    <section className="card" aria-labelledby="schedule-heading">
      <div className="section-header">
        <h2 id="schedule-heading">Schedule</h2>
        {canEdit && (
          <button
            type="button"
            className="button"
            onClick={() => setForm({ open: true, entry: null })}
          >
            Add activity
          </button>
        )}
      </div>

      {isOrganizer && !open && (
        <p className="note">
          This event is {event.eventStatus.toLowerCase()}, so its schedule can no longer be changed.
        </p>
      )}

      {loading ? (
        <p className="muted" role="status">Loading schedule…</p>
      ) : error ? (
        <div className="alert alert-error" role="alert">
          <p>{error}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      ) : (
        <DataTable
          caption="Schedule"
          columns={columns}
          rows={items}
          rowKey={(s) => s.scheduleId}
          emptyMessage={canEdit ? 'No activities yet. Use "Add activity".' : 'No activities scheduled.'}
        />
      )}

      <ScheduleFormDialog
        open={form.open}
        event={event}
        entry={form.entry}
        onClose={() => setForm({ open: false, entry: null })}
        onSaved={handleSaved}
      />

      <ConfirmDialog
        open={deleting !== null}
        title="Delete activity?"
        message={deleting ? `"${deleting.activityName}" will be removed from the schedule.` : ''}
        confirmLabel="Delete"
        danger
        busy={deleteBusy}
        onConfirm={confirmDelete}
        onCancel={() => setDeleting(null)}
      />
    </section>
  )
}