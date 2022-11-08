#!/bin/sh
#
# Copyright (C) 2022 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x

amixer -c 0 cset name='SpkrLeft PA Volume', 20
amixer -c 0 cset name='SpkrRight PA Volume', 20
amixer -c 0 cset name='WSA RX0 MUX' AIF1_PB
amixer -c 0 cset name='WSA RX1 MUX' AIF1_PB
amixer -c 0 cset name='WSA_RX0 INP0' RX0
amixer -c 0 cset name='WSA_RX1 INP0' RX1
amixer -c 0 cset name='WSA_COMP1 Switch' 1
amixer -c 0 cset name='WSA_COMP2 Switch' 1
amixer -c 0 cset name='SpkrLeft WSA MODE' 0
amixer -c 0 cset name='SpkrRight WSA MODE' 0
amixer -c 0 cset name='SpkrLeft COMP Switch' 1
amixer -c 0 cset name='SpkrLeft BOOST Switch' 1
amixer -c 0 cset name='SpkrLeft DAC Switch' 1
amixer -c 0 cset name='SpkrLeft VISENSE Switch' 0
amixer -c 0 cset name='SpkrRight COMP Switch' 1
amixer -c 0 cset name='SpkrRight BOOST Switch' 1
amixer -c 0 cset name='SpkrRight DAC Switch' 1
amixer -c 0 cset name='SpkrRight VISENSE Switch' 0
amixer -c 0 cset name='WSA_RX0 Digital Volume' 85
amixer -c 0 cset name='WSA_RX1 Digital Volume' 85

amixer -c 0 cset name='WSA_CODEC_DMA_RX_0 Audio Mixer MultiMedia2' 1

aplay -D plughw:0,2 /usr/share/sounds/alsa/Front_Center.wav
