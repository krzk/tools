#!/bin/sh
#
# Copyright (C) 2022 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x

speakers_on() {
	amixer -c 0 cset name='SpkrLeft PA Volume' 20
	amixer -c 0 cset name='SpkrRight PA Volume' 20
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
	amixer -c 0 cset name='SpkrLeft VISENSE Switch' 1
	amixer -c 0 cset name='SpkrRight COMP Switch' 1
	amixer -c 0 cset name='SpkrRight BOOST Switch' 1
	amixer -c 0 cset name='SpkrRight DAC Switch' 1
	amixer -c 0 cset name='SpkrRight VISENSE Switch' 1
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
	amixer -c 0 cset name='SpkrLeft COMP Switch' 0
	amixer -c 0 cset name='SpkrLeft VISENSE Switch' 0
	amixer -c 0 cset name='SpkrLeft DAC Switch' 0
	amixer -c 0 cset name='SpkrRight COMP Switch' 0
	amixer -c 0 cset name='SpkrRight VISENSE Switch' 0
	amixer -c 0 cset name='SpkrRight DAC Switch' 0
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
}

dmic0_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' MSM_DMIC
	#amixer -c 0 cset name='TX DEC1 MUX' MSM_DMIC
	amixer -c 0 cset name='TX DMIC MUX0' DMIC2
	amixer -c 0 cset name='TX DMIC MUX1' DMIC3
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='TX_DEC1 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
}

dmic0_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
	amixer -c 0 cset name='TX DEC0 MUX' ZERO
}

headset_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' SWR_MIC
	amixer -c 0 cset name='TX SMIC MUX0' ADC1 # or 2?
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='TX1 MODE' ADC_NORMAL
	amixer -c 0 cset name='ADC2_MIXER Switch' 1
	amixer -c 0 cset name='HDR12 MUX' NO_HDR12
	amixer -c 0 cset name='ADC2 MUX' INP2
	amixer -c 0 cset name='ADC2 Switch' 1
	amixer -c 0 cset name='ADC2 Volume' 12
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
}

headset_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC2_MIXER Switch' 0
	amixer -c 0 cset name='ADC2 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX1 MODE' ADC_INVALID
}

speakers_on
aplay -D plughw:0,5 /usr/share/sounds/alsa/Front_Center.wav
#speakers_off

# Headset:
headset_on
aplay -D plughw:0,4 /usr/share/sounds/alsa/Front_Center.wav

# Record:
echo "Recording for 5 seconds - DMIC"
dmic0_record_on
arecord -D plughw:0,6 -f S16_LE -c 1 -r 48000 -d 5 out.waw
dmic0_record_off
aplay -D plughw:0,5 out.waw

headset_record_on
arecord -D plughw:0,6 -f S16_LE -c 1 -r 48000 -d 5 out.waw
headset_record_off
aplay -D plughw:0,5 out.waw
