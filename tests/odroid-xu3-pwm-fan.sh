#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

# grep . /sys/class/hwmon/hwmon0/*/pwm1

pwm_fan_cleanup() {
	print_msg "Exit trap, cleaning up..."
	# Need to echo so shell will not exit if cleanup command fails
	echo 0 > ${hwmon}/pwm1 || print_msg "Cleaning $hwmon failed"
	trap - EXIT
}

test_pwm_fan() {
	local name="PWM fan"
	print_msg "Testing..."
	# TODO: iterate over all hwmon devices to find pwmfan
	local hwmon="/sys/class/hwmon/hwmon0"

	if [ ! -f "${hwmon}/pwm1" ]; then
		# On older multi_v7 it may not be enabled
		print_msg "Missing ${hwmon}/pwm1, skipping"
		return 0
	fi

	# We test for idle fan, so settle first
	sleep 5

	test_cat ${hwmon}/name "pwmfan"
	test_cat_ge ${hwmon}/pwm1 "0"

	echo 100 > ${hwmon}/pwm1
	sleep 2
	test_cat ${hwmon}/pwm1 "100"

	echo 130 > ${hwmon}/pwm1
	sleep 2
	test_cat ${hwmon}/pwm1 "130"

	echo 100 > ${hwmon}/pwm1
	sleep 2
	test_cat ${hwmon}/pwm1 "100"

	echo 0 > ${hwmon}/pwm1
	sleep 2
	test_cat ${hwmon}/pwm1 "0"

	print_msg "OK"
}

trap "pwm_fan_cleanup" EXIT
test_pwm_fan
trap - EXIT
