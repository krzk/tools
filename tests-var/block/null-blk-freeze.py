#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzysztof.kozlowski@canonical.com>
#                             <krzk@kernel.org>
#
# Script based on Linux kernel commit 7996a8b5511a ("blk-mq: fix hang caused
# by freeze/unfreeze sequence")

import os
import sys

def setup(dev_id, dev):
    os.system("modprobe null_blk shared_tags=1 nr_devices=0 queue_mode=2")

    print(f"Making: {dev}")
    os.mkdir(dev)

    os.system(f"echo 512 > {dev}/blocksize")
    os.system(f"echo 0 > {dev}/completion_nsec")
    os.system(f"echo 0 > {dev}/irqmode")
    os.system(f"echo 2 > {dev}/queue_mode")
    os.system(f"echo 1024 > {dev}/hw_queue_depth")
    os.system(f"echo 0 > {dev}/memory_backed")
    os.system(f"echo 512 > {dev}/size")
    os.system(f"echo 1 > {dev}/power")

    os.system(f"echo mq-deadline > /sys/block/nullb{dev_id}/queue/scheduler")

def run(dev_id, dev):
    while True:
        # print(f"On/off for {dev_id}")
        on = f"echo 1 > {dev}/power"
        off = f"echo 0 > {dev}/power"
        os.system(on)
        os.system(off)

if __name__ == "__main__":
    dev_id = sys.argv[1]

    if not dev_id:
        print("Missing argument")
        sys.exit(1)

    dev = f"/sys/kernel/config/nullb/nullb{dev_id}"
    setup(dev_id, dev)
    run(dev_id, dev)
