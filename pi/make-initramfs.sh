#!/bin/sh
#
# Copyright (c) 2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

usage() {
	echo "$(basename $0) <base_cpio> <modules_dir> <addons_dir> <output_file>"
	exit 1
}

die() {
	echo "Fail: $1"
	exit 1
}

MODULES_TMP=""
OUTPUT_TMP=""
temp_cleanup() {
	echo "Exit trap, cleaning up tmp..."
	test -n "$MODULES_TMP" && rm -fr "$MODULES_TMP"
	test -n "$OUTPUT_TMP" && rm -fr "$OUTPUT_TMP"
}

test $# -eq 4 || usage

BASE_CPIO="$(readlink -f """$1""")"
MODULES_DIR="$(readlink -f """$2""")"
ADDONS_DIR="$(readlink -f """$3""")"
OUTPUT_FILE="$4"

# TODO: finish modules
MODULES_WANTED="phy-exynos-usb2 ohci-exynos dwc2 r8152"

test -f "$BASE_CPIO" || die "Missing base_cpio file"
test -d "$MODULES_DIR" || die "Missing modules directory"
test -d "$ADDONS_DIR" || die "Missing addons directory"

trap "temp_cleanup" EXIT

KERNEL_NAME="$(ls """${MODULES_DIR}/lib/modules""")"
test -d "${MODULES_DIR}/lib/modules/${KERNEL_NAME}" || die "Cannot get kernel name. Got: $KERNEL_NAME"
echo "Got kernel name: $KERNEL_NAME"

cp "$BASE_CPIO" "$OUTPUT_FILE"
OUTPUT_FILE_FULL="$(readlink -f """$OUTPUT_FILE""")"

#cd "$ADDONS_DIR" && fakeroot find -mindepth 1 -printf '%P\0' | LANG=C bsdcpio -0 -o -H newc -R 0:0 >> "$OUTPUT_FILE_FULL"
cd "$ADDONS_DIR" && fakeroot find -mindepth 1 -printf '%P\0' | LANG=C cpio -0 -oA -H newc -R 0:0 -F "$OUTPUT_FILE_FULL"
test $? -eq 0 || die "Adding addons to cpio failed"
cd -

test -d "${MODULES_DIR}/lib" || die "Module directory should be top-level, containing /lib"
MODULES_TMP="`mktemp -d`" || die "Create tmp directory for modules failed"
for module in $MODULES_WANTED; do
	echo "Copying module: $module"
done
#cd "$MODULES_DIR" && fakeroot find -mindepth 1 -printf '%P\0' | LANG=C cpio -0 -oA -H newc -R 0:0 -F "$OUTPUT_FILE_FULL"
#test $? -eq 0 || die "Adding modules to cpio failed"
#cd -

OUTPUT_TMP="`mktemp`" || die "Creating tmp file for compression failed"
cat "${OUTPUT_FILE_FULL}" | gzip -c > "${OUTPUT_TMP}"

mkimage -n "U-Boot Odroid ARMv7 ramdisk" -A arm -O linux -T ramdisk -C gzip \
	-d "${OUTPUT_TMP}" "$OUTPUT_FILE_FULL" || die "Create U-Boot image into $OUTPUT_FILE_FULL failed"

exit 0
