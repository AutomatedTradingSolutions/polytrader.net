#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import sys

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from data_object import DataObject

class AssetClass(DataObject):

  @staticmethod
  def GetterProcedureName():
    return 'GetAssetClass'

  @classmethod
  def GetDatabaseInstance(class_, db_, filter_):
    connection_ = db_.GetConnection('ro')
    result_ = db_.CallProcedure(connection_, __class__.GetterProcedureName(), filter_)
    if len(result_) != 1:
      raise ValueError('{instance} not found error'.format(instance=filter_))
    row_ = result_[0]
    return class_(row_)

  def GetId(self):
    return self._id

  def GetCode(self):
    return self._code

  def GetName(self):
    return self._name

AssetClass.AddClassMember('_id')
AssetClass.AddClassMember('_code', sourceName = 'ASSCLSCODE', pkFlag = True)
AssetClass.AddClassMember('_name')

class Frequency(DataObject):

  @staticmethod
  def GetterProcedureName():
    return 'GetFrequency'

  @classmethod
  def GetDatabaseInstance(class_, db_, filter_):
    connection_ = db_.GetConnection('ro')
    result_ = db_.CallProcedure(connection_, __class__.GetterProcedureName(), filter_)
    if len(result_) != 1:
      raise ValueError('{instance} not found error'.format(instance=filter_))
    row_ = result_[0]
    return class_(row_)

  def GetId(self):
    return self._id

  def GetCode(self):
    return self._code

  def GetName(self):
    return self._name

Frequency.AddClassMember('_id')
Frequency.AddClassMember('_code', sourceName = 'FREQCODE', pkFlag = True)
Frequency.AddClassMember('_name')
