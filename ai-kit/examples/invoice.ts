export type Line = { qty: number; unitPaisa: number }

/** Total in paisa after discount (percent 0-100) and 15% VAT on the discounted amount. */
export function invoiceTotal(lines: Line[], discountPercent = 0): number {
  if (discountPercent < 0 || discountPercent > 100) throw new RangeError('discount must be 0-100')
  const subtotal = lines.reduce((s, l) => {
    if (!Number.isInteger(l.qty) || l.qty < 0) throw new RangeError('qty must be a non-negative integer')
    return s + l.qty * l.unitPaisa
  }, 0)
  const discounted = Math.round(subtotal * (1 - discountPercent / 100))
  return Math.round(discounted * 1.15)
}
