#!/usr/bin/env python3

from data_object import DataObject
from crud import CRUD

# decorator for TimeSeries
class Instrument(DataObject):

  def GetId(self):
    return self._id

  def GetCode(self):
    return self._code

  def GetName(self):
    return self._name

  def GetAssetClassId(self):
    return self._assetClassId

  def GetDecimals(self):
    return self._decimals

Instrument.AddClassMember('_id', sourceName = 'INSTRID')
Instrument.AddClassMember('_code', sourceName = 'INSTRCODE', pkFlag = True)
Instrument.AddClassMember('_name')
Instrument.AddClassMember('_assetClassId')
Instrument.AddClassMember('_decimals')
Instrument.AddClassMember('_schemaName')

Instrument.AddCRUDMethod(CRUD.CREATE, 'AddInstrument')
Instrument.AddCRUDMethod(CRUD.READ, 'GetInstrument')
