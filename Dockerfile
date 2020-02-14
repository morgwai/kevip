FROM ubuntu:bionic

RUN apt-get update && apt-get install -y --no-install-recommends iproute2 iptables ucarp && \
	rm -rf /var/lib/apt/lists/*

COPY ./vip-* ./run-ucarp.sh /

CMD ["/run-ucarp.sh"]
