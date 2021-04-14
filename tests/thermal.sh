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

test_thermal() {
	local name="Thermal"
	print_msg "Testing..."
	local therm="/sys/class/thermal"

	local exp_tmu0_trip="50000"
	local exp_tmu_zones=5

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1)
		exp_tmu0_trip="70000"
		;;
	hardkernel,odroid-u3|hardkernel,odroid-x)
		exp_tmu0_trip="70000"
		exp_tmu_zones=1
		;;
	hardkernel,odroid-xu)
		exp_tmu_zones=4
		;;
	insignal,arndale-octa)
		if is_kernel_le 5 1; then
			echo "Proper thermal support for Arndale Octa comes up with v5.2"
			return 0
		fi
		exp_tmu0_trip="60000"
		;;
	esac

	test $(ls ${therm}/*/temp | wc -l) -eq $exp_tmu_zones || error_msg "Number of thermal zones"

	test_cat ${therm}/thermal_zone0/mode "enabled"
	# On older stable kernels there might be no "passive" entry
	test -f ${therm}/thermal_zone0/passive && test_cat ${therm}/thermal_zone0/passive "0"
	test_cat ${therm}/thermal_zone0/trip_point_0_temp $exp_tmu0_trip

	for tmu in $(seq 0 $((exp_tmu_zones - 1))); do
		test_cat_gt ${therm}/thermal_zone${tmu}/temp 20000
		test_cat_lt ${therm}/thermal_zone${tmu}/temp 65000
	done

	print_msg "OK"
}

test_thermal
