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
link_file = input("Enter the name of link file(without .txt): ")+ ".txt"
out_file  = input("Enter the name for output file(without .txt): ")+ ".txt"
junk_file = input("Enter the name for junk file(without .txt): ")+ ".txt"
cur_type  = input("Do you want to start from the beginning(y or n): ")




if cur_type.lower() == "y":
    cur_num = 1
    t_type    = input("Do you want to extract articles for all links(type Y or N): ")
    if t_type.lower() == "y":
        number = float('inf')
    else:
        number = float(input("Type the number of articles you want to extract: "))
        
else:
    cur_num = int(input("Enter the number you want to start from: "))
    number = float(input("Type the number of articles you want to extract: "))

start_time = time.time()
count = 0
effective_count = 0
with open(link_file, 'r') as infile, open(out_file,"a") as outfile,open(junk_file,"a") as junkfile:
    for link in infile:
        
        if count < cur_num-1:
            count+=1
            continue
            
        if count - (cur_num-1) < number:
            driver.get(link)
            count+=1
        
            
            ##extract tag
            tt = []
            try:
                tag = driver.find_elements_by_class_name("article-breadCrumb")
                if tag == []:
                    print("This article has no tag, may not be an article: " + link)
                    junkfile.write(link + "\n")
                    continue
                for t in tag:
                    outfile.write("tag_g: ")
                    outfile.write(t.text + " ")
            except NoSuchElementException:
                print("This article has no tag, may not be an article: " + link)
                junkfile.write(link + "\n")
                continue
            
            ##extract headline
            try:
                headline = driver.find_element_by_class_name("wsj-article-headline").text
                outfile.write("headline_h: "+headline+" ")
                effective_count += 1
            except NoSuchElementException:
                print("This article has no headline, may not be an article: " + link)
                junkfile.write(link + "\n")
                continue
            
            
            ##extract time
            try:
                timestamp = driver.find_element_by_class_name("timestamp").text
            except NoSuchElementException:
                print("This article has no time stamp, may not be an article: " + link)
                junkfile.write(link + "\n")
                continue
            # clean time stamp if it exists 
            timestamp = re.sub(r'Updated ', '', timestamp)
            timestamp = re.sub(r' ET', '', timestamp)
            timestamp = re.sub(r'p.m.', 'PM', timestamp)
            timestamp = re.sub(r'a.m.', 'AM', timestamp)
            outfile.write("time_t: "+ timestamp +"\n")
            
            ##extract article text
            paragraphs = driver.find_elements_by_xpath('//*[@id="wsj-article-wrap"]/p')
            text = []
            if paragraphs == []:
                print("This article has no text, may not be an article: " + link)
                junkfile.write(link + "\n")
                continue
            outfile.write(link)
            for tt in paragraphs:
                if('@wsj.com' not in tt.text and 'contributed to this article' not in tt.text):
                    text.append(tt.text)
            text = "".join(text)
            text = re.sub(r'\n'," ",text)
            outfile.write(text.lower() + "\n")
            outfile.write("++++++++++++++++++++++++++"+ "\n")
            
            ##print 
            if number < 1000:
                d = 10
            else:
                d = 100
            if (count - cur_num+1) % d == 0:
                print("# extract article: " + str(count - cur_num + 1))
            if effective_count % d == 0:
                print("# extract effective article: " + str(effective_count))
            time.sleep(0.5)
end_time = time.time()
print("Time spent: " + str(np.round((end_time - start_time),3)) + "s")
print("Total number of article:" + str(count - cur_num + 1))
print("Total number of effective article:" + str(effective_count))
print("You should start from {} next time".format(count+1))
print("Article extraction complete!")
o_c = input("Do you want to close Chromedriver?(type Y or N)")
if o_c.lower() == "y":
    driver.close()