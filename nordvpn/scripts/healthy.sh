#!/bin/bash
# Script to check if the vpn is started correctly and is connected

RSLT=$(nordvpn status)
if [[ "$RSLT" =~ "Status: Connected" ]] ; then
    echo "HEALTHY"
    exit 0
else
    exit 1
fi

