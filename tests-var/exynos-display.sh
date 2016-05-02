#!/bin/bash

for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done

grep . /sys/class/drm/card0-*/*

killall Xorg
echo 3 > /sys/devices/platform/exynos-drm/graphics/fb0/blank
echo 0 > /sys/devices/platform/exynos-drm/graphics/fb0/blank
