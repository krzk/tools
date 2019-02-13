#!/bin/bash
#
# Copyright (c) 2015-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

TARGET="$1"
NAME="$2"

# die error_msg
die() {
	echo "FAIL: $1"
	exit 1
}

# test_cat file expected
test_cat() {
	read -r val < "$1"
	test "$val" = "$2" || { echo "ERROR: Wrong $1 ($val == $2)"; return 1; }
	return 0
}

#test_cat_lt file expected
test_cat_lt() {
	read -r val < "$1"
	test $val -lt $2 || { echo "ERROR: Wrong $1 ($val < $2)"; return 1; }
	return 0
}

#test_cat_gt file expected
test_cat_gt() {
	read -r val < "$1"
	test $val -gt $2 || { echo "ERROR: Wrong $1 ($val > $2)"; return 1; }
	return 0
}

#test_cat_ge file expected
test_cat_ge() {
	read -r val < "$1"
	test $val -ge $2 || { echo "ERROR: Wrong $1 ($val >= $2)"; return 1; }
	return 0
}

#test_cat_gt file expected_low expected_high
test_cat_range() {
	read -r val < "$1"
	test $val -ge $2 || { echo "ERROR: Wrong $1 ($val >= $2)"; return 1; }
	test $val -le $3 || { echo "ERROR: Wrong $1 ($val <= $3)"; return 1; }
	return 0
}

# print_msg msg
# assuming 'name' is set
print_msg() {
	echo "${name}: $1"
}

# error_msg msg
# assuming 'name' is set
error_msg() {
	echo "ERROR: ${name}: $1"
	exit 2
}

get_board_compatible() {
	sed 's/\x0.\+/\n/' /sys/firmware/devicetree/base/compatible
}

# is_kernel_le major minor
# returns 0 if current kernel is less or equal to major.minor
is_kernel_le() {
	local exp_major="$1"
	local exp_minor="$2"
	local kver="$(uname -r)"
	local kmajor="${kver%%.*}"
	local kminor="${kver#*.}"
	kminor="${kminor%%.*}"

	test $kmajor -lt $exp_major && return 0
	if [ $kmajor -eq $exp_major ]; then
		test $kminor -le $exp_minor && return 0
	fi

	return 1
}

# run_as_nonroot cmd
run_as_nonroot() {
	if [ "$SUDO_USER" != "" ]; then
		sudo -u "$SUDO_USER" $*
	else
		$*
	fi
}
