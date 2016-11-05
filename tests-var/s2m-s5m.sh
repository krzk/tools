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

# clk:
echo "s2mps14-clk" > /sys/bus/platform/drivers/s2mps11-clk/unbind
echo "s2mps14-clk" > /sys/bus/platform/drivers/s2mps11-clk/bind

test_cat() {
  local val="$(cat $1)"
  test "$val" = "$2" || echo "ERROR: Wrong $1 ($val)"
}
test_cat /sys/kernel/debug/clk/s2mps11_ap/clk_enable_count 0
test_cat /sys/kernel/debug/clk/s2mps11_ap/clk_prepare_count 1
test_cat /sys/kernel/debug/clk/s2mps11_bt/clk_enable_count 0
test_cat /sys/kernel/debug/clk/s2mps11_bt/clk_prepare_count 0
test_cat /sys/kernel/debug/clk/s2mps11_cp/clk_enable_count 0
test_cat /sys/kernel/debug/clk/s2mps11_cp/clk_prepare_count 0


echo "s5m8767-clk" > /sys/bus/platform/drivers/s2mps11-clk/unbind
echo "s5m8767-clk" > /sys/bus/platform/drivers/s2mps11-clk/bind

echo "s2mps14-pmic" > /sys/bus/platform/drivers/s2mps11-pmic/unbind

GPIO=/sys/kernel/debug/gpio
grep gpio-21 $GPIO | grep LDO11 | grep "out hi"

# RTC
echo "s2mps14-rtc" > /sys/bus/platform/drivers/s5m-rtc/unbind
echo "s2mps14-rtc" > /sys/bus/platform/drivers/s5m-rtc/bind

echo "file drivers/rtc/rtc-s5m.c +p" > /sys/kernel/debug/dynamic_debug/control

RTC=rtc1
cat /proc/interrupts | grep -i rtc
/sbin/hwclock -w -f /dev/$RTC
rtcwake -d $RTC -m on -s 5 -v
rtcwake -d $RTC -m mem -s 5 -v
cat /proc/interrupts | grep -i rtc

# OLD:
RTC=rtc0
date 021010002012
/sbin/hwclock -w -f /dev/$RTC
cat /proc/interrupts | grep -i rtc
echo 0 > /sys/class/rtc/$RTC/wakealarm
echo `date '+%s' -d '+ 5 seconds'` > /sys/class/rtc/$RTC/wakealarm
echo mem > /sys/power/state
