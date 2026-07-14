# NVIDIA Proprietary Driver External Display (HDMI) Resolution Report

This report documents the diagnosis and resolution of the external display (HDMI) issue encountered after installing the proprietary NVIDIA drivers on Kali Linux 2026.2.

---

## System Profile
* **OS:** Kali GNU/Linux Rolling x86_64 (Version 2026.2)
* **Kernel:** `7.0.12+kali-amd64`
* **Desktop Environment:** GNOME 50.2 (Running under **Wayland**)
* **Integrated GPU (iGPU):** Intel HD Graphics 530 (Skylake)
* **Discrete GPU (dGPU):** NVIDIA GeForce GTX 960M (Maxwell)
* **Connection Port:** Physical HDMI (physically wired to the NVIDIA dGPU)

---

## The Problem
After transitioning from the open-source Nouveau driver to the proprietary NVIDIA driver (550.163.01), the external monitor connected via HDMI stopped receiving any display signal and was no longer detected by the system. However, the internal laptop display (driven by the Intel IGP) worked perfectly.

---

## Diagnostics Process

### 1. Verification of Driver Loading
First, we verified that the proprietary NVIDIA driver was correctly installed and loaded:
* `lspci -nnk` confirmed the NVIDIA card was using the `nvidia` kernel driver.
* `nvidia-smi` successfully displayed the GPU stats, temperatures, and showed that GNOME Shell was registering memory allocation on the GPU.
* `lsmod | grep nvidia` showed that the core modules (`nvidia`, `nvidia_modeset`, `nvidia_uvm`, and `nvidia_drm`) were loaded.

### 2. Identifying the Display Session
Running `loginctl show-session 2 -p Type` and checking `$XDG_SESSION_TYPE` revealed that the GNOME desktop environment was running a Wayland session rather than X11.

### 3. Checking Kernel Modesetting (KMS)
Wayland compositors (like GNOME's Mutter) rely entirely on Kernel Mode Setting (KMS) to interface with graphics cards and manage display outputs. We inspected the DRM modeset configuration of the Nvidia driver:
```bash
cat /sys/module/nvidia_drm/parameters/modeset
```
* **Result:** `N` (Disabled)

This was the critical clue. With the open-source Nouveau driver, KMS is enabled by default. However, when installing the proprietary NVIDIA driver on Debian/Kali Linux, Kernel Modesetting is disabled by default.

---

## Why It Happened (Root Cause)

1. **Hardware Topography (Muxless Optimus):** On this HP Pavilion laptop, the laptop's internal screen is wired to the Intel iGPU, but the external HDMI port is physically wired directly to the NVIDIA dGPU.
2. **KMS & Wayland Requirements:** Because the display session is running on Wayland, the system cannot use legacy X11 offloading mechanisms. Mutter (the display manager) needs to talk to the NVIDIA card using DRM/KMS APIs to discover its ports (HDMI) and route frames.
3. **The Block:** Since `nvidia-drm.modeset` was set to `0` (disabled), the Nvidia driver did not register its KMS display interfaces with the Linux kernel. Therefore, the HDMI port was completely invisible to GNOME, making the external monitor appear "disconnected" or undetected.

---

## Resolution Applied

To fix this, we enabled NVIDIA DRM Kernel Modesetting, allowing Wayland to recognize and drive the HDMI port. The following steps were executed:

### Step 1: Force Kernel Modesetting on Nvidia Module
We created a modprobe configuration file at `/etc/modprobe.d/nvidia-drm-modeset.conf` containing:
```ini
options nvidia-drm modeset=1
```

### Step 2: Inject Boot Parameter into GRUB
We modified `/etc/default/grub` to append `nvidia_drm.modeset=1` to the default kernel boot options:
```ini
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia_drm.modeset=1"
```

### Step 3: Rebuild the Initramfs
Because the graphics modules are loaded early in the boot sequence, we rebuilt the initramfs to ensure the new `modeset=1` option is bundled:
```bash
sudo update-initramfs -u
```

### Step 4: Update the Bootloader
Finally, we regenerated the GRUB boot menu configuration to apply the new command-line parameters:
```bash
sudo update-grub
```

---

## What to do next

To apply the changes and restore HDMI output:

1. **Reboot the system:**
   ```bash
   sudo reboot
   ```
2. **Connect the HDMI Monitor:** Once the system reboots, GNOME Mutter will initialize the NVIDIA card with KMS support, detect the monitor on the HDMI port, and automatically activate it.
3. **Verify:**
   You can verify that KMS is active after rebooting by running:
   ```bash
   cat /sys/module/nvidia_drm/parameters/modeset
   # This should now output: Y
   ```

---

> [!NOTE]
> This fix ensures that your GPU offloading (PRIME) also functions optimally under Wayland, allowing you to run performance-intensive tools (like Hashcat) on the NVIDIA GPU while GNOME displays everything smoothly.
