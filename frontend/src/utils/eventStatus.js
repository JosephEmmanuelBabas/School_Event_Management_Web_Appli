// The status changes the server allows. Completed and Cancelled are final.
export const NEXT_STATUSES = {
  Upcoming: ['Ongoing', 'Cancelled'],
  Ongoing: ['Completed', 'Cancelled'],
}

export const ALL_STATUSES = ['Upcoming', 'Ongoing', 'Completed', 'Cancelled']

// Only Upcoming and Ongoing events can be edited or have their status changed.
export function isOpenStatus(status) {
  return status in NEXT_STATUSES
}