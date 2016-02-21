#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

# grep . /sys/class/thermal/*/temp
# grep . /sys/class/thermal/cooling_device*/*

test_cooling() {
	local name="Cooling"
	print_msg "Testing..."
	local therm="/sys/class/thermal"
	# TODO: iterate over all hwmon devices to find pwmfan
	local hwmon="/sys/class/hwmon/hwmon0"

	if [ -d "${hwmon}/pwm1" ]; then
		# On older multi_v7 it may not be enabled
		print_msg "Missing ${hwmon}/pwm1, skipping"
		return 0
	fi

	# TODO: test other cooling devices (after DTS changes)

	test $(ls ${therm}/*/temp | wc -l) -eq 5 || print_msg "ERROR: Number of thermal zones"
	test_cat ${therm}/cooling_device0/cur_state "0"
	test_cat ${therm}/cooling_device0/max_state "3"

	test_cat ${hwmon}/pwm1 "0"

	echo 1 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "1"
	test_cat ${hwmon}/pwm1 "130"

	echo 2 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "2"
	test_cat ${hwmon}/pwm1 "170"

	echo 3 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "3"
	test_cat ${hwmon}/pwm1 "230"

	echo 0 > ${therm}/cooling_device0/cur_state
	sleep 1
	test_cat ${therm}/cooling_device0/cur_state "0"
	test_cat ${hwmon}/pwm1 "0"

	print_msg "Done"
}

test_thermal() {
	local name="Thermal"
	print_msg "Testing..."
	local therm="/sys/class/thermal"

	test $(ls ${therm}/*/temp | wc -l) -eq 5 || print_msg "ERROR: Number of thermal zones"

	test_cat ${therm}/thermal_zone0/mode "enabled"
	test_cat ${therm}/thermal_zone0/passive "0"
	test_cat ${therm}/thermal_zone0/trip_point_0_temp "50000"
	# Why this is less than room temperature?
	test_cat_gt ${therm}/thermal_zone0/temp 23000
	test_cat_lt ${therm}/thermal_zone0/temp 45000

	test_cat_gt ${therm}/thermal_zone1/temp 30000
	test_cat_lt ${therm}/thermal_zone1/temp 65000
	test_cat_gt ${therm}/thermal_zone2/temp 30000
	test_cat_lt ${therm}/thermal_zone2/temp 64000
	test_cat_gt ${therm}/thermal_zone3/temp 23000
	test_cat_lt ${therm}/thermal_zone3/temp 65000
	test_cat_gt ${therm}/thermal_zone4/temp 23000
	test_cat_lt ${therm}/thermal_zone4/temp 60000
	print_msg "Done"
}

test_cooling
test_thermal
