#!/bin/bash
iface=$(ip route show default  |cut -d ' ' -f 5) &&
addrInfo=( $(ip addr show ${iface} |grep inet |grep -v inet6 |grep -v secondary) ) &&
IFS=/ addrMask=( ${addrInfo[1]} ) &&
addr=${addrMask[0]}  &&
mask=${addrMask[1]}  &&
vid=$(echo ${VIP} |cut -d . -f 4) &&
prio=$(echo ${addr} |cut -d . -f 4) &&

exec ucarp -z -n -u /usr/local/sbin/vip-add.sh -d /usr/local/sbin/vip-del.sh \
	-i ${iface} -s ${addr} -k ${prio} -a ${VIP} -v ${vid} -x "${mask} ${TARGET}" -p ${PASSWORD}
