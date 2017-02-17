#!/bin/sh

sudo apt-get update
sudo apt-get -y install curl
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-get -y install software-properties-common
sudo add-apt-repository \
       "deb https://apt.dockerproject.org/repo/ \
       ubuntu-$(lsb_release -cs) \
       main"
sudo apt-get update
sudo apt-get -y install docker-engine
sudo usermod -aG docker ubuntu

# Add GatewayPorts yes to /etc/ssh/sshd_config
sudo /bin/sh -c 'echo "GatewayPorts yes" >> /etc/ssh/sshd_config'
sudo /etc/init.d/ssh restart
