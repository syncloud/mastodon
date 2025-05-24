import time
from os.path import dirname, join
from subprocess import check_output

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from syncloudlib.integration.hosts import add_host_alias

from test import lib

DIR = dirname(__file__)


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode, data_dir, app, domain, device_host, local, selenium):
    if not local:
        add_host_alias(app, device_host, domain)
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)     

        def module_teardown():
            device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
            device.run_ssh("snap run invoiceninja.sql invoiceninja -e 'select * from users;' > {0}/users.log".format(TMP_DIR), throw=False)
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

def test_publish_text(selenium):
    done = "//span[text()='Done']"
    if selenium.exists_by(By.XPATH, done):
        selenium.find_by_xpath(done).click()
    time.sleep(2)
    selenium.find_by_xpath("//span[text()='New post']").click()
    selenium.find_by_xpath("//textarea[contains(@placeholder, 'on your mind')]").send_keys("test post")
    publish = "//button[text()='Publish!']"
    selenium.wait_driver.until(EC.element_to_be_clickable((By.XPATH, publish)))   
    selenium.screenshot('publish-text-before')
    selenium.wait_driver.until(EC.invisibility_of_element_located((By.XPATH, "//span[@text()='Your home feed is being prepared!']")))
    selenium.find_by_xpath(publish).click()
    selenium.find_by_xpath("//*[text()='test post']")
    selenium.screenshot('publish-text')

def test_publish_image(selenium):
    
    selenium.find_by_xpath("//span[text()='New post']").click()
    selenium.find_by_xpath("//label/textarea").send_keys("test image")
    file = selenium.driver.find_element(By.XPATH, '//input[@type="file"]')
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    publish = "//button[text()='Publish!']"
    selenium.wait_driver.until(EC.element_to_be_clickable((By.XPATH, publish)))
    selenium.find_by_xpath(publish).click()
    selenium.find_by_xpath("//span[text()='New post']")
    assert not selenium.exists_by(By.XPATH, "//span[contains(.,'Error processing')]")
    selenium.find_by_xpath("//*[text()='test image']")
    selenium.screenshot('publish-image')

def test_publish_video(selenium):
    
    selenium.find_by_xpath("//span[text()='New post']").click()
    selenium.find_by_xpath("//label/textarea").send_keys("test video")
    file = selenium.driver.find_element(By.XPATH, '//input[@type="file"]')
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'videos', 'test.mp4'))
    publish = "//button[text()='Publish!']"
    selenium.wait_driver.until(EC.element_to_be_clickable((By.XPATH, publish)))
    selenium.find_by_xpath(publish).click()
    selenium.find_by_xpath("//*[text()='test video']")
    selenium.find_by_xpath("//span[text()='New post']")
    assert not selenium.exists_by(By.XPATH, "//span[contains(.,'Error processing')]")
    selenium.screenshot('publish-video')


def test_profile(selenium, ui_mode):
    selenium.find_by_xpath("//a[@title='user']").click()
    #selenium.find_by_xpath("//button[text()='Edit profile']").click()
    selenium.open_app("/settings/profile")
    selenium.find_by_id('account_avatar').send_keys(join(DIR, 'images', 'profile.jpeg'))
    selenium.screenshot('profile-file')
    selenium.find_by_xpath("//button[text()='Save changes']").click()   
    selenium.screenshot('profile-saved')
    if ui_mode == "mobile":
        selenium.find_by_xpath("//a[@aria-label='Toggle menu']").click()
    selenium.find_by_xpath("//a[text()='Back to Mastodon']").click()
    selenium.find_by_xpath("//span[text()='New post']")
    selenium.screenshot('posts')


def test_import(selenium, ui_mode):
    selenium.find_by_xpath("//a[@title='Preferences']").click()
    selenium.find_by_xpath("//a[contains(.,'Import and export')]").click()
    selenium.find_by_xpath("//a[@href='/settings/imports']").click()
    selenium.find_by_id('form_import_data').send_keys(join(DIR, 'csv', 'following.csv'))
    selenium.screenshot('import')
    selenium.find_by_xpath("//button[text()='Upload']").click()   
    error = selenium.exists_by(By.XPATH, "//span[contains(.,'has contents that are not')]") 
    selenium.screenshot('import-saved')
    assert not error
    selenium.find_by_xpath("//a[text()='Back to Mastodon']").click()
    selenium.find_by_xpath("//span[text()='New post']")


def test_export(selenium, ui_mode):
    selenium.find_by_xpath("//a[@title='Preferences']").click()
    selenium.find_by_xpath("//a[contains(.,'Import and export')]").click()
    #selenium.find_by_xpath("//a[contains(.,'Data export']").click() 
    selenium.screenshot('export')
    if ui_mode == "mobile":
        selenium.find_by_xpath("//a[@aria-label='Toggle menu']").click()
    selenium.find_by_xpath("//a[text()='Back to Mastodon']").click()
    selenium.find_by_xpath("//span[text()='New post']")
