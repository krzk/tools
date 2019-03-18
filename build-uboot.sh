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
	echo "    board - arndale, arndale-octa, odroid-u3, odroid-xu3, all"
	exit 1
}

build() {
	local config="$1"

	echo "#########################################################"
	echo "Building config: $config"
	CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make ${config}_config
	CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make -j`getconf _NPROCESSORS_ONLN`
}

set -e -E

BOARD="$1"
test -n "$BOARD" || usage

if [ "$BOARD" == "all" ]; then
	CONFIG="arndale odroid odroid-xu3 origen peach-pi peach-pit s5pc210_universal s5p_goni smdk5250 smdk5420 smdkc100 smdkv310 snow trats trats2"
	# TODO: espresso7420
else
	CONFIG="$BOARD"
fi

if [ $BUILD_ALL -eq 0 ]; then
	CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make clean
	build $CONFIG
else
	CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make clean
	for config in $CONFIG; do
		build $config
	done
fi

echo "U-boot fusing for SD:"
echo "dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk0 seek=63"
echo "U-boot fusing for eMMC (cannot be done through adapter):"
echo "echo 0 > /sys/block/mmcblk1boot0/force_ro"
echo "dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk1boot0 seek=62"
