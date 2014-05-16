# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

date > /etc/vmware_img_build_time

# Add VMware apt repo
apt-key adv --keyserver keyserver.ubuntu.com --recv 66FD4949
echo "deb http://packages.vmware.com/tools/esx/latest/ubuntu lucid main" >> /etc/apt/sources.list

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install vmware-tools-esx-nox vmware-tools-esx-kmods-$(uname -r)
apt-get clean

# Setup sudo to allow no-password sudo for "admin"
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

# Remove items used for building, since they aren't needed anymore
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

# Install and configure puppet
gem install puppet --no-ri --no-rdoc

exit
