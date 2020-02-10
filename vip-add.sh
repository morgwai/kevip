#!/bin/bash
iface=${1} &&
vip=${2}
maskTarget=( ${3} ) && # for example "24 10.33.0.4"
mask=${maskTarget[0]} &&
target=${maskTarget[1]} &&
ipCmd=add &&
iptablesCmd='-A' &&
if [[ ${0} == *vip-del.sh ]]; then
	ipCmd=del &&
	iptablesCmd='-D' ;
fi &&

ip addr ${ipCmd} ${vip}/${mask} dev ${iface} &&
iptables -t nat ${iptablesCmd} PREROUTING -d ${vip} -j DNAT --to-destination ${target}
# && iptables -t nat ${iptablesCmd} POSTROUTING -d ${target} -j MASQUERADE
