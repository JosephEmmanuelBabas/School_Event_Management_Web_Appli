import { useEffect, useId, useRef } from 'react'

// A dialog built on the browser's <dialog> element. The browser handles the focus
// trap and the Esc key. Children are only mounted while open, so a form inside
// starts fresh every time the dialog opens.
export default function Modal({ open, title, onClose, children }) {
  const dialogRef = useRef(null)
  const titleId = useId()

  useEffect(() => {
    const dialog = dialogRef.current
    if (!dialog) return
    if (open && !dialog.open) dialog.showModal()
    if (!open && dialog.open) dialog.close()
  }, [open])

  return (
    <dialog
      ref={dialogRef}
      className="modal"
      aria-labelledby={titleId}
      onCancel={(event) => {
        // Esc was pressed. Let the parent decide whether to close.
        event.preventDefault()
        onClose()
      }}
    >
      {open && (
        <div className="modal-body">
          <h2 id={titleId}>{title}</h2>
          {children}
        </div>
      )}
    </dialog>
  )
}