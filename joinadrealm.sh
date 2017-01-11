#!/bin/bash

adjoinaccount=$1

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. sudo -s works really good here." 1>&2
   exit 1
fi

if [ ! $adjoinaccount ]; then
	echo "Specify a user in the contoso.org realm with permissions to create machine accounts." 1>&2
	exit 1
fi

echo "Joining domain as $1"

if grep "search contoso.org" /etc/resolvconf/resolv.conf.d/base
then
	echo 'Skipping /etc/resolvconf/resolv.conf.d updates'
else
	cat << EOF >> /etc/resolvconf/resolv.conf.d/base
search contoso.org
EOF

	cat << EOF >> /etc/resolvconf/resolv.conf.d/head
search contoso.org
EOF

	cat << EOF >> /etc/resolvconf/resolv.conf.d/tail
search contoso.org
EOF
fi


cat << EOF > /etc/krb5.conf
[libdefaults]
	default_realm = contoso.org

# The following krb5.conf variables are only for MIT Kerberos.
	krb4_config = /etc/krb.conf
	krb4_realms = /etc/krb.realms
	kdc_timesync = 1
	ccache_type = 4
	forwardable = true
	proxiable = true

# The following libdefaults parameters are only for Heimdal Kerberos.
	v4_instance_resolve = false
	v4_name_convert = {
		host = {
			rcmd = host
			ftp = ftp
		}
		plain = {
			something = something-else
		}
	}
	fcc-mit-ticketflags = true

[realms]
	contoso.org = {
		kdc = contoso.org:88
		admin_server = contoso.org
		default_domain = contoso.org
	}

[domain_realm]
	.contoso.org = contoso.org

[login]
	krb4_convert = true
	krb4_get_tickets = false

EOF

cat << EOF > /etc/ntp.conf
# /etc/ntp.conf
# ops.terrapower..com
# NTP configuration
# --------------------------------------------------
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable
server ntp.contoso.org
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
restrict 127.0.0.1
restrict ::1
EOF

cat << EOF > /etc/realmd.conf
[service]
automatic-install = no

[users]
default-home = /home/%D/%U
default-shell = /bin/bash

[contoso.org]
computer-ou = OU=Workstation,OU=Computer,OU=.Account.,DC=contoso,dc=org
automatic-id-mapping = yes
fully-qualified-names = no
EOF



if grep "#hosts updated for activedirectory" /etc/hosts
then
	echo 'Skipping /etc/hosts update'
else
	cat << EOF >> /etc/hosts
#hosts updated for activedirectory
EOF

	HOSTNAME=`hostname`
	sed -i.orig "s/${HOSTNAME}/${HOSTNAME}.contoso.org ${HOSTNAME}/g" /etc/hosts
fi


if grep "#ad.sh modified for user login skeletons" /etc/pam.d/common-session
then
	echo 'skipping /etc/pam.d/common-session update'
else
	cat << EOF >> /etc/pam.d/common-session
#ad.sh modified for user login skeletons
EOF
	sed -i.orig '/session\s*required\s*pam_unix.so/a session required pam_mkhomedir.so skel=/etc/skel/ umask=0077' /etc/pam.d/common-session
fi

#echo "Getting kerberos ticket for $adjoinaccount"
#kinit $adjoinaccount 2>&1
#echo 'Waiting 5 seconds for initial crap to settle.'
#sleep 5
#echo 'Press enter to continue.'
#read foo
#echo 'Here is what your ticket looks like.'
#klist
#echo 'Discovering contoso.org realm'
#realm discover contoso.org 2>&1
#echo 'Waiting 5 more seconds for secondary crap to settle.'
#sleep 5
#echo 'Press enter to continue some more.'
#read foo



if [ -f /etc/sssd/sssd.conf ]; then
	echo 'Trying to remove old sssd.conf'
	rm /etc/sssd/sssd.conf
fi

if [ -f /etc/samba/smb.conf ]; then
	echo 'Trying to remove old smb.conf'
	rm /etc/samba/smb.conf
fi


echo 'Restarting realmd service'
service realmd restart
echo 'Joining contoso.org realm.'
realm join -v -U $adjoinaccount contoso.org 2>&1
echo 'Waiting another 5 seconds for AD to settle.'
sleep 5
echo 'Press enter to continue a little further.'
read foo
echo 'Here is how your realm is configured.'
realm list
echo 'Waiting the last 5 seconds for AD services to settle.'
echo 'Make sure your new machine account is replicated before expecting this to work.'
sleep 5
echo 'Press enter to finish.'
read foo
#echo 'Granting rights to let users in the contoso.org realm the right to logon.'
#realm permit -a
echo 'Done.'





cat << EOF > /etc/sssd/sssd.conf
[sssd]
domains = contoso.org
config_file_version = 2
services = nss, pam, sudo, ssh
debug_level=7

[pam]
debug_level=7

[domain/contoso.org]
debug_level=7
ad_domain = contoso.org
krb5_realm = contoso.org
realmd_tags = manages system joined-with-adcli
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%d/%u
access_provider = ad
ad_gpo_access_control = permissive
ad_enable_dns_sites = True
dyndns_update = True
EOF



cat << EOF > /etc/samba/smb.conf
[global]
   workgroup = AD
   client signing = yes
   client use spnego = yes
   kerberos method = secrets and keytab
   realm = contoso.org
   security = ads
 
   server string = %h server (Samba, Ubuntu)
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000
   syslog = 0
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes
EOF


chown root:root /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf

echo 'Reboot your machine for sssd to refresh cache. Just like a windows machine!'
