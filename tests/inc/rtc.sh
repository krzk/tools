#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

. $(dirname ${BASH_SOURCE[0]})/0-common.sh

test_rtc() {
    local name="RTC"
    print_msg "Testing..."
    rtcwake -d rtc0 -m on -s 5 > /dev/null
    rtcwake -d rtc1 -m on -s 5 > /dev/null
    print_msg "OK"
}