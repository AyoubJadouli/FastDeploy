#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Modify /etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Prompt user for network configuration
read -p "Enter the desired IP address (default is 10.10.10.X): " IP_ADDRESS
if [[ -z "$IP_ADDRESS" ]]; then
    IP_ADDRESS="10.10.10.$((RANDOM % 100))"
fi

GATEWAY="${IP_ADDRESS%.*}.1"
read -p "Enter the gateway (default is $GATEWAY): " USER_GATEWAY
if [[ ! -z "$USER_GATEWAY" ]]; then
    GATEWAY=$USER_GATEWAY
fi

# Modify /etc/network/interfaces
cat <<EOL > /etc/network/interfaces
auto lo
iface lo inet loopback

iface eth0 inet manual

auto vmbr0
iface vmbr0 inet static
    address $IP_ADDRESS/24
    gateway $GATEWAY
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0
EOL



# Install a standard Debian Bookworm (amd64)
# Assuming you have already installed Debian and set a static IP.

# Add an /etc/hosts entry for your IP address
IP=$(hostname --ip-address)
echo "127.0.0.1       localhost" > /etc/hosts
echo "$IP   $(hostname).proxmox.com $(hostname)" >> /etc/hosts

echo "
# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" >> /etc/hosts

# Install Proxmox VE
# Adapt sources.list
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

# Add the Proxmox VE repository key
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 

# Update your repository and system
apt update && apt full-upgrade -y

# Install the Proxmox VE Kernel
apt install -y pve-kernel-6.2

# Reboot
echo "System will reboot in 10 seconds. Please run the script again after reboot."
sleep 10
reboot

# If you are reading this after rebooting, comment the lines above this and run the script again

# Install the Proxmox VE packages
apt install -y proxmox-ve postfix open-iscsi

# Remove the Debian Kernel
apt remove -y linux-image-amd64 'linux-image-6.1*'

# Update and check grub2 config
update-grub

# Remove the os-prober Package
apt remove -y os-prober

# Notes
echo "Don't forget to:"
echo "1. Connect to the Proxmox VE web interface (https://your-ip-address:8006)"
echo "2. Create a Linux Bridge"
echo "3. Upload Subscription Key (if you have one)"
echo "4. Troubleshoot any issues using the provided troubleshooting guide"

