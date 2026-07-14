# Kali Linux Nvidia HDMI External Monitor Fix

This repository provides a diagnostic guide and an automated script to resolve the issue where external monitors (connected via HDMI) stop working on Kali Linux after installing the proprietary NVIDIA drivers.

This problem typically affects hybrid graphics (Optimus) laptops with both an integrated GPU (Intel/AMD) and a discrete NVIDIA GPU, running a GNOME Wayland session.

---

## The Problem

After switching from the open-source Nouveau driver to the proprietary NVIDIA driver, the external monitor connected via HDMI stops receiving any display signal and is no longer detected by the system. However, the internal laptop display (driven by the integrated graphics) continues to work.

---

## Why It Happens (Root Cause)

1. **Hardware Routing:** On many hybrid laptops, the internal screen is wired to the integrated graphics card, while the external HDMI port is physically wired directly to the discrete NVIDIA GPU.
2. **Wayland and KMS Requirements:** Modern desktop environments running under Wayland (such as GNOME with Mutter) rely entirely on Kernel Mode Setting (KMS) to interface with graphics hardware and manage display outputs.
3. **The Configuration Gap:** When installing the proprietary NVIDIA driver on Debian-based distributions like Kali Linux, DRM Kernel Modesetting is disabled by default (`nvidia-drm.modeset=0`).
4. **The Result:** Because KMS is disabled, the NVIDIA driver does not register its display interfaces with the Linux kernel's DRM subsystem. The Wayland compositor cannot see the NVIDIA GPU as a display-capable device, rendering the HDMI port completely invisible.

---

## The Solution

To fix this, Kernel Modesetting must be enabled for the Nvidia driver. This requires making configuration changes to both the modprobe module options and the GRUB bootloader parameters, followed by rebuilding the initramfs.

The included `apply_fix.sh` script automates these steps.

### What the Script Does:

1. **Creates Modprobe Configuration:** It adds `options nvidia-drm modeset=1` to `/etc/modprobe.d/nvidia-drm-modeset.conf`.
2. **Updates GRUB Parameters:** It appends `nvidia_drm.modeset=1` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`.
3. **Rebuilds Initramfs:** Rebuilds the initial ramdisk (using `update-initramfs -u`) to ensure the Nvidia driver loads with modesetting enabled during early boot.
4. **Updates GRUB Bootloader:** Runs `update-grub` to apply the updated kernel command-line arguments.

---

## How to Use

1. Clone this repository:
   ```bash
   git clone https://github.com/ishan3299/kali-nvidia-hdmi-fix.git
   cd kali-nvidia-hdmi-fix
   ```

2. Make the script executable:
   ```bash
   chmod +x apply_fix.sh
   ```

3. Run the script with sudo privileges:
   ```bash
   sudo ./apply_fix.sh
   ```

4. Reboot your system:
   ```bash
   sudo reboot
   ```

---

## Verification

After rebooting, you can verify that Kernel Modesetting is successfully enabled by running:

```bash
cat /sys/module/nvidia_drm/parameters/modeset
```

If the output is `Y`, modesetting is active. Connect your HDMI cable, and the external display will now be detected and work as expected.
