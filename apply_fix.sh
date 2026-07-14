#!/bin/bash
set -e

echo "Applying Nvidia HDMI display output fix..."

# 1. Create the modprobe configuration to enable KMS on nvidia-drm
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm-modeset.conf

# 2. Update GRUB configuration to include nvidia_drm.modeset=1
# Backup /etc/default/grub
sudo cp /etc/default/grub /etc/default/grub.bak

# Update GRUB_CMDLINE_LINUX_DEFAULT
if grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
    echo "nvidia_drm.modeset=1 already present in /etc/default/grub"
else
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/g' /etc/default/grub
    echo "Added nvidia_drm.modeset=1 to /etc/default/grub"
fi

# 3. Update initramfs to make sure the modeset setting is loaded early in boot
echo "Updating initramfs..."
sudo update-initramfs -u

# 4. Update GRUB menu entries
echo "Updating GRUB..."
sudo update-grub

echo "Fix applied successfully! Please reboot your system to apply changes."
