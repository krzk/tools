#!/bin/bash
#
# Copyright (c) 2023 Krzysztof Kozlowski
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

test $# -eq 2 || die "Wrong number of parameters"

test -f arch/arm64/Kconfig.platforms || die "Missing Kconfig.platforms"

OUT_DIR="$1"
WANT_PLATFORMS=""

case "$2" in
	samsung)
		WANT_PLATFORMS="EXYNOS|TESLA"
		;;
	qcom)
		WANT_PLATFORMS="QCOM"
		;;
	*)
		die "Unsupported platforms to strip"
		;;
esac


while IFS= read -r platform ; do
	scripts/config --file "${OUT_DIR}.config" -d "$platform"
done < <(grep config -- arch/arm64/Kconfig.platforms | cut -d ' ' -f 2 | grep -vE "$WANT_PLATFORMS")
