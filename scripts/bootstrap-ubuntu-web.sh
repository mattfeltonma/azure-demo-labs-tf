#!/bin/bash

# Update repositories
export DEBIAN_FRONTEND=dialog
apt-get -o DPkg::Lock::Timeout=60 update

# Install apache2
apt-get -o DPkg::Lock::Timeout=60 install -y apache2

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

# Setup a simple hello world page
echo "<html><body><h1>This is machine ${HOSTNAME}</h1></body></html>" > /var/www/html/index.html

# Start apache2 service
systemctl start apache2