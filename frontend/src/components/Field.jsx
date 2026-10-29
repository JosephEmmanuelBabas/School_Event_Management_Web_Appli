// A label plus an input, with the error and hint tied to the input for screen readers.
export default function Field({ id, label, error, hint, required = false, ...inputProps }) {
  const errorId = `${id}-error`
  const hintId = `${id}-hint`
  const describedBy = [hint ? hintId : null, error ? errorId : null].filter(Boolean).join(' ')

  return (
    <div className="field">
      <label htmlFor={id}>
        {label}
        {required && <span aria-hidden="true"> *</span>}
      </label>
      <input
        id={id}
        aria-required={required ? 'true' : undefined}
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={describedBy || undefined}
        {...inputProps}
      />
      {hint && <p className="field-hint" id={hintId}>{hint}</p>}
      {error && <p className="field-error" id={errorId}>{error}</p>}
    </div>
  )
}