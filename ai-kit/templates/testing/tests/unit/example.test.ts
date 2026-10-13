// Pattern file: delete once the repo has real tests.
// One describe per unit, scenario names read as sentences, Arrange → Act → Assert.
import { describe, expect, it } from 'vitest'

function formatBdt(paisa: number): string {
  if (!Number.isInteger(paisa)) throw new TypeError('amount must be integer paisa')
  const taka = paisa / 100
  return `৳${taka.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

describe('formatBdt', () => {
  it('formats whole taka with lakh grouping', () => {
    expect(formatBdt(12_345_600)).toBe('৳1,23,456.00')
  })
  it('keeps paisa', () => {
    expect(formatBdt(1_05)).toBe('৳1.05')
  })
  it('handles zero and negatives (refunds)', () => {
    expect(formatBdt(0)).toBe('৳0.00')
    expect(formatBdt(-500)).toBe('৳-5.00')
  })
  it('rejects fractional paisa', () => {
    expect(() => formatBdt(1.5)).toThrow(TypeError)
  })
})
