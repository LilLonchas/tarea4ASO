#!/bin/bash

DOMINIO="$1"
SERVIDOR="ldap://192.168.124.135"
BASE_DN=$(echo "$DOMINIO" | awk -F. '{printf "dc=%s,dc=%s", $1, $2}')

if [ -z "$DOMINIO" ]; then
  echo "Uso: $0 nombre_dominio"
  exit 1
fi

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install libnss-ldap libpam-ldap ldap-utils nscd -y

sudo debconf-set-selections <<EOF
ldap-auth-config ldap-auth-config/ldapns/ldap-server string $SERVIDOR
ldap-auth-config ldap-auth-config/ldapns/base-dn string $BASE_DN
ldap-auth-config ldap-auth-config/ldapns/ldap-version select 3
ldap-auth-config ldap-auth-config/rootbinddn string cn=admin,$BASE_DN
ldap-auth-config ldap-auth-config/pam_password select md5
EOF

sudo dpkg-reconfigure -f noninteractive ldap-auth-config

sudo sed -i '/^passwd:/ s/$/ ldap/' /etc/nsswitch.conf
sudo sed -i '/^group:/ s/$/ ldap/' /etc/nsswitch.conf
sudo sed -i '/^shadow:/ s/$/ ldap/' /etc/nsswitch.conf

sudo bash -c 'echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session'
sudo systemctl restart nscd
