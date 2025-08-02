#!/usr/bin/python3

import pulsar

client = pulsar.Client('pulsar://pulsar1:6650')

producer = client.create_producer('persistent://xtenant/xns/Saliou-topic',                  
                                    properties={
                                        "producer-name": "test-producer-name",
                                        "producer-id": "test-producer-id"
                                    })

for i in range(1000000):
    producer.send(('Hello-%d' % i).encode('utf-8'))
client.close()
