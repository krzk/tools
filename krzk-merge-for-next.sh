#!/bin/sh
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

BRANCHES="fixes next/soc next/soc64 next/drivers next/dt next/dt64 next/defconfig next/defconfig64"

die() {
	echo "Fail: $1"
	exit 1
}

git checkout for-next || die "git checkout for-next error"
git reset --hard master || die "git reset --hard master error"
for br in $BRANCHES; do
	git merge $br || die "git merge $br error"
done
