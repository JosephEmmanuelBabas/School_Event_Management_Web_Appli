import { useEffect, useState } from 'react'
import { api } from '../api/client'

// Loads one page of a paged endpoint. The params are compared by value, so a new
// object with the same contents does not trigger another request.
export function useApiPage(path, params) {
  const key = JSON.stringify(params ?? {})
  const [state, setState] = useState({ items: [], totalCount: 0, loading: true, error: '' })

  useEffect(() => {
    let cancelled = false
    api.getPage(path, JSON.parse(key))
      .then(({ items, totalCount }) => {
        if (!cancelled) setState({ items, totalCount, loading: false, error: '' })
      })
      .catch((err) => {
        if (!cancelled) setState((current) => ({ ...current, loading: false, error: err.message }))
      })
    return () => {
      cancelled = true
    }
  }, [path, key])

  return state
}