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
sleep 120
touch timestamp_jenkins
aws s3 cp timestamp_jenkins s3://terraform-rep0/
aws s3 cp s3://terraform-rep0/id_rsa.pub .
cat id_rsa.pub >> .ssh/authorized_keys
sudo apt-get install openjdk-8-jdk -y
sleep 180
git clone https://github.com/gb8may/devops_infra.git
cd /devops_infra/playbooks/jenkins
cp Jenkinsfile /var/lib/jenkins/
