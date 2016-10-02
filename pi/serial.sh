#!/bin/sh
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

SERIAL=/dev/ttyUSB
if [ $# -gt 0 ]; then
	if [ "$1" = "xu3" ]; then
		SERIAL="/dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00CFE461-if00-port0"
	else
		SERIAL="${SERIAL}$1"
	fi
fi
picocom -b 115200 $SERIAL
