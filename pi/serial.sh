#!/bin/sh
#
# Copyright (c) 2015-2025 Krzysztof Kozlowski
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

SERIAL=/dev/ttyUSB
if [ $# -gt 0 ]; then
	if [ "$1" = "u3" ]; then
		SERIAL="$SERIAL_u3"
	elif [ "$1" = "x" ]; then
		SERIAL="$SERIAL_x"
	elif [ "$1" = "mc1" ]; then
		SERIAL="$SERIAL_mc1"
	elif [ "$1" = "hc1" ]; then
		SERIAL="$SERIAL_hc1"
	elif [ "$1" = "arndaleocta" ] || [ "$1" = "octa" ]; then
		SERIAL="$SERIAL_arndaleocta"
	else
		SERIAL="${SERIAL}$1"
	fi
fi
picocom -b 115200 --flow none "$SERIAL"
