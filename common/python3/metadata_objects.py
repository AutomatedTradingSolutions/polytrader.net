#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import sys

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from data_object import DataObject
from crud import CRUD

class AssetClass(DataObject):

  def GetId(self):
    return self._id

  def GetCode(self):
    return self._code

  def GetName(self):
    return self._name

AssetClass.AddClassMember('_id')
AssetClass.AddClassMember('_code', sourceName = 'ASSCLSCODE', pkFlag = True)
AssetClass.AddClassMember('_name')

AssetClass.AddCRUDMethod(CRUD.READ, 'GetAssetClass')

class Frequency(DataObject):

  def GetId(self):
    return self._id

  def GetCode(self):
    return self._code

  def GetName(self):
    return self._name

Frequency.AddClassMember('_id')
Frequency.AddClassMember('_code', sourceName = 'FREQCODE', pkFlag = True)
Frequency.AddClassMember('_name')

Frequency.AddCRUDMethod(CRUD.READ, 'GetFrequency')
