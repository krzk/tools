#!/bin/sh
#
# Copyright (c) 2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#
# Should be run inside directory with repos

for i in `ls`
do
	test -d "$i" || continue
	cd "$i"

	git rev-parse --is-inside-work-tree > /dev/null 2>&1
	if [ $? -ne 0  ]; then
		cd ..
		continue
	fi

	echo "Prunning remotes in repo $i"
	git remote prune `git remote`

	echo "Running gc in repo $i"
	git gc

	cd ..
done
