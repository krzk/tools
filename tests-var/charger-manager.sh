#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t debugfs none /sys/kernel/debug

# OLD virtual device, no parent
cat /sys/devices/virtual/power_supply/battery/uevent
grep . /sys/devices/virtual/power_supply/battery/charger.0/*
# NEW, with parent
cat /sys/class/power_supply/battery/uevent
grep . /sys/class/power_supply/battery/charger.0/*

cat /sys/class/thermal/thermal_zone*/temp

sleep 5 && grep . /sys/devices/virtual/power_supply/battery/charger.0/* > /log.txt
cat /log.txt

echo "charger-manager@0" > /sys/bus/platform/drivers/charger-manager/unbind
echo "charger-manager@0" > /sys/bus/platform/drivers/charger-manager/bind

# Trats2
cat /sys/devices/virtual/power_supply/battery/capacity &
echo "12-0036" > /sys/bus/i2c/drivers/max17042/unbind
cat /sys/devices/virtual/power_supply/battery/capacity
cat /sys/devices/virtual/power_supply/battery/temp
cat /sys/class/thermal/thermal_zone*/temp

echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/unbind
grep . /sys/devices/virtual/power_supply/battery/charger.0/*
grep . /sys/devices/virtual/power_supply/battery/*
cat /sys/devices/virtual/power_supply/battery/capacity

echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/bind
grep . /sys/devices/virtual/power_supply/battery/charger.0/*
grep . /sys/devices/virtual/power_supply/battery/*
cat /sys/devices/virtual/power_supply/battery/capacity

echo "12-0036" > /sys/bus/i2c/drivers/max17042/bind
cat /sys/devices/virtual/power_supply/battery/capacity
cat /sys/devices/virtual/power_supply/battery/temp
cat /sys/class/thermal/thermal_zone*/temp


# Testing external thermal zone
# Change charger-manager or FG to ignore FG reports
# DTS: cm-thermal-zone = "max170xx_battery";
cat /sys/devices/virtual/power_supply/battery/temp_ambient
echo "12-0036" > /sys/bus/i2c/drivers/max17042/unbind
cat /sys/devices/virtual/power_supply/battery/temp_ambient
cat /sys/devices/virtual/power_supply/battery/temp

echo "12-0036" > /sys/bus/i2c/drivers/max17042/unbind
echo "12-0036" > /sys/bus/i2c/drivers/max17042/bind
cat /sys/devices/virtual/power_supply/battery/temp_ambient
cat /sys/devices/virtual/power_supply/battery/temp


# Rinato
echo "1-0036" > /sys/bus/i2c/drivers/max17040/unbind
cat /sys/devices/virtual/power_supply/cm-battery/online
cat /sys/devices/virtual/power_supply/cm-battery/capacity

echo "1-0036" > /sys/bus/i2c/drivers/max17040/bind
cat /sys/devices/virtual/power_supply/cm-battery/online
cat /sys/devices/virtual/power_supply/cm-battery/capacity

cat /sys/devices/virtual/power_supply/cm-battery/capacity &
echo "1-0036" > /sys/bus/i2c/drivers/max17040/unbind
