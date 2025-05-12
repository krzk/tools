#!/bin/bash
#
# Copyright (c) 2021 Canonical Ltd.
# Copyright (c) 2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "$(basename "$0") <-d drive>"
	echo " -d <drive>        - drive image file (type: raw or qcow2 depending on extension)"
	exit 1
}

set -x
IMG_FILE=""
IMG_FILE_TYPE=""
QEMU_MEM="${QEMU_MEM:=1G}"
QEMU_CPU="${QEMU_CPU:=2}"

while getopts "hd:k:m:" flag
do
	case "$flag" in
		d)
			IMG_FILE="$OPTARG"
			;;
		*)
			usage
			;;
	esac
done

test -n "$IMG_FILE" || usage
test -f "$IMG_FILE" || die "Passed drive image '${IMG_FILE}' not a file"

if [ "${IMG_FILE: -5}" == ".qcow" ]; then
	IMG_FILE_TYPE="qcow2"
elif [ "${IMG_FILE: -4}" == ".raw" ]; then
	IMG_FILE_TYPE="raw"
else
	die "Type of drive image not recognized by extension"
fi

qemu-system-x86_64 -enable-kvm \
	-drive "file=${IMG_FILE},format=${IMG_FILE_TYPE}" \
	-cpu host \
	-m "${QEMU_MEM}" -smp "cores=${QEMU_CPU}" \
	-serial stdio \
	-device virtio-scsi-pci,id=scsi \
	-usb \
	-nic user,hostfwd=tcp:127.0.0.1:60022-:22
