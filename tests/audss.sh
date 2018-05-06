#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_audss() {
	local name="Audss rebind"
	local device=""

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4|hardkernel,odroid-xu)
		device="3810000.audss-clock-controller"
		;;
	hardkernel,odroid-u3)
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
