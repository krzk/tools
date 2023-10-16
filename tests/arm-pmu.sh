#!/bin/bash
#
# Copyright (c) 2019-2023 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

arm_pmu_single_cluster() {
	local output=""
	local i=0

	IFS=$'\n' output=( $(perf stat -e task-clock,cycles,instructions,branches,branch-misses,cache-misses,branch-load-misses,branch-loads -x ';' id 2>&1) )

	[[ "${output[$i]}" =~ ^uid=0 ]] || error_msg "Cannot match uid"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^[0-9\.]+\;[a-zA-Z]+\;task-clock ]] || error_msg "Cannot match uid"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;cycles\; ]] || error_msg "Cannot match cycles"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;instructions\; ]] || error_msg "Cannot match instructions"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;branches\; ]] || error_msg "Cannot match branches"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;branch-misses\; ]] || error_msg "Cannot match branch-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;cache-misses\; ]] || error_msg "Cannot match cache-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;branch-load-misses\; ]] || error_msg "Cannot match branch-load-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;branch-loads\; ]] || error_msg "Cannot match branch-loads"
	i=$(expr $i + 1)

	return 0
}

arm_pmu_two_clusters() {
	local output=""
	local i=0

	IFS=$'\n' output=( $(perf stat -e task-clock,cycles,instructions,branches,branch-misses,cache-misses,branch-load-misses,branch-loads -x ';' id 2>&1) )

	[[ "${output[$i]}" =~ ^uid=0 ]] || error_msg "Cannot match uid"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^[0-9\.]+\;[a-zA-Z]+\;task-clock ]] || error_msg "Cannot match uid"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/cycles/\; ]] || error_msg "Cannot match cycles"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/cycles/\; ]] || error_msg "Cannot match cycles"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/instructions/\; ]] || error_msg "Cannot match instructions"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/instructions/\; ]] || error_msg "Cannot match instructions"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branches/\; ]] || error_msg "Cannot match branches"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branches/\; ]] || error_msg "Cannot match branches"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branch-misses/\; ]] || error_msg "Cannot match branch-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branch-misses/\; ]] || error_msg "Cannot match branch-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/cache-misses/\; ]] || error_msg "Cannot match cache-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/cache-misses/\; ]] || error_msg "Cannot match cache-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branch-load-misses/\; ]] || error_msg "Cannot match branch-load-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branch-load-misses/\; ]] || error_msg "Cannot match branch-load-misses"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branch-loads/\; ]] || error_msg "Cannot match branch-loads"
	i=$(expr $i + 1)
	[[ "${output[$i]}" =~ ^([0-9]+|<not counted>)\;\;[a-z0-9_]+/branch-loads/\; ]] || error_msg "Cannot match branch-loads"
	i=$(expr $i + 1)

	return 0
}

test_arm_pmu() {
	local name="arm-pmu"
	local expected_hardware_events=0
	local expected_hardware_cache_events=0
	local has_two_clusters=0

	print_msg "Testing..."

	if is_kernel_le 4 14; then
		print_msg "SKIPPED: older kernel, not implemented"
		return 0
	fi

	case "$(get_board_compatible)" in
	insignal,arndale-octa|hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu4|hardkernel,odroid-xu)
		expected_hardware_events=7
		expected_hardware_cache_events=15
		if is_kernel_ge 6 6; then
			has_two_clusters=1
		fi
		;;
	hardkernel,odroid-u3|hardkernel,odroid-x)
		expected_hardware_events=8
		expected_hardware_cache_events=10
		;;
	hardkernel,odroid-xu3-lite)
		print_msg "SKIPPED: not implemented"
		return 0
		;;
	*)
		error_msg "Wrong board"
	esac

	if is_kernel_ge 6 0; then
		# Not sure if this is since kernel v6.0.
		# Some newer kernels started to skip hardware cache events. No clue why.
		expected_hardware_cache_events=0
	fi

	local count=$(perf list | grep "Hardware event" | wc -l)
	test $count -ge $expected_hardware_events || error_msg "Not enough: Hardware event"

	count=$(perf list | grep "Hardware cache event" | wc -l)
	test $count -ge $expected_hardware_cache_events || error_msg "Not enough: Hardware cache event"

	if [ $has_two_clusters == 0 ]; then
		arm_pmu_single_cluster
	else
		arm_pmu_two_clusters
	fi

	# Sometimes these do not appear in logs:
	#[[ "${output[9]}" =~ ^[0-9]+\;\;L1-dcache-loads\; ]] || error_msg "Cannot match L1-dcache-loads"
	#[[ "${output[10]}" =~ ^[0-9]+\;\;L1-dcache-load-misses\; ]] || error_msg "Cannot match L1-dcache-load-misses"
	#[[ "${output[11]}" =~ ^\<not[[:space:]]supported\>\;\;L1-icache-loads\; ]] || error_msg "Cannot match L1-icache-loads"
	#[[ "${output[12]}" =~ ^\<not[[:space:]]counted\>\;\;L1-icache-load-misses\; ]] || error_msg "Cannot match L1-icache-load-misses"

	print_msg "OK"
}

test_arm_pmu
