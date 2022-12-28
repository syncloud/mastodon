from os.path import dirname, join

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from syncloudlib.integration.hosts import add_host_alias
from subprocess import check_output, CalledProcessError, STDOUT
from integration import lib
import time
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

def test_publish(selenium):
    done = "//span[text()='Done']"
    if selenium.exists_by(By.XPATH, done):
        selenium.find_by_xpath(done).click()
    selenium.find_by_xpath("//span[text()='Publish']").click()
    selenium.find_by_xpath("//label/textarea").send_keys("test post")
    selenium.find_by_xpath("//button[text()='Publish!']").click()
    selenium.find_by_xpath("//*[text()='test post']")
    selenium.screenshot('publish')

def test_profile(selenium, ui_mode):
    selenium.find_by_xpath("//a[@title='user']").click()
    #selenium.find_by_xpath("//button[text()='Edit profile']").click()
    selenium.open_app("/settings/profile")
    #time.sleep(5)
    file = selenium.find_by_xpath('//input[@type="file"]')
    #driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    selenium.screenshot('profile-file')
    selenium.find_by_xpath("//button[text()='Save changes']").click()   
    selenium.screenshot('profile-saved')
    if ui_mode == "mobile":
        selenium.find_by_xpath("//a[@aria-label='Toggle menu']").click()
    selenium.find_by_xpath("//img[@alt='Mastodon']").click()
    selenium.find_by_xpath("//span[text()='Publish']")
    selenium.screenshot('posts')

def test_teardown(driver):
    driver.quit()
