#!/bin/bash

# Script to start a vpn service (nordvpn) and attach containers that require a vpn connections.
# Also make regular containers accessible via the mesh-network of nordvpn
#
# iproute2 package should be installed, otherwise ip command will fail
#
# Containers can be configured using labels (starting with com.tgiesela.vpn) :
#
#     containers which need a vpn (hidden ip):
#     	com.tgiesela.vpn.hiddenip=true|false
#     containers which need to be accessed from the outside world (via meshenet)
#       com.tgiesela.vpn.accessible=true|false
#       com.tgiesela.vpn.vpnport=<port1>[;<port2>...]       #required
#       com.tgiesela.vpn.containerport=<port1>[;<port2>...] #required
#          note: the order of ports has to be the same in both arrays, e.g. port1 is mapped to port1
#
CMD=$1
if [ -z "$CMD" ] ; then
    echo "No option specified, assuming BUILD"
    CMD=build
fi
case "$CMD" in
    build|start) ;;
    *)
       echo "Illegal start option, should be one of 'build, start', found ${CMD}"
       exit 1
esac
source load_vars.sh

if [ "$CMD" == "build" ] ; then
    docker network create --subnet ${DOCKERNETWORK} --gateway ${DOCKERGATEWAY} --ipv6 mailnet
    docker compose --parallel 1 up --build -d 
else
    docker compose up -d
fi

# Now wait for the VPN servive to become ready
STATUS=$(docker ps --format '{{.Status}}' -f name=nordvpn)
echo $STATUS
while [[ ! "${STATUS}" =~ "(healthy)" ]] ; do
   echo "Waiting for VPN to become ready"
   sleep 5
   STATUS=$(docker ps --format '{{.Status}}' -f name=nordvpn)
done

# Hide containers behind vpn
HIDDENCONTAINERS=$(docker ps --format '{{.Names}}' --filter "label=com.tgiesela.vpn.hiddenip=true")
for container in $HIDDENCONTAINERS ; do
    echo -e "\nProcessing docker container: $container\n"
    docker exec --privileged ${container} ip route show
    docker exec --privileged ${container} ip route del default
    docker exec --privileged ${container} ip route add default via ${VPNIP}

    IFS=';' read -ra ADDR <<< "$LOCALNETWORKS"
    for i in "${ADDR[@]}"; do
       if [ $i != $DOCKERNETWORK ] ; then
           docker exec --privileged ${container} ip route add $i via ${DOCKERGATEWAY}
       fi
    done

    docker exec --privileged ${container} ip route show
done
BEHINDVPNCONTAINERS=$(docker ps --format '{{.Names}}' --filter "label=com.tgiesela.vpn.accessible=true")
for container in $BEHINDVPNCONTAINERS ; do
    echo -e "\nFORWARDING Processing docker container: $container\n"
    SRCPORTS=$(docker inspect --format '{{ index .Config.Labels "com.tgiesela.vpn.vpnport"}}' ${container})
    DSTPORTS=$(docker inspect --format '{{ index .Config.Labels "com.tgiesela.vpn.containerport"}}' ${container})
    IFS=';' read -ra SRCPORTARRAY <<< $SRCPORTS
    IFS=';' read -ra DSTPORTARRAY <<< $DSTPORTS
    if [ ${#SRCPORTARRAY[@]} != ${#DSTPORTARRAY[@]} ] ; then
       echo 'Length of vpnport array does not match length of containerport array'
       exit 1
    fi
    for ((i=0; i<${#SRCPORTARRAY[@]}; i++)); do
        SRCPORT=${SRCPORTARRAY[i]}
        DSTPORT=${DSTPORTARRAY[i]}
        docker exec nordvpn /forward.sh ${SRCPORT} ${container} ${DSTPORT}
    done
done
