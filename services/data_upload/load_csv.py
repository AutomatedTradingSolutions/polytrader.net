#!/usr/bin/env python3

import sys
import os
import csv

from time import time

from file_io import ReadCSV, SimpleFileWriter
from metadata_objects import Frequency
from data_object import *
import tocv
import tohlcv
from data_serialiser import SerialiseData
from time_series import Instrument, CSVUpload
from encoders import EncodeAsCSV, EncodeAsJSON
from serialisers import SerialiseAsMessage
import db_adapters as dba
import mq_adapters as mqa

if __name__ != '__main__':
  print('run as script')
  exit()

if len(sys.argv) < 6:
  print('arg error', file=sys.stderr)
  exit(99)

# arg 0 this script
# arg 1 csv filename
# arg 2 routing key for message serialisation
# arg 3 data format for serialisation
# arg 4 optional chunk size for message pumping

filename_ = sys.argv[1]
assetClassCode = sys.argv[2]
instrumentCode = sys.argv[3]
frequencyCode = sys.argv[4]
uploaderId = sys.argv[5]

routingKey_ = instrumentCode

messagesChunk = 100

if len(sys.argv) > 6:
  messagesChunk = int(sys.argv[6])

# show args
print('Script is {script}'.format(script=sys.argv[0]))
print('Filename is {filename}'.format(filename=filename_))
print('Asset class is {assetclass}'.format(assetclass=assetClassCode))
print('Instrument is {instrument}'.format(instrument=instrumentCode))
print('Frequency is {frequency}'.format(frequency=frequencyCode))

# container for non-specific csv data
class csvDataObject(DataObject):

  @staticmethod
  def AddClassMembers(members_):
    for col_ in members_:
      csvDataObject.AddClassMember(col_)
    return csvDataObject.GetClassMemberCount()

# add class members
csvDataObject.AddClassMembers( ReadCSV.GetFileCols(filename_) )
# now register with the factory
DataObjectFactory.Register(csvDataObject, FactoryRegisterKey(assetClassCode = None))

key_ = FactoryRegisterKey(assetClassCode = assetClassCode, instrumentCode = instrumentCode, freqCode = frequencyCode)
class_ = DataObjectFactory.GetClass(key_, exactKeyMatch = False)

print('Using class {cls}'.format(cls=class_.__name__))

# csv loader message broker access. localhost only.
uname_ = 'guest'
passwd_ = 'guest'
xchg_ = 'amq.topic'
xtype_ = 'topic'

# csv loader database access. localhost only.
dbuname_ = 'csvuploader'
dbpasswd_ = str()
dbname_ = 'REFDATA'

exitCode_ = 1

#encode_ = e.EncodeAsCompressedCSV(TOHLCV.Compress, , writeKeys_ = False)
# standard encoder for non-specific CSV data
encoder_ = EncodeAsCSV(encodeKeys_ = False)

serialised_ = SimpleFileWriter(filename_+'.serialised', int)

db_ = dba.PyMySQL(dbuname_, dbpasswd_, dbname_)

instrument_ = Instrument.GetDatabaseInstance(db_, EncodeAsJSON().Encode({Instrument.GetClassMember('_code').GetSourceName(): instrumentCode}))

rabbit_ = mqa.RabbitMQ(uname_, passwd_, xchg_, xtype_, routingKey_)
serialiser_ = SerialiseAsMessage(rabbit_)

serialiseData = SerialiseData(serialiser_, instrument_, class_, encoder_)

ReadCSV(filename_, serialiseData.Serialise, serialised_.Read()).Read()

if not serialiseData.IsSerialised():
  try:
    serialised_.Write(serialiseData.GetStart(0))
  except:
    print('{script} error saving bytes serialised {bytes} for {filename}'.format(script=__name__, bytes=str(serialiseData.GetStart(0)), filename=filename_))

frequency_ = Frequency.GetDatabaseInstance(db_, EncodeAsJSON().Encode({Frequency.GetClassMember('_code').GetSourceName(): frequencyCode}))

# to be determined from the data
periodStart = '20170101'
periodEnd = '20170130'

CSVUpload((filename_, frequency_.GetId(), instrument_.GetAssetClassId(), instrument_.GetId(), periodStart, periodEnd, uploaderId)).AddToDatabase(db_)

exit(exitCode_)
