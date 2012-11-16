# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

date > /etc/vagrant_box_build_time

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline5-dev
apt-get clean

# Setup sudo to allow no-password sudo for "admin"
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

# Install NFS client
apt-get -y install nfs-common

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

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

# Install sqlite
apt-get -y install sqlite3 libsqlite3-dev

# Install ruby
apt-get -y install python-software-properties
apt-add-repository ppa:brightbox/ruby-ng
apt-get -y update
apt-get -y install ruby1.9.1 ruby1.9.1-dev rubygems

# Install and configure puppet
gem install -v "= 2.7.19" puppet --no-ri --no-rdoc

echo "FACTER_govuk_class=development" >> /etc/environment
echo "FACTER_govuk_platform=development" >> /etc/environment

# Setup sudo to preserve Facter variables
sed -i -e '/Defaults\s\+env_reset/a Defaults\tenv_keep+="FACTER_govuk_platform FACTER_govuk_class"' /etc/sudoers

mkdir -p /etc/puppet
cat >/etc/puppet/puppet.conf <<EOM
[main]
modulepath=/var/govuk/puppet/modules:/var/govuk/puppet/vendor/modules
manifestdir=/var/govuk/puppet/manifests
EOM

cat >/usr/local/bin/govuk_puppet <<EOM
#!/bin/sh
cd /var/govuk/puppet
exec sudo RUBYOPT="-W0" puppet apply manifests/site.pp $@
EOM
chmod +x /usr/local/bin/govuk_puppet

exit
