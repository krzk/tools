#!/bin/bash
#
# Copyright (c) 2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

grep -z 'hardkernel,odroid-u3' -q /sys/firmware/devicetree/base/compatible
if [ $? -ne 0 ]; then
	echo "Not an Odroid-U3 board"
	exit 0
fi

lsusb | grep '0424:9730' -q
test $? -eq 0 && exit 0

set -e -E

echo "Missing LAN, trying to reset through gpa1-1..."
for chip in /sys/class/gpio/gpiochip*; do
	label="$(cat ${chip}/label)"
	if [ "$label" == "gpa1" ]; then
		base="$(cat ${chip}/base)"
		gpio="$(expr $base + 1)"
		test -d /sys/class/gpio/gpio${gpio} || echo "$gpio" > /sys/class/gpio/export
		echo low > /sys/class/gpio/gpio${gpio}/direction
		echo high > /sys/class/gpio/gpio${gpio}/direction

		set +e +E
		lsusb | grep '0424:9730' -q
		if [ $? -eq 0 ]; then
			echo "Reset successful..."
		else
			echo "Reset unsuccessful..."
		fi
	fi
done
