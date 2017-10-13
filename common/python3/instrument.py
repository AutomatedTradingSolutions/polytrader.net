#!/usr/bin/env python3

from data_object import DataObject

# decorator for TimeSeries
class Instrument(DataObject):

  @staticmethod
  def GetterProcedureName():
    return 'GetInstrument'

  @classmethod
  def GetDatabaseInstance(class_, db_, filter_):
    connection_ = db_.GetConnection('ro')
    #id_ = None
    #name_ = None
    #assetClass_ = None
    #decimals_ = None
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
