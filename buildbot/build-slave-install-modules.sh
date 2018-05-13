#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

set -e -E
# Be verbose for Buildbot debugging
set -x

test $# -eq 1 || die "Wrong number of parameters"

KERNEL_NAME="$1"
echo "Installing $KERNEL_NAME modules"

MODULES_DIR="./modules-install"
MODULES_NAME_DIR="${MODULES_DIR}/${KERNEL_NAME}"

test $(ls "$MODULES_DIR" | wc -l) == "1" || die "Expected to find only one directory with modules"
test -d "$MODULES_NAME_DIR" || die "Directory does not exist: $MODULES_NAME_DIR"
test "$USER" = "root" || die "Expected to be run as root"

umask 022

rm -fr "/lib/modules/${KERNEL_NAME}"
mv "${MODULES_NAME_DIR}" /lib/modules/
chown -R root:root "/lib/modules/${KERNEL_NAME}"
rm -fr "$MODULES_DIR"
