#!/bin/bash

cd devops_infra/playbooks/jenkins/
ansible-playbook site.yml -l jenkins -u ubuntu
