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

BINS="out/zImage out/arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb"
rm -f $BINS

~/dev/tools/release.sh -c exynos -E IPV6 -t tests || die "release fail"

for file in $BINS; do
	test -f "$file" || die "No $file"
done

echo scp $BINS pi:/srv/tftp/
scp $BINS pi:/srv/tftp/
