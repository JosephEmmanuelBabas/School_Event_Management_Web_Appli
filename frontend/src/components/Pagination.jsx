export default function Pagination({ page, pageSize, totalCount, onPageChange }) {
  if (totalCount === 0) return null

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize))
  const first = page * pageSize + 1
  const last = Math.min((page + 1) * pageSize, totalCount)

  return (
    <nav className="pagination" aria-label="Pagination">
      <span role="status">
        Showing {first} to {last} of {totalCount}
      </span>
      <div className="pagination-buttons">
        <button
          type="button"
          className="button button-secondary button-small"
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 0}
        >
          Previous
        </button>
        <span aria-current="page">Page {page + 1} of {totalPages}</span>
        <button
          type="button"
          className="button button-secondary button-small"
          onClick={() => onPageChange(page + 1)}
          disabled={page >= totalPages - 1}
        >
          Next
        </button>
      </div>
    </nav>
  )
}