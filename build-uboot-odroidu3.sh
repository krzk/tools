#!/bin/sh

set -e -E

CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make clean
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make odroid_config
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make -j4

# For lthor:
tar -cf u-boot.tar u-boot.bin

echo "U-boot fusing for SD:"
echo "dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk0 seek=63"
echo "U-boot fusing for eMMC (cannot be done through adapter):"
echo "echo 0 > /sys/block/mmcblk1boot0/force_ro"
echo "dd iflag=dsync oflag=dsync if=u-boot-dtb.bin of=/dev/mmcblk1boot0 seek=62"
