#!/bin/bash
#
# Copyright (c) 2022 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "$(basename $0) <remote_branch> <tux-plan.yaml> [remote]"
	echo "  remote - optional, if missing, the remote from master branch will be used"
	exit 1
}

# One or more args needed
test $# -ge 2 || usage
BRANCH="$1"
TUX_PLAN="$2"
REMOTE="$3"

if [ "$REMOTE" == "" ]; then
	REMOTE="$(git rev-parse --abbrev-ref --symbolic-full-name master@{upstream})"
	REMOTE="${REMOTE%%/*}"
fi
URL="$(git remote get-url ${REMOTE})"
echo "Using URL: $URL"

tuxsuite plan --git-repo "$URL" --git-ref "$BRANCH" "$TUX_PLAN"
