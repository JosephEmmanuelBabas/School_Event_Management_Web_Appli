export const ROLE_NAMES = ['Super Admin', 'Event Organizer']
export const ACCOUNT_STATUSES = ['Active', 'Inactive', 'Suspended']

export const MIN_PASSWORD_LENGTH = 10
const MAX_PASSWORD_BYTES = 72 // the hashing method ignores anything beyond this

// Returns an error message, or '' when the password is acceptable.
export function checkPassword(password) {
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `Password must be at least ${MIN_PASSWORD_LENGTH} characters long.`
  }
  if (new TextEncoder().encode(password).length > MAX_PASSWORD_BYTES) {
    return 'Password is too long (at most 72 bytes).'
  }
  return ''
}