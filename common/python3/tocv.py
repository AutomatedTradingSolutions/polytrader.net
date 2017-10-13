#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import time

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from data_object import FactoryRegisterKey, DataObjectFactory, DataObject
from math_lib import GetFloatDiffAsInt

class TOCV(DataObject):

  def _Compress(self, price_, decimals_):
    return GetFloatDiffAsInt(price_, self.GetOpen(), decimals_)

  @staticmethod
  def Compress(obj_, name_, objSpec):
    if obj_.GetCompressionKey().__contains__(name_):
      return obj_._Compress(obj_.Get(name_), objSpec())
    return obj_.Get(name_)

  def GetCompressionKey(self):
    if self._compressionKey == None:
      self._compressionKey = frozenset(['_close'])
    return self._compressionKey

  def _Expand(self, price_, decimals_):
    return self.GetOpen() + ( price_ * (1.0 / decimals_) )

  @staticmethod
  def Expand(obj_, name_, objSpec):
    if obj_.GetExpansionKey().__contains__(name_):
      return obj_._Expand(obj_.Get(name_), objSpec())
    return obj_.Get(name_)

  def GetExpansionKey(self):
    if self._expansionKey == None:
      self._expansionKey = frozenset(['_close'])
    return self._expansionKey

  def GetTime(self):
    return self._time

  def GetOpen(self):
    return self._open

  def GetClose(self):
    return self._close

  def GetVolume(self):
    return self._volume

  def GetTimeAsStr(self):
    return str(self.GetTime().tm_year) \
      + str(self.GetTime().tm_mon) \
      + str(self.GetTime().tm_mday) \
      + str(self.GetTime().tm_hour) \
      + str(self.GetTime().tm_min) \
      + str(self.GetTime().tm_sec)

  def GetSimpleAvg(self):
    return (self.GetOpen() + self.GetClose()) / 2

TOCV.AddClassMember('_time', pkFlag = True)
TOCV.AddClassMember('_open')
TOCV.AddClassMember('_close')
TOCV.AddClassMember('_volume')

# register by asset class and frequency = tick
DataObjectFactory.Register( TOCV, FactoryRegisterKey(assetClassCode = 'SPTFX', freqCode = 'TICK') )
