from selenium.webdriver import Firefox
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.keys import Keys
import time

def auto_browse(url):
    print('auto click on url: ' + url)
    opts = Options()
    opts.add_argument('--headless')
    opts.add_argument('--disable-gpu')
    #assert opts.headless  # Operating in headless mode
    browser = Firefox(options=opts)
    browser.get(url)
    auth_form = browser.find_element_by_xpath('/html/body/div[1]/div/div[1]/div[2]/div/div[2]/div/form/input[2]')
    auth_form.send_keys('123456')
    auth_form.send_keys(Keys.ENTER)
    time.sleep(5)
    try:
        browser.close()
    except Exception as err:
        print(err)
        pass
