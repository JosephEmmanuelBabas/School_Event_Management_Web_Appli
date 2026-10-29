// All HTTP calls to the Spring Boot backend go through this file.
// In development Vite forwards /api/* to http://localhost:8080 (see vite.config.js),
// so the browser talks to a single origin and the session cookie just works.

const API_BASE = '/api'
const UNSAFE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE'])

export class ApiError extends Error {
  constructor(status, message, fieldErrors = null) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.fieldErrors = fieldErrors
  }
}

let csrf = null // { headerName, token }
let onUnauthorized = () => {}

// Called when any request comes back 401 (the session has ended).
export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler
}

export function clearCsrf() {
  csrf = null
}

async function getCsrf(forceRefresh = false) {
  if (!csrf || forceRefresh) {
    const response = await fetch(`${API_BASE}/auth/csrf`, { credentials: 'same-origin' })
    if (!response.ok) {
      throw new ApiError(response.status, 'Could not reach the server.')
    }
    csrf = await response.json()
  }
  return csrf
}

function toQuery(params) {
  if (!params) return ''
  const search = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && value !== '') {
      search.append(key, String(value))
    }
  }
  const text = search.toString()
  return text ? `?${text}` : ''
}

function defaultMessage(status) {
  switch (status) {
    case 401: return 'Please log in.'
    case 403: return 'You do not have permission to do that.'
    case 404: return 'Not found.'
    default: return 'Something went wrong. Please try again.'
  }
}

async function toApiError(response) {
  let body = null
  try {
    body = await response.json()
  } catch {
    // empty or non-JSON body
  }
  return new ApiError(
    response.status,
    body?.message || defaultMessage(response.status),
    body?.fieldErrors ?? null,
  )
}

async function send(method, path, { body, form, params } = {}, allowRetry = true) {
  const headers = { Accept: 'application/json' }
  let payload
  if (form) {
    payload = new URLSearchParams(form) // sent as a normal HTML form
  } else if (body !== undefined) {
    headers['Content-Type'] = 'application/json'
    payload = JSON.stringify(body)
  }

  // Writes must carry the CSRF token.
  if (UNSAFE_METHODS.has(method)) {
    const { headerName, token } = await getCsrf()
    headers[headerName] = token
  }

  const response = await fetch(`${API_BASE}${path}${toQuery(params)}`, {
    method,
    headers,
    body: payload,
    credentials: 'same-origin',
  })

  // A 403 on a write can mean the CSRF token went stale. The server refused it
  // before doing anything, so it is safe to fetch a fresh token and try once more.
  if (response.status === 403 && UNSAFE_METHODS.has(method) && allowRetry) {
    await getCsrf(true)
    return send(method, path, { body, form, params }, false)
  }

  if (response.status === 401 && !path.startsWith('/auth/login')) {
    onUnauthorized()
  }
  if (!response.ok) {
    throw await toApiError(response)
  }
  return response
}

async function readJson(response) {
  if (response.status === 204) return null
  const text = await response.text()
  return text ? JSON.parse(text) : null
}

export const api = {
  async get(path, params) {
    return readJson(await send('GET', path, { params }))
  },

  // For paged lists: the body is the page, the total comes in the X-Total-Count header.
  async getPage(path, params) {
    const response = await send('GET', path, { params })
    return {
      items: (await readJson(response)) ?? [],
      totalCount: Number(response.headers.get('X-Total-Count') ?? 0),
    }
  },

  async post(path, body) {
    return readJson(await send('POST', path, { body }))
  },

  async put(path, body) {
    return readJson(await send('PUT', path, { body }))
  },

  async delete(path) {
    return readJson(await send('DELETE', path))
  },

  async login(username, password) {
    await send('POST', '/auth/login', { form: { username, password } })
    clearCsrf() // the server issues a new CSRF token at login
  },

  async logout() {
    try {
      await send('POST', '/auth/logout')
    } finally {
      clearCsrf()
    }
  },
}