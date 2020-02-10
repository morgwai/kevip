#!/bin/bash
mask=$(echo ${3} |cut -d - -f 1) &&
target=$(echo ${3} |cut -d - -f 2) &&

ip addr del ${2}/${mask} dev ${1} &&
iptables -t nat -D PREROUTING -d ${2} -j DNAT --to-destination ${target} &&
iptables -t nat -D POSTROUTING -j MASQUERADE
