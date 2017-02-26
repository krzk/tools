#!/bin/bash
#
# Copyright (c) 2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "$(basename $0) <machine>"
	echo "    machine: smdkc210 (default), vexpress-a9"
	exit 1
}

ROOT_DIR=../
MACHINE=smdkc210
DTB=${ROOT_DIR}cur-linux/dts/exynos4210-smdkv310.dtb
CMDLINE="console=ttySAC0,115200n8 console=ttyS0 earlyprintk"
KERNEL=${ROOT_DIR}cur-linux/zImage
INITRD=${ROOT_DIR}armv7-odroidu3-exynos-v4.10-initramfs.cpio.gz
MEM=1024
CPU=2
QEMU=arm-softmmu/qemu-system-arm

case $1 in
	vexpress-a9)
		MACHINE=vexpress-a9
		DTB=${ROOT_DIR}cur-linux/dts/vexpress-v2p-ca9.dtb
		CMDLINE="console=ttyAMA0,115200 console=ttyS0 earlyprintk"
		;;
	smdkc210)
		;;
	*)
		test $# -eq 0 || usage
		;;
esac

echo "Running QEMU with MACHINE $MACHINE, DTB $DTB"
$QEMU -m $MEM -M $MACHINE -smp $CPU $IMG -append "$CMDLINE" \
	-d guest_errors \
	-serial stdio \
	-D ${ROOT_DIR}/log-${MACHINE}.log \
	-kernel $KERNEL -dtb $DTB -initrd $INITRD
