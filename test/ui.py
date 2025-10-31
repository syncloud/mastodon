from os.path import dirname, join
from subprocess import check_output

import pytest
from selenium.webdriver.common.by import By
from syncloudlib.integration.hosts import add_host_alias

from test import lib

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'

@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode, data_dir, app, domain, device_host, local, selenium):
    if not local:
        add_host_alias(app, device_host, domain)
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)     

        def module_teardown():
            device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
            device.run_ssh('cp -r {0}/log/*.log {1}'.format(data_dir, TMP_DIR), throw=False)
            device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, ui_mode))
            check_output('cp /videos/* {0}'.format(artifact_dir), shell=True)
            check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)
            selenium.log()
        request.addfinalizer(module_teardown)

def test_start(module_setup, app, domain, device_host, device):
    device.activated()
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    lib.login(selenium, device_user, device_password)

def test_first_start(selenium):
    selenium.click_by(By.XPATH, "//button[contains(.,'Save and continue')]")
    selenium.click_by(By.XPATH, "//span[contains(.,'Done')]")
    selenium.invisible_by(By.XPATH, "//span[@text()='Your home feed is being prepared!']")

def test_publish_text(selenium):
    selenium.find_by(By.XPATH, "//textarea[contains(@placeholder, 'on your mind')]").send_keys("test post")
    selenium.screenshot('publish-text-enter')
    selenium.screenshot('publish-text-before')
    selenium.click_by(By.XPATH, "//button[text()='Post']")
    selenium.find_by(By.XPATH, "//*[text()='test post']")
    selenium.screenshot('publish-text')

def test_publish_image(selenium):
    selenium.find_by(By.XPATH, "//button[text()='Post']")
    selenium.find_by(By.XPATH, "//textarea[contains(@placeholder, 'on your mind')]").send_keys("test image")
    file = selenium.driver.find_element(By.XPATH, '//input[@type="file"]')
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    assert not selenium.exists_by(By.XPATH, "//span[contains(.,'Error processing')]")
    selenium.click_by(By.XPATH, "//button[text()='Post']")
    selenium.click_by(By.XPATH, "//button[text()='Post anyway']")
    selenium.find_by(By.XPATH, "//*[text()='test image']")
    selenium.screenshot('publish-image')

def test_publish_video(selenium):
    selenium.find_by(By.XPATH, "//button[text()='Post']")
    selenium.find_by(By.XPATH, "//textarea[contains(@placeholder, 'on your mind')]").send_keys("test video")
    file = selenium.driver.find_element(By.XPATH, '//input[@type="file"]')
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'videos', 'test.mp4'))
    assert not selenium.exists_by(By.XPATH, "//span[contains(.,'Error processing')]")
    selenium.click_by(By.XPATH, "//button[text()='Post']")
    selenium.find_by(By.XPATH, "//*[text()='test video']")
    selenium.screenshot('publish-video')


def test_profile(selenium):
    selenium.click_by(By.XPATH, "//span[.='Preferences']")
    selenium.click_by(By.XPATH, "//a[contains(.,'Public profile')]")
    selenium.find_by_id('account_avatar').send_keys(join(DIR, 'images', 'profile.jpeg'))
    selenium.screenshot('profile-file')
    selenium.click_by(By.XPATH, "//button[text()='Save changes']")
    selenium.screenshot('profile-saved')
    selenium.click_by(By.XPATH, "//a[contains(.,'Back to Mastodon')]")
    selenium.find_by(By.XPATH, "//span[text()='Home']")
    selenium.screenshot('posts')


def test_import(selenium):
    selenium.click_by(By.XPATH, "//span[.='Preferences']")
    selenium.click_by(By.XPATH, "//a[contains(.,'Import and export')]")
    selenium.click_by(By.XPATH, "//a[text()=' Import']")
    selenium.find_by(By.ID,'form_import_data').send_keys(join(DIR, 'csv', 'following.csv'))
    selenium.screenshot('import')
    selenium.click_by(By.XPATH, "//button[text()='Upload']")
    error = selenium.exists_by(By.XPATH, "//span[contains(.,'has contents that are not')]") 
    selenium.screenshot('import-saved')
    assert not error
    selenium.click_by(By.XPATH, "//a[contains(.,'Back to Mastodon')]")
    selenium.find_by(By.XPATH, "//span[text()='Home']")


def test_export(selenium):
    selenium.click_by(By.XPATH, "//span[.='Preferences']")
    selenium.click_by(By.XPATH, "//a[contains(.,'Import and export')]")
    selenium.click_by(By.XPATH, "//a[text()=' Export']")
    selenium.screenshot('export')
    selenium.find_by(By.XPATH, "//a[contains(.,'Back to Mastodon')]").click()
    selenium.find_by(By.XPATH, "//span[text()='Home']")

