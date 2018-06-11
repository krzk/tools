#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

cd /sys/fs/cgroup/freezer
mkdir frozen
cd frozen
echo "FROZEN" > freezer.state
cat freezer.state

echo PID > cgroup.procs

echo mem > /sys/power/state
