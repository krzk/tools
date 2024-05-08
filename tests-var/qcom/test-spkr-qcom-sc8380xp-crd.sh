#!/bin/sh
#
# Copyright (C) 2023-2024 Linaro Ltd
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
	amixer -c 0 cset name='WooferLeft PA Volume' 10
	amixer -c 0 cset name='TwitterLeft PA Volume' 10
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
	amixer -c 0 cset name='WooferRight PA Volume' 10
	amixer -c 0 cset name='TwitterRight PA Volume' 10
	amixer -c 0 cset name='WSA WSA_RX0 Digital Volume' 70
	amixer -c 0 cset name='WSA WSA_RX1 Digital Volume' 70
	amixer -c 0 cset name='WSA2 WSA_RX0 Digital Volume' 70
	amixer -c 0 cset name='WSA2 WSA_RX1 Digital Volume' 70
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
	amixer -c 0 cset name='HPHR Volume' 15
	amixer -c 0 cset name='HPHL Volume' 15
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

# AMIC2, ??? does not work so far
headset_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' SWR_MIC
	# Should go to ADC2 on WCD938x (SWR_INPUT1)
	amixer -c 0 cset name='TX SMIC MUX0' SWR_MIC1
	# DEC1 must be set before DEC0 for the latter to be changeable
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	# TX1 matches ADC2
	amixer -c 0 cset name='TX1 MODE' ADC_NORMAL
	amixer -c 0 cset name='ADC2_MIXER Switch' 1
	amixer -c 0 cset name='HDR12 MUX' NO_HDR12
	amixer -c 0 cset name='ADC2 MUX' INP2
	amixer -c 0 cset name='ADC2 Switch' 1
	amixer -c 0 cset name='ADC2 Volume' 18
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
	# Not really needed
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
}

headset_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC2_MIXER Switch' 0
	amixer -c 0 cset name='ADC2 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX1 MODE' ADC_INVALID
}

# Works
dmic01_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100

	amixer -c 0 cset name='VA DEC1 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX1' DMIC1
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='VA_DEC1 Volume' 100
	
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

dmic01_va_record_off() {
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 0
	amixer -c 0 cset name='VA_DEC0 Volume' 0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='VA DMIC MUX0' ZERO

	amixer -c 0 cset name='VA_DEC1 Volume' 0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='VA DMIC MUX1' ZERO
}

# Works
dmic23_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC2
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100

	amixer -c 0 cset name='VA DEC1 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX1' DMIC3
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='VA_DEC1 Volume' 100
	
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

dmic23_va_record_off() {
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 0
	amixer -c 0 cset name='VA_DEC0 Volume' 0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='VA DMIC MUX0' ZERO

	amixer -c 0 cset name='VA_DEC1 Volume' 0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='VA DMIC MUX1' ZERO
}

# TODO:
dmic0123_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100

	amixer -c 0 cset name='VA DEC1 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX1' DMIC1
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='VA_DEC1 Volume' 100

	amixer -c 0 cset name='VA DEC2 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX2' DMIC2
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC2' 1
	amixer -c 0 cset name='VA_DEC2 Volume' 100

	amixer -c 0 cset name='VA DEC3 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX3' DMIC3
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC3' 1
	amixer -c 0 cset name='VA_DEC3 Volume' 100

	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

HEADSET=0
SPEAKER=1
MIC=2
DMIC=3
if ! [ -c /dev/snd/pcmC0D${HEADSET}p ]; then
	echo "Missing /dev/snd/pcmC0D${HEADSET}p"
	exit 1
fi

speakers_on
#aplay -D plughw:0,$SPEAKER /usr/share/sounds/alsa/Front_Center.wav
#aplay -D plughw:0,$SPEAKER ~/stereo.wav
#aplay -D plughw:0,$SPEAKER ~/4channels.wav
aplay -D plughw:0,$SPEAKER ~/4-side-channels.wav
speakers_off

headset_on
aplay -D plughw:0,$HEADSET ~/stereo.wav
headset_off

# Record:
headset_record_on
echo "Recording for 5 seconds - AMIC2/headphones"
arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
headset_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

dmic01_va_record_on
echo "Recording for 5 seconds - DMIC01"
arecord -D plughw:0,${DMIC} -f S16_LE -c 2 -r 48000 -d 5 out_h.wav
dmic01_va_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

dmic23_va_record_on
echo "Recording for 5 seconds - DMIC23"
arecord -D plughw:0,${DMIC} -f S16_LE -c 2 -r 48000 -d 5 out_h.wav
dmic23_va_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off
