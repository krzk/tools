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

test_s5p_sss_selftests() {
	local name="s5p-sss selftests"
	local expected_alg="cbc-aes-s5p ecb-aes-s5p"
	local expected_alg_num=2
	local found_alg=0
	local cipher_type="skcipher"
	print_msg "Testing..."

	if is_kernel_le 4 4; then
		# On v4.4 s5p-sss might not be enabled
		print_msg "Old kernel, skipped"
		return 0
	elif is_kernel_le 5 4; then
		cipher_type="ablkcipher"
	fi

	for alg in $expected_alg; do
		print_msg "Testing for ${alg}..."
		cmd="grep -A 11 "$alg" /proc/crypto"

		$cmd | grep "selftest     : passed" > /dev/null || error_msg "${alg}: not matching: passed"
		$cmd | grep "module       : kernel" > /dev/null || error_msg "${alg}: not matching: module kernel"
		$cmd | grep "refcnt       : 1" > /dev/null || error_msg "${alg}: not matching: refcnt 1"
		$cmd | grep "internal     : no" > /dev/null || error_msg "${alg}: not matching: no internal"
		$cmd | grep "type         : $cipher_type" > /dev/null || error_msg "${alg}: not matching: $cipher_type"
		$cmd | grep "blocksize    : 16" > /dev/null || error_msg "${alg}: not matching: 'min keysize  : 16'"
		$cmd | grep "min keysize  : 16" > /dev/null || error_msg "${alg}: not matching: 'min keysize  : 16'"
		$cmd | grep "max keysize  : 32" > /dev/null || error_msg "${alg}: not matching: 'max keysize  : 32'"
		found_alg=$(($found_alg + 1))
	done

	test $found_alg -eq $expected_alg_num || \
		error_msg "Found $found_alg algorithms instead of $expected_alg_num"

	print_msg "OK"
}

test_s5p_sss_selftests
