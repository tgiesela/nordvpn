FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget apt-transport-https ca-certificates && \
    apt-get install -y --no-install-recommends iputils-ping dnsutils && \ 
    apt-get install -y --no-install-recommends net-tools tcpdump nano && \ 
    wget -qO /etc/apt/trusted.gpg.d/nordvpn_public.asc https://repo.nordvpn.com/gpg/nordvpn_public.asc && \
    echo "deb https://repo.nordvpn.com/deb/nordvpn/debian stable main" > /etc/apt/sources.list.d/nordvpn.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nordvpn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 scripts/init.sh /init.sh
COPY --chmod=0755 scripts/forward.sh /forward.sh
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]
