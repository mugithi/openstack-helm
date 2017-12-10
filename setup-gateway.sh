#!/bin/bash
set -x

# Assign IP address to br-ex
OSH_BR_EX_ADDR="172.20.41.16/24"
OSH_EXT_SUBNET="172.20.41.0/24"
sudo ip addr add ${OSH_BR_EX_ADDR} dev br-ex
sudo ip link set br-ex up

# Setup masquerading on default route dev to public subnet
DEFAULT_ROUTE_DEV="eno1.41"
sudo iptables -t nat -A POSTROUTING -o ${DEFAULT_ROUTE_DEV} -s ${OSH_EXT_SUBNET} -j MASQUERADE
