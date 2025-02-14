#!/bin/bash
#
# Copyright (c) 2018-2025 Krzysztof Kozlowski
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
ADDONS_DIR=""
if [ -n "$3" ]; then
	ADDONS_DIR="$(readlink -f """$3""")"
fi
OUTPUT_FILE="$4"

MODULES_WANTED="clk-s2mps11 \
dwc2 \
ehci-exynos \
lan78xx \
ohci-exynos \
phy-exynos-usb2 \
r8152 \
rtc-s5m \
rtl8150 \
s2mpa01 s2mps11 s5m8767 \
sec-core sec-irq \
"

test -f "$BASE_CPIO" || die "Missing base_cpio file"
test -d "$MODULES_DIR" || die "Missing modules directory"
test -z "$ADDONS_DIR" || test -d "$ADDONS_DIR" || die "Missing addons directory"

trap "temp_cleanup" EXIT

KERNEL_NAME="$(ls """${MODULES_DIR}/lib/modules""")"
test -d "${MODULES_DIR}/lib/modules/${KERNEL_NAME}" || die "Cannot get kernel name. Got: $KERNEL_NAME"
echo "Got kernel name: $KERNEL_NAME"

if [ "${BASE_CPIO##*.}" == "xz" ]; then
	xz -d --stdout "$BASE_CPIO" > "$OUTPUT_FILE"
else
	cp "$BASE_CPIO" "$OUTPUT_FILE"
fi
OUTPUT_FILE_FULL="$(readlink -f """$OUTPUT_FILE""")"

if [ -n "$ADDONS_DIR" ]; then
	cd "$ADDONS_DIR" && fakeroot find -mindepth 1 -printf '%P\0' | LANG=C cpio -0 -oA -H newc -R 0:0 -F "$OUTPUT_FILE_FULL"
	test $? -eq 0 || die "Adding addons to cpio failed"
	cd - > /dev/null
fi

test -d "${MODULES_DIR}/lib" || die "Module directory should be top-level, containing /lib"
MODULES_TMP="`mktemp -d`" || die "Create tmp directory for modules failed"
MODULES_TMP_SUBDIR="${MODULES_TMP}/usr/lib"
mkdir -p "${MODULES_TMP_SUBDIR}/modules/${KERNEL_NAME}"

for module in $MODULES_WANTED; do
	echo "Copying module: $module"
	module_file="$(cd """${MODULES_DIR}/lib""" && find ./ -name """${module}.ko""")"

	# Missing module is okay - MODULES_WANTED contains everything for different kernels, even for builtin
	test -n "$module_file" || continue

	module_dir="$(dirname """$module_file""")"
	mkdir -p "${MODULES_TMP_SUBDIR}/$module_dir" || die "Cannot make directory for module $module_file"
	cp "${MODULES_DIR}/lib/${module_file}" "${MODULES_TMP_SUBDIR}/${module_dir}" || die "Cannot copy module $module_file"
done

cp "${MODULES_DIR}/lib/modules/${KERNEL_NAME}/modules.order" "${MODULES_DIR}/lib/modules/${KERNEL_NAME}/modules.builtin" \
	"${MODULES_TMP_SUBDIR}/modules/${KERNEL_NAME}" || die "Cannot copy modules.order and modules.builtin for kernel $KERNEL_NAME"
depmod --basedir "${MODULES_TMP}/usr" "$KERNEL_NAME" || die "depmod for kernel $KERNEL_NAME failed"

cd "$MODULES_TMP" && fakeroot find -mindepth 1 -printf '%P\0' | LANG=C cpio -0 -oA -H newc -R 0:0 -F "$OUTPUT_FILE_FULL"
test $? -eq 0 || die "Adding modules to cpio failed"
cd - > /dev/null

OUTPUT_TMP="`mktemp`" || die "Creating tmp file for compression failed"
cat "${OUTPUT_FILE_FULL}" | gzip -c > "${OUTPUT_TMP}"

mkimage -n "U-Boot Odroid ARMv7 ramdisk" -A arm -O linux -T ramdisk -C gzip \
	-d "${OUTPUT_TMP}" "$OUTPUT_FILE_FULL" || die "Create U-Boot image into $OUTPUT_FILE_FULL failed"

exit 0
