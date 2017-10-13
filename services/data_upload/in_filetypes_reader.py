#!/usr/bin/env python3

import sys
from bs4 import BeautifulSoup

# arg 0 this script name
# arg 1 filetype code e.g. ohlc
# arg n branch name and optional branch attributes

minArgs_ = 2

if minArgs_ > len(sys.argv):
  print('arg error', file=sys.stderr)
  exit(99)

exitCode_ = 1 # default should file open fail

def getArg(arg_):
  return arg_.partition('=')[0]

def getAttributes(arg_):

  i = arg_.find('=')

  if i < 0:
    return {}

  str_ = arg_.partition('=')[2]
  dict_ = {}
  attributes_ = str_.split()

  for attr_ in attributes_:
    p_ = attr_.partition(':')
    #dict_.update({p_[0]: p_[2]})
    dict_[p_[0]] = p_[2]

  return dict_

with open('in_filetypes.xml', 'r') as file_:

  try:
    config_ = file_.read()
    soup_ = BeautifulSoup(config_, 'xml')
    branch_ = soup_.find('filetypes')

    for arg_ in sys.argv[1:]:
      branch_ = branch_.find(getArg(arg_), getAttributes(arg_))

    print(branch_.getText(separator = ' ', strip = True))

    exitCode_ = 0

  except AttributeError as err_:
      exitCode_ = 2
      print('%s not found error' % err_, file=sys.stderr)

  except:
    exitCode_ = 3
    [ print(ei_, file=sys.stderr) for ei_ in sys.exc_info() ]

exit(exitCode_)
