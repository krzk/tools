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

get_mmc() {
	for i in `seq 0 9`; do
		test -b /dev/mmcblk${i} && echo /dev/mmcblk${i} && return 0
	done
	echo ""
	return 1
}

test_cpu_mmc_stress() {
	local name="CPU stress"
	print_msg "Testing..."
	local therm="/sys/class/thermal"
	local t1="$(cat ${therm}/thermal_zone0/temp)"
	local t2=""
	local pids=""
	# TODO: iterate over all hwmon devices to find pwmfan
	local hwmon="/sys/class/hwmon/hwmon0"
	local mmc=$(get_mmc)

	test -n "$mmc" || error_msg "Could not find MMC device"
	print_msg "Using $mmc device"

	if [ -d "${hwmon}/pwm1" ]; then
		# On older multi_v7 it may not be enabled
		test_cat ${hwmon}/name "pwmfan"
		test_cat ${hwmon}/pwm1 "0"
	fi

	# Make all CPUs busy
	test -f /sys/kernel/bL_switcher/active && echo 0 > /sys/kernel/bL_switcher/active
	test_cat_gt ${therm}/thermal_zone0/temp 25000
	test_cat_lt ${therm}/thermal_zone0/temp 45000


	for i in `seq 8`; do
		{ sudo -u $USER cat "$mmc" | gzip -c > /dev/null & disown ; } 2> /dev/null
		pids="$pids $!"
	done

	sleep 15

	t2="$(cat ${therm}/thermal_zone0/temp)"
	test $t1 -lt $t2  || print_msg "ERROR: test $t1 -lt $t2"

	test_cat_gt ${therm}/thermal_zone0/temp 40000
	test_cat_lt ${therm}/thermal_zone0/temp 65000
	# Unfortunately this may not be sufficient to reach next threshold
	# of cooling device, so fan may be still at 0
	# test_cat_gt ${hwmon}/pwm1 50

	sudo -u $USER kill $pids

	print_msg "Temperature diff: $t2 - $t1 = $(expr $t2 - $t1)"
}

test_cpu_mmc_stress
