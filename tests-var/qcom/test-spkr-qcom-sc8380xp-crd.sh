#!/bin/sh
#
# Copyright (C) 2023 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x

speakers_on() {
	amixer -c 0 cset name='WSA WSA RX0 MUX' AIF1_PB
	# Weird crashes when setting mixer settings. Sleeping helps a bit.
	sleep 0.3
	amixer -c 0 cset name='WSA WSA RX1 MUX' AIF1_PB
	sleep 0.3
	amixer -c 0 cset name='WSA WSA_RX0 INP0' RX0
	sleep 0.1
	amixer -c 0 cset name='WSA WSA_RX1 INP0' RX1
	sleep 0.3
	amixer -c 0 cset name='WSA2 WSA RX0 MUX' AIF1_PB
	sleep 0.3
	amixer -c 0 cset name='WSA2 WSA RX1 MUX' AIF1_PB
	sleep 0.1
	amixer -c 0 cset name='WSA2 WSA_RX0 INP0' RX0
	sleep 0.1
	amixer -c 0 cset name='WSA2 WSA_RX1 INP0' RX1
	sleep 0.1
	amixer -c 0 cset name='WSA WSA_COMP1 Switch' 1
	sleep 0.1
	amixer -c 0 cset name='WSA WSA_COMP2 Switch' 1
	sleep 0.1
	amixer -c 0 cset name='WSA2 WSA_COMP1 Switch' 1
	sleep 0.1
	amixer -c 0 cset name='WSA2 WSA_COMP2 Switch' 1
	sleep 0.1
	amixer -c 0 cset name='WooferLeft WSA MODE' 0
	amixer -c 0 cset name='WooferLeft COMP Switch' 1
	amixer -c 0 cset name='WooferLeft PBR Switch' 1
	amixer -c 0 cset name='WooferLeft BOOST Switch' 1
	amixer -c 0 cset name='WooferLeft DAC Switch' 1
	amixer -c 0 cset name='WooferLeft VISENSE Switch' 0
	amixer -c 0 cset name='TwitterLeft WSA MODE' 0
	amixer -c 0 cset name='TwitterLeft COMP Switch' 1
	amixer -c 0 cset name='TwitterLeft PBR Switch' 1
	amixer -c 0 cset name='TwitterLeft BOOST Switch' 1
	amixer -c 0 cset name='TwitterLeft DAC Switch' 1
	amixer -c 0 cset name='TwitterLeft VISENSE Switch' 0
	amixer -c 0 cset name='WooferLeft PA Volume' 20
	amixer -c 0 cset name='TwitterLeft PA Volume' 20
	amixer -c 0 cset name='WooferRight WSA MODE' 0
	amixer -c 0 cset name='WooferRight COMP Switch' 1
	amixer -c 0 cset name='WooferRight PBR Switch' 1
	amixer -c 0 cset name='WooferRight BOOST Switch' 1
	amixer -c 0 cset name='WooferRight DAC Switch' 1
	amixer -c 0 cset name='WooferRight VISENSE Switch' 0
	amixer -c 0 cset name='TwitterRight WSA MODE' 0
	amixer -c 0 cset name='TwitterRight COMP Switch' 1
	amixer -c 0 cset name='TwitterRight PBR Switch' 1
	amixer -c 0 cset name='TwitterRight BOOST Switch' 1
	amixer -c 0 cset name='TwitterRight DAC Switch' 1
	amixer -c 0 cset name='TwitterRight VISENSE Switch' 0
	amixer -c 0 cset name='WooferRight PA Volume' 20
	amixer -c 0 cset name='TwitterRight PA Volume' 20
	amixer -c 0 cset name='WSA WSA_RX0 Digital Volume' 84
	amixer -c 0 cset name='WSA WSA_RX1 Digital Volume' 84
	amixer -c 0 cset name='WSA2 WSA_RX0 Digital Volume' 84
	amixer -c 0 cset name='WSA2 WSA_RX1 Digital Volume' 84
	amixer -c 0 cset name='WSA_CODEC_DMA_RX_0 Audio Mixer MultiMedia2' 1
}

