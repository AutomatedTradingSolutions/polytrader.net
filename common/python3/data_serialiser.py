#!/usr/bin/env python3

import sys
import os
import csv

from data_object import *
from time_series import TimeSeries
import encoders as e
import serialisers as s

class SerialiseData:

  def __init__(self, serialiser_, instrument_, dataobject_, encoder_ = None, chunk_ = 0):
    self._serialiser = serialiser_
    self._timeSeries = TimeSeries(instrument_)
    self._dataobject = dataobject_
    self._encoder = encoder_
    self._chunk = chunk_

    self._recs = 0
    self._unserialised = 0

  def GetTimeSeries(self):
    return self._timeSeries

  def GetStart(self, timeSeriesIndex):
    return self.GetTimeSeries()[timeSeriesIndex].GetArg(0)

  def GetEnd(self, timeSeriesIndex):
    return self.GetTimeSeries()[timeSeriesIndex].GetArg(1)

  def IsSerialised(self):
    return self._unserialised == 0

  def __Serialise(self, encoder_ = None):
    self._unserialised = self.GetTimeSeries().SerialiseUsing(self._serialiser, encoder_)
    self._recs = 0
    return self.IsSerialised()

  def _Serialise(self, force_ = False):
    if force_ or self._recs >= self._chunk:
      self.__Serialise(self._encoder)

    return self.IsSerialised()

  def Serialise(self, record_, start_ = 0, next_ = 0):
    if self._unserialised > 0:
      return self._Serialise(force_ = True)

    if len(record_) == self._dataobject.GetClassMemberCount():
      obj_ = self._dataobject(record_)
      self.GetTimeSeries().Add(obj_, start_, end_)
      self._recs += 1
      return self._Serialise()

    # unknown record type when here
    # flush records before adding unknown
    if not self._Serialise(force_ = True):
      return False

    obj_ = ",".join(record_)
    self.GetTimeSeries().Add(obj_)

    return self.__Serialise()
