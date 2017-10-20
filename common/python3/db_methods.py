#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import sys

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from data_object import DataObject

class GetDatabaseInstance:

  def __init__(self, db_):
    self._db = db_

  def Select(self, class_, procName, filter_, recordsExpected = None):
    connection_ = self._db.GetConnection('ro')
    result_ = self._db.CallProcedure(connection_, procName, filter_)
    if recordsExpected != None and len(result_) != recordsExpected:
      raise ValueError('Got {actual} record(s) but expected {expected}'.format(actual=len(result_), expected=recordsExpected))
    return [ class_(row_) for row_ in result_ ]

  def Insert(self):
    pass

  def Update(self):
    pass

  def Delete(self):
    pass
