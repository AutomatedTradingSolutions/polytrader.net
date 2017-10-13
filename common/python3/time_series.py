#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import sys

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from data_object import DataObject, DataObjectFactory, FactoryRegisterKey
from math_lib import *

class TimeSeriesData:
  def __init__(self, obj_, *args_, **kwargs_):
    self._obj = obj_
    self._args = args_
    self._kwargs = kwargs_
  def GetObj(self):
    return self._obj
  def GetArgs(self):
    return self._args
  def GetArg(self, index_):
    return self._args[index_]
  def GetKeywordArgs(self):
    return self._kwargs
  def GetKeywordArg(self, keyword_):
    return self._kwargs[keyword_]

class TimeSeries:

  def __init__(self, spec_, serialiser_ = None, encoder_ = None):
    self._spec = spec_ # e.g. Instrument
    self._serialiser = serialiser_
    self._encoder = encoder_
    self._data = []

  def _GetData(self):
    return self._data

  def Add(self, obj_, *args_):
    if self._serialiser != None:
      try:
        encoded_ = self._Encode(obj_)
        self._serialiser.Serialise(encoded_)
        return
      except:
        # dump exception and obj_ add to list
        for ei_ in sys.exc_info():
          print(ei_, file=sys.stderr)

    self._GetData().append( TimeSeriesData(obj_, args_) )

  def Get(self, i):
    return self.__getitem__(i)

  def Count(self):
    return len(self._GetData())

  def SetSerialiser(self, serialiser_):
    self._serialiser = serialiser_

  def SetEncoder(self, encoder_):
    self._encoder = encoder_

  def _Encode(self, obj_):
    if self._encoder == None:
      return obj_
    return self._encoder.Encode(obj_)

  def Encode(self, obj_):
    if self._encoder == None:
      raise ValueError('{obj} _encoder not set. See SetEncoder.'.format(obj=repr(self_)))
    return _Encode(obj_)

  def Serialise(self):
    if self._serialiser == None:
      raise ValueError('{obj} _serialiser not set. See SetSerialiser.'.format(obj=repr(self)))

    try:
      while self.Count() > 0:
        obj_ = self._Encode(self._GetData()[0].GetObj())
        self._serialiser.Serialise(obj_)
        del self._data[0]
    except:
      # stop serialising and dump exception
      for ei_ in sys.exc_info():
        print(ei_, file=sys.stderr)

    return self.Count()

  def SerialiseUsing(self, serialiser_, encoder_):
    currentSerialiser_ = self._serialiser
    currentEncoder_ = self._encoder
    self.SetSerialiser(serialiser_)
    self.SetEncoder(encoder_)
    self.Serialise()
    self.SetSerialiser(currentSerialiser_)
    self.SetEncoder(currentEncoder_)
    return self.Count()

  def __getitem__(self, key):
    if self.Count() == 0:
      raise ValueError('{obj} is empty. See Add.'.format(obj=repr(self)))
    if key < 0 or key >= self.Count():
      raise ValueError('{obj} key must be in range 0,{count}'.format(obj=repr(self), count=self.Count()-1))
    return self._GetData()[key]

  def GetSpec(self):
    return self._spec
