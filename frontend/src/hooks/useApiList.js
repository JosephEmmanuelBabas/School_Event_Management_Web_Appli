import { useCallback, useEffect, useState } from 'react'
import { api } from '../api/client'

// Loads a list from the API. Call reload() after a change to fetch it again.
export function useApiList(path) {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reloadCount, setReloadCount] = useState(0)

  useEffect(() => {
    let cancelled = false
    api.get(path)
      .then((data) => {
        if (cancelled) return
        setItems(data)
        setError('')
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [path, reloadCount])

  const reload = useCallback(() => setReloadCount((count) => count + 1), [])

  return { items, loading, error, reload }
}