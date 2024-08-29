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
for dir in $(ls -d ../*) ;do 
echo "Processing $dir"
   if [ -f "${dir}/docker-compose.yml" ] ; then
echo "    $dir contains compose.yml"
       if [ -f "${dir}/vars" ] ; then
echo "    source vars from $dir"
	    source ${dir}/vars
       fi
   fi
done
docker network create --subnet ${DOCKERNETWORK} --gateway ${DOCKERGATEWAY} --ipv6 mailnet
docker compose up --build -d
# Now wait for the VPN servive to become ready
STATUS=$(docker ps --format '{{.Status}}' -f name=nordvpn)
echo $STATUS
while [[ ! "${STATUS}" =~ "healthy" ]] ; do
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
