NS1="NS1"
NS2="NS2"
NODE_IP="192.168.100.101"
BRIDGE_SUBNET="172.16.1.0/24"
BRIDGE_IP="172.16.1.1"
TUNNEL_IP="172.16.1.100"
IP1="172.16.1.2"
IP2="172.16.1.3"
TO_NODE_IP="192.168.100.100"
TO_BRIDGE_SUBNET="172.16.0.0/24"
TO_BRIDGE_IP="172.16.0.1"
TO_TUNNEL_IP="172.16.0.100"
TO_IP1="172.16.0.2"
TO_IP2="172.16.0.3"

echo "Creating Namespaces"
ip netns add $NS1
ip netns add $NS2

echo "Creating veth pairs"
ip link add veth11 type veth peer name veth10
ip link add veth21 type veth peer name veth20

echo "Add veth to name spaces"
ip link set veth11 netns $NS1
ip link set veth21 netns $NS2

echo "Givinb IP@ to the veth interfaces inside name spaces"
ip netns exec NS1 ip addr add $IP1/24 dev veth11
ip netns exec NS2 ip addr add $IP2/24 dev veth21

echo "Enabling veth interface inside name spaces"
ip netns exec NS1 ip link set dev veth11 up
ip netns exec NS2 ip link set dev veth21 up

echo "Creating the brigde"
ip link add br0 type bridge
ip link show type bridge

echo "Enabling the bridge"
ip link set dev br0 up


echo " Adding veth to the bridge"
ip link set dev veth10 master br0
ip link set dev veth20 master br0

echo "Adding an IP @ to bridge"
ip addr add $BRIDGE_IP/24 dev br0

echo "Enabling the bridge"
ip link set dev br0 up

echo "Enabling the veth connected to the bridge"
ip link set dev veth20 up
ip link set dev veth10 up

echo "Setting the loopback interfaces for the name spaces"
ip netns exec $NS1 ip link set lo up
ip netns exec $NS2 ip link set lo up

echo "Setting Default route in the namespaces"
ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

echo "Enabeling packet forwarding"
sysctl -w net.ipv4.ip_forward=1

#---------------------------------- Tunnel Configuration ----------------
echo "Open port 9000 on firewalld for Redhat linux"
firewall-cmd --add-port=9000/udp
#firewall-cmd --list-ports

echo "Establishing UDP Tunnel"
socat UDP:$TO_NODE_IP:9000,bind=$NODE_IP:9000 TUN:$TUNNEL_IP/16,tun-name=tunudp,iff-no-pi,tun-type=tun

echo "Setting the MTU on the tun interface"
ip link set dev tunudp mtu 1492


echo "Disabling Reverse Path Filtering on all interfaces"
sysctl -w net.ipv4.conf.all.rp_filter=0
