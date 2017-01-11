#!/bin/bash
#should be run as root. (sudo -s)

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. sudo -s works really good here." 1>&2
   exit 1
fi

echo 'Running this script will reboot the machine when finished.'
echo 'Press a key or something to start'
read foo
apt-get update -y
apt-get upgrade -y
apt-get install realmd sssd ssh sssd-tools adcli samba-common-bin ntp -y
DEBIAN_FRONTEND=noninteractive apt-get -y install krb5-user
dpkg-reconfigure resolvconf

reboot
#reboot and continue from here.
