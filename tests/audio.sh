#!/bin/bash
#
# Copyright (c) 2016-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_audio() {
	local name="Audio"
	print_msg "Testing..."

	if [ "$(get_board_compatible)" == "hardkernel,odroid-hc1" ] ||
		[ "$(get_board_compatible)" == "insignal,arndale-octa" ]; then
		print_msg "No audio, skipping"
		return 0
	fi

	# On kernels <=v4.12, expected:
	# default:CARD=OdroidXU3
	# On kernels ~v4.13, expected is something like:
	# default:CARD=D3830000i2sHiFi
	run_as_nonroot aplay -L | egrep -i "odroid|D3830000i2sHiFi"

	run_as_nonroot aplay /usr/share/sounds/alsa/Front_Right.wav
	run_as_nonroot speaker-test --channels 2  --nloops 3

	print_msg "OK"
}

test_audio
