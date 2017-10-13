#!/usr/bin/env python3

import sys
import os
import csv

class ReadCSV:

  @staticmethod
  def GetFileFormat(file_, delimiters_ = ',;\t '):
    pos_ = file_.tell()
    file_.seek(0)
    format_ = csv.Sniffer().sniff(file_.read(1024), delimiters_)
    file_.seek(pos_)
    return format_

  # when csv file has no col headers
  @staticmethod
  def GetFileColsFromHeader(filename_):
    with open(filename_ + '.header', 'r') as file_:
      reader_ = csv.reader(file_, __class__.GetFileFormat(file_))
      return next(reader_)

  @staticmethod
  def GetFileCols(filename_):
    with open(filename_, 'r', newline = '') as file_:

      hasHeader_ = csv.Sniffer().has_header(file_.read(1024))

      if hasHeader_:
        file_.seek(0)
        reader_ = csv.reader(file_, __class__.GetFileFormat(file_))
        return next(reader_)

      return __class__.GetFileColsFromHeader(filename_)

  def __init__(self, filename_, func_, start_ = 0):
    self._filename = filename_
    self._func = func_
    self._start = start_

  def _Read(self, file_):
    dialect_ = self.GetFileFormat(file_)
    reader_ = csv.reader(file_, dialect_)
    # start_ = file_.tell()

    # for record_ in reader_:
    while True:
      start_ = reader_.line_num
      record_ = next(reader_)
      if not record_:
        break
      # next_ = file_.tell()
      next_ = reader_.line_num
      yield record_, start_, next_

  def Read(self):

    with open(self._filename, 'r', newline='') as file_:

      if self._start > 0:
        file_.seek(self._start)

      for seq_, (record_, start_, next_) in enumerate(self._Read(file_)):
        if not self._func(record_, start_, next_):
          break

class SimpleFileWriter:

  def __init__(self, filename_, class_):
    self._filename = filename_
    self._class = class_

  def Read(self):
    if not os.path.exists(self._filename):
      return self._class()

    with open(self._filename, 'r') as file_:
      data_ = file_.read()
      if len(data_) == 0:
        return self._class()
      return self._class(data_)

  def Write(self, data_, mode_ = 'w'):
    with open(self._filename, mode_) as file_:
      file_.write(data_)
