#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

grep . /sys/class/thermal/*/*

# Odroid XU3 specific:
THERM="/sys/class/thermal"
grep . ${THERM}/*/temp
grep . ${THERM}/thermal_zone0/*
grep . ${THERM}/cooling_device0/*

# test_cat file expected
test_cat() {
  local val="$(cat $1)"
  test "$val" = "$2" || echo "ERROR: Wrong ${1}: $val"
}
# test_cat_lt file expected
test_cat_lt() {
  local val="$(cat $1)"
  test $val -lt $2 || echo "ERROR: Wrong ${1}: $val"
}

test_cat ${THERM}/cooling_device0/cur_state "0"
test_cat ${THERM}/cooling_device0/max_state "3"
test_cat ${THERM}/thermal_zone0/mode "enabled"
test_cat ${THERM}/thermal_zone0/passive "0"
test_cat ${THERM}/thermal_zone0/trip_point_0_temp "50000"
test_cat_lt ${THERM}/thermal_zone0/temp 40000
test_cat_lt ${THERM}/thermal_zone1/temp 60000
test_cat_lt ${THERM}/thermal_zone2/temp 65000
test_cat_lt ${THERM}/thermal_zone3/temp 62000
test_cat_lt ${THERM}/thermal_zone4/temp 60000
