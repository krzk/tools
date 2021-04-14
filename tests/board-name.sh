#!/bin/bash
#
# Copyright (c) 2015-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

test_board_name() {
	local of="/sys/firmware/devicetree/base/compatible"
	local soc_family="Samsung Exynos"
	local soc_id=""
	local soc_machine=""
	local soc_revision=""
	local found_board=0
	echo -n "Board: "

	case "$TARGET" in
	arndaleocta|octa)
		grep -z 'insignal,arndale-octa$' -q $of && echo "Arndale Octa" && found_board=1
		soc_id="EXYNOS5420"
		soc_machine="Insignal Arndale Octa evaluation board based on Exynos5420"
		soc_revision="20"
		;;
	odroidmc1|mc1)
		grep -z 'hardkernel,odroid-hc1$' -q $of && echo "Odroid HC1" && found_board=1
		grep -z 'hardkernel,odroid-xu4$' -q $of && echo "Odroid XU4" && found_board=1
		soc_id="EXYNOS5800"
		soc_machine="Hardkernel Odroid HC1"
		soc_revision="1"
		;;
	odroidu3|u3)
		grep -z 'hardkernel,odroid-u3$' -q $of && echo "Odroid U3" && found_board=1
		soc_id="EXYNOS4412"
		soc_machine="Hardkernel ODROID-U3 board based on Exynos4412"
		soc_revision="20"
		;;
	odroidx|x)
		grep -z 'hardkernel,odroid-x$' -q $of && echo "Odroid X" && found_board=1
		soc_id="EXYNOS4412"
		soc_machine="Hardkernel ODROID-X board based on Exynos4412"
		soc_revision="11"
		;;
	odroidxu3|xu3)
		grep -z 'hardkernel,odroid-xu3-lite$' -q $of && echo "Odroid XU3 Lite" && found_board=1
		grep -z 'hardkernel,odroid-xu3$' -q $of && echo "Odroid XU3" && found_board=1
		soc_id="EXYNOS5800"
		soc_machine="Hardkernel Odroid XU3"
		soc_revision=""
		;;
	odroidxu|xu)
		grep -z 'hardkernel,odroid-xu$' -q $of && echo "Odroid XU" && found_board=1
		soc_id="EXYNOS5410"
		soc_machine="Hardkernel Odroid XU"
		soc_revision="23"
		;;
	odroidhc1|hc1)
		grep -z 'hardkernel,odroid-hc1$' -q $of && echo "Odroid HC1" && found_board=1
		grep -z 'hardkernel,odroid-xu4$' -q $of && echo "Odroid XU4" && found_board=1
		soc_id="EXYNOS5800"
		soc_machine="Hardkernel Odroid HC1"
		soc_revision="1"
		;;
	*)
		grep -z 'insignal,arndale-octa$' -q $of && echo "Arndale Octa" && found_board=1
		grep -z 'hardkernel,odroid-hc1$' -q $of && echo "Odroid HC1" && found_board=1
		grep -z 'hardkernel,odroid-u3$' -q $of && echo "Odroid U3" && found_board=1
		grep -z 'hardkernel,odroid-x$' -q $of && echo "Odroid X" && found_board=1
		grep -z 'hardkernel,odroid-xu$' -q $of && echo "Odroid XU" && found_board=1
		grep -z 'hardkernel,odroid-xu3-lite$' -q $of && echo "Odroid XU3 Lite" && found_board=1
		grep -z 'hardkernel,odroid-xu3$' -q $of && echo "Odroid XU3" && found_board=1
		grep -z 'hardkernel,odroid-xu4$' -q $of && echo "Odroid XU4" && found_board=1
	esac

	if is_kernel_le 5 5; then
		print_msg "Skipping soc0 revision checks, older kernel"
	else
		test -n "$soc_family" && test_cat /sys/bus/soc/devices/soc0/family "$soc_family"
		test -n "$soc_id" && test_cat /sys/bus/soc/devices/soc0/soc_id "$soc_id"
		test -n "$soc_machine" && test_cat /sys/bus/soc/devices/soc0/machine "$soc_machine"
		test -n "$soc_revision" && test_cat /sys/bus/soc/devices/soc0/revision "$soc_revision"
	fi

	if [ $found_board -ne 1 ]; then
		echo
		error_msg "Wrong board"
	fi

	return 0
}

test_board_name
