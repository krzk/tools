#!/bin/bash
#
# Copyright (c) 2016-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

have_tcrypt() {
	set +e
	modinfo tcrypt > /dev/null
	if [ $? -eq 0 ]; then
		echo "yes"
	else
		echo "no"
	fi
	set -e
	return 0
}

test_s5p_sss_tcrypt() {
	local name="s5p-sss tcrypt"
	print_msg "Testing..."

	if [ "$(have_tcrypt)" != "yes" ]; then
		print_msg "No tcrypt, skipping"
		return 0
	fi

	set +e
	modprobe tcrypt sec=1 mode=500
	set -e

	print_msg "OK"
}

test_s5p_sss_tcrypt
