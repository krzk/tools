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

# RTC
sudo rtcwake -m on -s 5 -v
sudo rtcwake -m freeze -s 5 -v

# usbhid:
ls -l /sys/class/input/
echo "1-1:1.0" > /sys/module/usbhid/drivers/usb\:usbhid/unbind
ls -l /sys/class/input/
echo "1-1:1.0" > /sys/module/usbhid/drivers/usb\:usbhid/bind
ls -l /sys/class/input/
modprobe -r mac_hid hid_generic usbhid hid
ls -l /sys/class/input/
modprobe usbhid
ls -l /sys/class/input/
