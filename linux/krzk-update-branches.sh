#!/bin/sh
#
# Copyright (c) 2015-2020 Krzysztof Kozlowski
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

# Get branches
REMOTE="$(git rev-parse --abbrev-ref master@{upstream})"
REMOTE="${REMOTE%%/*}"
if [ "$REMOTE" = "krzk-korg" ]; then
	BRANCHES="fixes for-next next/defconfig next/defconfig64 next/drivers next/dt next/dt64 next/soc next/soc64"
elif [ "$REMOTE" = "krzk-pinctrl" ]; then
	BRANCHES="for-next pinctrl-fixes pinctrl-next"
else
	die "Unknown upstream"
fi

for br in $BRANCHES; do
	echo -n "${br}: "
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
