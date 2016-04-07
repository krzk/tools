#!/bin/bash

# -E MMC_TEST -> and test it!
# -E PM_DEVFREQ,MMC_DEVFREQ
# -E RELAY,TRACEPOINTS,BLK_DEV_IO_TRACE
# echo "file drivers/mmc/card/block.c +p" > /sys/kernel/debug/dynamic_debug/control

dd if=/dev/mmcblk0p7 of=/root/test iflag=direct oflag=direct count=128 bs=1M
dd if=/dev/mmcblk0p7 iflag=direct count=128 bs=1M > /dev/null

dd if=/dev/mmcblk0p15 of=/opt/usr/test_test iflag=direct oflag=direct count=128 bs=1M
dd if=/dev/mmcblk0p15 iflag=direct count=128 bs=1M > /dev/null

grep . /sys/kernel/debug/mmc1/*

echo 100000000 > /sys/kernel/debug/mmc1/clock
echo 25000000 > /sys/kernel/debug/mmc1/clock



grep . /sys/kernel/debug/clk/*mmc1*/clk_rate

dd if=/dev/mmcblk0p7 of=/root/tesst iflag=direct oflag=direct count=128 bs=1M &
for i in `seq 80`; do
 for freq in 25000000 50000000 100000000; do
  echo $freq > /sys/kernel/debug/mmc1/clock
  sleep 0.01
 done
done

dd if=/dev/mmcblk0p15 of=/opt/usr/test_test iflag=direct oflag=direct count=128 bs=1M &
for i in `seq 80`; do
 for freq in 25000000 50000000 100000000; do
  echo $freq > /sys/kernel/debug/mmc0/clock
  sleep 0.01
 done
done

#318:
dd if=/dev/mmcblk0p7 of=/root/test_file iflag=direct oflag=direct count=128 bs=1M &
for i in `seq 100`; do
 for freq in 25000000 50000000 100000000; do
  echo $freq > /sys/kernel/debug/mmc0/clock
 done
done


blktrace/btreplay -d /mnt/sd/btrace -F -M btracemap -W -v

