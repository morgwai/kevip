FROM ubuntu:bionic

RUN apt-get update && apt-get install -y --no-install-recommends iproute2 iptables ucarp && \
	rm -rf /var/lib/apt/lists/*

COPY ./run-ucarp.sh /
COPY ./vip-*.sh /usr/local/sbin/

CMD ["/run-ucarp.sh"]
