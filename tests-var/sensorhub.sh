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

# test_cat file expected
test_cat() {
	local val="$(cat $1)"
	test "$val" = "$2" || echo "ERROR: Wrong $1 ($val)"
}

grep . /sys/class/sensors/*/*

SENS="/sys/class/sensors"

test_cat ${SENS}/accelerometer_sensor/name "MPU6500"
test_cat ${SENS}/accelerometer_sensor/raw_data "0,0,0"
test_cat ${SENS}/accelerometer_sensor/reactive_alert "0"
test_cat ${SENS}/accelerometer_sensor/selftest "1,5.9,5.8,26.3"
test_cat ${SENS}/accelerometer_sensor/vendor "INVENSENSE"

test_cat ${SENS}/gyro_sensor/name "MPU6500"
test_cat ${SENS}/gyro_sensor/power_off "1"
test_cat ${SENS}/gyro_sensor/power_on "1"
test_cat ${SENS}/gyro_sensor/selftest "0,0.062,2.750,0.937,0.060,0.080,0.130,0.3,1.2,1.5,85,85,85"
test_cat ${SENS}/gyro_sensor/selftest_dps "500"
test_cat ${SENS}/gyro_sensor/temperature "40"
test_cat ${SENS}/gyro_sensor/vendor "INVENSENSE"

test_cat ${SENS}/hrm_sensor/hrm_eol "0 0 0 0 0 0 0"
test_cat ${SENS}/hrm_sensor/hrm_lib "0,0,0"
test_cat ${SENS}/hrm_sensor/hrm_raw "0,0"
test_cat ${SENS}/hrm_sensor/name "ADPD142"
test_cat ${SENS}/hrm_sensor/vendor "ADI"

test_cat ${SENS}/ssp_sensor/accel_poll_delay "200000000"
test_cat ${SENS}/ssp_sensor/enable "0"
test_cat ${SENS}/ssp_sensor/enable_irq "1"
test_cat ${SENS}/ssp_sensor/gyro_poll_delay "200000000"
test_cat ${SENS}/ssp_sensor/hrm_poll_delay "200000000"
test_cat ${SENS}/ssp_sensor/mcu_dump "OK"
test_cat ${SENS}/ssp_sensor/mcu_name "STM32F401CCY6B"
test_cat ${SENS}/ssp_sensor/mcu_rev "ST0114052300,ST0114052300"
test_cat ${SENS}/ssp_sensor/mcu_sleep_test "(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0, 0, 0, 0)"

test_cat ${SENS}/ssp_sensor/mcu_test "STM32F401CCY6B,NG,OK"
test_cat ${SENS}/ssp_voice/voice_pcmdump "OK"

# Firmware update:
test_cat ${SENS}/ssp_sensor/mcu_reset "OK"
test_cat ${SENS}/ssp_sensor/mcu_update_ums "NG"
test_cat ${SENS}/ssp_sensor/mcu_update "OK"
test_cat ${SENS}/ssp_sensor/mcu_update2 "OK"

# TODO:
# /sys/class/sensors/ssp_sensor/ssp_flush

