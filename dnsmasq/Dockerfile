FROM debian:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget apt-transport-https ca-certificates && \
    apt-get install -y --no-install-recommends iputils-ping dnsutils && \
    apt-get install -y --no-install-recommends net-tools tcpdump nano procps && \
    apt-get install -y --no-install-recommends dnsmasq iptables iproute2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 scripts/init.sh /init.sh
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

