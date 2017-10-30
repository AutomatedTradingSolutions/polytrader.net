#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Virtual host arg not given. Exiting."
  return 99
fi

if [[ -z "$2" ]]; then
  echo "Instrument code not given. Exiting."
  return 99
fi

echo "Declaring queues for virtual host "$1

source=PRICEDATA

python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination="$2.stream.in" routing_key="$2.stream.in.#" arguments='{"method":"POST"}'
python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination="$2.stream.in.ser" routing_key="$2.stream.in.#" arguments='{"method":"POST"}'
python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination="$2.stream.in.err" routing_key="$2.stream.in.err.#" arguments=''
python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination="$2.stream.out" routing_key="$2.stream.out.#" arguments=''

python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination=$2.request routing_key="$2.request" arguments='{"method":"GET"}'
python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination=$2.response routing_key="$2.response" arguments=''
