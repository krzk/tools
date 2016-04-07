#!/bin/bash

# Reproducing DSI error (after resume: PLL failed to stabilize)
# Build with -E EXPERT -D FRAMEBUFFER_CONSOLE

cat /sys/kernel/debug/pm_genpd/pm_genpd_summary
echo 3 > /sys/devices/platform/exynos-drm/graphics/fb0/blank
cat /sys/kernel/debug/pm_genpd/pm_genpd_summary
grep . /sys/devices/platform/exynos-drm/drm/card0/card0-DSI-1/*

grep "disabled" /sys/devices/platform/exynos-drm/drm/card0/card0-DSI-1/enabled
/root/modeset-vsync
grep "enabled" /sys/devices/platform/exynos-drm/drm/card0/card0-DSI-1/enabled
echo 3 > /sys/devices/platform/exynos-drm/graphics/fb0/blank

echo mem > /sys/power/state

