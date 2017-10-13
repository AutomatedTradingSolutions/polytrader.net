#!/usr/bin/env python3

# start with the python debugger. should be commented before release.
import pdb

import logging
import typing

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('sqla.engine.base').setLevel(logging.DEBUG)

def isPrimeNumber(number):
  return number > 1 and not (number % 2 == 0 or number % 3 == 0)

def getPrimeNumbers(start, end = 0):
  # validate
  if start < 2:
    start = 2
    if end < start:
      end = start
  # calc primes and stuff into an array
  return [ p for p in range(start, end+1) if isPrimeNumber(p) ]

def GetFloatDiffAsInt(p1, p2, decimals_):
  p = int(10**decimals_)
  i1 = int(p1 * p)
  i2 = int(p2 * p)
  return i1-i2
