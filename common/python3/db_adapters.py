#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

from abc import ABC, abstractmethod

import sys

import pymysql
import sqlalchemy
import sqlalchemy.orm as orm
import sqlalchemy.ext.declarative as declarative

_dbase = declarative.declarative_base()

import logging
import typing

from base_connect import _BaseConnect

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

# base class for database engines
class _DB(_BaseConnect):
  def __init__(self, protocol_, username_, passwd_, ip_, port_, dbname_, autoCommit):
    # example mysql connection 'mysql+pymysql://username:password@host/dbname'
    self._protocol = protocol_
    self._username = username_
    self._passwd = passwd_
    self._ip = ip_
    self._port = port_
    self._dbname = dbname_
    self._autoCommit = autoCommit
    super(_DB, self).__init__()

  @abstractmethod
  def CallProcedure(self, connection_, procName, *args_):
    pass

  def InsertIntoTable(self, connection_, tableName, *args_):
    sql_ = 'insert into {tablename} values ({args})'.format(tablename=tableName, args=args_)
    connection_.execute(sql_)

  def Delete(self, connection_, tableName, *args_):
    sql_ = 'delete from {tablename} where {args}'.format(tablename=tableName, args=args_)
    connection_.execute(sql_)

  def Update(self, connection_, tableName, sargs_, wargs_):
    set_ = [ '{field}={value}'.format(arg_.GetFirst(), arg_.GetSecond()) for arg_ in sargs_ ]
    where_ = [ '{field}={value}'.format(arg_.GetFirst(), arg_.GetSecond()) for arg_ in wargs_ ]
    sql_ = 'update {tablename} set {sargs} where {wargs}'.format(tablename=tableName, sargs=set_, wargs=where_)
    connection_.execute(sql_)

  @abstractmethod
  def Save(self, connection_):
    pass

  @abstractmethod
  def Discard(self, connection_):
    pass

# PyMySQL
class PyMySQL(_DB):

  def __init__(self, username_, passwd_, dbname_, port_ = 3306, protocol_ = None, ip_ = 'localhost', autoCommit = False):
    super(PyMySQL, self).__init__(protocol_, username_, passwd_, ip_, port_, dbname_, autoCommit)

  def _Connect(self):
    return pymysql.connect(host = self._ip, user = self._username, password = self._passwd, db = self._dbname, port = self._port, autocommit = self._autoCommit)

  def _Close(self, connection_):
    # connection_.close()
    pass

  def CallProcedure(self, connection_, procName, *args_):
    try:
      cursor_ = connection_.cursor()
      cursor_.callproc(procName, args_)
      return [ row_ for row_ in cursor_ ]
    except:
      for ei_ in sys.exc_info():
        print(ei_)
    finally:
      cursor_.close()

  def Save(self, connection_):
    connection_.commit()

  def Discard(self, connection_):
    connection_.rollback()

# SQLAlchemy+PyMySQL
class SQLAlchemy(_DB):

  def __init__(self, username_, passwd_, dbname_, port_ = 3306, protocol_ = 'mysql+pymysql', ip_ = 'localhost', autoCommit = False):
    super(SQLAlchemy, self).__init__(protocol_, username_, passwd_, ip_, port_, dbname_, autoCommit)
    self._engine = None

  def _Connect(self):
    # lazy connector
    if self._engine == None:
      self._engine = sqlalchemy.create_engine(self._protocol+'://'+self._username+':'+self._passwd+'@'+self._ip+'/'+self._dbname)
    return self._engine.connect()

  def _Close(self, connection_):
    pass

  def CallProcedure(self, connection_, procName, *args_):
    # procArgs_ = [ arg_ for arg_ in args_ ]
    try:
      sql_ = 'call {procname}({args})'.format(procname=procName, args=",".join(args_))
      result_ = connection_.execute(sql_)
      return result_
    except:
      for ei_ in sys.exc_info():
        print(ei_)
    finally:
      pass

  def Save(self, connection_):
    pass

  def Discard(self, connection_):
    pass

class MongoNoSQL(_DB):
  def __init__(self, username_, passwd_, dbname_, port_ = 27017, protocol_ = 'nosql+pymysql', ip_ = 'localhost', autoCommit = False):
    super(MongoNoSQL, self).__init__(protocol_, username_, passwd_, ip_, port_, dbname_, autoCommit)

  def _Connect(self):
    pass

  def _Close(self, connection_):
    pass

  def CallProcedure(self, connection_, procName, *args_):
    try:
      pass
    except:
      for ei_ in sys.exc_info():
        print(ei_)
    finally:
      pass

  def Save(self, connection_):
    pass

  def Discard(self, connection_):
    pass
