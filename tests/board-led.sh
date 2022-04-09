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

test_board_led() {
	local name="Board LED"
	local leds=""
	local sysfs="/sys/class/leds"
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1|hardkernel,odroid-xu4)
		leds="blue:heartbeat"
		;;
	hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu)
		leds="blue:heartbeat green:mmc0 red:microSD"
		;;
	hardkernel,odroid-u3)
		leds="led1:heart"
		;;
	hardkernel,odroid-x)
		leds="led1:heart led2:mmc0"
		;;
	*)
		print_msg "No LEDs on board, skipping"
		return 0
	esac

	for led in $leds; do
		echo $led
		test -d "${sysfs}/${led}"
		test_cat "${sysfs}/${led}/max_brightness" 255

		echo "none" > "${sysfs}/${led}/trigger"
		grep "\[none\]" "${sysfs}/${led}/trigger"
		echo "0" > "${sysfs}/${led}/brightness"
		test_cat "${sysfs}/${led}/brightness" 0

		echo "127" > "${sysfs}/${led}/brightness"
		test_cat "${sysfs}/${led}/brightness" 127

		echo "255" > "${sysfs}/${led}/brightness"
		test_cat "${sysfs}/${led}/brightness" 255

		echo "heartbeat" > "${sysfs}/${led}/trigger"
		grep "\[heartbeat\]" "${sysfs}/${led}/trigger"
	done

	print_msg "OK"
}

test_board_led
