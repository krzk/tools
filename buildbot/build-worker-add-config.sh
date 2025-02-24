#!/bin/bash
#
# Copyright (c) 2023-2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

SELF_DIR="$(dirname "${BASH_SOURCE[0]}")"
. "${SELF_DIR}/inc-build-slave.sh"

set -e -E
# Be verbose for Buildbot debugging
set -x

test $# -eq 3 || die "Wrong number of parameters"

OUT_DIR="$1"
WANT_SUBSYSTEM=""
WANT_PLATFORM=""

case "$2" in
	memory|pinctrl|w1)
		WANT_SUBSYSTEM="drivers/${2}/"
		;;
	*)
		die "Unsupported subsystem to add"
		;;
esac

case "$3" in
	qcom|samsung)
		WANT_PLATFORM="$3/"
		;;
	memory|w1)
		;;
	*)
		die "Unsupported platforms to add"
		;;
esac

for f in $(find "${WANT_SUBSYSTEM}${WANT_PLATFORM}" -name "*Kconfig*") ; do
	while IFS= read -r platform ; do
		scripts/config --file "${OUT_DIR}.config" -e "$platform"
	done < <(grep -E '^(menu)?config' -- $f | cut -d ' ' -f 2)
done
