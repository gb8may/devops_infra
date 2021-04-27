#!/bin/bash

# Instaling Ansible
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible -y

sudo apt-get install python3-pip -y
sudo apt install awscli -y
pip3 install boto3

# Building hosts - inventory - file
echo "[servers]
10.0.1.71    ansible
10.0.1.208   jenkins

[servers:vars]
ansible_python_interpreter=/usr/bin/python3" >> /etc/ansible/hosts

echo "127.0.0.1   ansible" >> /etc/hosts

# Generating SSH key

