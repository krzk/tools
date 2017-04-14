#!/bin/bash
#
# Copyright (c) 2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

test_audio() {
	local name="Audio"
	print_msg "Testing..."

	run_as_nonroot aplay -L | grep -i odroid
	run_as_nonroot aplay /usr/share/sounds/alsa/Front_Right.wav
	run_as_nonroot speaker-test --channels 2  --nloops 3

	print_msg "OK"
}

test_audio
