#!/bin/sh
#
# Copyright (c) 2015-2019 Krzysztof Kozlowski
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
	echo "$(basename $0) <board>"
	echo "    board - odroid-u3, odroid-xu3, arndale-octa"
	exit 1
}
set -e -E

BOARD="$1"
test -n "$BOARD" || usage

CONFIG="$BOARD"
case "$BOARD" in
	odroid-u3)
		CONFIG="odroid"
		;;
	odroid-xu3)
		;;
	arndale-octa)
		CONFIG="arndale_octa"
		;;
	*)
		usage
		;;
esac

CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make clean
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make ${CONFIG}_config
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make -j4

echo "U-boot fusing for SD:"
echo "dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk0 seek=63"
echo "U-boot fusing for eMMC (cannot be done through adapter):"
echo "echo 0 > /sys/block/mmcblk1boot0/force_ro"
echo "dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk1boot0 seek=62"
