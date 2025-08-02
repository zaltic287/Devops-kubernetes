#!/usr/bin/python3

###############################################################
#  TITRE: 
#
#  AUTEUR:   Xavier
#  VERSION: 
#  CREATION:  
#  MODIFIE: 
#
#  DESCRIPTION: 
#			https://chromedriver.chromium.org/downloads
#			https://chromedriver.storage.googleapis.com/112.0.5615.49/chromedriver_linux64.zip
#			> /usr/local/bin/webdriver
#			https://fr.finance.yahoo.com/quote/<code>?p=<code>
###############################################################



from selenium import webdriver
import sys,time,re,json,pika
import yaml,os
from datetime import datetime
from json import dumps
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.chrome.options import Options
import logging
from pythonjsonlogger import jsonlogger

# Configuration ###################################################

ymlfile = """
rabbitmq:
  host: rmq1
  user: Saliou
  port: 5672
  password: password
  queue: cryptos.target
log_level: INFO
"""

local_path = os.path.abspath(os.path.dirname(__file__))

if os.path.isfile(os.path.join(local_path, "config.yml")):

  with open(os.path.join(local_path, "config.yml"), "r") as ymlfile:
    yaml_settings = yaml.load(ymlfile, Loader=yaml.FullLoader)

  rabbitmq_host     = yaml_settings['rabbitmq']['host']
  rabbitmq_port     = yaml_settings['rabbitmq']['port']
  rabbitmq_vhost    = yaml_settings['rabbitmq']['vhost']
  rabbitmq_user     = yaml_settings['rabbitmq']['user']
  rabbitmq_password = yaml_settings['rabbitmq']['password']
  rabbitmq_queue    = yaml_settings['rabbitmq']['queue']
  log_level         = yaml_settings['log_level']

rabbitmq_global = rabbitmq_host + ":" + str(rabbitmq_port) + rabbitmq_vhost + rabbitmq_queue

logging.basicConfig(level=log_level)
root = logging.getLogger()
hdlr = root.handlers[0]
json_format = logging.Formatter('{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}')
hdlr.setFormatter(json_format)



# Connexion ###################################################

try:
  credentials = pika.PlainCredentials(rabbitmq_user, rabbitmq_password)
  connection = pika.BlockingConnection(pika.ConnectionParameters(rabbitmq_host,rabbitmq_port,rabbitmq_vhost,credentials))
  channel = connection.channel()
  channel.queue_declare(queue=rabbitmq_queue,durable=True)
  logging.info("Rabbitmq connected : " + rabbitmq_global)
except:
  logging.error("Rabbitmq not connected : error")
  sys.exit(1)

# Class		  ###################################################

class Message():

  def __init__(self, created_at, runts, code, title):
    self.runts = runts
    self.code = code
    self.title = title
    self.created_at = created_at

  def getCode(self):
    return self.code

  def getTitle(self):
    return self.title

  def getCreatedAt(self):
    return self.created_at

  def getRunts(self):
    return self.runts

  def jsonMessage(self):
    message = { "createdAt": self.created_at, "runts": self.runts, "code": self.code, "title": self.title }
    message = json.dumps(message)
    return message

  def pushToQueue(self):
    channel.basic_publish(exchange=rabbitmq_queue,
                 routing_key='cryptos',
                 properties=pika.BasicProperties(
                   delivery_mode = 2
                 ),
                 body=self.jsonMessage())


# Let's Go !! #################################################

def main():

  logging.info("collect the size of the crypto list")

  options = Options()
  #options.headless = False
  options.add_argument("--headless")
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_experimental_option("excludeSwitches", ['enable-automation'])

  browser = webdriver.Chrome(options=options)

  page = browser.get('https://fr.finance.yahoo.com/crypto-monnaies/?count=100&offset=0')

  try: 
    button = browser.find_element(By.XPATH, '//*[@id="consent-page"]/div/div/div/form/div[2]/div[2]/button[1]').click()
  except NoSuchElementException:
    pass

  time.sleep(1)

  max_number = browser.find_element(By.XPATH,'//*[@id="fin-scr-res-table"]/div[1]/div[1]/span[2]/span').text

  max_number = re.match(".*sur ([0-9]+$)",max_number)

  logging.info("Size : " + max_number.groups()[0])
  if max_number:
    max_range = (int(max_number.groups()[0][0]) + 1) * 10 ** (len(max_number.groups()[0]) - 1)

  logging.info("Max range : " + str(max_range))

  runts = json.dumps(datetime.now(),default=str)

  log_counter = 0

  for x in range(0, max_range, 100):

    browser.get('https://fr.finance.yahoo.com/crypto-monnaies/?count=100&offset=' + str(x) + '&guccounter=1')

    names = browser.find_elements(By.XPATH,'//*[@data-test="quoteLink"]')

    counter = 0
    for i in names:
      counter += 1
      message = Message(time.time(), runts, i.text, i.get_attribute("title"))
      logging.debug("Code crypto message generated : " + i.text)
      
      message.pushToQueue()
      logging.debug("Code crypto message pushed : " + i.text)
      log_counter += 1

    time.sleep(1)

  logging.info("Line inserted : " + str(log_counter))

if __name__ == '__main__':
    try:
      main()
    except KeyboardInterrupt:
      logging.info("Interrupted")
      try:
          sys.exit(0)
      except SystemExit:
          os._exit(0)