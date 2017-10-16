#!/bin/bash

python3 rabbitmqadmin.py declare queue --vhost=$1 name=$2 durable=true
