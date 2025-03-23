#!/bin/bash

# Parameters:
#   1 port on which traffic comes in
#   2 container/host which is the target
#   3 target port

function addrule(){
    RULE=$*
    echo iptables -t nat -D $RULE
    echo iptables -t nat -A $RULE
    iptables -t nat -D $RULE || true
    iptables -t nat -A $RULE
}
cat /etc/resolv.conf
SRCPORT=$1
TARGET=$2
DSTPORT=$3

SRCPORTPROTOCOL=$(echo "$SRCPORT" | awk '{split($0,a,"/"); print a[1], a[2]==""?"tcp":a[2]}')
DSTPORTPROTOCOL=$(echo "$DSTPORT" | awk '{split($0,a,"/"); print a[1], a[2]==""?"tcp":a[2]}')
SRCPORTARR=($SRCPORTPROTOCOL)
DSTPORTARR=($DSTPORTPROTOCOL)

# Always use dockers DNS to resolve hostnames
TARGETIP=$(dig +short @127.0.0.11 "${TARGET}")
if [ -z "$TARGETIP" ] ; then
    echo "Can't resolve hostname ${TARGET}"
    exit 2
fi
# Always use dockers DNS to resolve hostnames
MYIP=$(dig +short @127.0.0.11 $(hostname))
echo "Adding port forwarding from :${SRCPORT} to ${TARGET}:${DSTPORT}"
# To avoid duplicate delete old rules first
set +e
CURRULE=$(iptables -t nat -S PREROUTING | grep "${SRCPORT}")
#if [ ! -z "$CURRULE" ] ; then
    #echo $CURRULE | sed 's/\-A /\-D /'| xargs iptables -t nat
#fi
CURRULE=$(iptables -t nat -S POSTROUTING | grep "${DSTPORT}")
#if [ ! -z "$CURRULE" ] ; then
    #echo $CURRULE | sed 's/\-A /\-D /'| xargs iptables -t nat
#fi

#iptables -t nat -D PREROUTING -p tcp --dport ${SRCPORT} -j DNAT --to-destination ${TARGETIP}:${DSTPORT} > /dev/null 2>&1
#iptables -t nat -D POSTROUTING -p tcp -d ${TARGETIP} --dport ${DSTPORT} -j SNAT --to-source ${MYIP} > /dev/null 2>&1
# (Re-) add the rules
set -e
#iptables -t nat -A PREROUTING -i nordlynx -p ${DSTPORTARR[1]} --dport ${SRCPORTARR[0]} -j DNAT --to-destination ${TARGETIP}:${DSTPORTARR[0]}
#iptables -t nat -A POSTROUTING -p ${DSTPORTARR[1]} -d ${TARGETIP} --dport ${DSTPORTARR[0]} -j SNAT --to-source ${MYIP}
addrule PREROUTING -i nordlynx -p "${DSTPORTARR[1]}" --dport "${SRCPORTARR[0]}" -j DNAT --to-destination "${TARGETIP}":"${DSTPORTARR[0]}"
addrule POSTROUTING -p "${DSTPORTARR[1]}" -d "${TARGETIP}" --dport "${DSTPORTARR[0]}" -j SNAT --to-source "${MYIP}"