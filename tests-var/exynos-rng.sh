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

echo exynos > /sys/class/misc/hw_random/rng_current
dd if=/dev/hwrng of=/dev/null bs=1 count=16
grep . /sys/kernel/debug/clk/sss/*
grep . /sys/devices/platform/10830400.rng/power/*

echo mem > /sys/power/state
dd if=/dev/hwrng of=/dev/null bs=1 count=16

echo 10830400.rng > /sys/bus/platform/drivers/exynos-rng/unbind
echo 10830400.rng > /sys/bus/platform/drivers/exynos-rng/bind
