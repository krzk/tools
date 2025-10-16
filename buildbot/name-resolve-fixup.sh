#!/bin/bash
#
# Copyright (c) 2021-2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

SELF_DIR="$(dirname "${BASH_SOURCE[0]}")"
. "${SELF_DIR}/inc-build-slave.sh"

# Be verbose for Buildbot debugging
set -x

NAMES=(github.com git.kernel.org build.krzk.eu)

if which resolvectl > /dev/null; then
	DNS_RESOLVER=(resolvectl query)
else
	which dig > /dev/null
	test $? || die "Missing DNS tools"
	DNS_RESOLVER=(dig)
fi

i=0
while [ $i -le 50 ]; do
	"${DNS_RESOLVER[@]}" "${NAMES[@]}"
	test $? -eq 0 && exit 0
	i=$(( i + 1 ))
	sleep 0.5
done

exit 1
