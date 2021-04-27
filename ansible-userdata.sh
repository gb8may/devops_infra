#!/bin/bash

# Instaling Ansible
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible -y

sudo apt-get install python3-pip -y
#sudo apt install awscli -y
pip3 install --upgrade awscli
pip3 install boto3

# Building hosts - inventory - file
echo "[servers]
ansible
jenkins

[servers:vars]
ansible_python_interpreter=/usr/bin/python3" >> /etc/ansible/hosts

echo "127.0.0.1   ansible" >> /etc/hosts

# Allowing SSH without confirmation

echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
sudo systemctl restart sshd

# Creating SSH keys
sleep 120

ssh-keygen -t rsa -N "" -C "" -f .ssh/id_rsa
cat .ssh/id_rsa.pub >> .ssh/authorized_keys
aws s3 cp .ssh/id_rsa.pub s3://terraform-rep0
