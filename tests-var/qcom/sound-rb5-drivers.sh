#!/bin/sh
#
# Copyright (C) 2023 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

# Test LPASS LPI concurrency issues

echo "start" > /sys/class/remoteproc/remoteproc1/state

# Test concurrent register updates - works best with msleep() between read and update
cd /sys/kernel/debug/pinctrl/33c0000.pinctrl
echo "gpio0 qua_mi2s_sclk" > pinmux-select &
sleep 0.1
echo "gpio0 swr_tx_clk" > pinmux-select 
