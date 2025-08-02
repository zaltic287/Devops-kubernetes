#!/usr/bin/python3

import pulsar

client = pulsar.Client('pulsar://192.168.13.170:6650')

consumer = client.subscribe(topic='persistent://xtenant/xns/Saliou-topic', subscription_name='sub1',initial_position=pulsar.InitialPosition.Earliest,consumer_type=pulsar.ConsumerType.Failover)

while True:
    msg = consumer.receive()
    try:
        print("Received message '{}' id='{}'".format(msg.data(), msg.message_id()))
        # Acknowledge successful processing of the message
        consumer.acknowledge(msg)
    except Exception:
        # Message failed to be processed
        consumer.negative_acknowledge(msg)

client.close()
