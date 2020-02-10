#!/bin/bash
mask=$(echo ${3} |cut -d - -f 1) &&
target=$(echo ${3} |cut -d - -f 2) &&

ip addr add ${2}/${mask} dev ${1} &&
iptables -t nat -A PREROUTING -d ${2} -j DNAT --to-destination ${target} &&
iptables -t nat -A POSTROUTING -j MASQUERADE
