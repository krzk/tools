#!/bin/sh
#
# Copyright (c) 2016,2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

BRANCHES="next/defconfig next/defconfig64 next/drivers next/dt next/dt64 fixes for-next master next/soc next/soc64"
REMOTE="krzk-korg"

die() {
	echo "Fail: $1"
	exit 1
}

echo "Proceed with git checkout -B? [y/n]"
read ANSWER

test "$ANSWER" = "y" || exit

for br in $BRANCHES; do
	echo "Updating: $br to ${REMOTE}/${br}"
	git checkout -B $br ${REMOTE}/${br} || die "git checkout $br error"
done

