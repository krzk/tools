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

. $(dirname ${BASH_SOURCE[0]})/inc-common.sh
. $(dirname ${BASH_SOURCE[0]})/odroid-xu3-cpu-online.sh
. $(dirname ${BASH_SOURCE[0]})/odroid-xu3-thermal.sh
. $(dirname ${BASH_SOURCE[0]})/rtc.sh
. $(dirname ${BASH_SOURCE[0]})/odroid-xu3-board-name.sh
. $(dirname ${BASH_SOURCE[0]})/odroid-xu3-cpu-mmc-stress.sh
. $(dirname ${BASH_SOURCE[0]})/clk-s2mps11.sh

# Sound: manual or:
sudo -u $USER aplay /usr/share/sounds/alsa/Front_Right.wav > /dev/null
echo "Sound/aplay: Done"

echo "3810000.audss-clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/unbind
echo "3810000.audss-clock-controller" > /sys/bus/platform/drivers/exynos-audss-clk/bind
echo "Audss rebind: Done"



# Other:
# USB: manual
#reboot
#poweroff
