#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

die() {
	echo "Fail: $1"
	exit 1
}

CROSS_COMPILE=""
JOBS="$(grep -c processor /proc/cpuinfo)"
JOBS="-j$(expr $JOBS + 1)"

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

echo "Executing build command:"
echo "CROSS_COMPILE=\"$CROSS_COMPILE\" make $JOBS $*"
CROSS_COMPILE="$CROSS_COMPILE" make $JOBS $*
