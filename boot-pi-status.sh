#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

pi_check() {
	local hostname=$(/usr/bin/hostname)
	local ping="offline"
	/usr/sbin/ping -c 1 -q -W 1 odroid > /dev/null
	test $? -eq 0 && ping="online"

	echo "Target alarmpi boot up

Pi thermal:
===========
temp: $(cat /sys/class/thermal/thermal_zone0/temp)
mode: $(cat /sys/class/thermal/thermal_zone0/mode)

Odroid:
=======
Ping: $ping
" | /usr/bin/mail -i -s 'Target alarmpi boot up' root
	wait
	# TODO: Find better way to wait for sendmail finish
	sleep 20
#$(sudo /usr/local/bin/gpio-pi.py status)
}

pi_check
# TODO: setsid, disown?
