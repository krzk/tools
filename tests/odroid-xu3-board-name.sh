#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_board_name() {
	local of="/sys/firmware/devicetree/base/compatible"
	echo -n "Board: "
	grep -z 'hardkernel,odroid-xu3-lite$' -q $of && echo "Odroid XU3 Lite" && return 0
	grep -z 'hardkernel,odroid-xu3$' -q $of && echo "Odroid XU3" && return 0
	grep -z 'hardkernel,odroid-xu4$' -q $of && echo "Odroid XU4" && return 0
	echo
	echo "ERROR: Wrong board"
}

test_board_name
