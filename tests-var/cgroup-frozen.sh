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

cd /sys/fs/cgroup/freezer
mkdir frozen
cd frozen
echo "FROZEN" > freezer.state
cat freezer.state

echo PID > cgroup.procs

echo mem > /sys/power/state
