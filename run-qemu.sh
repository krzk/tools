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
	echo "$(basename $0) [-m machine] [-k kernel] [-d dtb]"
	echo " -m <machine>      - smdkc210, vexpress-a9 (default: $MACHINE)"
	echo " -k <kernel>       - path to zImage (default: $KERNEL)"
	echo " -d <dtb>          - path to dtb (default: $DTB)"
	exit 1
}

ROOT_DIR=../
MACHINE=smdkc210
DTB=${ROOT_DIR}cur-linux/dts/exynos4210-smdkv310.dtb
CMDLINE_CONSOLE="console=ttySAC0,115200n8"
CMDLINE="console=ttyS0 earlyprintk root=PARTUUID=6efc8dd5-01 rootwait rw"
KERNEL=${ROOT_DIR}cur-linux/zImage
INITRD=${ROOT_DIR}armv7-odroidu3-exynos-v4.10-initramfs.cpio.gz
IMG="-drive file=${ROOT_DIR}arch-arm.qcow2,if=sd,bus=0,index=2"
MEM=1024
CPU=2
QEMU=arm-softmmu/qemu-system-arm

while getopts "hd:k:m:" flag
do
	case "$flag" in
		d)
			DTB="$OPTARG"
			;;
		k)
			KERNEL="$OPTARG"
			;;
		m)
			MACHINE="$OPTARG"
			;;
		*)
			usage
			;;
	esac
done

case $MACHINE in
	vexpress-a9)
		MACHINE=vexpress-a9
		DTB=${ROOT_DIR}cur-linux/dts/vexpress-v2p-ca9.dtb
		CMDLINE_CONSOLE="console=ttyAMA0,115200"
		;;
	smdkc210)
		;;
	*)
		test $# -eq 0 || usage
		;;
esac

echo "Running QEMU with MACHINE $MACHINE, DTB $DTB"
$QEMU -m $MEM -M $MACHINE -smp $CPU $IMG -append "$CMDLINE_CONSOLE $CMDLINE" \
	-d guest_errors \
	-serial stdio \
	-D ${ROOT_DIR}log-${MACHINE}.log \
	-kernel $KERNEL -dtb $DTB -initrd $INITRD
