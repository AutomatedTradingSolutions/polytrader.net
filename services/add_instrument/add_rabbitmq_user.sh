#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Virtual host arg not given. Exiting."
  return 99
fi

uname=pricedata_service

echo "Declaring user "$uname

python3 $PYTHONPATH/rabbitmqadmin.py declare user name=$uname password= tags=
python3 $PYTHONPATH/rabbitmqadmin.py declare permission vhost=$1 user=$uname configure='' write='*.stream.out|*.stream.in.err' read='*.stream.in|*.stream.in.ser'
