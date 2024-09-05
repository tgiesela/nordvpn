#!/bin/bash
CMD=$1
if [ -z "$CMD" ] ; then
    echo "No option specified, assuming STOP"
    CMD=stop
fi

source load_vars.sh
docker compose $CMD
