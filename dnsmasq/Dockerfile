FROM debian:12.7

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm" \ 
    APTLIST="cron wget curl ca-certificates jq locales nano sqlite3 dnsutils iproute2 net-tools procps iputils-ping" \
    UPDATE="apt update && apt -y upgrade" \
    CLEANUP="apt -y autoremove && apt -y clean && rm -rf /var/lib/apt/lists"

RUN eval ${UPDATE} && \
	apt -qy install --no-install-recommends ${APTLIST} && \
    locale-gen --no-purge nl_NL.UTF-8 en_US.UTF-8 && \
    eval ${CLEANUP}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
		apt-transport-https  \
		tcpdump \
        dnsmasq \
		iptables && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 scripts/init.sh /init.sh
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

