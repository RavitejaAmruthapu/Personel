#!/bin/sh
USER_ID=$(id)
GROUP_ID=$(id -g)
echo "Username: "+$USER_ID
sudo /etc/init.d/dbus start
sudo service ssh start
trap : TERM INT; sleep infinity & wait
