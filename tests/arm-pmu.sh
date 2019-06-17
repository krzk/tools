#!/bin/bash
#
# Copyright (c) 2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_arm_pmu() {
	local name="arm-pmu"
	local expected_hardware_events=0
	local expected_hardware_cache_events=0
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	insignal,arndale-octa|hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu4|hardkernel,odroid-xu)
		expected_hardware_events=7
		expected_hardware_cache_events=15
		;;
	hardkernel,odroid-u3)
		expected_hardware_events=8
		expected_hardware_cache_events=10
		;;
	hardkernel,odroid-xu3-lite)
		print_msg "Not implemented"
		return 0
		;;
	*)
		error_msg "Wrong board"
	esac

	local count=$(perf list | grep "Hardware event" | wc -l)
	test $count -ge $expected_hardware_events || error_msg "Not enough: Hardware event"

	count=$(perf list | grep "Hardware cache event" | wc -l)
	test $count -ge $expected_hardware_cache_events || error_msg "Not enough: Hardware cache event"

	local output=""
	IFS=$'\n' output=( $(perf stat -e task-clock,cycles,instructions,branches,branch-misses,cache-misses,branch-load-misses,branch-loads -x ';' id 2>&1) )

	[[ "${output[0]}" =~ ^uid=0 ]] || error_msg "Cannot match uid"
	[[ "${output[1]}" =~ ^[0-9\.]+\;[a-zA-Z]+\;task-clock ]] || error_msg "Cannot match uid"
	[[ "${output[2]}" =~ ^[0-9]+\;\;cycles\; ]] || error_msg "Cannot match cycles"
	[[ "${output[3]}" =~ ^[0-9]+\;\;instructions\; ]] || error_msg "Cannot match instructions"
	[[ "${output[4]}" =~ ^[0-9]+\;\;branches\; ]] || error_msg "Cannot match branches"
	[[ "${output[5]}" =~ ^[0-9]+\;\;branch-misses\; ]] || error_msg "Cannot match branch-misses"
	[[ "${output[6]}" =~ ^[0-9]+\;\;cache-misses\; ]] || error_msg "Cannot match cache-misses"
	[[ "${output[7]}" =~ ^[0-9]+\;\;branch-load-misses\; ]] || error_msg "Cannot match branch-load-misses"
	[[ "${output[8]}" =~ ^[0-9]+\;\;branch-loads\; ]] || error_msg "Cannot match branch-loads"
	# Sometimes these do not appear in logs:
	#[[ "${output[9]}" =~ ^[0-9]+\;\;L1-dcache-loads\; ]] || error_msg "Cannot match L1-dcache-loads"
	#[[ "${output[10]}" =~ ^[0-9]+\;\;L1-dcache-load-misses\; ]] || error_msg "Cannot match L1-dcache-load-misses"
	#[[ "${output[11]}" =~ ^\<not[[:space:]]supported\>\;\;L1-icache-loads\; ]] || error_msg "Cannot match L1-icache-loads"
	#[[ "${output[12]}" =~ ^\<not[[:space:]]counted\>\;\;L1-icache-load-misses\; ]] || error_msg "Cannot match L1-icache-load-misses"

	print_msg "OK"
}

test_arm_pmu
