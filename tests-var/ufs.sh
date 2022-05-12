#!/bin/bash
#
# Copyright (c) 2022 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

DEVICE="/sys/devices/platform/soc@0/1d84000.ufshc"

echo -n 'file drivers/scsi/ufs/ufshcd.c +p' > /sys/kernel/debug/dynamic_debug/control
echo -n 'file drivers/opp/core.c +p' > /sys/kernel/debug/dynamic_debug/control
if [ -d "$DEVICE" ]; then
	echo 0 > ${DEVICE}/clkscale_enable
	cat /sys/kernel/debug/pm_genpd/pm_genpd_summary
	echo 1 > ${DEVICE}/clkscale_enable
	cat /sys/kernel/debug/pm_genpd/pm_genpd_summary
	echo 50000000 > ${DEVICE}/devfreq/1d84000.ufshc/max_freq
	cat /sys/kernel/debug/pm_genpd/pm_genpd_summary
	echo 200000000 > ${DEVICE}/devfreq/1d84000.ufshc/max_freq
	cat /sys/kernel/debug/pm_genpd/pm_genpd_summary
fi