speakers_off() {
	amixer -c 0 cset name="WSA WSA RX0 MUX" ZERO
	amixer -c 0 cset name="WSA WSA RX1 MUX" ZERO
	amixer -c 0 cset name='WSA WSA_COMP1 Switch' 0
	amixer -c 0 cset name='WSA WSA_COMP2 Switch' 0
	amixer -c 0 cset name="WSA WSA_RX0 INP0" ZERO
	amixer -c 0 cset name="WSA WSA_RX1 INP0" ZERO
	amixer -c 0 cset name="WSA2 WSA RX0 MUX" ZERO
	amixer -c 0 cset name="WSA2 WSA RX1 MUX" ZERO
	amixer -c 0 cset name='WSA2 WSA_COMP1 Switch' 0
	amixer -c 0 cset name='WSA2 WSA_COMP2 Switch' 0
	amixer -c 0 cset name="WSA2 WSA_RX0 INP0" ZERO
	amixer -c 0 cset name="WSA2 WSA_RX1 INP0" ZERO
	amixer -c 0 cset name='WooferLeft COMP Switch' 0
	amixer -c 0 cset name='WooferLeft PBR Switch' 0
	amixer -c 0 cset name='WooferLeft BOOST Switch' 0
	amixer -c 0 cset name='WooferLeft DAC Switch' 0
	amixer -c 0 cset name='WooferLeft VISENSE Switch' 0
	amixer -c 0 cset name='TwitterLeft COMP Switch' 0
	amixer -c 0 cset name='TwitterLeft PBR Switch' 0
	amixer -c 0 cset name='TwitterLeft BOOST Switch' 0
	amixer -c 0 cset name='TwitterLeft DAC Switch' 0
	amixer -c 0 cset name='TwitterLeft VISENSE Switch' 0
	amixer -c 0 cset name='WooferRight COMP Switch' 0
	amixer -c 0 cset name='WooferRight PBR Switch' 0
	amixer -c 0 cset name='WooferRight BOOST Switch' 0
	amixer -c 0 cset name='WooferRight DAC Switch' 0
	amixer -c 0 cset name='WooferRight VISENSE Switch' 0
	amixer -c 0 cset name='TwitterRight COMP Switch' 0
	amixer -c 0 cset name='TwitterRight PBR Switch' 0
	amixer -c 0 cset name='TwitterRight BOOST Switch' 0
	amixer -c 0 cset name='TwitterRight DAC Switch' 0
	amixer -c 0 cset name='TwitterRight VISENSE Switch' 0
}

headset_on() {
	amixer -c 0 cset name='RX_RX0 Digital Volume' 65
	amixer -c 0 cset name='RX_RX1 Digital Volume' 65
	amixer -c 0 cset name='HPHR Volume' 20
	amixer -c 0 cset name='HPHL Volume' 20
	amixer -c 0 cset name='RX_HPH PWR Mode' LOHIFI
	amixer -c 0 cset name='RX HPH Mode' CLS_H_ULP
	amixer -c 0 cset name='RX_MACRO RX0 MUX' AIF1_PB
	amixer -c 0 cset name='RX_MACRO RX1 MUX' AIF1_PB
	amixer -c 0 cset name='RX INT0_1 MIX1 INP0' RX0
	amixer -c 0 cset name='RX INT1_1 MIX1 INP0' RX1
	amixer -c 0 cset name='RX INT0 DEM MUX' CLSH_DSM_OUT
	amixer -c 0 cset name='RX INT1 DEM MUX' CLSH_DSM_OUT
	amixer -c 0 cset name='RX_COMP1 Switch' 1
	amixer -c 0 cset name='RX_COMP2 Switch' 1
	amixer -c 0 cset name='HPHL_RDAC Switch' 1
	amixer -c 0 cset name='HPHR_RDAC Switch' 1
	amixer -c 0 cset name='HPHL Switch' 1
	amixer -c 0 cset name='HPHR Switch' 1
	amixer -c 0 cset name='CLSH Switch' 1
	amixer -c 0 cset name='LO Switch' 1
	amixer -c 0 cset name='RX_CODEC_DMA_RX_0 Audio Mixer MultiMedia1' 1
	# Must stay off:
	amixer -c 0 cset name='HPHL_COMP Switch' 0
	amixer -c 0 cset name='HPHR_COMP Switch' 0
}

headset_off() {
	amixer -c 0 cset name='RX_MACRO RX0 MUX' ZERO
	amixer -c 0 cset name='RX_MACRO RX1 MUX' ZERO
	amixer -c 0 cset name='RX INT0_1 MIX1 INP0' ZERO
	amixer -c 0 cset name='RX INT1_1 MIX1 INP0' ZERO
	amixer -c 0 cset name='RX INT0 DEM MUX' NORMAL_DSM_OUT
	amixer -c 0 cset name='RX INT1 DEM MUX' NORMAL_DSM_OUT
	amixer -c 0 cset name='RX_COMP1 Switch' 0
	amixer -c 0 cset name='RX_COMP2 Switch' 0
	amixer -c 0 cset name='HPHL_RDAC Switch' 0
	amixer -c 0 cset name='HPHR_RDAC Switch' 0
	amixer -c 0 cset name='HPHL Switch' 0
	amixer -c 0 cset name='HPHR Switch' 0
}

HEADSET=0
SPEAKER=1
MIC=2
if ! [ -c /dev/snd/pcmC0D${HEADSET}p ]; then
	echo "Missing /dev/snd/pcmC0D${HEADSET}p"
	exit 1
fi

speakers_on
#aplay -D plughw:0,$SPEAKER /usr/share/sounds/alsa/Front_Center.wav
#aplay -D plughw:0,$SPEAKER /root/stereo.wav
#aplay -D plughw:0,$SPEAKER /root/4channels.wav
aplay -D plughw:0,$SPEAKER /root/4-side-channels.wav
speakers_off

headset_on
aplay -D plughw:0,$HEADSET /usr/share/sounds/alsa/Front_Center.wav
headset_off
