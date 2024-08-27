#!/bin/bash

# Parameters:
#   1 port on which traffic comes in
#   2 container/host which is the target
#   3 target port

SRCPORT=$1
TARGET=$2
DSTPORT=$3

TARGETIP=$(dig +short ${TARGET})
MYIP=$(dig +short $(hostname))
echo "Adding port forwarding from :${SRCPORT} to ${TARGET}:${DSTPORT}"
# To avoid duplicate delete old rules first
set +e
iptables -t nat -D PREROUTING -p tcp --dport ${SRCPORT} -j DNAT --to-destination ${TARGETIP}:${DSTPORT}
iptables -t nat -D POSTROUTING -p tcp -d ${TARGETIP} --dport ${DSTPORT} -j SNAT --to-source ${MYIP}
# (Re-) add the rules
set -e
iptables -t nat -A PREROUTING -p tcp --dport ${SRCPORT} -j DNAT --to-destination ${TARGETIP}:${DSTPORT}
iptables -t nat -A POSTROUTING -p tcp -d ${TARGETIP} --dport ${DSTPORT} -j SNAT --to-source ${MYIP}
