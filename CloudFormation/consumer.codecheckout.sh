#!/bin/bash -x
#
#  Admin portal checkout script
#

# Here's where we're going to put the application
#
root=/mnt/applications

# Add SSH keys we'll probably need down the road
#
cat /mnt/ssh_keys >> ~ec2-user/.ssh/authorized_keys

# Move the configuration files into place
#
cp /mnt/database.yml $root/admin/config
cp /mnt/settings.yml $root/admin/config

# Link the application to main, the common Rails application root
#
ln -s $root/customer $root/main

# Make everything owned by the ec2-user
#
chown -R ec2-user:ec2-user $root

# Fire up the Bertie!
#
/etc/init.d/nginx restart 
