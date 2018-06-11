#!/bin/bash
#
# Copyright (c) 2016-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_usb() {
	local name="lsusb"
	local expected_usb=""

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1)
		# Format: NUMBER_VENDOR:PRODUCT
		expected_usb="1_1d6b:0001 3_1d6b:0002 2_1d6b:0003 1_0bda:8153"
		;;
	hardkernel,odroid-u3)
		# Format: NUMBER_VENDOR:PRODUCT
		expected_usb="1_1d6b:0002 1_0424:3503 1_0424:9730"
		;;
	hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite)
		# Format: NUMBER_VENDOR:PRODUCT
		expected_usb="1_1d6b:0001 2_1d6b:0002 1_1d6b:0003 1_0424:ec00 1_0424:9514"
		;;
	*)
		error_msg "Wrong board"
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
