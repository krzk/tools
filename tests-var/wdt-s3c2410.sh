# Copyright (c) 2017,2023 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

# Boot with:
setenv opts s3c2410_wdt.soft_noboot=1

sudo wdctl

# Assuming there is no watchdog daemon
sudo touch /dev/watchdog0
# Wait for timer expire
