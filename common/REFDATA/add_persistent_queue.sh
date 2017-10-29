#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Virtual host arg not given. Exiting."
  return 99
fi

echo "Declaring queues for virtual host "$1

# direct exchange queues
# GET requests prioritised above all other requests
# POST responses prioritised above all other responses

python3 $PYTHONPATH/rabbitmqadmin.py declare queue --vhost=$1 name=REFDATA.request durable=true arguments='{"x-max-priority":1}'
python3 $PYTHONPATH/rabbitmqadmin.py declare queue --vhost=$1 name=REFDATA.response durable=true arguments='{"x-max-priority":1}'
