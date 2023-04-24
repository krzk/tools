#!/bin/sh
#
# Copyright (c) 2015-2023 Krzysztof Kozlowski
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
	BRANCHES="fixes next/dt next/dt64 next/dt-bindings next/qcom-pinctrl"
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
git reset --hard master || die "git reset --hard master error"
for br in $BRANCHES; do
	git merge $br || die "git merge $br error"
done
