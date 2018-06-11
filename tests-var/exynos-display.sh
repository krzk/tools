#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done

grep . /sys/class/drm/card0-*/*

killall Xorg
echo 3 > /sys/devices/platform/exynos-drm/graphics/fb0/blank
echo 0 > /sys/devices/platform/exynos-drm/graphics/fb0/blank

# modetest
# git://anongit.freedesktop.org/mesa/drm
# set -e -E
# rm -fr out/
# make clean -j4
# ./autogen.sh --enable-exynos-experimental-api --enable-install-test-programs --enable-static --host=arm-linux-gnueabi --prefix=/tmp/drm-install/
# make -j4
# make install
# tar -cf drm-install-arm.tar /tmp/drm-install/

./kmstest
./modetest -e
./modetest -c
./modetest -f
./modetest -p
# Odroid XU3:
./modetest -s 28:1920x1080
./modetest -s 28:1920x1080 -v
./modetest -s 28:1920x1080 -v -C
