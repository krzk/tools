#!/bin/sh
#
# Copyright (c) 2023 Linaro Ltd
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

SERIAL_qrd="/dev/serial/by-id/usb-QUALCOMM_Inc._Embedded_Power_Measurement__EPM__device_6E02020620151F14-if01"

# Weird, Alpaca works only via initstring, not echo to picocom's stdin
picocom -b 115200 --echo --initstring "$(echo -ne 'usbDevicePower off\r\n')" -x 100 --flow none "$SERIAL_qrd"
picocom -b 115200 --echo --initstring "$(echo -ne 'devicePower off\r\n')" -x 100 --flow none "$SERIAL_qrd"
