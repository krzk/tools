#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

# Compile: -E DMATEST -D PM_RUNTIME

cat /sys/kernel/debug/clk/clk_summary | grep dma

grep . /sys/kernel/debug/clk/[apm]dma*/*
grep . /sys/bus/amba/drivers/dma-pl330/*/power/*

# Rinato/Trats2
echo 12850000.mdma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 12680000.pdma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 12690000.pdma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 12850000.mdma > /sys/bus/amba/drivers/dma-pl330/bind
echo 12680000.pdma > /sys/bus/amba/drivers/dma-pl330/bind
echo 12690000.pdma > /sys/bus/amba/drivers/dma-pl330/bind

# Arndale Octa
echo 10800000.mdma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 121a0000.pdma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 121b0000.pdma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 3880000.adma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 10800000.mdma > /sys/bus/amba/drivers/dma-pl330/bind
echo 121a0000.pdma > /sys/bus/amba/drivers/dma-pl330/bind
echo 121b0000.pdma > /sys/bus/amba/drivers/dma-pl330/bind
echo 3880000.adma > /sys/bus/amba/drivers/dma-pl330/bind

# test_cat file expected
test_cat() {
  local val="$(cat $1)"
  test "$val" = "$2" || echo "ERROR: Wrong $1 ($val)"
}

echo "file drivers/dma/dmatest.c +p" > /sys/kernel/debug/dynamic_debug/control
echo 5000 > /sys/module/dmatest/parameters/timeout
echo 1 > /sys/module/dmatest/parameters/iterations
echo 4 > /sys/module/dmatest/parameters/threads_per_chan
echo 4194304 > /sys/module/dmatest/parameters/test_buf_size
echo dma1chan0 > /sys/module/dmatest/parameters/channel
echo 1 > /sys/module/dmatest/parameters/run
test_cat /sys/class/dma/dma1chan0/in_use "1"
grep . /sys/class/dma/dma1chan0/*
sleep 1
cat /sys/module/dmatest/parameters/run

echo 3 > /sys/module/dmatest/parameters/iterations
for channel in `ls -1 /sys/class/dma/` ; do
  echo "############### DMA: $channel"
  echo $channel > /sys/module/dmatest/parameters/channel
  echo 1 > /sys/module/dmatest/parameters/run
  test_cat /sys/class/dma/${channel}/in_use "1"
  cat /sys/module/dmatest/parameters/run
  sleep 1
  echo $bytes
done

for i in /sys/bus/amba/drivers/dma-pl330/*.[amp]dma/power ; do
  echo "########### $i"
  cat ${i}/runtime_status
  cat ${i}/runtime_active_time
  echo "on" > ${i}/control
  cat ${i}/runtime_status
  grep . /sys/kernel/debug/clk/[apm]*dma*/clk_enable_count
  cat ${i}/runtime_active_time
  echo "auto" > ${i}/control
  cat ${i}/runtime_status
  cat ${i}/runtime_active_time
done

echo mem > /sys/power/state

DMADEV=/sys/bus/amba/drivers/dma-pl330/12680000.pdma
echo "on" > ${DMADEV}/power/control
cat ${DMADEV}/power/runtime_status
grep . /sys/kernel/debug/clk/[pm]*dma*/clk_enable_count
echo mem > /sys/power/state
grep . /sys/kernel/debug/clk/[pm]*dma*/clk_enable_count
echo "auto" > ${DMADEV}/power/control

# arndale octa
echo 3880000.adma > /sys/bus/amba/drivers/dma-pl330/unbind
echo 3880000.adma > /sys/bus/amba/drivers/dma-pl330/bind

echo 3 > /sys/module/dmatest/parameters/iterations
for channel in `ls -1 /sys/class/dma/ | grep -v dma0
chan` ; do
  echo "############### DMA: $channel"
  echo $channel > /sys/module/dmatest/parameters/channel
  echo 1 > /sys/module/dmatest/parameters/run
  cat /sys/module/dmatest/parameters/run
  sleep 1
done
