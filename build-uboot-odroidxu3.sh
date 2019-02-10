#!/bin/sh

set -e -E

CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make clean
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make odroid-xu3_config
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make -j4

echo "Fuse to sd:"
echo "sudo dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk0 seek=63"
