#!/bin/bash

set -e
NAME=nordvpn
RUN_DIR=/run/$NAME
SOCKET=${RUN_DIR}/nordvpnd.sock
PID=${RUN_DIR}/nordvpnd.pid
DAEMON=/usr/sbin/nordvpnd
NORDVPN_GROUP="nordvpn"
info () {
    echo "[INFO] $@"
}

create_socket_dir() {
  if [[ -d "$RUN_DIR" ]]; then
    return
  fi
  mkdir -m 0750 "$RUN_DIR"
  chown root:"$NORDVPN_GROUP" "$RUN_DIR"
}

config_mesh() {
    if [ ! -z "$MESHROUTING" ] || [ ! -z "$MESHLOCAL" ]; then
        nordvpn set mesh on
        IFS=';' read -ra HOST <<< "$MESHROUTING"
        for i in "${HOST[@]}"; do
            echo "Adding $i to routing list"
            nordvpn mesh peer routing allow ${i}
        done
        IFS=';' read -ra HOST <<< "$MESHLOCAL"
        for i in "${HOST[@]}"; do
            echo "Adding $i to local list"
            nordvpn mesh peer local allow ${i}
        done
    else
        nordvpn set mesh off
    fi
}
appSetup() {
    echo "[INFO] setup"
    create_socket_dir
}
delDNSrules() {
    iptables -S |grep 'dport 53'|sed 's/-A/-D/g'| xargs -L 1 iptables
}
enableForwarding(){
    subnetNORDVPN=$(ip -o -f inet addr show nordlynx | awk '{print $4;}'|sed 's/\/32/\/16/')
    echo subnetNORDVPN=10.5.0.0/24
    IFS=';' read -ra ADDR <<< "$NETWORK"
    for i in "${ADDR[@]}"; do
       echo "Adding $i to whitelist"
       iptables -I FORWARD -i nordlynx -o eth0+ -s $subnetNORDVPN -d ${i} -m conntrack --ctstate NEW -j ACCEPT;
       nordvpn whitelist add subnet ${i}
    done
    iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT;
    iptables -t nat -I POSTROUTING -o eth0+ -s $subnetNORDVPN -j MASQUERADE;
    iptables -t nat -A POSTROUTING -o nordlynx -j MASQUERADE

# To allow forwarding of DNS requests from other containers
    iptables -t nat -A POSTROUTING -s ${DOCKERNETWORK} -o eth+ -j MASQUERADE
}

appStart() {
    [ -f /.alreadysetup ] && echo "Skipping setup..." || appSetup
    echo "[INFO] start"

    trap "appStop" SIGTERM
    trap "appStop" SIGINT
    set +e
    rm -f ${SOCKET}
    rm -f ${PID}
    exec ${DAEMON} &
echo "SLEEPING"
    # Do nothing if NordVPN isn't available
    while [ ! -S ${SOCKET} ] ; do
        sleep 1
    done
echo "AWAKE: DAEMON ACTIVE!!"

    nordvpn logout --persist-token
    echo "LOGGING IN"
    nordvpn login --token ${TOKEN}

    IFS=';' read -ra ADDR <<< "$NETWORK"
    for i in "${ADDR[@]}"; do
       echo "Adding $i to whitelist"
       nordvpn whitelist add subnet ${i}
    done
#    nordvpn whitelist add port 25
#    nordvpn set lan-discovery enabled

    config_mesh
    echo "LOGGED IN"
    nordvpn connect ${CONNECT}
    echo 'nameserver 127.0.0.11' > /etc/resolv.conf
    echo "CONNECTED"
    nordvpn status
    delDNSrules
    enableForwarding


#    tail -f /entrypoint.sh
    wait $!
    echo "Wait completed"
}
appStop() {
    echo "TRAP HANDLER" active
    echo "Stopping"
    nordvpn logout --persist-token
    nordvpn disconnect
}

appHelp() {
        echo "Available options:"
        echo " app:start          - Starts nordvpn"
        echo " app:setup          - First time setup."
        echo " app:help           - Displays the help"
        echo " [command]          - Execute the specified linux command eg. /bin/bash."
}

case "$1" in
        app:start)
                appStart
                ;;
        app:setup)
                appSetup
                ;;
        app:help)
                appHelp
                ;;
        *)
                if [ -x $1 ]; then
                        $1
                else
                        prog=$(which $1)
                        if [ -n "${prog}" ] ; then
                                shift 1
                                $prog $@
                        else
                                appHelp
                        fi
                fi
                ;;
esac
echo "Exiting now"
exit 0
