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
###############################################################


import psycopg2
import pika, sys, os, json, yaml
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
  
  postgresql_host     = yaml_settings['postgresql']['host']
  postgresql_port     = yaml_settings['postgresql']['port']
  postgresql_database    = yaml_settings['postgresql']['database']
  postgresql_user     = yaml_settings['postgresql']['user']
  postgresql_password = yaml_settings['postgresql']['password']
  
  log_level         = yaml_settings['log_level']

rabbitmq_global = rabbitmq_host + ":" + str(rabbitmq_port) + rabbitmq_vhost + rabbitmq_queue
postgresql_global = postgresql_host + ":" + str(postgresql_port) + "/" + postgresql_database

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

try:
  conn = psycopg2.connect(
          database=postgresql_database,
          user=postgresql_user,
          password=postgresql_password,
          host=postgresql_host,
          port=postgresql_port
  )
  logging.info("Postgresql connected : " + postgresql_global)
except:
  logging.error("Postgresql not connected : error")
  sys.exit(1)

# Let's Go !! #################################################

def main():

    cursor = conn.cursor()
    cursor.execute("CREATE TABLE IF NOT EXISTS cryptos_ref (code varchar(255) PRIMARY KEY, date_create timestamp, title varchar(255),scrape_begin timestamp, scrape_end timestamp )")
    conn.commit()


    def callback(ch, method, properties, body):
      data = json.loads(body)
      print(body)
      data = json.loads(body)
      sql = "INSERT INTO cryptos_ref (code, date_create,title) VALUES(%s,%s,%s) ON CONFLICT (code) DO NOTHING;"
      value = (data['code'],data['runts'],data['title'])
      cursor.execute(sql,value)
      conn.commit()

    channel.basic_consume(queue="cryptos.target",on_message_callback=callback,auto_ack=True)
    channel.start_consuming()


if __name__ == '__main__':
    try:
        main()
        conn.close()
    except KeyboardInterrupt:
      conn.close()
      logging.info("Interrupted")
      try:
          sys.exit(0)
      except SystemExit:
          os._exit(0)
