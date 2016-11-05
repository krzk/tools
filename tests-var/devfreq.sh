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

# Build
# -E PM_DEVFREQ,ARM_EXYNOS3_BUS_DEVFREQ,DEVFREQ_EVENT_EXYNOS_PPMU

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t debugfs none /sys/kernel/debug

echo "file drivers/devfreq/exynos/exynos3_bus.c +p" > /sys/kernel/debug/dynamic_debug/control
echo "file drivers/devfreq/event/exynos-ppmu.c +p" > /sys/kernel/debug/dynamic_debug/control
echo "file drivers/devfreq/exynos/exynos3_bus.c -p" > /sys/kernel/debug/dynamic_debug/control
echo "file drivers/devfreq/event/exynos-ppmu.c -p" > /sys/kernel/debug/dynamic_debug/control

grep . /sys/class/devfreq/*busfreq*/*

# 3.16
echo 80000 > /sys/class/devfreq/116a0000.busfreq/min_freq
echo 100000 > /sys/class/devfreq/106a0000.busfreq/min_freq
echo 100000 > /sys/class/devfreq/116a0000.busfreq/min_freq
echo 133000 > /sys/class/devfreq/106a0000.busfreq/min_freq
echo 133000 > /sys/class/devfreq/116a0000.busfreq/min_freq
echo 200000 > /sys/class/devfreq/106a0000.busfreq/min_freq
echo 134000 > /sys/class/devfreq/116a0000.busfreq/min_freq
echo 400000 > /sys/class/devfreq/106a0000.busfreq/min_freq
echo 135000 > /sys/class/devfreq/116a0000.busfreq/min_freq

grep . /sys/class/regulator/regulator.31/*
grep . /sys/class/regulator/regulator.33/*

#mainline
echo 50000 > /sys/class/devfreq/soc:busfreq@106A0000/min_freq
echo 50000 > /sys/class/devfreq/soc:busfreq@116A0000/min_freq
echo 80000 > /sys/class/devfreq/soc:busfreq@116A0000/min_freq
echo 100000 > /sys/class/devfreq/soc:busfreq@106A0000/min_freq
echo 100000 > /sys/class/devfreq/soc:busfreq@116A0000/min_freq
echo 133000 > /sys/class/devfreq/soc:busfreq@106A0000/min_freq
echo 133000 > /sys/class/devfreq/soc:busfreq@116A0000/min_freq
echo 200000 > /sys/class/devfreq/soc:busfreq@106A0000/min_freq
echo 200000 > /sys/class/devfreq/soc:busfreq@116A0000/min_freq
echo 400000 > /sys/class/devfreq/soc:busfreq@106A0000/min_freq
echo 400000 > /sys/class/devfreq/soc:busfreq@116A0000/min_freq

grep . /sys/class/regulator/regulator.26/*
grep . /sys/class/regulator/regulator.28/*

# Other
cat /sys/kernel/debug/clk/clk_summary | grep dmc
cat /sys/kernel/debug/clk/clk_summary | grep aclk
cat /sys/kernel/debug/clk/clk_summary | grep gd[lr]
cat /sys/kernel/debug/clk/clk_summary | grep mfc

echo mem > /sys/power/state

echo "soc:busfreq@106A0000" > /sys/bus/platform/drivers/exynos3250-busfreq/unbind
echo "soc:busfreq@116A0000" > /sys/bus/platform/drivers/exynos3250-busfreq/unbind
echo "soc:busfreq@106A0000" > /sys/bus/platform/drivers/exynos3250-busfreq/bind
echo "soc:busfreq@116A0000" > /sys/bus/platform/drivers/exynos3250-busfreq/bind


# Benchmarks
./perf bench mem memcpy -l 256MB -i 10
./perf bench mem memset -l 256MB -i 10
dd if=/dev/mmcblk0p15 of=/opt/usr/tesst iflag=direct oflag=direct count=128 bs=1M

