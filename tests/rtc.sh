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
	if rtcwake --help 2>&1 | grep -q BusyBox
	then
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
	if [ -c "/dev/${rtc}" ]; then
		hwclock --systohc -f "/dev/${rtc}"
		for _ in $(seq 2); do
			$(rtc_suspend_rtcwake_cmd) -d "$rtc" -m on -s 1
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
