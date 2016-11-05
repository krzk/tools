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

echo "file drivers/rtc/rtc-s5m.c +p" > /sys/kernel/debug/dynamic_debug/control
date 021010002012
/sbin/hwclock -w -f /dev/rtc1
for i in `seq 50`; do
	echo 0 > /sys/class/rtc/rtc1/wakealarm
	echo `date '+%s' -d '+ 5 seconds'` > /sys/class/rtc/rtc1/wakealarm
	echo mem > /sys/power/state
	sleep 1
	echo
	echo "########################"
done
