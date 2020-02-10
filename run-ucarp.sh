#!/bin/bash
iface=$(ip route show default  |cut -d ' ' -f 5) &&
tmp=$(ip addr show ${iface} |grep inet |grep -v inet6 |grep -v secondary) &&
	# the above removes leading spaces
addrMask=$(echo ${tmp} |cut -d ' ' -f 2) &&
addr=$(echo ${addrMask} |cut -d '/' -f 1) &&
mask=$(echo ${addrMask} |cut -d '/' -f 2) &&
vid=$(echo ${VIP} |cut -d . -f 4) &&
prio=$(echo ${addr} |cut -d . -f 4) &&

exec ucarp -z -n -u /usr/local/sbin/vip-add.sh -d /usr/local/sbin/vip-del.sh \
	-i ${iface} -s ${addr} -k ${prio} -a ${VIP} -v ${vid} -x ${mask}-${TARGET} -p ${PASSWORD}
