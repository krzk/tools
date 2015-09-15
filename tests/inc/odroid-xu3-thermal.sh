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

# grep . /sys/class/thermal/*/temp

test_thermal() {
    local name="Thermal"
    print_msg "Starting"
    local therm="/sys/class/thermal"

    test $(ls ${therm}/*/temp | wc -l) -eq 5 || print_msg "ERROR: Number of thermal zones"
    test_cat ${therm}/cooling_device0/cur_state "0"
    test_cat ${therm}/cooling_device0/max_state "3"
    test_cat ${therm}/thermal_zone0/mode "enabled"
    test_cat ${therm}/thermal_zone0/passive "0"
    test_cat ${therm}/thermal_zone0/trip_point_0_temp "50000"
    # Why this is less than room temperature?
    test_cat_gt ${therm}/thermal_zone0/temp 23000
    test_cat_lt ${therm}/thermal_zone0/temp 45000

    test_cat_gt ${therm}/thermal_zone1/temp 30000
    test_cat_lt ${therm}/thermal_zone1/temp 65000
    test_cat_gt ${therm}/thermal_zone2/temp 30000
    test_cat_lt ${therm}/thermal_zone2/temp 64000
    test_cat_gt ${therm}/thermal_zone3/temp 23000
    test_cat_lt ${therm}/thermal_zone3/temp 65000
    test_cat_gt ${therm}/thermal_zone4/temp 23000
    test_cat_lt ${therm}/thermal_zone4/temp 60000

}