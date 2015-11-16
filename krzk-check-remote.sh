#!/bin/sh
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

BRANCHES="next/defconfig next/drivers next/dt next/dt64 fixes for-next next/soc"

die() {
	echo "Fail: $1"
	exit 1
}

for br in $BRANCHES; do
	echo -n "${br}: "
	# git checkout $br || die "git checkout $br error"
	git rev-list --count ${br}..${br}@{u}
	test $? -eq 0 || die "git rev-list error"
done

echo "Proceed with git reset --hard? [y/n]"
read ANSWER

test "$ANSWER" = "y" || exit

for br in $BRANCHES; do
	BR_COMMITS=`git rev-list --count ${br}..${br}@{u}`
	test $? -eq 0 || die "git rev-list error"
	if [ $BR_COMMITS -gt 0 ]; then
		echo "Updating: $br from $(git rev-parse ${br}) to $(git rev-parse ${br}@{u})"
		git checkout $br || die "git checkout $br error"
		git reset --hard ${br}@{u}
	fi
done

