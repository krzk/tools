#!/bin/bash
#
# Copyright (c) 2018-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

# test_drm
test_drm() {
	local name="DRM"
	print_msg "Testing..."
	local drm="/sys/class/drm"
	local expected_cards=""
	local expected_outputs=""
	local expected_nodrm=0

	case "$(get_board_compatible)" in
	hardkernel,odroid-u3|hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4)
		expected_outputs="card0/card0-HDMI-A-1 card0-HDMI-A-1"
		;;
	hardkernel,odroid-hc1|hardkernel,odroid-xu)
		if is_kernel_le 5 5; then
			expected_nodrm=1
		else
			expected_cards="card0"
		fi
		;;
	hardkernel,odroid-xu)
		expected_nodrm=1
		;;
	insignal,arndale-octa)
		expected_outputs="card0/card0-HDMI-A-1 card0-HDMI-A-1"
		;;
	*)
		error_msg "Wrong board"
	esac

	for card in $expected_outputs; do
		test -d "${drm}/${card}" || error_msg "Missing card ${card}"
		test_cat "${drm}/${card}/dpms" "On"
		test_cat "${drm}/${card}/enabled" "disabled"
		test_cat "${drm}/${card}/status" "disconnected"
	done

	for card in $expected_cards; do
		test -d "${drm}/${card}" || error_msg "Missing card ${card}"
	done

	if [ $expected_nodrm -eq 1 ]; then
		test $(ls ${drm}/ | wc -l) -eq 1 || error_msg "Expected no DRM"
	fi

	print_msg "OK"
}

test_drm
