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

set -e -E

test $# -eq 2 || die "Wrong number of parameters"

NAME="$1"
OUT_DIR="$2"

# Remove old modules-out
rm -fr "${OUT_DIR}/modules-out"
# Install modules into modules-out
build-slave.sh INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=modules-out modules_install
# Delete symlinks from modules-out
find "${OUT_DIR}/modules-out/lib/modules/" -type l -delete
# Tar the modules-out (download cannot transfer entire directories)
tar -czf "${OUT_DIR}/modules-out.tar.gz" -C "${OUT_DIR}/modules-out" lib/modules
