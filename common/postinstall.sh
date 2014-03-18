# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

date > /etc/vagrant_box_build_time

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev 
if [ "$(lsb_release -sc)" = "lucid" ]; then
  apt-get -y install libreadline5-dev
else
  apt-get -y install libreadline-gplv2-dev
fi
apt-get clean

# Installing the virtualbox guest additions
apt-get -y install dkms
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Setup sudo to allow no-password sudo for "admin"
groupadd -r admin
usermod -a -G admin vagrant
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

# Add puppet user and group
adduser --system --group --home /var/lib/puppet puppet

# Install NFS client
apt-get -y install nfs-common

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Remove items used for building, since they aren't needed anymore
apt-get -y remove linux-headers-$(uname -r)
apt-get -y autoremove

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces

#
# Start GOV.UK-specific setup
#

# Set up the GOV.UK apt repository
apt-key adv --keyserver keyserver.ubuntu.com --recv 24B253BC
echo "deb http://gds-packages.s3-website-us-east-1.amazonaws.com current main" > /etc/apt/sources.list.d/gds.list

# Install ruby
apt-get -y install python-software-properties
apt-add-repository ppa:brightbox/ruby-ng
apt-get -y update
apt-get -y install ruby1.9.1 ruby1.9.1-dev rubygems

# Install a few other packages that should be installed by default
apt-get -y install git-core moreutils
gem install -v "= 1.2.3" bundler --no-ri --no-rdoc

# Install puppet repo and packages
if ! dpkg -l puppetlabs-release >/dev/null; then
  TMPFILE=$(mktemp)
  wget -qO ${TMPFILE} http://apt.puppetlabs.com/puppetlabs-release-precise.deb
  dpkg -i ${TMPFILE}
  rm ${TMPFILE}
  apt-get update -qq
fi

apt-get install -y puppet='3.2.*' puppet-common='3.2.*'

echo "FACTER_govuk_platform=development" >> /etc/environment

# Setup sudo to preserve Facter variables
sed -i -e '/Defaults\s\+env_reset/a Defaults\tenv_keep+="FACTER_govuk_platform"' /etc/sudoers

# Finally, preinstall GitHub keys
cat >>/etc/ssh/ssh_known_hosts <<EOM
# github.com SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze1+github8
github.com ssh-dss AAAAB3NzaC1kc3MAAACBANGFW2P9xlGU3zWrymJgI/lKo//ZW2WfVtmbsUZJ5uyKArtlQOT2+WRhcg4979aFxgKdcsqAYW3/LS1T2km3jYW/vr4Uzn+dXWODVk5VlUiZ1HFOHf6s6ITcZvjvdbp6ZbpM+DuJT7Bw+h5Fx8Qt8I16oCZYmAPJRtu46o9C2zk1AAAAFQC4gdFGcSbp5Gr0Wd5Ay/jtcldMewAAAIATTgn4sY4Nem/FQE+XJlyUQptPWMem5fwOcWtSXiTKaaN0lkk2p2snz+EJvAGXGq9dTSWHyLJSM2W6ZdQDqWJ1k+cL8CARAqL+UMwF84CR0m3hj+wtVGD/J4G5kW2DBAf4/bqzP4469lT+dF2FRQ2L9JKXrCWcnhMtJUvua8dvnwAAAIB6C4nQfAA7x8oLta6tT+oCk2WQcydNsyugE8vLrHlogoWEicla6cWPk7oXSspbzUcfkjN3Qa6e74PhRkc7JdSdAlFzU3m7LMkXo1MHgkqNX8glxWNVqBSc0YRdbFdTkL0C6gtpklilhvuHQCdbgB3LBAikcRkDp+FCVkUgPC/7Rw==
# github.com SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze1+github8
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
# github.gds SSH-2.0-OpenSSH_5.8p1 Debian-1ubuntu3+github1
github.gds ssh-dss AAAAB3NzaC1kc3MAAACBALyBPelmTsXJnDQxaxxi87qW+w9kjg4P8sQjvAXaQmGT/LbHUIjvfC/ql5PPPETYyUHai+cNAG3AZqdVDe8WHHJYLSU4Inb86z1Svof/QIro8bqpGLRABtZVvi+wirhzFHVuGNoqfJIT/h03RQqJLTQTIYHxbsuMyagjFs5xk3ThAAAAFQCzpaosSe/1XajHtvPuzk/5nMpM4wAAAIBig8/z0I8VhRV85NZ3btLTa7ICAzvxV42yrfG/MUIY2r134WrT4JVQeEisObLQk2SdrmhV6cxbnIa7RyQRXjWThwq/W/RDZ641GTacndqz7wwsUbY+VVu+OV3Abt5wHKcV8WTGr7R7r3PCIGxZiMCB+bJxlGss3zn9eUXRrWKiwgAAAIEAs26QqN+/mR08TsIlTjAvhGynJ/t0znoDtdjx03LkqazEi8sT1zwSkgRigUHpR9RtZ9ESIE7FEZBVGJg5isWJtBjJOPyX8mB8DfnIHMp/bXWOWAqFCS/pZ52/LRXCU0lTeE9CQe50PGsH6slduWcnHgh+jYarRY0mhvikuPKM9jo=
# github.gds SSH-2.0-OpenSSH_5.8p1 Debian-1ubuntu3+github1
github.gds ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJsR5gu4+LPnomBEO37hY0l1chnD6U3eA1EHUg/o5op95dal49ZEvVEGtDCWyzwb2AF82/+APwCEHmAGF9l0suG5mU/VvtH4ne+S1Kji0TY+67t5rDDmckC0hqSkBxBrDyHROkXtRIyc/dyyuRhQBgW6zY1bEgM+eobxskWqBbx8bbUhPqH61Bm8fUCegvbgta8YHLKRF2fJ7EMkSXB8ghHQiiWTh1qj7Sz5lUNVGlOwwvXGiVMTLNaTLM+yO/I4Z8+94VkMTkdF4GVP7mn0jx3o84hZ3ZfcKgdD3bWl+e5vLboKb5F4mxMBto85+0F7iI0vnko9mAVHkGKpJjDwf5
EOM

# Remove myself
rm -f /home/vagrant/postinstall.sh

exit
