// columns: [{ key, header, render?(row), className?, sortable? }]. The caption is for screen readers.
// Pass sort = { key, direction } and onSort(key) to make columns with sortable: true clickable.
export default function DataTable({
  caption,
  columns,
  rows,
  rowKey,
  emptyMessage = 'Nothing to show.',
  sort,
  onSort,
}) {
  function ariaSort(column) {
    if (!column.sortable || !sort || sort.key !== column.key) return undefined
    return sort.direction === 'asc' ? 'ascending' : 'descending'
  }

  return (
    <div className="table-wrap">
      <table className="data-table">
        <caption className="visually-hidden">{caption}</caption>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column.key} scope="col" className={column.className} aria-sort={ariaSort(column)}>
                {column.sortable && onSort ? (
                  <button type="button" className="sort-button" onClick={() => onSort(column.key)}>
                    {column.header}
                    <span aria-hidden="true">
                      {sort?.key === column.key ? (sort.direction === 'asc' ? ' ▲' : ' ▼') : ' ↕'}
                    </span>
                  </button>
                ) : (
                  column.header
                )}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={columns.length} className="empty-cell">{emptyMessage}</td>
            </tr>
          ) : (
            rows.map((row) => (
              <tr key={rowKey(row)}>
                {columns.map((column) => (
                  <td key={column.key} className={column.className}>
                    {column.render ? column.render(row) : row[column.key]}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  )
}