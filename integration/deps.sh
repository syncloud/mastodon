#!/bin/bash -e

apt-get update
apt-get install -y sshpass openssh-client curl
pip install -r requirements.txt
