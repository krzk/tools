#!/bin/bash

grep . /sys/bus/platform/devices/126c0000.adc/iio\:device0/*
grep . /sys/bus/platform/devices/thermistor-*/temp*

rtcwake -d rtc0 -m mem -s 5 -v
rtcwake -d rtc1 -m mem -s 5 -v

echo "3810000.clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/unbind
echo "3810000.clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/bind

udevadm trigger