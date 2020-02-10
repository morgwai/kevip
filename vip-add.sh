#!/bin/bash
maskTarget=( ${3} ) &&
mask=${maskTarget[0]} &&
target=${maskTarget[1]} &&

ip addr add ${2}/${mask} dev ${1} &&
iptables -t nat -A PREROUTING -d ${2} -j DNAT --to-destination ${target} &&
iptables -t nat -A POSTROUTING -j MASQUERADE
