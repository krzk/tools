#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t debugfs none /sys/kernel/debug

ls -al /sys/kernel/debug/regulator/ | grep CHARGER
ls -al /sys/kernel/debug/regulator/ | grep EMMC
grep . /sys/class/regulator/regulator.2/*
grep . /sys/class/regulator/regulator.3/*

cat /sys/class/power_supply/battery/uevent
cat /sys/class/power_supply/max*/uevent

test "`cat /sys/class/power_supply/max14577-charger/device/fast_charge_timer`" = "5" || echo "Wrong fast charge timer"
echo "4" > /sys/class/power_supply/max14577-charger/device/fast_charge_timer && echo "ERROR: Should return EINVAL"
test "`cat /sys/class/power_supply/max14577-charger/device/fast_charge_timer`" = "5" || echo "Wrong fast charge timer"
echo "6" > /sys/class/power_supply/max14577-charger/device/fast_charge_timer || echo "ERROR: Cannot set fast charge timer"
test "`cat /sys/class/power_supply/max14577-charger/device/fast_charge_timer`" = "6" || echo "Wrong fast charge timer"
echo "8" > /sys/class/power_supply/max14577-charger/device/fast_charge_timer && echo "ERROR: Should return EINVAL"
echo "5" > /sys/class/power_supply/max14577-charger/device/fast_charge_timer || echo "ERROR: Cannot set fast charge timer"


cat /sys/class/extcon/max*-muic/state

grep . /sys/class/regulator/regulator.15/*
grep . /sys/class/regulator/regulator.16/*
GPIO=/sys/kernel/debug/gpio
grep gpio-21 $GPIO | grep LDO11 | grep "out hi"

# Fuel Gauge
echo "1-0036" > /sys/bus/i2c/drivers/max17040/unbind
echo "1-0036" > /sys/bus/i2c/drivers/max17040/bind
