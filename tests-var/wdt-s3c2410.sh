# Copyright (c) 2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#
# Boot with:
setenv opts s3c2410_wdt.soft_noboot=1
# Then kill wd:
sudo killall -9 watchdog
# Wait for timer expire
