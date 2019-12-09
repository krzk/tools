#!/bin/sh
#
# Copyright (c) 2019 Krzysztof Kozlowski
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
	echo "Updating ${br}"
	git push ${REMOTE} master:${br}
	echo git fetch ${REMOTE} ${br}:${br}
	git fetch ${REMOTE} ${br}:${br}
done
