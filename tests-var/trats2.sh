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

grep . /sys/bus/platform/devices/126c0000.adc/iio\:device0/*
grep . /sys/bus/platform/devices/thermistor-*/temp*

rtcwake -d rtc0 -m mem -s 5 -v
rtcwake -d rtc1 -m mem -s 5 -v

echo "3810000.clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/unbind
echo "3810000.clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/bind

udevadm trigger
