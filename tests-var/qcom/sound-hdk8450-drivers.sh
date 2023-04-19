#!/bin/sh
#
# Copyright (C) 2023 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

# Requires removal of .suppress_bind_attrs
echo sdw:0:0217:010d:00:3 > /sys/bus/soundwire/drivers/wcd9380-codec/unbind
echo sdw:0:0217:010d:00:4 > /sys/bus/soundwire/drivers/wcd9380-codec/unbind
echo audio-codec > /sys/bus/platform/drivers/wcd938x_codec/unbind
echo 3210000.soundwire-controller > /sys/bus/platform/drivers/qcom-soundwire/unbind
echo 33b0000.soundwire-controller > /sys/bus/platform/drivers/qcom-soundwire/unbind

echo sdw:0:0217:0202:00:1 > /sys/bus/soundwire/drivers/wsa883x-codec/unbind
echo sdw:0:0217:0202:00:2 > /sys/bus/soundwire/drivers/wsa883x-codec/unbind
echo 3250000.soundwire-controller > /sys/bus/platform/drivers/qcom-soundwire/unbind
