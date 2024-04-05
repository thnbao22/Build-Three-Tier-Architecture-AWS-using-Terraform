#!/bin/bash 
# Scrip to install apache server
yum update -y
yum install httpd
sudo systemctl start httpd
sudo systemctl status httpd

echo "Hello World, my name is Charles from $(hostname -f) > var/www/html/index.html
