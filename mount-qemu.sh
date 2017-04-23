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

set -e -E

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "$(basename $0) <qcow2.img> <dst>"
	exit 1
}

test $# -eq 2 || usage

FILE="$1"
test -f "$FILE" || die "Missing file $FILE"

DST="$2"
test -d "$DST" || die "Missing directory dst $DST"

QEMU_PATH="out"
QEMU_NBD="${QEMU_PATH}/qemu-nbd"

modprobe nbd
$QEMU_NBD -c /dev/nbd0 "$FILE"

mount /dev/nbd0p1 "$DST"
