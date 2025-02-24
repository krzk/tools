#!/bin/bash
#
# Copyright (c) 2015-2025 Krzysztof Kozlowski
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

# Unused:
# NAME="$1"
OUT_DIR="$2"

# Remove old modules-out and dtb-out
rm -fr "${OUT_DIR}modules-out" "${OUT_DIR}dtb-out"
# Install modules and dtbs
"${SELF_DIR}/build-slave.sh" INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=modules-out modules_install
"${SELF_DIR}/build-slave.sh" INSTALL_DTBS_PATH=dtb-out dtbs_install
# Delete symlinks from modules-out
find "${OUT_DIR}modules-out/lib/modules/" -type l -delete
# Tar the modules and dtbs (download cannot transfer entire directories)
tar -cf - -C "${OUT_DIR}modules-out" lib/modules | xz --threads=0 > "${OUT_DIR}modules-out.tar.xz"
find "${OUT_DIR}dtb-out" -name "*exynos*.dtb" -printf "%f\n" | \
	tar -cf - -C "${OUT_DIR}dtb-out" --verbatim-files-from --files-from - | \
	xz --threads=0 > "${OUT_DIR}dtb-out.tar.xz"

# Show the sizes:
cd "${OUT_DIR}" && ls -lh modules-out.tar.xz dtb-out.tar.xz
