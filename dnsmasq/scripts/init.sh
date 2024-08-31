#!/bin/bash
DAEMON=/usr/sbin/dnsmasq
set -e
info () {
    echo "[INFO] $@"
}

appSetup() {
    echo "[INFO] setup"
    echo "# NO DNS" > /etc/resolv.conf
}

appStart() {
    [ -f /.alreadysetup ] && echo "Skipping setup..." || appSetup
    echo "[INFO] start"

    trap "appStop" SIGTERM
    trap "appStop" SIGINT
    set +e
    exec ${DAEMON} -d --log-debug &

#tail -f /init.sh
    wait $!
    echo "Wait completed"
}
appStop() {
    echo "TRAP HANDLER" active
    echo "Stopping"
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
