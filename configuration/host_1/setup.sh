#!/bin/bash
set -e

# --- Configuration ---
BRIDGE_NAME="br0"
SUBNET_CIDR="10.0.1.0/24"
BRIDGE_IP_CIDR="10.0.1.1/24"
BRIDGE_IP="10.0.1.1"

# Namespace 1 settings
NS1_NAME="ns1"
NS1_IP="10.0.1.2/24"
VETH1_HOST="veth10"
VETH1_NS="veth11"

# Namespace 2 settings
NS2_NAME="ns2"
NS2_IP="10.0.1.3/24"
VETH2_HOST="veth20"
VETH2_NS="veth21"

# WAN Interface
WAN_IF=$(ip route | grep default | awk '{print $5}' | head -n1)

# --- Execution ---

# Create Namespaces
ip netns add $NS1_NAME
ip netns add $NS2_NAME

# Create Veth Pairs
ip link add $VETH1_HOST type veth peer name $VETH1_NS
ip link add $VETH2_HOST type veth peer name $VETH2_NS

# Move interfaces to Namespaces
ip link set $VETH1_NS netns $NS1_NAME
ip link set $VETH2_NS netns $NS2_NAME

# Setup Bridge
ip link add $BRIDGE_NAME type bridge
ip link set $VETH1_HOST master $BRIDGE_NAME
ip link set $VETH2_HOST master $BRIDGE_NAME

# Assign IP Addresses
ip addr add $BRIDGE_IP_CIDR dev $BRIDGE_NAME
ip netns exec $NS1_NAME ip addr add $NS1_IP dev $VETH1_NS
ip netns exec $NS2_NAME ip addr add $NS2_IP dev $VETH2_NS

# Bring Interfaces Up
ip link set $BRIDGE_NAME up
ip link set $VETH1_HOST up
ip link set $VETH2_HOST up

# Bring namespace 1 interface up
ip netns exec $NS1_NAME ip link set $VETH1_NS up
ip netns exec $NS1_NAME ip link set lo up

# Bring namespace 2 interface up
ip netns exec $NS2_NAME ip link set $VETH2_NS up
ip netns exec $NS2_NAME ip link set lo up

# Add default gateway in ns1
ip netns exec $NS1_NAME ip route add default via $BRIDGE_IP

# Add default gateway in ns2
ip netns exec $NS2_NAME ip route add default via $BRIDGE_IP

# Enable IP forwarding
sysctl --write net.ipv4.ip_forward=1

# Enable NAT (Masquerade) on that interface
iptables --table nat --append POSTROUTING --source $SUBNET_CIDR --out-interface $WAN_IF --jump MASQUERADE

# Allow outbound traffic from br0
iptables --table filter --append FORWARD --in-interface br0 --out-interface $WAN_IF --jump ACCEPT

# Allow return traffic to br0
iptables --table filter --append FORWARD --in-interface $WAN_IF --out-interface br0 --match state --state RELATED,ESTABLISHED --jump ACCEPT
