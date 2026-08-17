import { Page, expect } from '@playwright/test'
import { env } from './env'

const OPTIONAL = 15_000

export async function login(page: Page) {
  await page.goto('/')

  const signIn = page.getByRole('link', { name: /^(log ?in|sign ?in)$/i }).first()
  await expect(signIn, 'login link on the landing page').toBeVisible()
  await signIn.click()

  const email = page.locator('#user_email')
  await expect(email, 'sign-in form after clicking login').toBeVisible()
  await email.fill(env('PLAYWRIGHT_DEVICE_USER'))

  const password = page.locator('#user_password')
  await password.fill(env('PLAYWRIGHT_DEVICE_PASSWORD'))
  await password.press('Enter')

  await expect(composeBox(page)).toBeVisible()
}

export function composeBox(page: Page) {
  return page
    .getByRole('textbox', { name: /what'?s on your mind/i })
    .or(page.locator('textarea[placeholder*="on your mind" i]'))
    .or(page.locator('.autosuggest-textarea__textarea'))
    .first()
}

export async function dismissOnboarding(page: Page) {
  for (const name of [/save and continue/i, /^done$/i, /^got it$/i, /^skip/i]) {
    const button = page.getByRole('button', { name }).first()
    if (await button.isVisible({ timeout: OPTIONAL }).catch(() => false)) {
      await button.click()
    }
  }
}

export async function publish(page: Page, text: string) {
  const box = composeBox(page)
  await expect(box).toBeVisible()
  await box.click()
  await box.fill(text)

  await page.getByRole('button', { name: /^post$/i }).first().click()
  await expect(page.getByText(text, { exact: false }).first()).toBeVisible()
}

export async function expectPublished(page: Page, text: string) {
  await expect(page.getByText(text, { exact: false }).first()).toBeVisible()
}

export async function publishMedia(page: Page, text: string, file: string) {
  const box = composeBox(page)
  await expect(box).toBeVisible()
  await box.click()
  await box.fill(text)

  await page.locator('input[type="file"]').first().setInputFiles(file)

  await expect(page.getByText(/error processing/i)).toHaveCount(0)
  await expect(page.locator('.compose-form__uploads-wrapper, [class*="upload"]').first()).toBeVisible()

  await page.getByRole('button', { name: /^post$/i }).first().click()

  const anyway = page.getByRole('button', { name: /post anyway/i }).first()
  if (await anyway.isVisible({ timeout: OPTIONAL }).catch(() => false)) {
    await anyway.click()
  }

  await expect(page.getByText(text, { exact: false }).first()).toBeVisible()
  await expect(page.getByText(/error processing/i)).toHaveCount(0)
}
