import { useMemo, useState } from 'react'
import { api } from '../../api/client'
import { useAuth } from '../../auth/useAuth'
import ConfirmDialog from '../../components/ConfirmDialog'
import DataTable from '../../components/DataTable'
import { useNotify } from '../../components/notifications/useNotify'
import Pagination from '../../components/Pagination'
import StatusBadge from '../../components/StatusBadge'
import { useApiList } from '../../hooks/useApiList'
import { ACCOUNT_STATUSES, ROLE_NAMES } from '../../utils/accounts'
import ResetPasswordDialog from './ResetPasswordDialog'
import UserFormDialog from './UserFormDialog'

const PAGE_SIZE = 10

export default function UsersPage() {
  const { user: me } = useAuth()
  const notify = useNotify()
  const { items, loading, error, reload } = useApiList('/users')

  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(0)

  const [form, setForm] = useState({ open: false, user: null })
  const [resetTarget, setResetTarget] = useState(null)
  const [statusChange, setStatusChange] = useState(null) // { user, newStatus }
  const [statusBusy, setStatusBusy] = useState(false)

  // The backend returns every account (a short list), so search and paging happen here.
  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase()
    return items.filter(
      (u) =>
        (!roleFilter || u.roleName === roleFilter) &&
        (!statusFilter || u.accountStatus === statusFilter) &&
        (!query ||
          u.username.toLowerCase().includes(query) ||
          `${u.firstName} ${u.lastName}`.toLowerCase().includes(query) ||
          (u.email ?? '').toLowerCase().includes(query)),
    )
  }, [items, search, roleFilter, statusFilter])

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const currentPage = Math.min(page, totalPages - 1)
  const pageRows = filtered.slice(currentPage * PAGE_SIZE, (currentPage + 1) * PAGE_SIZE)

  function changeFilter(setter, value) {
    setter(value)
    setPage(0)
  }

  function handleSaved(kind, username) {
    setForm({ open: false, user: null })
    notify.success(`User "${username}" was ${kind}.`)
    reload()
  }

  function handlePasswordDone(target) {
    setResetTarget(null)
    notify.success(`The password of "${target.username}" was reset.`)
  }

  async function confirmStatusChange() {
    const { user: target, newStatus } = statusChange
    setStatusBusy(true)
    try {
      await api.put(`/users/${target.userId}`, {
        username: target.username,
        firstName: target.firstName,
        lastName: target.lastName,
        email: target.email,
        roleName: target.roleName,
        accountStatus: newStatus,
      })
      setStatusChange(null)
      notify.success(`"${target.username}" is now ${newStatus}.`)
    } catch (err) {
      setStatusChange(null)
      notify.error(err.message) // for example "At least one active Super Admin must remain."
    } finally {
      setStatusBusy(false)
      reload()
    }
  }

  const columns = [
    {
      key: 'username',
      header: 'Username',
      render: (u) => (
        <>
          {u.username}
          {u.userId === me.userId && <span className="tag">You</span>}
        </>
      ),
    },
    { key: 'name', header: 'Name', render: (u) => `${u.lastName}, ${u.firstName}` },
    { key: 'email', header: 'Email', render: (u) => u.email ?? '—' },
    { key: 'roleName', header: 'Role', render: (u) => <span className="badge badge-plain">{u.roleName}</span> },
    { key: 'accountStatus', header: 'Status', render: (u) => <StatusBadge status={u.accountStatus} /> },
    {
      key: 'actions',
      header: <span className="visually-hidden">Actions</span>,
      className: 'num',
      render: (u) => {
        const isSelf = u.userId === me.userId
        const active = u.accountStatus === 'Active'
        return (
          <div className="row-actions">
            <button
              type="button"
              className="button button-secondary button-small"
              onClick={() => setForm({ open: true, user: u })}
              aria-label={`Edit ${u.username}`}
            >
              Edit
            </button>
            <button
              type="button"
              className="button button-secondary button-small"
              onClick={() => setResetTarget(u)}
              aria-label={`Reset the password of ${u.username}`}
            >
              Reset password
            </button>
            {!isSelf && (
              <button
                type="button"
                className={active ? 'button button-danger-outline button-small' : 'button button-secondary button-small'}
                onClick={() => setStatusChange({ user: u, newStatus: active ? 'Inactive' : 'Active' })}
                aria-label={`${active ? 'Deactivate' : 'Activate'} ${u.username}`}
              >
                {active ? 'Deactivate' : 'Activate'}
              </button>
            )}
          </div>
        )
      },
    },
  ]

  const filtering = search.trim() !== '' || roleFilter !== '' || statusFilter !== ''

  return (
    <main className="page">
      <div className="page-header">
        <h1>Users</h1>
        <button type="button" className="button" onClick={() => setForm({ open: true, user: null })}>
          Add user
        </button>
      </div>
      <p className="note">
        Accounts are never deleted, only deactivated, so the audit log always stays complete. A
        deactivated user is signed out on their next click and cannot log in again.
      </p>

      {loading ? (
        <p className="muted" role="status">Loading users…</p>
      ) : error ? (
        <div className="alert alert-error" role="alert">
          <p>{error}</p>
          <button type="button" className="button button-secondary button-small" onClick={reload}>
            Try again
          </button>
        </div>
      ) : (
        <>
          <div className="filters" role="search" aria-label="Filter users">
            <div className="filter">
              <label htmlFor="user-search">Search</label>
              <input
                id="user-search"
                type="search"
                placeholder="Username, name or email"
                value={search}
                onChange={(e) => changeFilter(setSearch, e.target.value)}
              />
            </div>
            <div className="filter">
              <label htmlFor="user-filter-role">Role</label>
              <select
                id="user-filter-role"
                value={roleFilter}
                onChange={(e) => changeFilter(setRoleFilter, e.target.value)}
              >
                <option value="">All roles</option>
                {ROLE_NAMES.map((name) => (
                  <option key={name} value={name}>{name}</option>
                ))}
              </select>
            </div>
            <div className="filter">
              <label htmlFor="user-filter-status">Status</label>
              <select
                id="user-filter-status"
                value={statusFilter}
                onChange={(e) => changeFilter(setStatusFilter, e.target.value)}
              >
                <option value="">All statuses</option>
                {ACCOUNT_STATUSES.map((status) => (
                  <option key={status} value={status}>{status}</option>
                ))}
              </select>
            </div>
          </div>

          <DataTable
            caption="Users"
            columns={columns}
            rows={pageRows}
            rowKey={(u) => u.userId}
            emptyMessage={filtering ? 'No users match your filters.' : 'No users yet.'}
          />
          <Pagination
            page={currentPage}
            pageSize={PAGE_SIZE}
            totalCount={filtered.length}
            onPageChange={setPage}
          />
        </>
      )}

      <UserFormDialog
        open={form.open}
        user={form.user}
        isSelf={form.user !== null && form.user.userId === me.userId}
        onClose={() => setForm({ open: false, user: null })}
        onSaved={handleSaved}
      />

      <ResetPasswordDialog
        user={resetTarget}
        onClose={() => setResetTarget(null)}
        onDone={handlePasswordDone}
      />

      <ConfirmDialog
        open={statusChange !== null}
        title={statusChange?.newStatus === 'Active' ? 'Activate user?' : 'Deactivate user?'}
        message={
          statusChange
            ? statusChange.newStatus === 'Active'
              ? `"${statusChange.user.username}" will be able to log in again.`
              : `"${statusChange.user.username}" will no longer be able to log in, and any open session ends on their next click.`
            : ''
        }
        confirmLabel={statusChange?.newStatus === 'Active' ? 'Activate' : 'Deactivate'}
        danger={statusChange?.newStatus !== 'Active'}
        busy={statusBusy}
        onConfirm={confirmStatusChange}
        onCancel={() => setStatusChange(null)}
      />
    </main>
  )
}