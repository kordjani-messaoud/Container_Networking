NS1="NS1"
NS2="NS2"
NODE_IP="192.168.100.100"
BRIDGE_SUBNET="172.16.0.0/24"
BRIDGE_IP="172.16.0.1"
IP1="172.16.0.2"
IP2="172.16.0.3"
TO_NODE_IP="192.168.100.101"
TO_BRIDGE_SUBNET="172.16.1.0/24"
TO_BRIDGE_IP="172.16.1.1"
TO_IP1="172.16.1.2"
TO_IP2="172.16.1.3"

#------------------------- Configuration ---------------------

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
#---------------------+++++++++++++++++++++++++++++
# this part is for    | this part is a normal ip commands
#executing ip commands| excuted inside a name space.
#inside a name space  |
ip netns exec NS2 ip addr add $IP2/24 dev veth21

echo "Enabling veth interface inside name spaces"
ip netns exec NS1 ip link set dev veth11 up
ip netns exec NS2 ip link set dev veth21 up

echo "Creating the brigde"
ip link add br0 type bridge
ip link show type bridge
# ip link delete br0

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

echo "Setting the route on the node the reach net namespace on the other node"
echo "The output interface(dev) can be whatever you have on your node"
ip route add $TO_BRIDGE_SUBNET via $TO_NODE_IP dev enp0s3

echo "Enabeling packet forwarding"
echo "net.ipv4.ip_forward is a kernet parameter and sysctl allow to configur it at runtime"
sysctl -w net.ipv4.ip_forward=1
#sysctl -a | grep net.ipv4.ip_forward

#--------------------------------- Test --------------------------------

echo "Testing connectivity between net namspaces and the node"
ip netns exec $NS1 ping $IP2

echo "Testing connectivity between net namspaces and the node"
ip netns exec $NS2 ping $TO_IP2
