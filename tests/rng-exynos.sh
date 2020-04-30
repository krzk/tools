#!/bin/bash
#
# Copyright (c) 2016-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_rng_exynos() {
	local name="rng-exynos"
	local rng="/sys/class/misc/hw_random/rng_current"
	local rng_name=""
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-u3|hardkernel,odroid-x)
		print_msg "RNG not supported yet (or broken?), skipping"
		return 0
		;;
	esac

	if is_kernel_le 4 16; then
		rng_name="exynos"
	else
		rng_name="10830600.rng"
	fi

	echo "$rng_name" > $rng
	test_cat $rng "$rng_name"

	dd if=/dev/hwrng of=/dev/null bs=1 count=16
	dd if=/dev/hwrng of=/dev/null bs=1 count=16
	dd if=/dev/hwrng of=/dev/null bs=1 count=16

	print_msg "OK"
}

test_rng_exynos
