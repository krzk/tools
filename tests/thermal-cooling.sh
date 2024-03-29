#!/bin/bash
#
# Copyright (c) 2015-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

# grep . /sys/class/thermal/*/temp
# grep . /sys/class/thermal/cooling_device*/*

cooling_cleanup() {
	print_msg "Exit trap, cleaning up..."
	# Need to echo so shell will not exit if cleanup command fails
	echo 0 > ${therm}/cooling_device0/cur_state || print_msg "Cleaning $therm failed"
	trap - EXIT
}

test_cooling() {
	local name="Cooling"
	print_msg "Testing..."
	local therm="/sys/class/thermal"
	# TODO: iterate over all hwmon devices to find pwmfan
	local hwmon="/sys/class/hwmon/hwmon0"
	local exp_tmu_zones=5
	local exp_cool_level_1=130
	local exp_cool_level_2=170
	local exp_cool_level_3=230

	case "$(get_board_compatible)" in
	hardkernel,odroid-u3|hardkernel,odroid-x)
		exp_tmu_zones=1
		exp_cool_level_1=102
		;;
	hardkernel,odroid-xu)
		exp_tmu_zones=4
		;;
	esac

	if [ ! -f "${hwmon}/pwm1" ]; then
		# On older multi_v7 it may not be enabled.
		# Odroid HC1 does not have it.
		print_msg "Missing ${hwmon}/pwm1, skipping"
		return 0
	fi

	# TODO: test other cooling devices (after DTS changes)

	# We test for idle fan, so settle first
	sleep 5

	test $(ls ${therm}/*/temp | wc -l) -eq ${exp_tmu_zones} || error_msg "Number of thermal zones"
	test_cat_ge ${therm}/cooling_device0/cur_state "0"
	test_cat ${therm}/cooling_device0/max_state "3"

	test_cat_ge ${hwmon}/pwm1 "0"

	echo 1 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "1"
	test_cat ${hwmon}/pwm1 $exp_cool_level_1

	echo 2 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "2"
	test_cat ${hwmon}/pwm1 $exp_cool_level_2

	echo 3 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "3"
	test_cat ${hwmon}/pwm1 $exp_cool_level_3

	echo 0 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "0"
	test_cat ${hwmon}/pwm1 "0"

	print_msg "OK"
}

trap "cooling_cleanup" EXIT
test_cooling
trap - EXIT
