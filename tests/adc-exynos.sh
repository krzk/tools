#!/bin/bash
#
# Copyright (c) 2019-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

test_adc_exynos() {
	local name="adc-exynos"
	# adc0 on XU3-lite jumps from 1400-2700
	local adc_values=("1000 3000" "0 1" "0 1" "1000 3000" "0 1" "0 1" "0 1" "0 1" "0 1" "0 1")
	local adc_dev="12d10000.adc"
	local iio_path="/sys/bus/iio/devices/iio:device0"
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1)
		if is_kernel_le 5 0; then
			print_msg "SKIPPED: older kernel, not implemented"
			return 0
		fi
		adc_values[0]="0 1"
		adc_values[3]="0 1"
		adc_values[9]="1294 1324"
		;;
	hardkernel,odroid-xu3-lite)
		adc_values[9]="367 377"
		;;
	hardkernel,odroid-x)
		adc_values=("1000 4000" "2500 3500" "2500 3500" "1000 4000")
		adc_dev="126c0000.adc"
		;;
	hardkernel,odroid-xu)
		if is_kernel_le 5 2; then
			print_msg "SKIPPED: older kernel, not implemented"
			return 0
		fi
		adc_values[3]="0 1"
		# Should be around 372 but in practice higher tolerance is needed
		adc_values[9]="365 379"
		;;
	hardkernel,odroid-u3)
		print_msg "ADC not supported, skipping"
		return 0
		;;
	hardkernel,odroid-xu3,hardkernel,odroid-xu4)
		print_msg "ADC not supported (values not known), skipping"
		return 0
		;;
	insignal,arndale-octa)
		# adc0 and adc1 are floating on connector, others are not connected.
		# adc9 seems to stick around 370 even though it is not connected.
		# Still we can get something.
		if is_kernel_le 5 1; then
			print_msg "SKIPPED: older kernel, not implemented"
			return 0
		fi
		adc_values=("1000 4000" "1000 4000" "1000 4000" "1000 4000" "1000 4000" "1000 4000" "1000 4000" "1000 4000" "1000 4000" "350 400")
		;;
	*)
		error_msg "Wrong board"
	esac

	test_cat "${iio_path}/name" "$adc_dev"

	cnt=${#adc_values[@]}
	for (( i = 0 ; i < cnt ; i++ )); do
		test_cat_range "${iio_path}/in_voltage${i}_raw" ${adc_values[$i]}
	done

	print_msg "Testing rebind..."
	echo "$adc_dev" > /sys/bus/platform/drivers/exynos-adc/unbind
	echo "$adc_dev" > /sys/bus/platform/drivers/exynos-adc/bind

	print_msg "OK"
}

test_adc_exynos
