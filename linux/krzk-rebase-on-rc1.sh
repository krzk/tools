#!/bin/bash
#
# Copyright (c) 2019-2023,2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

die() {
	echo "Fail: $1"
	exit 1
}

# Get branches
REMOTE="$(git rev-parse --abbrev-ref --symbolic-full-name master@{upstream})"
REMOTE="${REMOTE%%/*}"
REMOTE_URL="$(git remote get-url ${REMOTE})"

if [[ $REMOTE_URL == *"/krzk/linux.git"* ]]; then
	BRANCHES="fixes for-next next/clk next/defconfig next/drivers next/dt next/dt64 next/soc next/soc64"
elif [[ $REMOTE_URL == *"/krzk/linux-dt.git"* ]]; then
	BRANCHES="fixes for-next next/dt next/dt64 next/dt-bindings next/qcom-pinctrl next/soc-drivers"
elif [[ $REMOTE_URL == *"/krzk/linux-mem-ctrl.git"* ]]; then
	BRANCHES="fixes for-next mem-ctrl-next"
elif [[ $REMOTE_URL == *"/krzk/linux-w1.git"* ]]; then
	BRANCHES="fixes for-next w1-next"
elif [[ $REMOTE_URL == *"/pinctrl/samsung.git"* ]]; then
	BRANCHES="fixes for-next pinctrl-next"
else
	die "Unknown upstream"
fi

for br in $BRANCHES; do
	echo "Updating ${br}"
	git push ${REMOTE} master:${br}
done

# Need to give server time to update refs, before fetching
sleep 1

for br in $BRANCHES; do
	echo git fetch ${REMOTE} ${br}:${br}
	git fetch ${REMOTE} ${br}:${br}
done
