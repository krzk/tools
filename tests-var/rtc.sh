#!/bin/bash

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t debugfs none /sys/kernel/debug

dmesg | grep rtc
rtcwake -d rtc0 -m mem -s 5 -v
rtcwake -d rtc0 -m on -s 5 -v
rtcwake -d rtc1 -m mem -s 5 -v

RTC=rtc1
cat /proc/interrupts | grep -i rtc
/sbin/hwclock -w -f /dev/$RTC
rtcwake -d $RTC -m on -s 5 -v
rtcwake -d $RTC -m mem -s 5 -v
cat /proc/interrupts | grep -i rtc

echo max77686-rtc > /sys/bus/platform/drivers/max77686-rtc/unbind
echo max77686-rtc > /sys/bus/platform/drivers/max77686-rtc/bind
rtcwake -d rtc2 -m mem -s 5 -v

# OLD:
RTC=rtc0
date 021010002012
/sbin/hwclock -w -f /dev/$RTC
cat /proc/interrupts | grep -i rtc
echo 0 > /sys/class/rtc/$RTC/wakealarm
echo `date '+%s' -d '+ 5 seconds'` > /sys/class/rtc/$RTC/wakealarm
echo mem > /sys/power/state
