#!/usr/bin/env bash
set -euo pipefail

echo "Restoring full AC performance, nyaa~"

# 1. Switch TLP to AC profile
sudo tlp start
sudo tlp ac

# 2. Restore full CPU power limits (PL1 = 45W, PL2 = 65W)
sudo tee /etc/intel-undervolt.conf >/dev/null <<'CONF'
enable yes

undervolt 0 'CPU' 0
undervolt 1 'GPU' 0
undervolt 2 'CPU Cache' 0
undervolt 3 'System Agent' 0
undervolt 4 'Analog I/O' 0

power package 65/28 45/28
tjoffset 0
daemon interval 5000
CONF
sudo intel-undervolt apply
sudo systemctl restart intel-undervolt.service

# 3. Bring all parked P-cores back online
for cpu in /sys/devices/system/cpu/cpu{0..11}/online; do
  [[ -f "$cpu" ]] && echo 1 | sudo tee "$cpu" >/dev/null
done

# 4. Unlock full Intel iGPU boost clocks
for card in /sys/class/drm/card*/gt_RP0_freq_mhz; do
  dir=$(dirname "$card")
  max_freq=$(cat "$card")
  echo "$max_freq" | sudo tee "$dir/gt_max_freq_mhz" "$dir/gt_boost_freq_mhz" >/dev/null 2>&1 || true
done

# 5. Restore default VM writeback & NMI watchdog settings
sudo rm -f /etc/sysctl.d/99-battery.conf
sudo sysctl -w vm.laptop_mode=0 vm.dirty_writeback_centisecs=500 vm.dirty_expire_centisecs=3000 kernel.nmi_watchdog=1 >/dev/null

# 6. Restore default audio power-save timeout (optional: keep 1 if you don't want popping)
sudo rm -f /etc/modprobe.d/audio-powersave.conf
[[ -f /sys/module/snd_hda_intel/parameters/power_save ]] && echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save >/dev/null

# 7. Reload webcam and Bluetooth kernel modules
sudo modprobe uvcvideo btusb bluetooth 2>/dev/null || true

# 8. Set USB/PCI runtime power control back to default 'on' so plugged-in peripherals have zero latency
for dev in /sys/bus/usb/devices/*/power/control; do
  echo on | sudo tee "$dev" >/dev/null 2>&1 || true
done

echo "--- Active AC Power Limits ---"
sudo intel-undervolt read | grep -A 3 "Power"
echo "Online CPUs: $(cat /sys/devices/system/cpu/online)"
echo "Max iGPU Freq: $(cat /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null || cat /sys/class/drm/card1/gt_max_freq_mhz) MHz"
echo "Full AC performance restored, purr~"
