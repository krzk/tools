#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E

. $(dirname ${BASH_SOURCE[0]})/inc/0-common.sh
. $(dirname ${BASH_SOURCE[0]})/inc/odroid-xu3-cpu-online.sh
. $(dirname ${BASH_SOURCE[0]})/inc/odroid-xu3-thermal.sh
. $(dirname ${BASH_SOURCE[0]})/inc/rtc.sh

test_cpu_online 6
test_thermal
test_rtc

# Sound: manual or:
aplay /usr/share/sounds/alsa/Front_Right.wav > /dev/null
echo "Sound/aplay: OK"

echo "3810000.audss-clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/unbind
echo "3810000.audss-clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/bind
echo "Audss rebind: OK"

# Other:
# USB: manual
#reboot
#poweroff
