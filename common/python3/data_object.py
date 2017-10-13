#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import hashlib

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

from math_lib import GetFloatDiffAsInt

class Pair:
  def __init__(self, first_, second_):
    self._first = first_
    self._second = second_

  def GetFirst(self):
    return self._first

  def GetSecond(self):
    return self._second

class FactoryRegisterKey:
  def __init__(self, *args_, **kwargs_):
    self._args = args_
    self._kwargs = kwargs_
    self._hash = self._GetHash()

  def IsKey(self, key_):
    # return hasattr(key_, '_args') and hasattr(key_, '_kwargs')
    return isinstance(key_, type(self))

  def __eq__(self, key_):
    if self.IsKey(key_):
      return self._args == key_._args and len(self._kwargs.keys - key_._kwargs.keys) == 0 and len(self._kwargs.items - key_._kwargs.items) == 0
    return False

  def _CompareArgs(self, key_):
    #return set(key_._args) <= set(self._args)
    subset_ = [ arg_ for arg_ in self._args if arg_ in key_._args ]
    return subset_ if len(subset_) == len(self._args) else []

  def _CompareKeywordArgs(self, key_):
    keyMatch = [ k for k in self._kwargs.keys() if k in key_._kwargs.keys() ]
    #keyMatch = [ k for k in ( key_._kwargs.keys() & self._kwargs.keys() ) ]
    if len(keyMatch) == len(self._kwargs.keys()):
      res_ = { k: self._kwargs[k] for k in keyMatch if self._kwargs[k] in key_._kwargs.values() }
      if len(res_) == len(self._kwargs):
        return res_
      #for k in keyMatch:
      #  if key_._kwargs[k] == self._kwargs[k]:
      #    ret_[k] = key_._kwargs[k]

    return {}

  def Compare(self, key_):
    if not self.IsKey(key_):
      return float()

    bestMatch = len(key_._args) + len(key_._kwargs)

    if bestMatch == 0:
      return float()

    match_ = len( self._CompareArgs(key_) )

    match_ += len( self._CompareKeywordArgs(key_) )

    return float(match_ / bestMatch)

  def __hash__(self):
    return self._hash

  def _GetHash(self):
    return hash(self.AsStr())

  def __str__(self):
    return self.AsStr()

  def AsStr(self, delim_ = '.'):
    return delim_.join(self._args) + \
      delim_ if len(self._args) > 0 else str() + \
      delim_.join("{key}={val}".format(key=str(key_), val=str(val_)) for (key_, val_) in self._kwargs.items())

class DataObjectFactory:
  _dataObject = {}
  _id = 0

  @staticmethod
  def GetRegister():
    return __class__._dataObject

  @staticmethod
  def GetRegistered(key_):
    return __class__.GetRegister()[key_]

  @staticmethod
  def _GetNewKey():
    __class__._id += 1
    return FactoryRegisterKey(id_ = __class__._id)

  @staticmethod
  def IsRegistered(key_):
    return __class__.GetRegister().__contains__(key_)

  @staticmethod
  def Register(class_, key_ = None):
    if key_ == None:
      key_ = __class__._GetNewKey()
    if __class__.IsRegistered(key_):
      raise ValueError("{key} is already registered".format(key=key_))
    __class__.GetRegister()[key_] = class_
    return key_

  @staticmethod
  def _IsThisClass(key_, class_):
    return class_ == __class__.GetRegistered(key_) or class_ == None

  @staticmethod
  def Find(key_, class_ = None):
    best_ = float()
    keys_ = []
    for k in __class__.GetRegister():
      if __class__._IsThisClass(k, class_):
        cmp_ = k.Compare(key_)
        if cmp_ > best_:
          keys_.clear()
          keys_.append(k)
          best_ = cmp_
        elif cmp_ == best_:
          keys_.append(k)

    return Pair(best_, keys_)

  @staticmethod
  def _Find(key_, class_ = None):
    pair_ = __class__.Find(key_, class_)

    if len(pair_.GetSecond()) == 1:
      return __class__.GetRegistered(pair_.GetSecond()[0])

    return None

  @staticmethod
  def GetClass(key_, exactKeyMatch = True):
    if __class__.IsRegistered(key_):
      return __class__.GetRegistered(key_)

    if exactKeyMatch:
      return None

    return __class__._Find(key_)

  @staticmethod
  def GetInstance(key_, type_ = None, exactKeyMatch = True, *args_):
    class_ = __class__.GetClass(key_, exactKeyMatch = True)

    if class_ == None and not exactKeyMatch:
      return __class__._Find(key_, type_)

    if class_ != None:
      return class_(args_)

    return None

