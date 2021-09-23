#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzysztof.kozlowski@canonical.com>
#                             <krzk@kernel.org>
#
# Script based on Linux kernel commit 7996a8b5511a ("blk-mq: fix hang caused
# by freeze/unfreeze sequence")

dev_id="$1"

test -n "$dev_id" || { echo "Missing argument" ; exit 1 ; }

set -eE

modprobe null_blk shared_tags=1 nr_devices=0 queue_mode=2

dev="/sys/kernel/config/nullb/nullb${dev_id}"
mkdir "$dev"

echo 512 > "$dev"/blocksize
echo 0 > "$dev"/completion_nsec
echo 0 > "$dev"/irqmode
echo 2 > "$dev"/queue_mode
echo 1024 > "$dev"/hw_queue_depth
echo 0 > "$dev"/memory_backed

echo 512 > "$dev"/size

echo 1 > "$dev"/power

echo mq-deadline > /sys/block/nullb${dev_id}/queue/scheduler

# FIXME: missing taskset

while true
do
	# echo "On/off for $dev_id"
	echo 1 > "$dev"/power
	echo 0 > "$dev"/power
done
