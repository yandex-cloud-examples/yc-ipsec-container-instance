# #######################
# strongSwan provisioning
# #######################

BASE_IMAGE=ubuntu:24.04

# Global Ubuntu things
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
timedatectl set-timezone Europe/Moscow
timedatectl set-ntp True

# Install System components
apt-get update -yq && apt-get upgrade -yq
apt-get install -yq docker.io docker-buildx yq

cp $HOME_DIR/ipsec-init.sh /usr/local/bin/ipsec-init.sh
cp $HOME_DIR/update-routes.sh /usr/local/bin/update-routes.sh

# Configure Kernel parameters
SYS_FILE=/etc/sysctl.conf
echo -e "net.ipv4.ip_forward = 1" >> $SYS_FILE
echo -e "net.ipv4.conf.all.accept_redirects = 0" >> $SYS_FILE
echo -e "net.ipv4.conf.all.send_redirects = 0" >> $SYS_FILE
echo -e "net.ipv4.conf.default.accept_redirects = 0" >> $SYS_FILE
echo -e "net.ipv4.conf.default.send_redirects = 0" >> $SYS_FILE
# Disable IPv6
echo -e "net.ipv6.conf.all.disable_ipv6 = 1" >> $SYS_FILE
echo -e "net.ipv6.conf.default.disable_ipv6 = 1" >> $SYS_FILE
echo -e "net.ipv6.conf.lo.disable_ipv6 = 1" >> $SYS_FILE

# ====================
# StrongSwan container
# ====================
cd $HOME_DIR/strongswan
docker pull $BASE_IMAGE
docker build -t strongswan:$SWAN_VER --build-arg SWAN_VER=$SWAN_VER .

# Enable rc.local system daemon
cat <<EOF > /etc/systemd/system/rc-local.service
[Unit]
  Description=/etc/rc.local Compatibility
  ConditionPathExists=/etc/rc.local

[Service]
  Type=forking
  ExecStart=/etc/rc.local start
  TimeoutSec=0
  StandardOutput=tty
  RemainAfterExit=yes
  SysVStartPriority=99

[Install]
  WantedBy=multi-user.target
EOF

# Create IPsec Tunnel interface
cat <<EOF > /etc/rc.local
#!/bin/bash

# Restore Kernel settings
sysctl -p

# ipsec0 interface
ip link add ipsec0 type xfrm dev eth0 if_id 48 
ip link set ipsec0 up

# Restore iptables configuration
/sbin/iptables-restore < /etc/network/iptables.save

# Update IP Routes to the remote site via ipsec0 interface
/usr/local/bin/update-routes.sh
EOF
chmod +x /etc/rc.local

systemctl enable rc-local
#systemctl start rc-local

# Enable transit traffic via IPsec tunnel
iptables -A FORWARD -i ipsec0 -j ACCEPT
iptables -A FORWARD -o ipsec0 -j ACCEPT
iptables-save > /etc/network/iptables.save

# ================
# Web-HC container
# ================
cd $HOME_DIR/web-hc

export ALPINE_VER=3.21.3
export WEBHC_VER=0.1.0

docker pull alpine:$ALPINE_VER
docker build -t web-hc:$WEBHC_VER --build-arg ALPINE_VER=$ALPINE_VER .

# Clean up image
userdel -f ubuntu
rm -rf /home/ubuntu
userdel -f yc-user
rm -rf /home/yc-user
rm -rf /root/.ssh/
