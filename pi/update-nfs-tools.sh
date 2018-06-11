#!/bin/sh
#
# Copyright (c) 2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

SRV_NFS_PATH="/srv/nfs"
SRV_NFS_BOARDS="odroidhc1 odroidu3 odroidxu odroidxu3"
TOOLS_PATH="opt/tools"

for board in $SRV_NFS_BOARDS; do
	path="${SRV_NFS_PATH}/${board}/${TOOLS_PATH}"
	if [ ! -d "$path" ]; then
		echo "Wrong path: $path"
		continue
	fi
	cd "$path"
	if [ "$(git rev-parse --abbrev-ref HEAD)" != "master" ]; then
		echo "Repo $path not on master branch"
		continue
	fi

	git remote update --prune
	git reset --hard origin/master
done
