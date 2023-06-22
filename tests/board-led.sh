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
	local max_brightness=255
	local sysfs="/sys/class/leds"
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1|hardkernel,odroid-xu4)
		leds="blue:heartbeat"
		# PWM
		max_brightness=255
		;;
	hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu)
		leds="blue:heartbeat green:mmc0 red:microSD"
		# PWM
		max_brightness=255
		;;
	hardkernel,odroid-u3)
		if is_kernel_le 5 19; then
			leds="led1:heart"
		else
			leds="blue:heartbeat"
		fi
		if is_kernel_le 5 10; then
			# GPIO
			max_brightness=255
		else
			max_brightness=1
		fi
		;;
	hardkernel,odroid-x)
		if is_kernel_le 5 19; then
			leds="led1:heart led2:mmc0"
		else
			leds="blue:heartbeat led2:mmc0"
		fi
		if is_kernel_le 5 10; then
			# GPIO
			max_brightness=255
		else
			max_brightness=1
		fi
		;;
	*)
		print_msg "No LEDs on board, skipping"
		return 0
	esac

	for led in $leds; do
		echo $led
		test -d "${sysfs}/${led}"
		test_cat "${sysfs}/${led}/max_brightness" $max_brightness

		echo "none" > "${sysfs}/${led}/trigger"
		grep "\[none\]" "${sysfs}/${led}/trigger"
		echo "0" > "${sysfs}/${led}/brightness"
		test_cat "${sysfs}/${led}/brightness" 0

		if [ $max_brightness != 1 ]; then
			echo "127" > "${sysfs}/${led}/brightness"
			test_cat "${sysfs}/${led}/brightness" 127
		fi

		echo "$max_brightness" > "${sysfs}/${led}/brightness"
		test_cat "${sysfs}/${led}/brightness" $max_brightness

		echo "heartbeat" > "${sysfs}/${led}/trigger"
		grep "\[heartbeat\]" "${sysfs}/${led}/trigger"
	done

	print_msg "OK"
}

test_board_led
