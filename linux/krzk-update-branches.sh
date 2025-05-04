#!/bin/bash
#
# Copyright (c) 2015-2023,2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#
# Update local branches to be synced with remote. If missing, create them.
# Master branch should be configured to track krzk master.

die() {
	echo "Fail: $1"
	exit 1
}

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
	echo -n "${br}: "
	revs=$(git rev-list --count origin/${br}..origin/${br} 2> /dev/null)
	if [ $? -ne 0 ]; then
		echo "creating remote"
		git push origin master:refs/heads/${br}
	fi

	revs=$(git rev-list --count ${br}..${br}@{u} 2> /dev/null)
	if [ $? -ne 0 ]; then
		echo "creating"
		git branch --track ${br} ${REMOTE}/${br}
		test $? -eq 0 || die "git branch error for ${br}"
	else
		echo "$revs"
		if [ "$revs" != "0" ]; then
			git fetch ${REMOTE} ${br}:${br}
		fi
	fi
done
