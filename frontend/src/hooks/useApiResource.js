import { useCallback, useEffect, useState } from 'react'
import { api } from '../api/client'

// Loads one object from the API. Call reload() to fetch it again.
export function useApiResource(path) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reloadCount, setReloadCount] = useState(0)

  useEffect(() => {
    let cancelled = false
    api.get(path)
      .then((result) => {
        if (cancelled) return
        setData(result)
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

  return { data, loading, error, reload }
}