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

set -e -E
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

# test_rtc_device device
test_rtc_device() {
	local rtc="$1"
	print_msg "Testing /dev/${rtc}..."
	if [ -c /dev/${rtc} ]; then
		hwclock --systohc -f /dev/${rtc}
		for i in `seq 5`; do
			rtcwake -d $rtc -m on -s 5 > /dev/null
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
