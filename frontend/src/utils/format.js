const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

// '2027-01-15' -> 'Fri, Jan 15, 2027'. Built from the parts, so no timezone can shift the day.
export function formatDate(iso) {
  if (!iso) return ''
  const [year, month, day] = iso.split('-').map(Number)
  const weekday = DAYS[new Date(year, month - 1, day).getDay()]
  return `${weekday}, ${MONTHS[month - 1]} ${day}, ${year}`
}

// '09:00:00' or '09:00' -> '9:00 AM'
export function formatTime(value) {
  if (!value) return ''
  const [hours, minutes] = value.split(':').map(Number)
  const suffix = hours >= 12 ? 'PM' : 'AM'
  const hour12 = hours % 12 === 0 ? 12 : hours % 12
  return `${hour12}:${String(minutes).padStart(2, '0')} ${suffix}`
}

// '09:00:00' -> '09:00' (the format <input type="time"> uses)
export function trimTime(value) {
  return value ? value.slice(0, 5) : ''
}

// Today's date in the browser's local time, as 'yyyy-mm-dd'.
export function todayIso() {
  const now = new Date()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  return `${now.getFullYear()}-${month}-${day}`
}

// '2027-01-15T15:05:03.123456' -> 'Jan 15, 2027 3:05 PM'
export function formatDateTime(value) {
  if (!value) return ''
  const [date, time] = value.split('T')
  const [year, month, day] = date.split('-').map(Number)
  return `${MONTHS[month - 1]} ${day}, ${year} ${formatTime(time)}`
}

// 66.7 -> '66.7%', null -> '—' (no data is not the same as 0%)
export function formatPercent(value) {
  return value === null || value === undefined ? '—' : `${value}%`
}

// The date `days` away from today (negative = in the past) in local time, as 'yyyy-mm-dd'.
export function addDaysIso(days) {
  const date = new Date()
  date.setDate(date.getDate() + days)
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${date.getFullYear()}-${month}-${day}`
}