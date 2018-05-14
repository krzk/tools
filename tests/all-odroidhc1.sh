#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E -x

. $(dirname ${BASH_SOURCE[0]})/inc-common.sh
#. $(dirname ${BASHSOURCE[0]})/pwm-fan.sh
. $(dirname ${BASH_SOURCE[0]})/cpu-online.sh
. $(dirname ${BASH_SOURCE[0]})/thermal.sh
. $(dirname ${BASH_SOURCE[0]})/odroid-xu3-board-name.sh
. $(dirname ${BASH_SOURCE[0]})/cpu-mmc-stress.sh
. $(dirname ${BASH_SOURCE[0]})/s5p-sss.sh
. $(dirname ${BASH_SOURCE[0]})/s5p-sss-cryptsetup.sh
. $(dirname ${BASH_SOURCE[0]})/usb.sh
. $(dirname ${BASH_SOURCE[0]})/var-all.sh
. $(dirname ${BASH_SOURCE[0]})/clk-s2mps11.sh
#. $(dirname ${BASH_SOURCE[0]})/audio.sh
# RTC often fail on NFS root so put it at the end
. $(dirname ${BASH_SOURCE[0]})/rtc.sh
# RNG does not work on Odroid, configured in secure mode?
#. $(dirname ${BASH_SOURCE[0]})/rng-exynos.sh
. $(dirname ${BASH_SOURCE[0]})/audss.sh


# Other:
# USB: manual
#reboot
#poweroff
