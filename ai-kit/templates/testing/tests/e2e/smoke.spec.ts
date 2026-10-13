import { expect, test } from '@playwright/test'

test.describe('smoke', () => {
  test('home page loads without errors', async ({ page }) => {
    const errors: string[] = []
    page.on('pageerror', e => errors.push(e.message))
    page.on('console', m => m.type() === 'error' && errors.push(m.text()))

    const res = await page.goto('/')
    expect(res?.status()).toBeLessThan(400)
    await expect(page.locator('body')).toBeVisible()
    expect(errors).toEqual([])
  })

  test('unknown route shows 404', async ({ page }) => {
    const res = await page.goto('/this-page-does-not-exist')
    expect(res?.status()).toBe(404)
  })
})
