#!/bin/bash

# $1 = virtual host name
# $2 = instrument code

. add_persistent_queue.sh "$1" "IN.$2"
. add_persistent_queue.sh "$1" "ERR.IN.$2"
. add_persistent_queue.sh "$1" "Serialise.$2"
