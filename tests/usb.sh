#!/bin/bash
#
# Copyright (c) 2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_usb() {
	local name="lsusb"
	local expected_usb=""

	case "$(get_board_compatible)" in
	hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite)
		expected_usb="1d6b:0001 1d6b:0002 1d6b:0003 0424:ec00 0424:9514"
		;;
	*)
		print_msg "ERROR: Wrong board"
		return
	esac

	for usb in $expected_usb; do
		lsusb -d "$usb" > /dev/null || error_msg "Missing USB device: $usb"
	done

	print_msg "OK"
}

test_usb
