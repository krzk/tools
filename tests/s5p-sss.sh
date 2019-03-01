#!/bin/bash
#
# Copyright (c) 2016-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_s5p_sss_selftests() {
	local name="s5p-sss selftests"
	local expected_alg="cbc-aes-s5p ecb-aes-s5p"
	local expected_alg_num=2
	local found_alg=0
	print_msg "Testing..."

	for alg in $expected_alg; do
		print_msg "Testing for ${alg}..."
		cmd="grep -A 11 "$alg" /proc/crypto"

		$cmd | grep "selftest     : passed" > /dev/null || error_msg "${alg}: not matching: passed"
		$cmd | grep "module       : kernel" > /dev/null || error_msg "${alg}: not matching: module kernel"
		$cmd | grep "refcnt       : 1" > /dev/null || error_msg "${alg}: not matching: refcnt 1"
		$cmd | grep "internal     : no" > /dev/null || error_msg "${alg}: not matching: no internal"
		$cmd | grep "type         : ablkcipher" > /dev/null || error_msg "${alg}: not matching: ablkcipher"
		$cmd | grep "blocksize    : 16" > /dev/null || error_msg "${alg}: not matching: 'min keysize  : 16'"
		$cmd | grep "min keysize  : 16" > /dev/null || error_msg "${alg}: not matching: 'min keysize  : 16'"
		$cmd | grep "max keysize  : 32" > /dev/null || error_msg "${alg}: not matching: 'max keysize  : 32'"
		found_alg=$(($found_alg + 1))
	done

	test $found_alg -eq $expected_alg_num || \
		error_msg "Found $found_alg algorithms instead of $expected_alg_num"

	print_msg "OK"
}

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

test_s5p_sss_selftests
test_s5p_sss_tcrypt
