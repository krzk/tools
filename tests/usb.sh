#!/bin/bash
#
# Copyright (c) 2016-2020 Krzysztof Kozlowski
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
	hardkernel,odroid-x)
		# Format: NUMBER_VENDOR:PRODUCT
		expected_usb="1_1d6b:0002 1_0424:3503 1_0424:9514 1_0424:ec00"
		;;
	hardkernel,odroid-xu)
		# Format: NUMBER_VENDOR:PRODUCT
		expected_usb="1_1d6b:0001 2_1d6b:0002 1_1d6b:0003 1_0424:3503 1_0424:9730"
		;;
	hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite)
		# Format: NUMBER_VENDOR:PRODUCT
		if is_kernel_le 4 4; then
			expected_usb="1_1d6b:0001 3_1d6b:0002 2_1d6b:0003 1_0424:ec00 1_0424:9514"
		else
			expected_usb="1_1d6b:0001 2_1d6b:0002 1_1d6b:0003 1_0424:ec00 1_0424:9514"
		fi
		;;
	insignal,arndale-octa)
		if is_kernel_le 4 9; then
			expected_usb="1_1d6b:0001 3_1d6b:0002 2_1d6b:0003 1_0b95:772a 1_05e3:0610"
		elif is_kernel_le 4 14; then
			# Kernel v4.14 does not detect one USB 3.0 hub. v4.4 and v4.9 have the same
			# as mainline.
			expected_usb="1_1d6b:0001 2_1d6b:0002 1_1d6b:0003 1_0b95:772a 1_05e3:0610"
		else
			expected_usb="1_1d6b:0001 3_1d6b:0002 2_1d6b:0003 1_0b95:772a 1_05e3:0610"
		fi
		;;
	*)
		error_msg "Wrong board"
	esac

	for usb in $expected_usb; do
		usb_no=${usb%_*}
		usb_dev=${usb#*_}
		found=$(lsusb -d "$usb_dev" | wc -l)
		test "$found" == "$usb_no" || error_msg "Not matched USB device: $usb (found: $found, expected: $usb_no)"
	done

	print_msg "OK"
}

test_usb
