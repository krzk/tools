#!/bin/sh
#
# Copyright (C) 2022-2023 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x

speakers_on() {
	amixer -c 0 cset name='SpkrNorth PA Volume' 20
	amixer -c 0 cset name='SpkrSouth PA Volume' 20
	amixer -c 0 cset name='WSA RX0 MUX' AIF1_PB
	amixer -c 0 cset name='WSA RX1 MUX' AIF1_PB
	amixer -c 0 cset name='WSA_RX0 INP0' RX0
	amixer -c 0 cset name='WSA_RX1 INP0' RX1
	amixer -c 0 cset name='WSA_COMP1 Switch' 1
	amixer -c 0 cset name='WSA_COMP2 Switch' 1
	amixer -c 0 cset name='SpkrNorth WSA MODE' 0
	amixer -c 0 cset name='SpkrSouth WSA MODE' 0
	amixer -c 0 cset name='SpkrNorth COMP Switch' 1
	amixer -c 0 cset name='SpkrNorth BOOST Switch' 1
	amixer -c 0 cset name='SpkrNorth DAC Switch' 1
	amixer -c 0 cset name='SpkrNorth VISENSE Switch' 1
	amixer -c 0 cset name='SpkrSouth COMP Switch' 1
	amixer -c 0 cset name='SpkrSouth BOOST Switch' 1
	amixer -c 0 cset name='SpkrSouth DAC Switch' 1
	amixer -c 0 cset name='SpkrSouth VISENSE Switch' 1
	amixer -c 0 cset name='WSA_RX0 Digital Volume' 85
	amixer -c 0 cset name='WSA_RX1 Digital Volume' 85
	amixer -c 0 cset name='WSA_CODEC_DMA_RX_0 Audio Mixer MultiMedia2' 1
}

speakers_off() {
	amixer -c 0 cset name="WSA RX0 MUX" ZERO
	amixer -c 0 cset name="WSA RX1 MUX" ZERO
	amixer -c 0 cset name='WSA_COMP1 Switch' 0
	amixer -c 0 cset name='WSA_COMP2 Switch' 0
	amixer -c 0 cset name="WSA_RX0 INP0" ZERO
	amixer -c 0 cset name="WSA_RX1 INP0" ZERO
	amixer -c 0 cset name='SpkrNorth COMP Switch' 0
	amixer -c 0 cset name='SpkrNorth VISENSE Switch' 0
	amixer -c 0 cset name='SpkrNorth DAC Switch' 0
	amixer -c 0 cset name='SpkrSouth COMP Switch' 0
	amixer -c 0 cset name='SpkrSouth VISENSE Switch' 0
	amixer -c 0 cset name='SpkrSouth DAC Switch' 0
}

if [ -c /dev/snd/pcmC0D4p ]; then
	HEADSET=4
	SPEAKER=5
else
	echo "Missing /dev/snd/pcmC0D4p and /dev/snd/pcmC0D5p"
	exit 1
fi

speakers_on
aplay -D plughw:0,${SPEAKER} /usr/share/sounds/alsa/Front_Center.wav
#speakers_off
