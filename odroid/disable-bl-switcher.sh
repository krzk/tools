#!/bin/sh
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

test -f /sys/kernel/bL_switcher/active && echo 0 > /sys/kernel/bL_switcher/active
