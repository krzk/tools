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

# test_cpu_online <expected>
test_cpu_online() {
	local name="CPU online"
	print_msg "Testing..."
	local expected=$1

	test -f /sys/kernel/bL_switcher/active && echo 0 > /sys/kernel/bL_switcher/active
	cpu_online=0
	for i in /sys/bus/cpu/devices/cpu*/online; do
		cpu_stat=$(cat $i)
		if [ $cpu_stat -eq 1 ]; then
			let "cpu_online+=1"
		fi
	done
	print_msg "$cpu_online"
	test $cpu_online -eq $expected || print_msg "ERROR: test $cpu_online -ne $expected"
}

test_cpu_online 8
