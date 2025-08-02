#!/home/vagrant/gapp/bin/python3

from gremlin_python import statics
from gremlin_python.structure.graph import Graph
from gremlin_python.process.graph_traversal import __
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection

import datetime
import uuid
import random

graph = Graph()
connection = DriverRemoteConnection('ws://janus4:8182/gremlin', 'g')
g_l = graph.traversal().withRemote(connection)

cities = ["Paris", "Londres", "Moscou", "Rome"]
categories = ["sportif","geek","jardinier","bricoleur"]

for city in cities:
    result = g_l.addV("city").property('name', city).next()
    print(result)

g = graph.traversal().withRemote(connection)
for i in range(0, 1000000):
    id_person = "id" + str(i)
    city = random.choice(cities)
    vcity = g.V().hasLabel(city).has('name',city).next()
    print(vcity)
    vpeople = g.addV(random.choice(categories)).property('name', id_person).property('city', city).property('uid',uuid.uuid1()).property('timestamp',datetime.datetime.now()).next()
    print(vpeople)
    g.addE('habite').from_(vpeople).to(vcity).next()

connection.close()


