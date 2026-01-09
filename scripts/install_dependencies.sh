#!/bin/bash
yum update -y
yum install -y ruby wget
cd /home/ec2-user

# Install CodeDeploy agent if not already installed
if ! service codedeploy-agent status; then
    wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
fi

# Install Node.js if not already installed
if ! command -v node &> /dev/null; then
    curl -sL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
fi