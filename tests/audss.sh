#!/bin/bash
#
# Copyright (c) 2015-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

test_audss() {
	local name="Audss rebind"
	local device=""
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4|hardkernel,odroid-xu|insignal,arndale-octa)
		device="3810000.audss-clock-controller"
		;;
	hardkernel,odroid-u3|hardkernel,odroid-x)
		device="3810000.clock-controller"
		;;
	*)
		error_msg "Wrong board"
	esac

	echo "$device" > /sys/bus/platform/drivers/exynos-audss-clk/unbind
	echo "$device" > /sys/bus/platform/drivers/exynos-audss-clk/bind

	print_msg "OK"
}

test_audss
