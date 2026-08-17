import * as path from 'node:path'
import { test, expect } from '../helpers/fixtures'
import { login, dismissOnboarding, publish, publishMedia, composeBox } from '../helpers/mastodon'
import { shoot } from '../helpers/screenshot'

const FIXTURES = path.join(import.meta.dirname, '..', '..')

test('login lands on the home feed', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await expect(composeBox(page)).toBeVisible()
  await shoot(page, testInfo, 'home')
})

test('publishing a post shows it in the feed', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await publish(page, 'syncloud smoke post')
  await shoot(page, testInfo, 'published')
})

test('publishing an image goes through the media pipeline', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await publishMedia(page, 'syncloud image post', path.join(FIXTURES, 'images', 'profile.jpeg'))
  await shoot(page, testInfo, 'published-image')
})

test('publishing a video goes through ffmpeg', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await publishMedia(page, 'syncloud video post', path.join(FIXTURES, 'videos', 'test.mp4'))
  await shoot(page, testInfo, 'published-video')
})

test('preferences open', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)

  await page.getByRole('link', { name: /preferences/i }).first().click()
  await expect(page.getByRole('heading', { name: /appearance|preferences/i }).first()).toBeVisible()
  await shoot(page, testInfo, 'preferences')
})
