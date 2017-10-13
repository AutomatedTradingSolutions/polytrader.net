#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

from abc import ABC, abstractmethod

#import pymysql
#import sqlalchemy as sqla
#import sqlalchemy.orm as orm
#import sqlalchemy.ext.declarative as declarative

#_dbase = declarative.declarative_base()

import kombu

import logging
import typing

from mq_adapters import *
from db_adapters import *

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

class ObjectSerialiser(ABC):
  @abstractmethod
  def Serialise(self, obj_):
    pass

# concrete implementation for o/s file serialisation
class SerialiseAsFile(ObjectSerialiser):

  def __init__(self, filename_, mode_ = 'a'):
    self._filename = filename_
    self._mode = mode_

  def Serialise(self, obj_):
    with open(self._filename, self._mode) as file_:
      file_.write(obj_)

# concrete implementation for message broker serialisation
class SerialiseAsMessage(ObjectSerialiser):

  # use localhost only credentials e.g. guest
  # serialise service should be co-located with broker service
  def __init__(self, mq_):
    self._mq = mq_

  def Serialise(self, obj_):
    connection_ = self._mq.GetConnection(str(id(self)))
    self._mq.Publish(connection_, obj_)

# concrete implementation for database serialisation
# decorated with a _DB object
class SerialiseInDB(ObjectSerialiser):

  def __init__(self, db_, tableName_, procName_):
    self._db = db_
    self._tableName = tableName_
    self._procName = procName_

  def Serialise(self, obj_):

    connection_ = self._db.GetConnection(str(id(self)))
    # record_ = OHLC_ORM(self._tablename, obj_)

    # conn_.execute('call add_ohlc()')
    if self._procName != None:
      self._db.CallProcedure(connection_, self._procName, obj_)

    if self._tableName != None:
      self._db.Insert(connection_, self._tableName, obj_)

    #db_ = declarative.declarative_base()
    _dbase.metadata.create_all(engine_)

    # create session for objects group
    Session_ = orm.session_maker(bind = engine_)
    session_ = orm.Session()
    session.add(record_)
    session.flush()
    session.commit()
