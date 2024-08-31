# nordvpn
nordvpn docker container

## Purpose
Docker container running a nordVPN client. This container can be used by other containers to hide their ip-address by accessing the internet via this container.
It is also possible to make the other containers accessible from the internet through the use of a VPN. This is achieved via the nordVPN meshnet option.

## Installation
Create a file named `vars` based on `vars.example`. 
Update the `docker-compose.yml` file in the root-folder of the repository. Add/remove docker compose projects you want to add to the complete docker-stack running with nordVPN.
For each service which you want to make use of the vpn add the following label to the service:

	labels:
	  - "com.tgiesela.vpn.hiddenip=true"

For each service which you want to be accessible via a remote vpn add the following labels to the service:

	labels:
           - "com.tgiesela.vpn.accessible=true"
           - "com.tgiesela.vpn.vpnport=<portnr>"
           - "com.tgiesela.vpn.containerport=<portnr>"

You can use my spotweb project as an example (http://github.com/tgiesela/spotweb).

Then run the `start.sh` bash-script.
The bash script will load all `vars` in the subfolders of this project and process them to get all variables set.
It will then run docker compose to build and start all the containers.
When all containers are started, the labels set on all containers will be used to set the routing for the docker containers via the vpn docker container.

## DNS
By default, nordvpn sets its own DNS-servers. So a DNS lookup inside the nordvpn container will always use them.
However, all other containers would use the docker DNS (127.0.0.11) and eventually use the DNS server set on the host machine.
This is why I added a dnsmasq container which is able to split DNS requests for Docker containers, a local DNS-server and eventually the nordVPN servers.
See dnsmasq/dnsmasq.conf for an example.
If you are using container names inside docker container to connect to other containers, you need to suffix them with `.mailnet` which is the name of the docker network and will be used by dnsmasq to route them to the docker DNS.

## Notes
You may have to update you docker compose .yml files to make them dependent on the vpn service.

I attempted to use the option to use the nordvpn container as a service via which all traffic should pass by using the docker optione `network_mode: service:vpn`. But this resulted in issues with port publishing, especially when multiple containers are using the same port (e.g. 80). 

I also attempted to use traefik as reverse proxy, but this gave the same kind of problems. Port conflicts.

That is why I ended up with this solution, which is based on an example from wireguard (https://www.linuxserver.io/blog/routing-docker-host-and-container-traffic-through-wireguard#routing-a-containers-traffic-through-the-wireguard-container-via).


