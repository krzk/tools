#!/bin/bash
#
# Copyright (c) 2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set +e +E

export LD_LIBRARY_PATH=/usr/local/lib
gcc -o kcapi-rng-test kcapi-rng-test.c -I/usr/local/include -L/usr/local/lib -lkcapi

echo "Testing kcapi-rng reads from 1 to 100 bytes..."
for i in `seq 100`; do
	RNG="$(./kcapi-rng-test $i | wc --bytes)"
	if [ $i -ne $RNG ]; then
		echo "RNG expected $i, got $RNG bytes"
		exit 1
	fi
done
