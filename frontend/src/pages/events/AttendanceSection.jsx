import { useMemo, useState } from 'react'
import { api } from '../../api/client'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import StatusBadge from '../../components/StatusBadge'
import { useApiList } from '../../hooks/useApiList'
import { canRecordAttendance } from '../../utils/eventStatus'
import { formatDateTime } from '../../utils/format'
import AttendanceFormDialog from './AttendanceFormDialog'

const STATUSES = ['Present', 'Late', 'Absent']

export default function AttendanceSection({ event, isOrganizer }) {
  const notify = useNotify()
  const { items, loading, error, reload } = useApiList(`/events/${event.eventId}/attendance`)

  const [statusFilter, setStatusFilter] = useState('')
  const [search, setSearch] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [removing, setRemoving] = useState(null)
  const [removeBusy, setRemoveBusy] = useState(false)
  const [busyId, setBusyId] = useState(null)

  const writable = isOrganizer && canRecordAttendance(event.eventStatus)

  // The summary is counted from the list, so it always matches the table.
  const counts = { Present: 0, Late: 0, Absent: 0 }
  for (const record of items) counts[record.attendanceStatus] += 1
  const total = items.length
  const rate = total === 0 ? null : Math.round(((counts.Present + counts.Late) * 1000) / total) / 10

  const recordedIds = useMemo(() => new Set(items.map((record) => record.participantId)), [items])

  const query = search.trim().toLowerCase()
  const rows = items.filter(
    (record) =>
      (!statusFilter || record.attendanceStatus === statusFilter) &&
      (!query ||
        record.participantName.toLowerCase().includes(query) ||
        record.studentNumber.toLowerCase().includes(query)),
  )

  async function changeStatus(record, newStatus) {
    setBusyId(record.attendanceId)
    try {
      await api.put(`/events/${event.eventId}/attendance/${record.attendanceId}`, {
        attendanceStatus: newStatus,
      })
      notify.success(`${record.participantName} is now ${newStatus}.`)
    } catch (err) {
      notify.error(err.message)
    } finally {
      setBusyId(null)
      reload()
    }
  }

  async function confirmRemove() {
    const target = removing
    setRemoveBusy(true)
    try {
      await api.delete(`/events/${event.eventId}/attendance/${target.attendanceId}`)
      setRemoving(null)
      notify.success(`Attendance record for ${target.participantName} was removed.`)
    } catch (err) {
      setRemoving(null)
      notify.error(err.message)
    } finally {
      setRemoveBusy(false)
      reload()
    }
  }

  const columns = [
    { key: 'studentNumber', header: 'Student number' },
    { key: 'participantName', header: 'Name' },
    {
      key: 'attendanceStatus',
      header: 'Status',
      render: (record) =>
        writable ? (
          <select
            className="select-compact"
            aria-label={`Attendance status for ${record.participantName}`}
            value={record.attendanceStatus}
            onChange={(e) => changeStatus(record, e.target.value)}
            disabled={busyId === record.attendanceId}
          >
            {STATUSES.map((status) => (
              <option key={status} value={status}>{status}</option>
            ))}
          </select>
        ) : (
          <StatusBadge status={record.attendanceStatus} />
        ),
    },
    { key: 'timeRecorded', header: 'Recorded at', render: (record) => formatDateTime(record.timeRecorded) },
  ]
  if (writable) {
    columns.push({
      key: 'actions',
      header: <span className="visually-hidden">Actions</span>,
      className: 'num',
      render: (record) => (
        <button
          type="button"
          className="button button-danger-outline button-small"
          onClick={() => setRemoving(record)}
          aria-label={`Remove the attendance record of ${record.participantName}`}
        >
          Remove
        </button>
      ),
    })
  }

  const filtering = statusFilter !== '' || query !== ''
  const emptyMessage = filtering
    ? 'No records match your filter.'
    : writable
      ? 'No attendance recorded yet. Use "Record attendance".'
      : 'No attendance recorded.'

  return (
    <section className="card" aria-labelledby="attendance-heading">
      <div className="section-header">
        <h2 id="attendance-heading">Attendance</h2>
        {writable && (
          <button type="button" className="button" onClick={() => setDialogOpen(true)}>
            Record attendance
          </button>
        )}
      </div>

      {isOrganizer && event.eventStatus === 'Upcoming' && (
        <p className="note">
          Attendance can be recorded once the event is ongoing. Use "Change status" at the top of
          the page to start it.
        </p>
      )}
      {isOrganizer && event.eventStatus === 'Cancelled' && (
        <p className="note">Attendance is not recorded for cancelled events.</p>
      )}

      {loading ? (
        <p className="muted" role="status">Loading attendance…</p>
      ) : error ? (
        <div className="alert alert-error" role="alert">
          <p>{error}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      ) : (
        <>
          <ul className="summary" aria-label="Attendance summary">
            <li>Present: <strong>{counts.Present}</strong></li>
            <li>Late: <strong>{counts.Late}</strong></li>
            <li>Absent: <strong>{counts.Absent}</strong></li>
            <li>Recorded: <strong>{total}</strong></li>
            <li>Attendance rate: <strong>{rate === null ? 'No data' : `${rate}%`}</strong></li>
          </ul>

          {total > 0 && (
            <div className="toolbar">
              <label htmlFor="attendance-filter-search" className="visually-hidden">
                Search attendance
              </label>
              <input
                id="attendance-filter-search"
                type="search"
                placeholder="Search by name or student number"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <label htmlFor="attendance-filter-status" className="visually-hidden">
                Filter by status
              </label>
              <select
                id="attendance-filter-status"
                className="select-compact"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="">All statuses</option>
                {STATUSES.map((status) => (
                  <option key={status} value={status}>{status}</option>
                ))}
              </select>
            </div>
          )}

          <DataTable
            caption="Attendance"
            columns={columns}
            rows={rows}
            rowKey={(record) => record.attendanceId}
            emptyMessage={emptyMessage}
          />
        </>
      )}

      <AttendanceFormDialog
        open={dialogOpen}
        event={event}
        recordedIds={recordedIds}
        onClose={() => setDialogOpen(false)}
        onRecorded={reload}
      />

      <ConfirmDialog
        open={removing !== null}
        title="Remove attendance record?"
        message={
          removing
            ? `The attendance record of ${removing.participantName} (${removing.attendanceStatus}) will be removed. You can record it again afterwards.`
            : ''
        }
        confirmLabel="Remove"
        danger
        busy={removeBusy}
        onConfirm={confirmRemove}
        onCancel={() => setRemoving(null)}
      />
    </section>
  )
}