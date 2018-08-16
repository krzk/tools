#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

# test_cpu_online
test_cpu_online() {
	local name="CPU online"
	print_msg "Testing..."
	local expected_cpus=0

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4)
		expected_cpus="0-7"
		;;
	hardkernel,odroid-u3|hardkernel,odroid-xu)
		expected_cpus="0-3"
		;;
	*)
		error_msg "Wrong board"
	esac

	test -f /sys/kernel/bL_switcher/active && echo 0 > /sys/kernel/bL_switcher/active

	test_cat /sys/devices/system/cpu/online "$expected_cpus"

	print_msg "OK"
}

test_cpu_online
