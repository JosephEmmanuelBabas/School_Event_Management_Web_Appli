import { useContext } from 'react'
import { NotificationContext } from './NotificationContext'

// Usage: const notify = useNotify(); notify.success('Saved.'); notify.error('Failed.')
export function useNotify() {
  const context = useContext(NotificationContext)
  if (!context) {
    throw new Error('useNotify must be used inside <NotificationProvider>.')
  }
  return context
}