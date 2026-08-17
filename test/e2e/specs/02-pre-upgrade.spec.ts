import { test } from '../helpers/fixtures'
import { login, dismissOnboarding, publish } from '../helpers/mastodon'
import { shoot } from '../helpers/screenshot'
import { UPGRADE_POST } from '../helpers/upgrade'

test('post survives the upgrade: publish before', async ({ page }, testInfo) => {
  await login(page)
  await dismissOnboarding(page)
  await publish(page, UPGRADE_POST)
  await shoot(page, testInfo, 'pre-upgrade')
})
