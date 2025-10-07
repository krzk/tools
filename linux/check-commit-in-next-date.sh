#!/bin/bash
#
# Copyright (c) 2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

REVS="$1"

#for commit in $(git rev-list "$REVS"); do
for commit in $(git rev-list --before=2025-08-27 next-20250911 ^next-20250829); do
	echo $commit
	# git show --no-patch --pretty="%cs" $commit
	git show --no-patch --format=fuller $commit
done
