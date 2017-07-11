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

# board_ping host
board_ping() {
	/usr/sbin/ping -c 1 -q -W 1 $1 > /dev/null
	if [ $? -eq 0 ]; then
		echo "online"
	else
		echo "offline"
	fi
	return 0
}

pi_check() {
	local hostname=$(/usr/bin/hostname)

	echo "Target alarmpi boot up

Pi:
===
IP:   $(ip addr show dev eth0 | grep inet | cut -f 6 -d ' ')
temp: $(cat /sys/class/thermal/thermal_zone0/temp)

Boards:
=======
Odroid XU3: $(sudo /usr/local/bin/gpio-pi.py odroidxu3 status)
Odroid XU3 ping: $(board_ping odroidxu3)
Odroid U3: $(sudo /usr/local/bin/gpio-pi.py odroidu3 status)
Odroid U3 ping: $(board_ping odroidu3)
" | /usr/bin/mail -i -s 'Target alarmpi boot up' root
	wait
	# TODO: Find better way to wait for sendmail finish
	sleep 20
}

pi_check
# TODO: setsid, disown?
