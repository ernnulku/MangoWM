#!/bin/sh

if grep -q "Discharging" /sys/class/power_supply/BAT*/status 2>/dev/null; then
    echo "Running on battery power."
    sudo bash battery.sh
else
    echo "Plugged into AC power."
    sudo bash ac.sh
fi
