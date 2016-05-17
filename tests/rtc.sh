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

test_rtc() {
	local name="RTC"

	print_msg "Testing /dev/rtc0..."
	test -c /dev/rtc0 || error_msg "Missing /dev/rtc0"
	hwclock --systohc -f /dev/rtc0
	rtcwake -d rtc0 -m on -s 5 > /dev/null

	print_msg "Testing /dev/rtc1..."
	test -c /dev/rtc1 || error_msg "Missing /dev/rtc1"
	hwclock --systohc -f /dev/rtc1
	rtcwake -d rtc1 -m on -s 5 > /dev/null

	print_msg "OK"
}

test_rtc
