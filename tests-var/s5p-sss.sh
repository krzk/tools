#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

# Disable: CRYPTO_MANAGER_DISABLE_TESTS
# Module: CRYPTO_TEST

cat /proc/crypto
dmesg | grep alg
dmesg | grep s5p

modprobe tcrypt sec=1 mode=500

for i in `seq 10`; do
	echo "Round $i ############"
	modprobe tcrypt sec=1 mode=500
	echo "Round $i ############"
	sleep 3
done
