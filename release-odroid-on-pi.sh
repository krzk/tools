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

KBUILD_OUTPUT="out/"
BINS="${KBUILD_OUTPUT}zImage ${KBUILD_OUTPUT}arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb"
MODULES_OUT="modules-out"
rm -fr $BINS $MODULES_OUT

~/dev/tools/release.sh -c exynos -E IPV6 -t tests -m $MODULES_OUT || die "release fail"

for file in $BINS; do
	test -f "$file" || die "No $file"
done

echo "scp $BINS pi:/srv/tftp/"
scp $BINS pi:/srv/tftp/

ssh odroid rm -fr modules/*
find ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/ -type 'l' -delete
scp -r ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/* odroid:modules/
ssh odroid sudo cp -r modules/* /lib/modules/
echo "scp -r ${KBUILD_OUTPUT}${MODULES_OUT}/lib/modules/* odroid:modules/"
echo "cp -r modules/* /lib/modules/"
