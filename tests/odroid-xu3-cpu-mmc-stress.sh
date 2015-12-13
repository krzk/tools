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

# grep . /sys/class/thermal/*/temp

test_cpu_mmc_stress() {
    local name="CPU stress"
    print_msg "Testing..."
    local therm="/sys/class/thermal"
    local t1="$(cat ${therm}/thermal_zone0/temp)"
    local t2=""
    local pids=""

    test_cat_gt ${therm}/thermal_zone0/temp 25000
    test_cat_lt ${therm}/thermal_zone0/temp 45000


    for i in `seq 8`; do
        { sudo -u $USER cat /dev/mmcblk0p2 | gzip -c > /dev/null & disown ; } 2> /dev/null
        pids="$pids $!"
    done

    sleep 15

    t2="$(cat ${therm}/thermal_zone0/temp)"
    test $t1 -lt $t2  || print_msg "ERROR: test $t1 -lt $t2"

    test_cat_gt ${therm}/thermal_zone0/temp 40000
    test_cat_lt ${therm}/thermal_zone0/temp 65000

    sudo -u $USER kill $pids

    print_msg "Temperature diff: $(expr $t2 - $t1)"
}

test_cpu_mmc_stress
