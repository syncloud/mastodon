from os.path import dirname, join

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from syncloudlib.integration.hosts import add_host_alias
from subprocess import check_output, CalledProcessError, STDOUT
from integration import lib
import time
from selenium.webdriver.support import expected_conditions as EC

DIR = dirname(__file__)


@pytest.fixture(scope="session")
def module_setup(request, device, log_dir, ui_mode, artifact_dir):
    def module_teardown():
        tmp_dir = '/tmp/syncloud/ui'
        
        device.run_ssh('mkdir -p {0}/{1}'.format(tmp_dir, ui_mode), throw=False)
        device.run_ssh('journalctl > {0}/{1}/journalctl.log'.format(tmp_dir, ui_mode), throw=False)
        device.run_ssh('cp -r /var/snap/mastodon/common/log {0}/{1}'.format(tmp_dir, ui_mode), throw=False)
        device.scp_from_device('{0}/*'.format(tmp_dir), artifact_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

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
    selenium.find_by_xpath("//span[text()='Publish']").click()
    selenium.find_by_xpath("//label/textarea").send_keys("test post")
    publish = "//button[text()='Publish!']"
    selenium.wait_driver.until(EC.element_to_be_clickable((By.XPATH, publish)))   
    selenium.screenshot('publish-text-before')
    selenium.wait_driver.until(EC.invisibility_of_element_located((By.XPATH, "//span[@text()='Your home feed is being prepared!']")))
    selenium.find_by_xpath(publish).click()
    selenium.find_by_xpath("//*[text()='test post']")
    selenium.screenshot('publish-text')

def test_publish_image(selenium):
    
    selenium.find_by_xpath("//span[text()='Publish']").click()
    selenium.find_by_xpath("//label/textarea").send_keys("test image")
    file = selenium.driver.find_element(By.XPATH, '//input[@type="file"]')
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    publish = "//button[text()='Publish!']"
    selenium.wait_driver.until(EC.element_to_be_clickable((By.XPATH, publish)))
    selenium.find_by_xpath(publish).click()
    selenium.find_by_xpath("//span[text()='Publish']")
    assert not selenium.exists_by(By.XPATH, "//span[contains(.,'Error processing')]")
    selenium.find_by_xpath("//*[text()='test image']")
    selenium.screenshot('publish-image')

def test_publish_video(selenium):
    
    selenium.find_by_xpath("//span[text()='Publish']").click()
    selenium.find_by_xpath("//label/textarea").send_keys("test video")
    file = selenium.driver.find_element(By.XPATH, '//input[@type="file"]')
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'videos', 'test.mp4'))
    publish = "//button[text()='Publish!']"
    selenium.wait_driver.until(EC.element_to_be_clickable((By.XPATH, publish)))
    selenium.find_by_xpath(publish).click()
    selenium.find_by_xpath("//*[text()='test video']")
    selenium.find_by_xpath("//span[text()='Publish']")
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
    selenium.find_by_xpath("//span[text()='Publish']")
    selenium.screenshot('posts')


def test_import(selenium, ui_mode):
    selenium.find_by_xpath("//a[@title='Preferences']").click()
    selenium.find_by_xpath("//a[contains(.,'Import and export')]").click()
    selenium.find_by_xpath("//a[@href='/settings/import']").click() 
    selenium.find_by_id('import_data').send_keys(join(DIR, 'csv', 'following.csv'))
    selenium.screenshot('import')
    selenium.find_by_xpath("//button[text()='Upload']").click()   
    error = selenium.exists_by(By.XPATH, "//span[contains(.,'has contents that are not')]") 
    selenium.screenshot('import-saved')
    assert not error
    if ui_mode == "mobile":
        selenium.find_by_xpath("//a[@aria-label='Toggle menu']").click()
    selenium.find_by_xpath("//a[text()='Back to Mastodon']").click()
    selenium.find_by_xpath("//span[text()='Publish']")


def test_export(selenium, ui_mode):
    selenium.find_by_xpath("//a[@title='Preferences']").click()
    selenium.find_by_xpath("//a[contains(.,'Import and export')]").click()
    #selenium.find_by_xpath("//a[contains(.,'Data export']").click() 
    selenium.screenshot('export')
    if ui_mode == "mobile":
        selenium.find_by_xpath("//a[@aria-label='Toggle menu']").click()
    selenium.find_by_xpath("//a[text()='Back to Mastodon']").click()
    selenium.find_by_xpath("//span[text()='Publish']")


def test_teardown(driver):
    driver.quit()
