#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-bat}"

if [[ "$MODE" == "ac" ]]; then
  echo "Restoring full AC performance, nya~"
  sudo tlp ac
  for cpu in /sys/devices/system/cpu/cpu{2..7}/online; do
    [[ -f "$cpu" ]] && echo 1 | sudo tee "$cpu" >/dev/null
  done
  for card in /sys/class/drm/card*/gt_RP0_freq_mhz; do
    dir=$(dirname "$card")
    max_freq=$(cat "$card")
    echo "$max_freq" | sudo tee "$dir/gt_max_freq_mhz" "$dir/gt_boost_freq_mhz" >/dev/null 2>&1 || true
  done
  sudo modprobe uvcvideo btusb 2>/dev/null || true
  echo "AC mode active!"
  exit 0
fi

echo "Starting ultra battery optimizations, nyaa~"

# 1. Start TLP and force battery mode first (before powertop)
sudo tlp start
sudo tlp power-saver

# 2. Apply CPU power caps (15W short / 12W long)
sudo tee /etc/intel-undervolt.conf >/dev/null <<'EOF'
enable yes

undervolt 0 'CPU' 0
undervolt 1 'GPU' 0
undervolt 2 'CPU Cache' 0
undervolt 3 'System Agent' 0
undervolt 4 'Analog I/O' 0

power package 12/4 10/18
tjoffset -5
daemon interval 5000
EOF
sudo intel-undervolt apply
sudo systemctl restart intel-undervolt.service

# 3. Park P-cores (keep cpu0, cpu1, and E-cores cpu8..11)
for cpu in /sys/devices/system/cpu/cpu{2..7}/online; do
  [[ -f "$cpu" ]] && echo 0 | sudo tee "$cpu" >/dev/null
done

# 4. Cap Intel iGPU clock to 300MHz for Neovim/MangoWC
for dir in /sys/class/drm/card*; do
  [[ -f "$dir/gt_max_freq_mhz" ]] && echo 300 | sudo tee "$dir/gt_max_freq_mhz" "$dir/gt_boost_freq_mhz" >/dev/null 2>&1 || true
done

# 5. Apply audio power-save both persistently and immediately
sudo tee /etc/modprobe.d/audio-powersave.conf >/dev/null <<'EOF'
options snd_hda_intel power_save=1 power_save_controller=Y
EOF
[[ -f /sys/module/snd_hda_intel/parameters/power_save ]] && echo 1 | sudo tee /sys/module/snd_hda_intel/parameters/power_save >/dev/null

# 6. Apply VM & NVMe writeback coalescing
sudo tee /etc/sysctl.d/99-battery.conf >/dev/null <<'EOF'
vm.laptop_mode = 5
vm.dirty_writeback_centisecs = 6000
vm.dirty_expire_centisecs = 6000
kernel.nmi_watchdog = 0
EOF
sudo sysctl --system >/dev/null

# 7. Unload unused webcam/Bluetooth modules & run powertop auto-tune last
sudo modprobe -r uvcvideo btusb 2>/dev/null || true
sudo powertop --auto-tune >/dev/null 2>&1 || true

# 8. Re-enable USB autosuspend only if needed, keeping HID mice responsive
for usb in /sys/bus/usb/devices/*/power/control; do
  dir=$(dirname "$usb")
  if grep -qiE "mouse|receiver|keyboard|hid" "$dir/product" 2>/dev/null; then
    echo on | sudo tee "$usb" >/dev/null
  fi
done

echo "--- Active Power Limits ---"
sudo intel-undervolt read | grep -A 3 "Power"
echo "Online CPUs: $(cat /sys/devices/system/cpu/online)"
echo "Battery mode locked in, purr~"
