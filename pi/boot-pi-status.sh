#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
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
hostname: $hostname
IP:   $(ip addr show dev eth0 | grep inet | cut -f 6 -d ' ')
temp: $(cat /sys/class/thermal/thermal_zone0/temp)

Boards:
=======
Odroid XU: $(sudo /usr/local/bin/gpio-pi.py odroidxu status)
Odroid XU ping: $(board_ping odroidxu)
Odroid XU3: $(sudo /usr/local/bin/gpio-pi.py odroidxu3 status)
Odroid XU3 ping: $(board_ping odroidxu3)
Odroid HC1: $(sudo /usr/local/bin/gpio-pi.py odroidhc1 status)
Odroid HC1 ping: $(board_ping odroidhc1)
Odroid U3: $(sudo /usr/local/bin/gpio-pi.py odroidu3 status)
Odroid U3 ping: $(board_ping odroidu3)
" | /usr/bin/mail -i -s "Target $hostname boot up" root
}

pi_check
