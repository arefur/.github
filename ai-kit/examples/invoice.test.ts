import { describe, expect, it } from 'vitest'
import { invoiceTotal } from '@/lib/invoice'

describe('invoiceTotal', () => {
  describe('happy path', () => {
    it('adds 15% VAT to a single line (H1)', () => {
      expect(invoiceTotal([{ qty: 2, unitPaisa: 10_000 }])).toBe(23_000)
    })
    it('applies discount before VAT across multiple lines (H2)', () => {
      const lines = [
        { qty: 1, unitPaisa: 10_000 },
        { qty: 3, unitPaisa: 5_000 },
      ]
      expect(invoiceTotal(lines, 10)).toBe(25_875)
    })
  })

  describe('boundaries', () => {
    it('returns 0 for no lines (B1)', () => {
      expect(invoiceTotal([])).toBe(0)
    })
    it('returns 0 for zero quantity (B2)', () => {
      expect(invoiceTotal([{ qty: 0, unitPaisa: 10_000 }])).toBe(0)
    })
    it('accepts 0% and 100% discount (B3)', () => {
      const lines = [{ qty: 1, unitPaisa: 10_000 }]
      expect(invoiceTotal(lines, 0)).toBe(11_500)
      expect(invoiceTotal(lines, 100)).toBe(0)
    })
    it('rejects discount just outside 0-100 (B4)', () => {
      const lines = [{ qty: 1, unitPaisa: 10_000 }]
      expect(() => invoiceTotal(lines, -1)).toThrow(RangeError)
      expect(() => invoiceTotal(lines, 100.01)).toThrow(RangeError)
    })
    it('rounds sub-paisa results to the nearest paisa (B5)', () => {
      expect(invoiceTotal([{ qty: 1, unitPaisa: 1 }])).toBe(1) // 1.15 -> 1
      expect(invoiceTotal([{ qty: 1, unitPaisa: 3 }])).toBe(3) // 3.45 -> 3
      expect(invoiceTotal([{ qty: 1, unitPaisa: 10 }])).toBe(12) // 11.5 -> 12 (half up)
    })
  })

  describe('invalid input', () => {
    it('rejects fractional and negative quantity (I1)', () => {
      expect(() => invoiceTotal([{ qty: 1.5, unitPaisa: 100 }])).toThrow(RangeError)
      expect(() => invoiceTotal([{ qty: -1, unitPaisa: 100 }])).toThrow(RangeError)
    })
    it('rejects NaN discount (I2)', () => {
      expect(() => invoiceTotal([{ qty: 1, unitPaisa: 100 }], NaN)).toThrow()
    })
    it('rejects non-integer unitPaisa (I3)', () => {
      expect(() => invoiceTotal([{ qty: 1, unitPaisa: 0.5 }])).toThrow()
      expect(() => invoiceTotal([{ qty: 1, unitPaisa: NaN }])).toThrow()
    })
  })

  describe('money', () => {
    it('always returns integer paisa (M1)', () => {
      for (const unitPaisa of [1, 7, 33, 999, 12_345]) {
        for (const discount of [0, 5, 12.5, 33.3]) {
          const total = invoiceTotal([{ qty: 3, unitPaisa }], discount)
          expect(Number.isInteger(total)).toBe(true)
        }
      }
    })
    it('supports a negative unit price for refund lines (M2)', () => {
      expect(invoiceTotal([{ qty: 1, unitPaisa: -10_000 }])).toBe(-11_500)
    })
  })

  describe('state', () => {
    it('is idempotent and does not mutate input (S1)', () => {
      const lines = [{ qty: 2, unitPaisa: 500 }]
      const copy = structuredClone(lines)
      expect(invoiceTotal(lines, 10)).toBe(invoiceTotal(lines, 10))
      expect(lines).toEqual(copy)
    })
  })
})
