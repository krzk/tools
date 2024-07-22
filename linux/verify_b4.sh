#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2024 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# Be sure people do not merge b4 branches

which b4 > /dev/null || exit 0

b4 prep --show-revision > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "ERROR: Looks like it is a b4-managed branch. Such branches should not be merged."
	exit 1
fi

exit 0
