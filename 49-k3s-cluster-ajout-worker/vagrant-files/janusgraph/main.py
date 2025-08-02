#!/usr/bin/python3

from typing import Optional

from fastapi import FastAPI,Header, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from gremlin_python import statics
from gremlin_python.structure.graph import Graph
from gremlin_python.process.graph_traversal import __
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection

from typing import Optional
from pydantic import BaseModel
import datetime
import uuid

class ProductModel(BaseModel):
 title: str
 description: Optional[str] = None
 price: float
 tax: Optional[float] = None

class PostModel(BaseModel):
 gid: Optional[str] = None
 status: Optional[int] = 200
 tenant: Optional[str] = 'demo'
 title: str
 description: Optional[str] = None
 author_id: int

class RegisterUser(BaseModel):
 gid: Optional[str] = None
 email: Optional[str] = None
 phone: Optional[str] = None
 password: Optional[str] = None
 first_name: str
 last_name: Optional[str] = None
 tenant: Optional[str] = 'demo'
 
class LoginUser(BaseModel):
 email: Optional[str] = None
 phone: Optional[str] = None
 password: Optional[str] = None
 tenant: Optional[str] = 'demo'

graph = Graph()
connection = DriverRemoteConnection('ws://janus4:8182/gremlin', 'g')

# The connection should be closed on shut down to close open connections with connection.close()
g = graph.traversal().withRemote(connection)
# Reuse 'g' across the application
app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

def getTraversal():
 graph_l = Graph()
 connection_l = DriverRemoteConnection('ws://janus4:8182/gremlin', 'g')
 # The connection should be closed on shut down to close open connections with connection.close()
 g_l = graph_l.traversal().withRemote(connection_l)
 # Reuse 'g' across the application
 return g_l

@app.get("/items/{id}", response_class=HTMLResponse)
async def read_item(request: Request, id: str):
 return templates.TemplateResponse("item.html", {"request": request, "id": id})

@app.get("/")
def read_root():
 return {"Hello": "World"}

@app.get("/beliefs")
def read_beliefs(token: Optional[str] = Header(None)):
 label = 'BELIEF'
 
 beliefs = g.V().hasLabel(label).has('status',200).valueMap(True).toList()
 return beliefs

@app.get("/join/{user}/{type}/{belief}")
def join_vertices(request: Request, user: str, type: str, belief: str):
  print(user)
  g.V(user).addE(type).to(g.V(belief)).next()
  return {'s':200}

@app.get("/users")
def users(token: Optional[str] = Header(None)):
 label = 'USER'
 
 list = g.V().hasLabel(label).valueMap(True).toList()
 return list

def addV(label, data):
 print("label:",label, "data:", data)
 g_l = getTraversal()
  
 if 'gid' not in data or data['gid'] is None:
  data['gid'] = uuid.uuid1()
 if 'tenant' not in data or data['tenant'] is None:
  data['tenant'] = 'opac'
 if 'status' not in data or data['status'] is None:
  data['status'] = 200
 exists = g_l.V().hasLabel(label).has('gid',data['gid']).hasNext()
 if exists :
   v = g_l.V().hasLabel(label).has('gid',data['gid']).property('status',data['status']).next()  
 else:
   g_l.addV(label).property('gid',data['gid']).property('created_at',datetime.datetime.now()).property('updated_at',datetime.datetime.now()).next() 
   v = g_l.V().hasLabel(label).has('gid',data['gid']).next()
 
 qu = g_l.V().hasLabel(label).has('gid',data['gid'])
 for key in data.keys():
   qu.property(key,data[key]) 
 qu.next()
 return {'s':200}
 
@app.get("/load")
def load(token: Optional[str] = Header(None)):
 list1 = [{'status':200,'title':'Hinduism','slug':'hinduism','gid':'hinduism'},
    {'status':200,'title':'Buddhism','slug':'buddhism','gid':'buddhism'},
    {'status':200,'title':'Islam','slug':'islam','gid':'islam'},
    {'status':200,'title':'Christianity','slug':'christianity','gid':'Christianity'},
    {'status':200,'title':'Ghandhism','slug':'ghandhism','gid':'ghandhism'},
    {'status':200,'title':'Truth','slug':'truth','gid':'truth'},
    {'status':200,'title':'Logic','slug':'logic','gid':'logic'},
    {'status':200,'title':'Science','slug':'science','gid':'science'},
    {'status':200,'title':'Faith','slug':'faith','gid':'faith'}]
 for item in list1:
   addV('BELIEF', item)
 users = [
    {'status':200, 'first_name':'John','last_name':' QA', 'email':'sqa1@g.com','password':'qa', 'phone':'+91-1234567891','tenant':'opac','is_admin':'Y'},
    {'status':200, 'first_name':'Loki','last_name':' QA', 'email':'sqa2@g.com','password':'qa', 'phone':'+91-1234567892','tenant':'opac','is_admin':'Y'},
    {'status':200, 'first_name':'Tina','last_name':' QA', 'email':'sqa3@g.com','password':'qa', 'phone':'+91-1234567893','tenant':'opac','is_admin':'N'},
    {'status':200, 'first_name':'Vayu','last_name':' QA', 'email':'sqa4@g.com','password':'qa', 'phone':'+91-1234567894','tenant':'opac','is_admin':'N'},
    {'status':200, 'first_name':'Beet','last_name':' QA', 'email':'sqa5@g.com','password':'qa', 'phone':'+91-1234567895','tenant':'opac','is_admin':'N'},
    {'status':200, 'first_name':'Sam','last_name':' QA', 'email':'sqa6@g.com','password':'qa', 'phone':'+91-1234567896','tenant':'opac','is_admin':'N'},
    {'status':200, 'first_name':'Nora','last_name':' QA', 'email':'sqa7@g.com','password':'qa', 'phone':'+91-1234567897','tenant':'opac','is_admin':'N'},
    {'status':200, 'first_name':'Daniel','last_name':' QA', 'email':'sqa8@g.com','password':'qa', 'phone':'+91-1234567898','tenant':'opac','is_admin':'N'},]
 for item in users:
   addV('USER', item)

