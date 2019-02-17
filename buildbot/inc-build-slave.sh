#!/bin/bash
#
# Copyright (c) 2016-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

# die error_msg
die() {
	echo "Fail: $1"
	exit 1
}

# On arch ping6 and ping were merged so '-4' and '-6' arguments are supported.
# However on pi, the IPv6 is disabled and running just 'ping' causes error:
# ping: socket: Address family not supported by protocol (raw socket required by specified options).
# Detect if '-4' is supported, if it is, then use it
get_ping() {
	ping -h |& grep vV64 > /dev/null
	if [ $? -eq 0 ]; then
		echo 'ping -4'
	else
		echo 'ping'
	fi
}

# get_serial target
get_serial() {
	local target=$1
	local serial=""

	case "$target" in
	arndaleocta|octa)
		serial="/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_A50285BI-if00-port0"
		;;
	odroidu3|u3)
		serial="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D45567-if00-port0"
		;;
	odroidxu3|xu3)
		serial="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00CFE461-if00-port0"
		;;
	odroidxu|xu)
		serial="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00521AAE-if00-port0"
		;;
	odroidhc1|hc1)
		serial="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D4562A-if00-port0"
		;;
	*)
		echo ""
		return 1
	esac

	echo $serial
	return 0
}
