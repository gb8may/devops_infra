#!/bin/bash

# Add address to hosts file
echo "127.0.0.1   jenkins
10.0.1.71   ansible" >> /etc/hosts 

# Instaling AWS CLI
apt-get update
sudo apt-get install awscli -y

# SSH config
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
sudo systemctl restart sshd

# Copy of SSH keys
cd /home/ubuntu/
aws s3 cp s3://terraform-rep0/id_rsa.pub .
cat id_rsa.pub >> .ssh/authorized_keys

