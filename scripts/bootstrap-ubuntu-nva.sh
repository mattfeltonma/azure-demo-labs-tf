#!/bin/bash

## Initialize variables with default values (if needed)
##
hostname=""
router_asn=""
nva_private_ip=""
public_nic_gateway_ip=""
private_nic_gateway_ip=""

## Parse named parameters
##
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --hostname) hostname="$2"; shift ;;
        --router_asn) router_asn="$2"; shift ;;
        --nva_private_ip) nva_private_ip="$2"; shift ;;
        --public_nic_gateway_ip) public_nic_gateway_ip="$2"; shift ;;
        --private_nic_gateway_ip) private_nic_gateway_ip="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

## Check that all required parameters are provided
##
if [[ -z "$hostname" || -z "$router_asn" || -z "$nva_private_ip" || -z "$public_nic_gateway_ip" || -z "$private_nic_gateway_ip" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 --hostname <hostname> --router_asn <asn> --nva_private_ip <ip> --public_nic_gateway_ip <ip> --private_nic_gateway_ip <ip>"
    exit 1
fi

# Set a custom port for SSH
mkdir -p /etc/systemd/system/ssh.socket.d
cat >/etc/systemd/system/ssh.socket.d/listen.conf <<EOF
[Socket]
ListenStream=
ListenStream=2222
EOF

# Restart SSH service
systemctl daemon-reload
systemctl restart ssh.socket

## Update repositories
##
export DEBIAN_FRONTEND=dialog
apt-get -o DPkg::Lock::Timeout=60 update

## Install net tools
##
export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=30 install net-tools -y

## Install support for persistency to iptables
##
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get -o DPkg::Lock::Timeout=30 install iptables-persistent -y

## Add kernal modules to support vrfs
##
apt-get -o DPkg::Lock::Timeout=30 install linux-modules-extra-azure -y

## Enable IPv4 forwarding
##
sed -r -i 's/#{1,}?net.ipv4.ip_forward ?= ?(0|1)/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

## Enable vrf support in network stacks
##
sysctl -p | grep -i "net.ipv4.tcp_l3"
if [ $? -eq 1 ]
then
    echo "net.ipv4.tcp_l3mdev_accept = 1" >> /etc/sysctl.conf
    echo "net.ipv4.udp_l3mdev_accept = 1" >> /etc/sysctl.conf
    sysctl -p
fi

## Configure routing
##
ls -l /etc/systemd/system/routingconfig.service
if [ $? -eq 2 ]
then
    cat << EOF |
[Unit]
Description=Configure vrf and routing for machine

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStart=/bin/bash -c "ip link add vrflan type vrf table 10"
ExecStart=/bin/bash -c "ip link set dev vrflan up"
ExecStart=/bin/bash -c "ip link set dev eth1 master vrflan"
ExecStart=/bin/bash -c "sleep 5"
ExecStart=/bin/bash -c "ip route add table 10 0.0.0.0/0 via $public_nic_gateway_ip"
ExecStart=/bin/bash -c "ip route add table 10 168.63.129.16 via $private_nic_gateway_ip"
ExecStart=/bin/bash -c "ip route add table 10 10.0.0.0/8 via $private_nic_gateway_ip"
ExecStart=/bin/bash -c "ip route add table 10 192.168.0.0/16 via $private_nic_gateway_ip"
ExecStart=/bin/bash -c "ip route add table 10 172.16.0.0/12 via $private_nic_gateway_ip"
ExecStart=/bin/bash -c "ip route add table 10 unreachable default metric 4278198272"
ExecStart=/bin/bash -c "ip route add 10.0.0.0/8 dev vrflan"
ExecStart=/bin/bash -c "ip route add 192.168.0.0/16 dev vrflan"
ExecStart=/bin/bash -c "ip route add 172.16.0.0/12 dev vrflan"

[Install]
WantedBy=multi-user.target
EOF
    awk '{print}' > /etc/systemd/system/routingconfig.service

    systemctl daemon-reload
    systemctl start routingconfig.service
    systemctl enable routingconfig.service
fi

##   Install and configure frr for BGP
##

## Add FRR repository and its key to the system
##
FRRVER="frr-stable"
curl -s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null
echo deb '[signed-by=/usr/share/keyrings/frrouting.gpg]' https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable | sudo tee -a /etc/apt/sources.list.d/frr.list

## Update package list
##
export DEBIAN_FRONTEND=dialog
apt-get -o DPkg::Lock::Timeout=60 update

## Install FRR
##
apt-get -o DPkg::Lock::Timeout=30 install frr frr-pythontools -y

## Check whether there is an frr log file which would indicate the frr service is already configured
## and running
ls -l /var/log/frr.log > /dev/null
if [ $? -eq 2 ]
then
    ## Create a log file for frr and set the ownership to frr
    mkdir -p /var/log/frr && sudo chown frr:frr /var/log/frr

    ## Create a log file for frr and set ownership to frr
    touch /var/log/frr.log
    chown frr:frr /var/log/frr.log

    ## Configure the daemons file to start zebra and bgpd an shut other protocols off
    ##
    echo 'zebra=yes' > /etc/frr/daemons
    echo 'bgpd=yes' >> /etc/frr/daemons
    echo 'ospfd=no' >> /etc/frr/daemons
    echo 'ospf6d=no' >> /etc/frr/daemons
    echo 'ripd=no' >> /etc/frr/daemons
    echo 'ripngd=no' >> /etc/frr/daemons
    echo 'isisd=no' >> /etc/frr/daemons
    echo 'babeld=no' >> /etc/frr/daemons
    echo 'pimd=no' >> /etc/frr/daemons
    echo 'ldpd=no' >> /etc/frr/daemons
    echo 'nhrpd=no' >> /etc/frr/daemons
    echo 'eigrpd=no' >> /etc/frr/daemons
    echo 'sharpd=no' >> /etc/frr/daemons
    echo 'staticd=no' >> /etc/frr/daemons
    echo 'pbrd=no' >> /etc/frr/daemons
    echo 'bfdd=no' >> /etc/frr/daemons
    echo 'fabricd=no' >> /etc/frr/daemons
    
    ## Rename existing frr config file
    ## 
    mv /etc/frr/frr.conf /etc/frr/frr.conf.bak

    ## Create a new frr config file
    ##
    cat <<EOF > /etc/frr/frr.conf
    ! Configure the hostname
    hostname $hostname

    ! Configure the frr log file
    log file /var/log/frr.log

    ! Configure the interface frr should listen on
    vrf vrflan
      rd $router_asn:1
      route-target import $router_asn:1
      route-target export $router_asn:1
    exit-vrf

    ! Configure frr to use the vrf route table
    table 10

    ! Configure ip forwarding for the vrf
    ip forwarding

    ! Configure support for vty
    line vty

    ! Configure bgp
    router bgp $router_asn vrf vrflan
      bgp router-id $nva_private_ip
      ! Configure address family
        address-family ipv4 unicast
        exit-address-family
        address-family ipv6
        exit-address-family
EOF

# # Start frr services
    systemctl daemon-reload
    systemctl start frr
    systemctl enable frr
fi

#   Configure iptables
# # Configure support for NAT for Internet-bound traffic
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# # Allow and forward traffic out of vrf (LAN) to eth0 (Internet)
iptables -A FORWARD -i eth0 -o vrflan -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i vrflan -o eth0 -j ACCEPT

# # Allow and forward traffic between eth1 (LAN) and vrf (LAN)
iptables -A FORWARD -i eth1 -o vrflan -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i vrflan -o eth1 -j ACCEPT

# # Log traffic that is dropped
iptables -A FORWARD -i eth0 -j LOG --log-prefix "Connection refused: "
iptables -A FORWARD -i eth0 -j DROP

# # Allow SSH traffic in eth0 and eth1
iptables -A INPUT -p tcp --dport ssh --tcp-flags SYN,ACK SYN,ACK -j LOG --log-prefix "SSH Connection established: "
iptables -A INPUT -p tcp --dport ssh -j ACCEPT

# # Allow return traffic across all interfaces
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# # Drop all other traffic sent directly to routers
iptables -A INPUT -i eth0 -j LOG --log-prefix "Connection refused: "
iptables -A INPUT -i eth0 -j DROP

# # Allow return traffic from sessions that interact with processes running on machine (such as ssh)
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# # Make the iptable rules persistent
sudo -i
sudo iptables-save > /etc/iptables/rules.v4
exit
