#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# Script based on Linux kernel commit 7996a8b5511a ("blk-mq: fix hang caused
# by freeze/unfreeze sequence")

import os
import sys

def setup(dev_id, dev):
    os.system("modprobe null_blk shared_tags=1 nr_devices=0 queue_mode=2")

    print(f"Making: {dev}")

    print("Number of CPUs: {}".format(os.cpu_count()))
    affinity_mask = {int(dev_id)}
    pid = 0
    os.sched_setaffinity(0, affinity_mask)
    print("CPU affinity mask is modified for process: {}".format(os.sched_getaffinity(pid)))

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
        with open(f"{dev}/power", "w") as f:
            f.write("1\n")
        with open(f"{dev}/power", "w") as f:
            f.write("0\n")

if __name__ == "__main__":
    dev_id = sys.argv[1]

    if not dev_id:
        print("Missing argument")
        sys.exit(1)

    dev = f"/sys/kernel/config/nullb/nullb{dev_id}"
    setup(dev_id, dev)
    run(dev_id, dev)
