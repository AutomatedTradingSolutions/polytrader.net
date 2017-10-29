#!/bin/bash

source=REFDATA

echo "Declaring bindings"

python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination=REFDATA.request routing_key=request arguments='{"method":"GET"}'
python3 $PYTHONPATH/rabbitmqadmin.py declare binding source=$source destination=REFDATA.response routing_key=response arguments='{"method":"POST"}'
