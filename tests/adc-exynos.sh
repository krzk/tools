#!/bin/bash
#
# Copyright (c) 2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_adc_exynos() {
	local name="adc-exynos"
	# adc0 on XU3-lite jumps from 1400-2700
	local adc_values=("1000 3000" "0 1" "0 1" "2700 2800" "0 1" "0 1" "0 1" "0 1" "0 1" "0 1")
	local iio_path="/sys/bus/iio/devices/iio:device0"
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1)
		adc_values[9]="1294 1324"
		;;
	hardkernel,odroid-xu3-lite)
		adc_values[9]="367 377"
		;;
	hardkernel,odroid-xu,hardkernel,odroid-u3)
		print_msg "ADC not supported, skipping"
		return 0
		;;
	hardkernel,odroid-xu3,hardkernel,odroid-xu4)
		print_msg "ADC not supported (values not known), skipping"
		return 0
		;;
	*)
		error_msg "Wrong board"
	esac

	test_cat "${iio_path}/name" "12d10000.adc"

	cnt=${#adc_values[@]}
	for (( i = 0 ; i < cnt ; i++ )); do
		test_cat_range "${iio_path}/in_voltage${i}_raw" ${adc_values[$i]}
	done

	print_msg "Testing rebind..."
	echo "12d10000.adc" > /sys/bus/platform/drivers/exynos-adc/unbind
	echo "12d10000.adc" > /sys/bus/platform/drivers/exynos-adc/bind

	print_msg "OK"
}

test_adc_exynos
