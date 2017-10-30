#!/bin/bash

# $1 = virtual host name
# $2 = instrument code

if [[ -z "$1" ]]; then
  echo "Virtual host arg not given. Exiting."
  return 99
fi

if [[ -z "$2" ]]; then
  echo "Instrument code not given. Exiting."
  return 99
fi

echo "Declaring queues for virtual host "$1" and instrument code "$2

. add_persistent_queue.sh "$1" "$2.stream.in"
. add_persistent_queue.sh "$1" "$2.stream.in.ser"
. add_persistent_queue.sh "$1" "$2.stream.in.err"
. add_persistent_queue.sh "$1" "$2.stream.out"
. add_persistent_queue.sh "$1" "$2.request"
. add_persistent_queue.sh "$1" "$2.response"
