#!/bin/bash
#
# Copyright (c) 2016,2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
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
		# Format: NUMBER_VENDOR:PRODUCT
		expected_usb="1_1d6b:0001 2_1d6b:0002 1_1d6b:0003 1_0424:ec00 1_0424:9514"
		;;
	*)
		print_msg "ERROR: Wrong board"
		return
	esac

	for usb in $expected_usb; do
		usb_no=${usb%_*}
		usb_dev=${usb#*_}
		found=$(lsusb -d "$usb_dev" | wc -l)
		test "$found" == "$usb_no" || error_msg "Missing USB device: $usb"
	done

	print_msg "OK"
}

test_usb
