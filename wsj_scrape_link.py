from selenium import webdriver
from selenium.webdriver.common.keys import Keys

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


import re
import time
import numpy as np



## Open WSJ homepage and log in : 
chrome_url = input("Enter the location of your chromedriver:"+"\n")
driver = webdriver.Chrome(chrome_url)
driver.get('http://www.wsj.com')
login = driver.find_element_by_link_text("Sign In").click()

username = input("type the username for wsj: ")
password = input("type the password for wsj: ")

time.sleep(2)
loginID = driver.find_element_by_id("username").send_keys(username)
loginPass = driver.find_element_by_id("password").send_keys(password)
loginReady = driver.find_element_by_class_name("basic-login-submit")
loginReady.submit()

def u_url(year,month,day):
    return "http://www.wsj.com/public/page/archive-" + str(year) + "-" + str(month) + "-" + str(day) + ".html"

def getPageUrl(elementLinks):
    extractLinks = []
    for element in elementLinks:
        links = element.get_attribute('href')
        extractLinks.append(links)
    return(extractLinks)

normal_year = {1:31,2:28,3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31}
leap_year = {1:31,2:29,3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31}               

year = int(input("The year you want to extract the link for wsj: "))
article_link = []
for month in range(1,13):
    if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
        year_type = leap_year
    else:
        year_type = normal_year
    for day in range(1,year_type[month]+1):
        url = u_url(year,month,day)
        driver.get(url)
        time.sleep(1)
        element = driver.find_elements_by_xpath('//ul[@class = "newsItem"]//a')
        link = getPageUrl(element)
        article_link.append(link)
        if day % 10 == 0:
            print("month:"+ str(month) + " " "day:" + str(day))
            
article_link = [y for x in article_link for y in x]
f_name = "wsj_" + str(year) + "_link.txt'"
f = open(f_name,'w')
for i in article_link:
    f.write(i)
    f.write("\n")
f.close()

print("The number of link extracted: " + str(len(article_link)))
print("link extraction complete!")

o_c = input("Do you want to close Chromedriver?(type Y or N)")
if o_c.lower() == "y":
    driver.close()