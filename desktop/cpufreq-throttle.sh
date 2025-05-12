#!/bin/bash
#
# Copyright (c) 2020,2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

MAX_FREQ=2000000
if [ "$1" == "slow" ]; then
	echo "Slowing down CPUs to $MAX_FREQ Hz..."
elif [ "$1" == "fast" ]; then
	read -r MAX_FREQ < /sys/bus/cpu/devices/cpu0/cpufreq/cpuinfo_max_freq
	echo "Runnig CPUs uncapped ($MAX_FREQ Hz)..."
else
	echo "$(basename "$0") <slow|fast>"
	exit 1
fi

for i in /sys/bus/cpu/devices/cpu* ; do
	echo "$MAX_FREQ" > ${i}/cpufreq/scaling_max_freq
done
