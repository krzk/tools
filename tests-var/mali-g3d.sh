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

elementary_test -to animation
/usr/apps/com.samsung.dali-demo/bin/dali-demo
cat /proc/interrupts | grep -i mali
cat /sys/kernel/debug/pm_genpd/pm_genpd_summary

grep . /sys/kernel/debug/mali/*
grep . /sys/kernel/debug/mali/userspace_settings/*
cat /sys/kernel/debug/ump/memory_usage

