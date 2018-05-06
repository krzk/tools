#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

# test_rtc_suspend_device device
test_rtc_suspend_device() {
	local rtc="$1"
	print_msg "Testing /dev/${rtc}..."
	if [ -c /dev/${rtc} ]; then
		hwclock --systohc -f /dev/${rtc}
		for i in `seq 3`; do
			rtcwake -d $rtc -m mem -s 5 -v
			# Test whether network works after suspend:
			sleep 5
			ifconfig eth0
			ping -c 1 google.pl
		done
	else
		error_msg "Missing /dev/${rtc}"
	fi
}

test_rtc_suspend() {
	local name="RTC"

	test_rtc_suspend_device rtc0
	test_rtc_suspend_device rtc1

	print_msg "OK"
}

test_rtc_suspend
