#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E

. 0-common.sh

echo 0 > /sys/kernel/bL_switcher/active
cpu_online=0
for i in /sys/bus/cpu/devices/cpu*/online; do
    cpu_stat=$(cat $i)
    if [ $cpu_stat -eq 1 ]; then
        let "cpu_online+=1"
    fi
done
echo "CPU online: $cpu_online"
test $cpu_online -gt 1 || die "test $cpu_online -gt 1"
echo "CPU online: OK"

THERM="/sys/class/thermal"
test $(ls ${THERM}/*/temp | wc -l) -eq 5 || die "Number of thermal zones"
test_cat ${THERM}/cooling_device0/cur_state "0"
test_cat ${THERM}/cooling_device0/max_state "3"
test_cat ${THERM}/thermal_zone0/mode "enabled"
test_cat ${THERM}/thermal_zone0/passive "0"
test_cat ${THERM}/thermal_zone0/trip_point_0_temp "50000"
# Why this is less than room temperature?
test_cat_gt ${THERM}/thermal_zone0/temp 25000
test_cat_lt ${THERM}/thermal_zone0/temp 45000
test_cat_gt ${THERM}/thermal_zone1/temp 30000
test_cat_lt ${THERM}/thermal_zone1/temp 60000
test_cat_gt ${THERM}/thermal_zone2/temp 30000
test_cat_lt ${THERM}/thermal_zone2/temp 65000
test_cat_gt ${THERM}/thermal_zone3/temp 30000
test_cat_lt ${THERM}/thermal_zone3/temp 60000
test_cat_gt ${THERM}/thermal_zone4/temp 30000
test_cat_lt ${THERM}/thermal_zone4/temp 60000
echo "Temperature: OK"

rtcwake -d rtc0 -m on -s 5 > /dev/null
rtcwake -d rtc1 -m on -s 5 > /dev/null
echo "RTC: OK"

# Sound: manual or:
aplay /usr/share/sounds/alsa/Front_Right.wav > /dev/null
echo "Sound/aplay: OK"

echo "3810000.audss-clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/unbind
echo "3810000.audss-clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/bind
echo "Audss rebind: OK"

# Other:
# USB: manual
#reboot
#poweroff
