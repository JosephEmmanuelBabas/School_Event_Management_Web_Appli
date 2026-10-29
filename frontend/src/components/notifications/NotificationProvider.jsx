import { useCallback, useMemo, useRef, useState } from 'react'
import { NotificationContext } from './NotificationContext'

const SUCCESS_MS = 4000
const ERROR_MS = 8000

export default function NotificationProvider({ children }) {
  const [items, setItems] = useState([])
  const nextId = useRef(1)

  const dismiss = useCallback((id) => {
    setItems((list) => list.filter((item) => item.id !== id))
  }, [])

  const show = useCallback(
    (kind, message) => {
      const id = nextId.current++
      setItems((list) => [...list, { id, kind, message }])
      setTimeout(() => dismiss(id), kind === 'error' ? ERROR_MS : SUCCESS_MS)
    },
    [dismiss],
  )

  const value = useMemo(
    () => ({
      success: (message) => show('success', message),
      error: (message) => show('error', message),
    }),
    [show],
  )

  return (
    <NotificationContext.Provider value={value}>
      {children}
      <div className="toast-region" aria-live="polite">
        {items.map((item) => (
          <div
            key={item.id}
            className={`toast toast-${item.kind}`}
            role={item.kind === 'error' ? 'alert' : 'status'}
          >
            <span>{item.message}</span>
            <button
              type="button"
              className="toast-close"
              onClick={() => dismiss(item.id)}
              aria-label="Dismiss message"
            >
              ×
            </button>
          </div>
        ))}
      </div>
    </NotificationContext.Provider>
  )
}