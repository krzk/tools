#!/bin/bash

grep . /sys/class/drm/card0-*/*

killall Xorg
echo 3 > /sys/devices/platform/exynos-drm/graphics/fb0/blank
echo 0 > /sys/devices/platform/exynos-drm/graphics/fb0/blank
