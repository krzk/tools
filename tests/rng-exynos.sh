#!/bin/bash
#
# Copyright (c) 2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_rng_exynos() {
	local name="rng-exynos"
	print_msg "Testing..."
	local rng="/sys/class/misc/hw_random/rng_current"

	if [ ! -f "$rng" ]; then
		print_msg "Missing ${rng}, skipping"
		return 0
	fi

	echo "exynos" > $rng
	test_cat $rng "exynos"

	dd if=/dev/hwrng of=/dev/null bs=1 count=16
	dd if=/dev/hwrng of=/dev/null bs=1 count=16
	dd if=/dev/hwrng of=/dev/null bs=1 count=16

	print_msg "OK"
}

test_rng_exynos
