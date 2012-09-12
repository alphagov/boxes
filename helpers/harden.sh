#!/bin/sh

set -e

ANSI_WHITE="\033[37m"
ANSI_RED="\033[31m"
ANSI_BLUE="\033[34m"
ANSI_RESET="\033[0m"
ANSI_BOLD="\033[1m"

status () {
  echo "${ANSI_BOLD}${ANSI_BLUE}---> ${ANSI_WHITE}${@}${ANSI_RESET}" >&2
}

abort () {
  echo "${ANSI_BOLD}${ANSI_RED}Error:${ANSI_RESET} $@" >&2
  exit 1
}

if [ "$(id -u)" -ne "0" ]; then
  abort "This script must be run as root. Rerun with su/sudo."
fi

status "Updating the system"
apt-get update -qq
apt-get upgrade -y
apt-get autoremove -y

status "Installing required packages"

status "Locking down SSH client"
cat >/etc/ssh/ssh_config <<EOF
Host *
  CheckHostIP yes
  ForwardAgent no
  ForwardX11 no
  ForwardX11Trusted no
  GSSAPIAuthentication no
  HashKnownHosts yes
  HostbasedAuthentication no
  PasswordAuthentication no
  Protocol 2
  SendEnv LANG LC_*
  StrictHostKeyChecking ask
  VisualHostKey yes
EOF

status "Locking down SSH server"
cat >/etc/ssh/sshd_config <<EOF
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
UsePrivilegeSeparation yes

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication
ChallengeResponseAuthentication no
GSSAPIAuthentication no
KerberosAuthentication no
PasswordAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
PubkeyAuthentication yes
StrictModes yes
UsePAM yes

X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server
EOF

status "Installing libpam-passwdqc"
apt-get install libpam-passwdqc -y

status "Installing libpam-tmpdir"
apt-get install libpam-tmpdir -y

status "Removing rlogin, rsh, rcp"
# On modern Ubuntu, these are symlinks to SSH, so Bastille's protectrhost
# doesn't work. Just remove the symlinks.
rm -f /usr/bin/rlogin
rm -f /usr/bin/rsh
rm -f /usr/bin/rcp

status "Locking down console logins"
# Deny root login on console(s)
echo "null" > /etc/securetty
# Deny all but ubuntu login on console(s)
echo "-:ALL EXCEPT ubuntu:LOCAL" >> /etc/security/access.conf

status "Applying user limits"
# Default limits
echo "* hard core 0"      >> /etc/security/limits.conf
echo "* hard nproc 256"   >> /etc/security/limits.conf
echo "* hard nofile 1024" >> /etc/security/limits.conf

# Set a restrictive default umask
sed -i -e '/pam_umask.so/d' /etc/pam.d/common-session
echo "session optional pam_umask.so umask=0077" >> /etc/pam.d/common-session

# Remove suid privileges
status "Removing setuid privileges for various utilities"
set +e
set -x
chmod -s /bin/mount
chmod -s /bin/umount
chmod -s /bin/fusermount
chmod -s /usr/bin/arping
chmod -s /usr/bin/mtr
chmod -s /usr/bin/traceroute
chmod -s /usr/bin/traceroute6.iputils
set +x
set -e

status "Adjusting kernel networking parameters"
cat >>/etc/sysctl.conf <<EOF
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.ip_forward = 0
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_syncookies = 1
EOF

status "Installing UFW firewall"
ufw default deny
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5666/tcp # Nagios NRPE
yes | ufw enable

status "Success!"
