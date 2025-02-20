#!/bin/bash
#
# Copyright (c) 2015,2016,2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

rtc_suspend_rtcwake_cmd() {
	rtcwake --help 2>&1 | grep -q BusyBox
	if [ $? -eq 0 ]; then
		echo "rtcwake"
	else
		echo "rtcwake -v"
	fi

	return 0
}

# test_rtc_device device
test_rtc_device() {
	local rtc="$1"
	print_msg "Testing /dev/${rtc}..."
	if [ -c /dev/${rtc} ]; then
		hwclock --systohc -f /dev/${rtc}
		for i in `seq 3`; do
			$(rtc_suspend_rtcwake_cmd) -d $rtc -m on -s 5
		done
	else
		error_msg "Missing /dev/${rtc}"
	fi
}

test_rtc() {
	local name="RTC"

	test_rtc_device rtc0
	test_rtc_device rtc1

	print_msg "OK"
}

test_rtc
