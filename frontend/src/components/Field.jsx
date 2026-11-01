// A label plus a control, with the error and hint tied to the control for screen readers.
// Use as="select" or as="textarea" for those controls; the default is an <input>.
export default function Field({
  id,
  label,
  error,
  hint,
  required = false,
  as: Control = 'input',
  ...controlProps
}) {
  const errorId = `${id}-error`
  const hintId = `${id}-hint`
  const describedBy = [hint ? hintId : null, error ? errorId : null].filter(Boolean).join(' ')

  return (
    <div className="field">
      <label htmlFor={id}>
        {label}
        {required && <span aria-hidden="true"> *</span>}
      </label>
      <Control
        id={id}
        aria-required={required ? 'true' : undefined}
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={describedBy || undefined}
        {...controlProps}
      />
      {hint && <p className="field-hint" id={hintId}>{hint}</p>}
      {error && <p className="field-error" id={errorId}>{error}</p>}
    </div>
  )
}