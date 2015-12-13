#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_clk_s2mps11() {
    local name="clk-s2mps11"
    local clk_name=""
    print_msg "Testing..."

    case "$(get_board_compatible)" in
    hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4)
        clk_name="s2mps11"
        ;;
    *)
        print_msg "ERROR: Wrong board"
	return
    esac

    test -d "/sys/kernel/debug/clk/${clk_name}_ap" || print_msg "ERROR: No ${clk_name}_ap"
    test -d "/sys/kernel/debug/clk/${clk_name}_bt" || print_msg "ERROR: No ${clk_name}_bt"
    test -d "/sys/kernel/debug/clk/${clk_name}_cp" || print_msg "ERROR: No ${clk_name}_cp"
    for clk in /sys/kernel/debug/clk/${clk_name}_*; do
        test_cat "${clk}/clk_enable_count" 0
        test_cat "${clk}/clk_notifier_count" 0
	if [[ "$clk" =~ "${clk_name}_ap" ]]; then
            test_cat "${clk}/clk_prepare_count" 1
	else
            test_cat "${clk}/clk_prepare_count" 0
	fi
        test_cat "${clk}/clk_rate" 32768
    done
}

test_clk_s2mps11
