#!/bin/bash

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t debugfs none /sys/kernel/debug

# regulator
cat /sys/kernel/debug/regulator/regulator_summary
cat /sys/bus/platform/devices/max77686-pmic/uevent
echo "max77686-pmic" > /sys/bus/platform/drivers/max77686-pmic/unbind
echo "max77686-pmic" > /sys/bus/platform/drivers/max77686-pmic/bind

ls -al /sys/kernel/debug/regulator
# Suspend on:
grep . /sys/class/regulator/regulator.6/*state*
# Suspend off:
grep . /sys/class/regulator/regulator.14/*state*
grep . /sys/class/regulator/regulator.33/*state*
grep . /sys/class/regulator/regulator.34/*state*
# GPIO regulators:
grep . /sys/class/regulator/regulator.24/*state*
grep . /sys/class/regulator/regulator.25/*state*
grep . /sys/class/regulator/regulator.26/*state*
grep . /sys/class/regulator/regulator.38/*state*
grep . /sys/class/regulator/regulator.39/*

# suspended regulators (before/after suspend):
REG=/sys/class/regulator/regulator
test "`cat ${REG}.6/microvolts`" = "1200000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.10/microvolts`" = "1000000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.11/microvolts`" = "1000000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.12/microvolts`" = "1000000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.14/microvolts`" = "1800000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.15/microvolts`" = "1950000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.16/microvolts`" = "3000000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.18/microvolts`" = "1950000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.19/microvolts`" = "1000000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.20/microvolts`" = "1800000" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.39/microvolts`" = "1200000" || echo "ERROR: WRONG VALUE"

# names:
test "`cat ${REG}.20/uevent | grep OF_NAME`" = "OF_NAME=ldo16" || echo "ERROR: WRONG VALUE"
test "`cat ${REG}.39/uevent | grep OF_NAME`" = "OF_NAME=buck9" || echo "ERROR: WRONG VALUE"

#GPIOs
GPIO=/sys/kernel/debug/gpio
grep gpio-85 $GPIO | grep LDO22 | grep "out hi"
grep gpio-131 $GPIO | grep BUCK9
grep gpio-174 $GPIO | grep LDO21 | grep "out lo"
# insert SD card
grep gpio-174 $GPIO | grep LDO21 | grep "out hi"
grep . /sys/class/regulator/regulator.28/*
# remove SD card
grep gpio-174 $GPIO | grep LDO21 | grep "out lo"



# RTC
date 021010002012
/sbin/hwclock -w -f /dev/rtc0
cat /proc/interrupts | grep -i rtc
rtcwake -d rtc0 -m on -s 5 -v
rtcwake -d rtc0 -m mem -s 5 -v

#clk
test "`ls /sys/kernel/debug/clk | grep 32khz_ | wc -l`" = "3" || echo "ERROR: WRONG VALUE"
grep . /sys/kernel/debug/clk/32khz_*/*
test "`cat /sys/kernel/debug/clk/32khz_ap/clk_prepare_count`" = "1" || echo "ERROR: WRONG VALUE"
