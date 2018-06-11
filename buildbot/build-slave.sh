#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

die() {
	echo "Fail: $1"
	exit 1
}

have_ccache() {
	which ccache > /dev/null
	echo $?
}

set -e -E
# Be verbose for Buildbot debugging
set -x

CROSS_COMPILE=""
JOBS="$(grep -c processor /proc/cpuinfo)"
# Non-linear scale of jobs
if [ $JOBS -lt 4 ]; then
	# <1,3>: n+1
	JOBS=$(($JOBS + 1))
else
	# >=5: n+n/2
	JOBS=$(($JOBS + $JOBS / 2))
fi
JOBS="-j${JOBS}"

case $ARCH in
	arm)
		# For ArchLinux on ARM:
		test "$(uname -m)" == "armv7l" && CROSS_COMPILE=""
		# For Ubuntu on x86:
		test $(which arm-linux-gnueabi-gcc) && CROSS_COMPILE="arm-linux-gnueabi-"
		;;
	arm64)
		CROSS_COMPILE="aarch64-linux-gnu-"
		;;
	*)
		;;
esac

# Check and enable ccache:
if [ "$(have_ccache)" == "0" ]; then
	export CROSS_COMPILE="ccache $CROSS_COMPILE"
fi

echo "Executing build command:"
echo "CROSS_COMPILE=\"$CROSS_COMPILE\" make $JOBS $*"
CROSS_COMPILE="$CROSS_COMPILE" make $JOBS $*

exit $?
