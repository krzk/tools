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

test_pwm_fan() {
    local name="PWM fan"
    print_msg "Testing..."
    # TODO: iterate over all hwmon devices to find pwmfan
    local hwmon="/sys/class/hwmon/hwmon0"

    if [ -d "${hwmon}/pwm1" ]; then
        # On older multi_v7 it may not be enabled
        print_msg "Missing ${hwmon}/pwm1, skipping"
	return 0
    fi

    test_cat ${hwmon}/name "pwmfan"
    test_cat ${hwmon}/pwm1 "0"

    echo 100 > ${hwmon}/pwm1
    sleep 2
    test_cat ${hwmon}/pwm1 "100"

    echo 130 > ${hwmon}/pwm1
    sleep 2
    test_cat ${hwmon}/pwm1 "130"

    echo 100 > ${hwmon}/pwm1
    sleep 2
    test_cat ${hwmon}/pwm1 "100"

    echo 0 > ${hwmon}/pwm1
    sleep 2
    test_cat ${hwmon}/pwm1 "0"

    print_msg "Done"
}

test_pwm_fan
