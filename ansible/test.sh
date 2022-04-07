#!/bin/bash
#
# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E

TEST_DIR="$(dirname ${BASH_SOURCE[0]})"

for file in ${TEST_DIR}/*yml; do
	ansible-playbook -v --syntax-check $file
done

exit $?
