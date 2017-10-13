#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

from abc import ABC, abstractmethod

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

# base class for all connection type classes
class _BaseConnect(ABC):
  def __init__(self):
    self._connections = {}

  @abstractmethod
  def _Connect(self):
    return None

  @abstractmethod
  def _Close(self, connection_):
    return None

  def GetConnections(self):
    return self._connections

  def IsConnection(self, cname_):
    return self.GetConnections().__contains__(cname_)

  def _MakeNewConnection(self, cname_):
    connection_ = self._Connect()
    self.GetConnections()[cname_] = connection_
    return connection_

  def GetConnection(self, cname_, makeIfNew = True):
    if self.IsConnection(cname_):
      return self.GetConnections()[cname_]
    if makeIfNew:
      return self._MakeNewConnection(cname_)
    raise ValueError(cname_ + 'connection not found error')

  def GetNewConnection(self, cname_):
    if self.IsConnection(cname_):
      raise ValueError('Connection already exists: ' + cname_)
    return self._MakeNewConnection(cname_)

  def _CloseConnections(self):
    while len(self.GetConnections()) > 0:
      key_ = next(iter(self.GetConnections()))
      self._Close(self.GetConnection(key_))
      del self._connections[key_]

  def __del__(self):
    self._CloseConnections()
