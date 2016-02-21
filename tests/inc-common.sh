#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

# die error_msg
die() {
	echo "FAIL: $1"
	exit 1
}

# test_cat file expected
test_cat() {
	local val="$(cat $1)"
	test "$val" = "$2" || echo "ERROR: Wrong $1 ($val == $2)"
}

#test_cat_lt file expected
test_cat_lt() {
	local val="$(cat $1)"
	test $val -lt $2 || echo "ERROR: Wrong $1 ($val < $2)"
}

#test_cat_gt file expected
test_cat_gt() {
	local val="$(cat $1)"
	test $val -gt $2 || echo "ERROR: Wrong $1 ($val > $2)"
}

# print_msg msg
# assuming 'name' is set
print_msg() {
	echo "${name}: $1"
}

get_board_compatible() {
	sed 's/\x0.\+/\n/' /sys/firmware/devicetree/base/compatible
}
