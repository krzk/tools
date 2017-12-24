#!/bin/sh
#
# Copyright (c) 2016,2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
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

