#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

# Be verbose for Buildbot debugging
set -x

test $# -gt 1 || die "Missing target name"

TARGET="$1"
NAME="$2"
TARGET_USER="buildbot"
# Timeout during wait_for_boot loop - for ssh and pings, in seconds
TIMEOUT_WAIT_FOR_BOOT=20

echo "Powering off target ${TARGET}..."
ssh_poweroff_target "$TARGET" "$TARGET_USER" $TIMEOUT_WAIT_FOR_BOOT

exit 0
