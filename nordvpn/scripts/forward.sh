#!/bin/bash

# Parameters:
#   1 port on which traffic comes in
#   2 container/host which is the target
#   3 target port
cat /etc/resolv.conf
SRCPORT=$1
TARGET=$2
DSTPORT=$3

# Always use dockers DNS to resolve hostnames
TARGETIP=$(dig +short @127.0.0.11 ${TARGET})
if [ -z "$TARGETIP" ] ; then
    echo "Can't resolve hostname ${TARGET}"
    exit 2
fi
# Always use dockers DNS to resolve hostnames
MYIP=$(dig +short @127.0.0.11 $(hostname))
echo "Adding port forwarding from :${SRCPORT} to ${TARGET}:${DSTPORT}"
# To avoid duplicate delete old rules first
set +e
CURRULE=$(iptables -t nat -S PREROUTING | grep ${SRCPORT})
if [ ! -z "$CURRULE" ] ; then
    echo $CURRULE | sed 's/\-A /\-D /'| xargs iptables -t nat
fi
CURRULE=$(iptables -t nat -S POSTROUTING | grep ${DSTPORT})
if [ ! -z "$CURRULE" ] ; then
    echo $CURRULE | sed 's/\-A /\-D /'| xargs iptables -t nat
fi

#iptables -t nat -D PREROUTING -p tcp --dport ${SRCPORT} -j DNAT --to-destination ${TARGETIP}:${DSTPORT} > /dev/null 2>&1
#iptables -t nat -D POSTROUTING -p tcp -d ${TARGETIP} --dport ${DSTPORT} -j SNAT --to-source ${MYIP} > /dev/null 2>&1
# (Re-) add the rules
set -e
iptables -t nat -A PREROUTING -p tcp --dport ${SRCPORT} -j DNAT --to-destination ${TARGETIP}:${DSTPORT}
iptables -t nat -A POSTROUTING -p tcp -d ${TARGETIP} --dport ${DSTPORT} -j SNAT --to-source ${MYIP}
