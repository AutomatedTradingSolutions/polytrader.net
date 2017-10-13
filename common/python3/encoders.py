#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

from abc import ABC, abstractmethod

from xml.dom import minidom

import json

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

class ObjectEncoder(ABC):
  def __init__(self, objDataFilter, getKeyFunc, getValueFunc):
    self._objDataFilter = objDataFilter
    self._getKeyFunc = getKeyFunc
    self._getValueFunc = getValueFunc

  def _GetObjDataFilter(self, obj_, x):
    return self._objDataFilter(obj_, x)

  def _GetKeyFunc(self, obj_, x):
    return self._getKeyFunc(obj_, x)

  def _GetValueFunc(self, obj_, x):
    return self._getValueFunc(obj_, x)

  @abstractmethod
  def Encode(self, obj_):
    pass

class EncodeAsCSV(ObjectEncoder):

  def __init__(self, objDataFilter = lambda obj_, x : True, getKeyFunc = lambda obj_, x : x, getValueFunc = lambda obj_, x : obj_[x], encodeKeys_ = True, delim_ = ',', endOfRecord = '\n\r', quote_ = None):
    self._encodeKeys = encodeKeys_
    self._keysEncoded = False
    self._delim = delim_
    self._endOfRecord = endOfRecord
    self._quote = quote_
    super(EncodeAsCSV, self).__init__(objDataFilter, getKeyFunc, getValueFunc)

  def _Quote(self, str_):
    if self._quote == None:
      return str_
    return self._quote + str_ + self._quote

  def _GetEndOfRecord(self):
    return self._endOfRecord

  def _GetKeys(self, obj_):
    return self._delim.join(_Quote(str(self._GetKeyFunc(obj_, x))) for x in obj_ if self._GetObjDataFilter(obj_, x))

  def _GetValues(self, obj_):
    return self._delim.join(_Quote(str(self._GetValueFunc(obj_, x))) for x in obj_ if self._GetObjDataFilter(obj_, x))

  def Encode(self, obj_):
    result_ = self._GetValues(obj_)
    if len(result_) > 0:
      result_ += self._GetEndOfRecord()
    if self._encodeKeys and not self._keysEncoded:
      keys_ = self._GetKeys(obj_)
      if len(keys_) > 0:
        result_ = keys_ + self._GetEndOfRecord() + result_
      self._keysEncoded = True
    return result_

class EncodeAsCompressedCSV(EncodeAsCSV):

  def __init__(self, getValueFunc, objSpec, objDataFilter = lambda obj_, x : True, getKeyFunc = lambda obj_, x : x, encodeKeys_ = True, delim_ = ',', endOfRecord = '\n\r', quote_ = None):
    self._objSpec = objSpec_
    super(EncodeAsCompressedCSV, self).__init__(objDataFilter, getKeyFunc, getValueFunc, encodeKeys_, delim_, endOfRecord, quote_)

  def _GetValues(self, obj_):
    return self._delim.join(_Quote(str(self._GetValueFunc(obj_, x, self._objSpec))) for x in obj_ if self._GetObjDataFilter(obj_, x))

class EncodeAsXML(ObjectEncoder):

  def __init__(self, element_, attributeFilter = lambda obj_, x : False, objDataFilter = lambda obj_, x : True, getKeyFunc = lambda obj_, x : x, getValueFunc = lambda obj_, x : obj_[x]):
    self._element = element_
    self._attributeFilter = attributeFilter
    super(EncodeAsXML, self).__init__(objDataFilter, getKeyFunc, getValueFunc)
    self._doc = None

  def Encode(self, obj_):
    # lazy doc setup
    if self._doc == None:
      self._doc = minidom.Document()

    # root_ = doc_.createElement('root')
    # doc_.appendChild(root_)
    element_ = doc_.createElement(self._element)

    pk_ = { self._GetKeyFunc(obj_, x): self._GetValueFunc(obj_, x) for x in obj_ if self._attributeFilter(obj_, x)}

    for x in pk_:
      element_.setAttribute(x, pk_[x])

    data_ = set(pk_) - set({ self._GetKeyFunc(obj_, x): self._GetValueFunc(obj_, x) for x in obj_ if self._GetObjDataFilter(obj_, x) })

    for tag_ in data_:
      element_ = doc_.createElement(tag_)
      value_ = doc_.createTextNode(data_[tag_])
      element_.appendChild(value_)

    return doc_.toprettyxml()

  def _Close(self):
    if self._doc != None:
      self._doc.unlink()
      self._doc = None

  def __del__(self):
    self._Close()

class EncodeAsJSON(ObjectEncoder):

  def __init__(self, indent_ = None, separators_ = (',', ':'), objDataFilter = lambda obj_, x : True, getKeyFunc = lambda obj_, x : x, getValueFunc = lambda obj_, x : obj_[x]):
    self._indent = indent_
    self._separators = separators_
    super(EncodeAsJSON, self).__init__(objDataFilter, getKeyFunc, getValueFunc)

  def Encode(self, obj_):

    #dict_ = {}
    #AddToDict = lambda collection_, pair_ : collection_.__setitem__(pair_.GetFirst(), pair_.GetSecond())
    #obj_.AsArray(memberFilter = self.GetObjDataFilter(), AddToCollection = AddToDict, collection_ = dict_)

    container_ = [ self._GetValueFunc(obj_, x) for x in obj_ if self._GetObjDataFilter(obj_, x) ] if self._getKeyFunc == None \
      else { self._GetKeyFunc(obj_, x): self._GetValueFunc(obj_, x) for x in obj_ if self._GetObjDataFilter(obj_, x) }

    encoded_ = json.dumps(container_, indent = self._indent, separators = self._separators)

    return encoded_

  def _Close(self):
    pass

  def __del__(self):
    self._Close()

class EncodeAsHTML(ObjectEncoder):

  def __init__(self, element_, objDataFilter = lambda obj_, x : True, getKeyFunc = lambda obj_, x : x, getValueFunc = lambda obj_, x : obj_[x]):
    self._element = element_
    super(EncodeAsHTML, self).__init__(objDataFilter, getKeyFunc, getValueFunc)
    self._doc = None

  # table
  def Encode(self, obj_):
    pass
