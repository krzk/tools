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
		expected_cpus=8
		;;
	hardkernel,odroid-u3|hardkernel,odroid-xu)
		expected_cpus=4
		;;
	*)
		error_msg "Wrong board"
	esac

	test -f /sys/kernel/bL_switcher/active && echo 0 > /sys/kernel/bL_switcher/active
	cpu_online=0
	if [ ! -r /sys/bus/cpu/devices/cpu0/online ]; then
		# On recent kernels on U3, the CPU0 is always online
		# Test recent kernel by checking hotplug (v4.9) or cpu_capacity (newer)
		if [ -r /sys/bus/cpu/devices/cpu0/hotplug/state ]; then
			read -r cpu_stat < /sys/bus/cpu/devices/cpu0/hotplug/state
			if [ $cpu_stat -eq 150 ]; then
				let "cpu_online+=1"
			fi
		elif [ -r /sys/bus/cpu/devices/cpu0/cpu_capacity ]; then
			let "cpu_online+=1"
		fi
	fi
	for i in /sys/bus/cpu/devices/cpu*/online; do
		read -r cpu_stat < $i
		if [ $cpu_stat -eq 1 ]; then
			let "cpu_online+=1"
		fi
	done
	print_msg "$cpu_online"
	test $cpu_online -eq $expected_cpus || error_msg "test $cpu_online -ne $expected_cpus"

	print_msg "OK"
}

test_cpu_online
