#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import time

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from tocv import TOCV
from data_object import FactoryRegisterKey, DataObjectFactory

class TOHLCV(TOCV):

  def GetCompressionKey(self):
    if self._compressionKey == None:
      self._compressionKey = frozenset(['_high', '_low']).union(super(__class__, self).GetCompressionKey())

    return self._compressionKey

  def GetExpansionKey(self):
    if self._expansionKey == None:
      self._expansionKey = frozenset(['_high', '_low']).union(super(__class__, self).GetExpansionKey())

    return self._expansionKey

  def GetHigh(self):
    return self._high

  def GetLow(self):
    return self._low

  def GetSimpleAvg(self):
    return (self.GetOpen() + self.GetHigh() + self.GetLow() + self.GetClose()) / 4

TOHLCV.AddClassMember('_high')
TOHLCV.AddClassMember('_low')

# register by asset class
DataObjectFactory.Register(TOHLCV, FactoryRegisterKey(assetClassCode = 'SPTFX'))
