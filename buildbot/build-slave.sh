#!/bin/bash
#
# Copyright (c) 2015-2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

have_ccache() {
	which ccache > /dev/null
	echo $?
}

set -e -E
# Be verbose for Buildbot debugging
set -x

JOBS="$(nproc)"
# Non-linear scale of jobs
if [ "$JOBS" -lt 4 ]; then
	# <1,3>: n+1
	JOBS=$((JOBS + 1))
else
	# >=5: n+n/2
	JOBS=$((JOBS + JOBS / 2))
fi
JOBS="-j${JOBS}"

# Check and enable ccache:
if [ "$(have_ccache)" == "0" ]; then
	if [[ "$CC" =~ ^clang ]]; then
		export CC="ccache $CC"
	else
		export CROSS_COMPILE="ccache $CROSS_COMPILE"
	fi
fi

make ${CC:+CC="$CC"} "$JOBS" "$@"

exit $?
