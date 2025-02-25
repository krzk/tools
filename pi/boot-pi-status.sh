#!/bin/bash
#
# Copyright (c) 2015-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

SERIAL_u3="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D45567-if00-port0"
SERIAL_mc1="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00CFE461-if00-port0"
SERIAL_x="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00521AAE-if00-port0"
SERIAL_hc1="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D4562A-if00-port0"
SERIAL_arndaleocta="/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0"

# board_ping host
board_ping() {
	/usr/sbin/ping -c 1 -q -W 1 "$1" > /dev/null
	if [ $? -eq 0 ]; then
		echo "online"
	else
		echo "offline"
	fi
	return 0
}

serial_check() {
	local serial="$1"

	if [ -c "$serial" ]; then
		echo "OK"
	else
		echo "ERROR"
	fi
	return 0
}

pi_check() {
	local hostname
	local msg

	hostname="$(/usr/bin/hostname)"

	msg="Target alarmpi boot up

Pi:
===
hostname: $hostname
IP:   $(ip addr show dev eth0 | grep inet | cut -f 6 -d ' ')
temp: $(cat /sys/class/thermal/thermal_zone0/temp)"

	if [ "$hostname" == "pi3" ]; then
		msg="$msg

Boards:
=======
Arndale Octa: $(sudo /usr/local/bin/gpio-pi.py arndaleocta status)
Arndale Octa serial: $(serial_check $SERIAL_arndaleocta)
Arndale Octa ping: $(board_ping arndaleocta)
Odroid X: $(sudo /usr/local/bin/gpio-pi.py odroidx status)
Odroid X serial: $(serial_check $SERIAL_x)
Odroid X ping: $(board_ping odroidx)
Odroid MC1: $(sudo /usr/local/bin/gpio-pi.py odroidmc1 status)
Odroid MC1 serial: $(serial_check $SERIAL_mc1)
Odroid MC1 ping: $(board_ping odroidmc1)
Odroid HC1: $(sudo /usr/local/bin/gpio-pi.py odroidhc1 status)
Odroid HC1 serial: $(serial_check $SERIAL_hc1)
Odroid HC1 ping: $(board_ping odroidhc1)
Odroid U3: $(sudo /usr/local/bin/gpio-pi.py odroidu3 status)
Odroid U3 serial: $(serial_check $SERIAL_u3)
Odroid U3 ping: $(board_ping odroidu3)
"
	fi
	echo "$msg" | /usr/bin/mail -i -s "Target $hostname boot up" root
}

pi_check
