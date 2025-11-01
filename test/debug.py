import os
import shutil
from os import environ
from os.path import dirname, join

from syncloudlib.integration.conftest import new_firefox_driver
from syncloudlib.integration.selenium_wrapper import SeleniumWrapper

from test.ui import test_login, test_publish_text, test_publish_image, \
    test_publish_video, test_profile, test_import, test_export

DIR = dirname(__file__)

def test_chrome():
    # sudo docker network create --ipv6 --subnet 2001:0DB8::/112 ip6net
    # sudo docker run -it --network ip6net -p 4444:4444 -p 5900:5900 -p 7900:7900 --shm-size="2g" selenium/standalone-firefox:4.35.0-20250828
    # firefox http://localhost:7900
    # password: secret

    driver = new_firefox_driver("http://localhost:4444/wd/hub", "desktop")

    # options = webdriver.ChromeOptions()
    # options.add_argument('--no-sandbox')
    # options.add_argument('--disable-dev-shm-usage')
    # options.set_capability('goog:loggingPrefs', {'performance': 'ALL'})
    # options.set_capability('acceptInsecureCerts', True)
    # driver = webdriver.Remote(options=options)
    driver.maximize_window()

    artifacts_dir = join(DIR, "artifact")
    if os.path.exists(artifacts_dir):
        shutil.rmtree(artifacts_dir)
    os.makedirs(artifacts_dir)

    selenium = SeleniumWrapper(
        driver,
        "desktop",
        artifacts_dir,
        environ["DOMAIN"],
        5,
        "firefox"
    )

    try:
        device_user = "test"
        test_login(selenium, device_user, "test1234")
        # test_first_start(selenium)
        test_publish_text(selenium)
        test_publish_image(selenium)
        test_publish_video(selenium)
        test_profile(selenium)
        test_import(selenium)
        test_export(selenium)
    finally:
        print()
        driver.quit()
