#!/bin/bash
#
# Copyright (c) 2015-2024 Krzysztof Kozlowski
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
	BRANCHES="fixes next/clk next/defconfig next/drivers next/dt next/dt64 next/soc next/soc64"
elif [[ $REMOTE_URL == *"/krzk/linux-dt.git"* ]]; then
	BRANCHES="fixes next/dt next/dt64 next/dt-bindings next/qcom-pinctrl next/soc-drivers"
elif [[ $REMOTE_URL == *"/krzk/linux-mem-ctrl.git"* ]]; then
	BRANCHES="fixes mem-ctrl-next"
elif [[ $REMOTE_URL == *"/krzk/linux-w1.git"* ]]; then
	BRANCHES="fixes w1-next"
elif [[ $REMOTE_URL == *"/pinctrl/samsung.git"* ]]; then
	BRANCHES="fixes pinctrl-next"
else
	die "Unknown upstream"
fi

git checkout for-next || die "git checkout for-next error"
git merge $BRANCHES
if [ $? -ne 0 ]; then
	echo
	echo "git merge $BRANCHES error"
	echo "You can try merging each branch individually:"
	for br in $BRANCHES; do
		echo "git merge $br"
	done
fi
