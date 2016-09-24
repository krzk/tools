#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
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

KBUILD_OUTPUT="out/"
BINS="${KBUILD_OUTPUT}zImage ${KBUILD_OUTPUT}arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb"
MODULES_OUT="modules-out"
PI_HOST="pi"
CONFIG_NAME="exynos"

while getopts "rc:" flag
do
	case "$flag" in
		r)
			PI_HOST="pi-remote"
			;;
		c)
			CONFIG_NAME="$OPTARG"
			;;
		*)
			echo "Usage: $(basename $0) [-r] [-c config_name]"
			exit 127
			;;
	esac
done

rm -fr $BINS $MODULES_OUT

echo "##############################################"
echo "Executing:"
echo ~/dev/tools/release.sh -c $CONFIG_NAME -t tests -m $MODULES_OUT
echo "##############################################"
echo
~/dev/tools/release.sh -c $CONFIG_NAME -m $MODULES_OUT || die "release fail"

for file in $BINS; do
	test -f "$file" || die "No $file"
done

echo "##############################################"
echo "Executing:"
echo "scp $BINS ${PI_HOST}:/srv/tftp/"
echo "find ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/ -type 'l' -delete"
echo "scp -r ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/* ${PI_HOST}:/srv/nfs/odroidxu3/lib/modules/"
echo "##############################################"
echo

scp $BINS ${PI_HOST}:/srv/tftp/
find ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/ -type 'l' -delete
scp -r ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/* ${PI_HOST}:/srv/nfs/odroidxu3/lib/modules/
