#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

SELF_DIR="$(dirname "${BASH_SOURCE[0]}")"
. "${SELF_DIR}/inc-build-slave.sh"

set -e -E
# Be verbose for Buildbot debugging
set -x

test $# -eq 2 || die "Wrong number of parameters"

NAME="$1"
OUT_DIR="$2"

if [ ! -f "arch/arm/boot/dts/exynos5410-odroidxu.dts" ]; then
	# If there is no Odroid XU DTS, then duplicate the SMDK DTB
	echo "No Odroid XU DTS, using SMDK5410"
	cp ${OUT_DIR}arch/arm/boot/dts/exynos5410-smdk5410.dtb ${OUT_DIR}arch/arm/boot/dts/exynos5410-odroidxu.dtb
fi
if [ ! -f "arch/arm/boot/dts/exynos5422-odroidxu3-lite.dts" ]; then
	# If there is no Odroid XU3 Lite DTS, then duplicate the XU3 DTB
	echo "No Odroid XU3 Lite DTS, using regular XU3"
	cp ${OUT_DIR}arch/arm/boot/dts/exynos5422-odroidxu3.dtb ${OUT_DIR}arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb
fi
if [ ! -f "arch/arm/boot/dts/exynos5422-odroidhc1.dts" ]; then
	# All compiled kernels have SMDK5410 and XU3 DTS but for example v4.1 does not have XU4 DTS
	if [ -f "arch/arm/boot/dts/exynos5422-odroidxu4.dts" ]; then
		# If there is no Odroid HC1 DTS, then duplicate the XU4 DTB
		echo "No Odroid HC1 DTS, using regular XU4"
		cp ${OUT_DIR}arch/arm/boot/dts/exynos5422-odroidxu4.dtb ${OUT_DIR}arch/arm/boot/dts/exynos5422-odroidhc1.dtb
	else
		echo "No Odroid HC1 DTS and no XU4 DTS."
	fi
fi

# Remove old modules-out
rm -fr "${OUT_DIR}modules-out"
# Install modules into modules-out
"${SELF_DIR}/build-slave.sh" INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=modules-out modules_install
# Delete symlinks from modules-out
find "${OUT_DIR}modules-out/lib/modules/" -type l -delete
# Tar the modules-out (download cannot transfer entire directories)
tar -czf "${OUT_DIR}modules-out.tar.gz" -C "${OUT_DIR}/modules-out" lib/modules
