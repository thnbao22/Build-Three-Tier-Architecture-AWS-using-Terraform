#!/bin/bash
# Script to install node
yum update -y
yum install -y gcc-c++ make
curl sl https://rpm.nodesource.com/setup_16.x | bash -
yum install -y nodejs