class DataObjectMemberAttributes:
  def __init__(self, memberName, sourceName = None, pkFlag = False, constructorFlag = True, setFlag = False):
    self._memberName = memberName
    self._sourceName = sourceName
    self._pkFlag = pkFlag
    self._constructorFlag = constructorFlag
    self._setFlag = setFlag

  def GetMemberName(self):
    return self._memberName

  def GetSourceName(self):
    return self._sourceName

  def GetPKFlag(self):
    return self._pkFlag

  def GetConstructorFlag(self):
    return self._constructorFlag

  def GetSetFlag(self):
    return self._setFlag

  def __eq__(self, obj_):
    for attr_ in ('_memberName', '_sourceName', '_pkFlag', '_constructorFlag', '_setFlag'):
      if not (getattr(self, attr_) == getattr(obj_, attr_) or getattr(obj_, attr_) == None):
        return False
    return True

  #def __hash__(self):
  #  return self._memberName

# base class for all application specific data types
class DataObject:
  _classMembers = {}

  @classmethod
  def GetClassMembers(class_):
    if not class_._classMembers.__contains__(class_):
      class_._classMembers[class_] = []
    return class_._classMembers[class_]

  @classmethod
  def GetClassMemberCount(class_, filter_ = None):
    if filter_ == None:
      return len(class_.GetClassMembers())
    return len( [ m_ for m_ in class_.GetClassMembers() if filter_(m_) ] )

  @classmethod
  def GetClassMember(class_, memberName):
    member_ = [ m_ for m_ in class_.GetClassMembers() if m_.GetMemberName() == memberName ]
    if len(member_) != 1:
      raise ValueError('{member} did not return 1'.format(member=memberName))
    return member_[0]

  @classmethod
  def AddClassMember(class_, memberName, sourceName = None, pkFlag = False, constructorFlag = True, setFlag = False):
    class_.GetClassMembers().append(DataObjectMemberAttributes(memberName, sourceName, pkFlag, constructorFlag, setFlag))

  @classmethod
  def AddClassMemberInstance(class_, dataObjectMember):
    class_.GetClassMembers().append(dataObjectMember)

  @classmethod
  def GetInstance(class_, *args_, **kwargs_):
    return class_(args_)

  def __init__(self, argArray_):

    if len(argArray_) != self.GetClassMemberCount(lambda m_ : m_.GetConstructorFlag()):
      raise ValueError('args error')

    i = 0
    for m_ in self.GetClassMembers():
      setattr(self, m_.GetMemberName(), argArray_[i] if m_.GetConstructorFlag() else None)
      if m_.GetConstructorFlag():
        i += 1

    self._customAttribute = []

  def Get(self, memberName):
    return self.__getitem__(memberName)

  def Set(self, memberName, value_):
    if len([ True for m_ in self.GetClassMembers() if m_.GetMemberName() == memberName ]) == 0:
      raise ValueError('{m} cannot be set'.format(m=memberName))
    return setattr(self, memberName, value_)

  def __getitem__(self, memberName):
    return getattr(self, memberName)

  def __iter__(self):
    self._iter = 0
    return self

  def __next__(self):
    #for member_ in self.GetClassMembers():
    #  yield member_

    #for x in self.GetAttributes():
    #  yield x

    if self._iter >= self.GetClassMemberCount():
      raise StopIteration

    m_ = self.GetClassMembers()[self._iter].GetMemberName()
    self._iter += 1
    return m_

  def __str__(self):
    str_ = ''
    i = 0
    for m_ in self:
      if i > 0:
        str_ = str_ + ', '
      str_ += str(m_) + ' = ' + str(self.Get(m_))
      i = i + 1

    return str_

  # metadata style access to class members
  # fundamental data can be optionally added
  # types of fundamental data can vary by asset type

  def AddAttribute(self, name_, value_):
    if not hasattr(self, name_):
      self.GetAttributes().append(name_)
      setattr(self, name_, value_)

  def GetAttribute(self, name_):
    if hasattr(self, name_):
      return getattr(self, name_)
    print('Undefined attribute' + name_)

  def GetAttributes(self):
    return self._customAttribute

  def RemoveAttribute(self, name_):
    if hasattr(self, name_):
      delattr(self, name_)
      self.GetAttributes().remove(name_)
