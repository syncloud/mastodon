import { test } from '../helpers/fixtures'
import { login, dismissOnboarding, expectPublished, publish } from '../helpers/mastodon'
import { shoot } from '../helpers/screenshot'
import { UPGRADE_POST } from '../helpers/upgrade'

test('post survives the upgrade: still there after', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await expectPublished(page, UPGRADE_POST)
  await shoot(page, testInfo, 'post-upgrade')
})

test('publishing still works after the upgrade', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await publish(page, 'syncloud post upgrade post')
  await shoot(page, testInfo, 'post-upgrade-publish')
})
