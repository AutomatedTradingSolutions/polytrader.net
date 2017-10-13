#!/usr/bin/env python3

from data_object import DataObject
from instrument import Instrument
from encoders import EncodeAsJSON

class CSVUpload(DataObject):

  @staticmethod
  def GetterProcedureName():
    return 'GetCSVUpload'

  @classmethod
  def GetDatabaseInstance(class_, db_, filter_):
    connection_ = db_.GetConnection('ro')
    result_ = db_.CallProcedure(connection_, __class__.GetterProcedureName(), filter_)
    if len(result_) != 1:
      raise ValueError('{instance} not found error'.format(instance=filter_))
    row_ = result_[0]
    return class_(row_)

  def AddToDatabase(self, db_):
    objDataFilter_ = lambda obj_, m_ : obj_.GetClassMember(m_).GetConstructorFlag()
    getKeyFunc_ = lambda obj_, m_ : obj_.GetClassMember(m_).GetSourceName()
    getValueFunc_ = lambda obj_, m_ : obj_[m_]
    doc_ = EncodeAsJSON(objDataFilter = objDataFilter_, getKeyFunc = getKeyFunc_, getValueFunc = getValueFunc_).Encode(self)
    connection_ = db_.GetNewConnection(str(id(self)))
    schemaName = Instrument.GetDatabaseInstance(db_, EncodeAsJSON().Encode({Instrument.GetClassMember('_id').GetSourceName(): self.Get('_instrumentId')})).Get('_schemaName')
    result_ = db_.CallProcedure(connection_, schemaName+'.AddCSVUpload', doc_)
    if len(result_) != 1:
      raise ValueError('{instance} not added error'.format(instance=self))
    row_ = result_[0]
    db_.Save(connection_)
    return row_

CSVUpload.AddClassMember('_id', sourceName = 'CSVUPID', pkFlag = True, constructorFlag = False)
CSVUpload.AddClassMember('_filename', sourceName = 'CSVUPFILE')
CSVUpload.AddClassMember('_frequencyId', sourceName = 'CSVUPFREQ')
CSVUpload.AddClassMember('_assetClassId', sourceName = 'CSVUPASSCLS')
CSVUpload.AddClassMember('_instrumentId', sourceName = 'CSVUPINSTR')
CSVUpload.AddClassMember('_uploadTimestamp', sourceName = 'CSVUPTIME', constructorFlag = False)
CSVUpload.AddClassMember('_periodStart', sourceName = 'CSVUPSTART')
CSVUpload.AddClassMember('_periodEnd', sourceName = 'CSVUPEND')
CSVUpload.AddClassMember('_uploaderId', sourceName = 'CSVUPLOADID')
