#!/bin/bash
#
# Copyright (c) 2022 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

test_exynos5422_dmc() {
	local name="exynos5422-dmc"
	local device="10c20000.memory-controller"
	local sysfs="/sys/bus/platform/drivers/exynos5-dmc/${device}"
	print_msg "Testing..."

	local dmesg_log="$(dmesg | grep $device)"
	case "$(get_board_compatible)" in
		hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4)
		;;
	*)
		test -z "$dmesg_log" || error_msg "ERROR: Expected missing dmesg log for $device"
		test ! -e "$sysfs" || error_msg "ERROR: Expected missing $sysfs"
		print_msg "OK"
		return 0
		;;
	esac

	test -n "$dmesg_log" || error_msg "ERROR: Expected dmesg log for $device"
	[[ "$dmesg_log" == *"DMC initialized"* ]] || error_msg "ERROR: Expected dmesg log for $device"

	test -L "$sysfs"
	test -L "${sysfs}/of_node"
	test -d "${sysfs}/devfreq"
	test -d "${sysfs}/devfreq/${device}"
	test_cat "${sysfs}/devfreq/${device}/name" "$device"
	test_cat "${sysfs}/devfreq/${device}/min_freq" "165000000"
	test_cat "${sysfs}/devfreq/${device}/max_freq" "825000000"
	test_cat_ge "${sysfs}/devfreq/${device}/cur_freq" "165000000"
	test_cat_le "${sysfs}/devfreq/${device}/cur_freq" "825000000"

	print_msg "OK"
}

test_exynos5422_dmc
