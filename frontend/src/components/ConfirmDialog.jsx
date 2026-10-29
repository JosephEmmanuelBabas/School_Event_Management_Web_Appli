import Modal from './Modal'

export default function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Confirm',
  danger = false,
  busy = false,
  onConfirm,
  onCancel,
}) {
  return (
    <Modal open={open} title={title} onClose={busy ? () => {} : onCancel}>
      <p>{message}</p>
      <div className="modal-actions">
        {/* Cancel gets the focus, so pressing Enter by accident does not delete anything. */}
        <button
          type="button"
          className="button button-secondary"
          onClick={onCancel}
          disabled={busy}
          autoFocus
        >
          Cancel
        </button>
        <button
          type="button"
          className={danger ? 'button button-danger' : 'button'}
          onClick={onConfirm}
          disabled={busy}
        >
          {busy ? 'Working…' : confirmLabel}
        </button>
      </div>
    </Modal>
  )
}