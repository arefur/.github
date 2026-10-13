// Pattern file: component test with Testing Library + user-event. Delete once real tests exist.
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useState } from 'react'
import { describe, expect, it, vi } from 'vitest'

function SubscribeForm({ onSubmit }: { onSubmit: (email: string) => Promise<void> }) {
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  return (
    <form
      onSubmit={async e => {
        e.preventDefault()
        if (!/^\S+@\S+\.\S+$/.test(email)) return setError('Enter a valid email')
        setBusy(true)
        try { await onSubmit(email); setError('') } catch { setError('Something went wrong, try again') } finally { setBusy(false) }
      }}
    >
      <label htmlFor="email">Email</label>
      <input id="email" value={email} onChange={e => setEmail(e.target.value)} />
      <button disabled={busy}>Subscribe</button>
      {error && <p role="alert">{error}</p>}
    </form>
  )
}

describe('SubscribeForm', () => {
  it('submits a valid email', async () => {
    const onSubmit = vi.fn().mockResolvedValue(undefined)
    render(<SubscribeForm onSubmit={onSubmit} />)
    await userEvent.type(screen.getByLabelText(/email/i), 'aref@amsoftbd.com')
    await userEvent.click(screen.getByRole('button', { name: /subscribe/i }))
    expect(onSubmit).toHaveBeenCalledWith('aref@amsoftbd.com')
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('rejects an invalid email without calling the API', async () => {
    const onSubmit = vi.fn()
    render(<SubscribeForm onSubmit={onSubmit} />)
    await userEvent.type(screen.getByLabelText(/email/i), 'not-an-email')
    await userEvent.click(screen.getByRole('button', { name: /subscribe/i }))
    expect(screen.getByRole('alert')).toHaveTextContent(/valid email/i)
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('shows a retry message when the API fails', async () => {
    render(<SubscribeForm onSubmit={vi.fn().mockRejectedValue(new Error('500'))} />)
    await userEvent.type(screen.getByLabelText(/email/i), 'aref@amsoftbd.com')
    await userEvent.click(screen.getByRole('button', { name: /subscribe/i }))
    expect(await screen.findByRole('alert')).toHaveTextContent(/try again/i)
  })
})
