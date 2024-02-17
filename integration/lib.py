from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import time


def login(selenium, device_user, device_password):

    selenium.open_app()
    selenium.screenshot('index')
    selenium.find_by_xpath("//span[text()='Login']").click()
    selenium.find_by_id("user_email").send_keys(device_user)
    password = selenium.find_by_id("user_password")
    password.send_keys(device_password)
    selenium.screenshot('credentials')
    password.send_keys(Keys.RETURN)
    selenium.find_by_xpath("//span[text()='Publish']")
    selenium.screenshot('main')
