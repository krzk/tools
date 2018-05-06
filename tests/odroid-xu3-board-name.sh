#!/bin/bash
#
# Copyright (c) 2015-2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_board_name() {
	local of="/sys/firmware/devicetree/base/compatible"
	echo -n "Board: "

	case "$TARGET" in
	odroidu3|u3)
		grep -z 'hardkernel,odroid-u3$' -q $of && echo "Odroid U3" && return 0
		;;
	odroidxu3|xu3)
		grep -z 'hardkernel,odroid-xu3-lite$' -q $of && echo "Odroid XU3 Lite" && return 0
		grep -z 'hardkernel,odroid-xu3$' -q $of && echo "Odroid XU3" && return 0
		;;
	odroidhc1|hc1)
		grep -z 'hardkernel,odroid-hc1$' -q $of && echo "Odroid HC1" && return 0
		grep -z 'hardkernel,odroid-xu4$' -q $of && echo "Odroid XU4" && return 0
		;;
	*)
		grep -z 'hardkernel,odroid-hc1$' -q $of && echo "Odroid HC1" && return 0
		grep -z 'hardkernel,odroid-u3$' -q $of && echo "Odroid U3" && return 0
		grep -z 'hardkernel,odroid-xu3-lite$' -q $of && echo "Odroid XU3 Lite" && return 0
		grep -z 'hardkernel,odroid-xu3$' -q $of && echo "Odroid XU3" && return 0
		grep -z 'hardkernel,odroid-xu4$' -q $of && echo "Odroid XU4" && return 0
		return 1
	esac

	echo
	error_msg "Wrong board"
}

test_board_name
