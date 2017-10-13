#!/bin/bash

# $1 = config code, $2 = dir code
function GetConfig
{
  _config=$(python3.5 in_filetypes_reader.py $1 $2)
  _res=$?
  if (( $_res != 0 )); then
    echo < 2
    exit $_res
  fi
  echo $_config
}

# $1 = filename
function LoadFile
{
  csvFile=$1

  if [[ ! -e "$inDir$csvFile" ]]; then
    echo "File not found $inDir$csvFile"
    return
  fi

  mv $inDir$csvFile $processingDir
  _res=$?

  if (( $_res != 0 )); then
    echo "File $inDir$csvFile"
    return
  fi

  python3.5 load_csv.py $processingDir$csvFile &

  procId=$!

  processList+="$procId=$csvFile"

  #while read whenTime, openPrice, highPrice, lowPrice, closePrice, volTraded
  #{
  #  if [[ $? ]]
  #} < $1
}

# no args
function LoadAllFiles
{
  for csvFile in $(ls ($inDir)*.csv 2>/dev/null)
  do
    if [[ -f "$csvFile" ]]; then
      LoadFile "$csvFile"
    fi
  done
}

# $1 = filename, $2 = pid
function MoveFile
{
  if 
  mv $processingDir$1 $doneDir
}

configCode=ohlc

baseDir=$(GetConfig $configCode basedir)
inDir=$baseDir$(GetConfig $configCode indir)
processingDir=$baseDir$(GetConfig $configCode wipdir)
errDir=$baseDir$(GetConfig $configCode errdir)
doneDir=$baseDir$(GetConfig $configCode donedir)

processList=( )

# if no args then load all .csv files in directory
# $1 = file to load
# is a file?

if [[ -z "$1" ]]; then
  LoadAllFiles
fi

if [[ -e "$1" ]]; then
  LoadFile "$1"
fi

for p in "${processList[@]}"; do
  wait -n
done



function Validate
  mysql -sN -u guest GetInstrumentNames
  for iname in $()
  if (( $1 <= $2 && 
