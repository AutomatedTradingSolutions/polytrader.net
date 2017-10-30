#!/bin/bash

# $1 = virtual host name

if [[ -z "$1" ]]; then
  echo "Virtual host arg not given. Exiting."
  return 99
fi

echo "Declaring exchange for virtual host "$1

python3 $PYTHONPATH/rabbitmqadmin.py declare exchange --vhost=$1 name=PRICEDATA type=topic durable=true
