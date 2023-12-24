#!/bin/bash
#
# Copyright (c) 2015-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x

. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh
. $(dirname "${BASH_SOURCE[0]}")/drm.sh
. $(dirname "${BASH_SOURCE[0]}")/exynos5422-dmc.sh
#. $(dirname ${BASHSOURCE[0]})/pwm-fan.sh
. $(dirname "${BASH_SOURCE[0]}")/cpu-online.sh
. $(dirname "${BASH_SOURCE[0]}")/thermal.sh
. $(dirname "${BASH_SOURCE[0]}")/thermal-cooling.sh
. $(dirname "${BASH_SOURCE[0]}")/board-name.sh
. $(dirname "${BASH_SOURCE[0]}")/board-led.sh
. $(dirname "${BASH_SOURCE[0]}")/cpu-mmc-stress.sh
. $(dirname "${BASH_SOURCE[0]}")/s5p-sss.sh
. $(dirname "${BASH_SOURCE[0]}")/s5p-sss-tcrypt.sh
. $(dirname "${BASH_SOURCE[0]}")/s5p-sss-cryptsetup.sh
. $(dirname "${BASH_SOURCE[0]}")/s5p-mfc.sh
. $(dirname "${BASH_SOURCE[0]}")/usb.sh
. $(dirname "${BASH_SOURCE[0]}")/var-all.sh
. $(dirname "${BASH_SOURCE[0]}")/clk-s2mps11.sh
. $(dirname "${BASH_SOURCE[0]}")/audio.sh
. $(dirname "${BASH_SOURCE[0]}")/adc-exynos.sh
. $(dirname "${BASH_SOURCE[0]}")/arm-pmu.sh
# RTC often fail on NFS root so put it at the end
. $(dirname "${BASH_SOURCE[0]}")/rtc.sh
# RNG does not work on Odroid, configured in secure mode?
#. $(dirname "${BASH_SOURCE[0]}")/rng-exynos.sh
. $(dirname "${BASH_SOURCE[0]}")/audss.sh


# Other:
# USB: manual
#reboot
#poweroff
