# Kali Linux NVIDIA HDMI External Monitor Fix

This repository provides an automated fix script and a diagnostic guide to resolve the issue where external monitors connected via HDMI (or DisplayPort) are not detected on Kali Linux after installing the proprietary NVIDIA drivers. 

This issue typically affects hybrid graphics (Optimus) laptops equipped with both an integrated GPU (Intel or AMD) and a discrete NVIDIA GPU, running a GNOME Wayland desktop environment.

---

## The Problem

After transitioning from the open-source Nouveau driver to the proprietary NVIDIA driver, the external monitor connected via HDMI stops receiving a signal and is no longer detected by the operating system. Meanwhile, the laptop's built-in display continues to function normally.

---

## Diagnostics

To determine if your system is affected by this specific issue, verify the following:

### 1. Verify Display Session Type
Check if your desktop environment is running under Wayland:
```bash
echo $XDG_SESSION_TYPE
```
This guide applies if the output is `wayland`.

### 2. Verify NVIDIA Driver Status
Confirm that the proprietary NVIDIA driver is loaded and active:
```bash
nvidia-smi
```
And check that the kernel modules are loaded:
```bash
lsmod | grep nvidia
```
You should see modules like `nvidia`, `nvidia_modeset`, `nvidia_uvm`, and `nvidia_drm` in the output.

### 3. Check Kernel Modesetting Status
Check if Kernel Modesetting (KMS) is enabled for the NVIDIA DRM module:
```bash
cat /sys/module/nvidia_drm/parameters/modeset
```
* **If the output is N:** Kernel Modesetting is disabled. This is the root cause of the issue.
* **If the output is Y:** Modesetting is already enabled. The issue may lie elsewhere (e.g., physical cables, ports, or display configuration).

---

## Why It Happens (Root Cause)

1. **Hardware Topography (Hybrid Graphics):** In most hybrid graphics laptops, the laptop's internal panel is driven directly by the integrated GPU (Intel or AMD). However, the external HDMI port is physically wired directly to the discrete NVIDIA GPU.
2. **Wayland and KMS Requirements:** Modern Wayland compositors (such as GNOME's Mutter) require Kernel Mode Setting (KMS) to interface with graphics hardware. They use DRM/KMS APIs to discover display outputs and manage multi-monitor setups.
3. **The Driver Configuration:** When installing the proprietary NVIDIA drivers on Debian-based distributions like Kali Linux, DRM Kernel Modesetting is disabled by default (`nvidia-drm.modeset=0` or `modeset=N`).
4. **The Consequence:** Because KMS is disabled, the NVIDIA driver does not register its display interfaces with the Linux kernel's DRM subsystem. The Wayland compositor cannot see the NVIDIA GPU as a display-capable device. Consequently, the HDMI port and any connected monitor are completely ignored by the system.

---

## The Solution

To resolve this issue, Kernel Modesetting must be enabled for the NVIDIA driver so that the Wayland compositor can detect and manage the HDMI output. This requires updating the modprobe configuration and the GRUB bootloader parameters, followed by rebuilding the initramfs.

The included `apply_fix.sh` script automates this process.

### What the Fix Script Does:

1. **Creates Modprobe Configuration:** It creates or updates `/etc/modprobe.d/nvidia-drm-modeset.conf` with the following option:
   ```ini
   options nvidia-drm modeset=1
   ```
2. **Appends GRUB Boot Parameters:** It updates `/etc/default/grub` to append `nvidia_drm.modeset=1` to the kernel boot command line (`GRUB_CMDLINE_LINUX_DEFAULT`).
3. **Rebuilds the Initramfs:** It regenerates the initial ramdisk (`update-initramfs -u`) to ensure the NVIDIA kernel driver is loaded with modesetting enabled during the early stages of system boot.
4. **Updates the Bootloader:** It updates the GRUB boot menu configurations (`update-grub`).

---

## How to Apply the Fix

1. Clone this repository:
   ```bash
   git clone https://github.com/ishan3299/kali-nvidia-hdmi-fix.git
   cd kali-nvidia-hdmi-fix
   ```

2. Make the script executable:
   ```bash
   chmod +x apply_fix.sh
   ```

3. Run the script with root privileges:
   ```bash
   sudo ./apply_fix.sh
   ```

4. Reboot your system:
   ```bash
   sudo reboot
   ```

---

## Post-Fix Verification

Once your system has rebooted, check the status of Kernel Modesetting again:

```bash
cat /sys/module/nvidia_drm/parameters/modeset
```

* The output should now be **Y**.
* Connect your HDMI cable. The external monitor should be detected immediately by GNOME and can be configured in Settings -> Displays.
