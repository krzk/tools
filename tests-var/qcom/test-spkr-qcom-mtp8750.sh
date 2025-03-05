#!/bin/sh
#
# Copyright (C) 2022-2024 Linaro Ltd
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
	amixer -c 0 cset name='SpkrLeft COMP Switch' 1
	amixer -c 0 cset name='SpkrLeft BOOST Switch' 1
	amixer -c 0 cset name='SpkrLeft DAC Switch' 1
	amixer -c 0 cset name='SpkrLeft VISENSE Switch' 0
	amixer -c 0 cset name='SpkrRight WSA MODE' 0
	amixer -c 0 cset name='SpkrRight COMP Switch' 1
	amixer -c 0 cset name='SpkrRight BOOST Switch' 1
	amixer -c 0 cset name='SpkrRight DAC Switch' 1
	amixer -c 0 cset name='SpkrRight VISENSE Switch' 0
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
	amixer -c 0 cset name='SpkrLeft BOOST Switch' 0
	amixer -c 0 cset name='SpkrLeft DAC Switch' 0
	amixer -c 0 cset name='SpkrLeft VISENSE Switch' 0
	amixer -c 0 cset name='SpkrRight COMP Switch' 0
	amixer -c 0 cset name='SpkrRight BOOST Switch' 0
	amixer -c 0 cset name='SpkrRight DAC Switch' 0
	amixer -c 0 cset name='SpkrRight VISENSE Switch' 0
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
	amixer -c 0 cset name='HPHR_COMP Switch' 1
	amixer -c 0 cset name='HPHL_COMP Switch' 1
	amixer -c 0 cset name='HPHL Switch' 1
	amixer -c 0 cset name='HPHR Switch' 1
	amixer -c 0 cset name='CLSH Switch' 1
	amixer -c 0 cset name='RX_CODEC_DMA_RX_0 Audio Mixer MultiMedia1' 1
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

dmic0_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

dmic1_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC1
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

dmic2_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC2
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

dmic3_va_record_on() {
	amixer -c 0 cset name='VA DEC0 MUX' VA_DMIC
	amixer -c 0 cset name='VA DMIC MUX0' DMIC3
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='VA_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 1
}

dmic_va_record_off() {
	amixer -c 0 cset name='MultiMedia4 Mixer VA_CODEC_DMA_TX_0' 0
	amixer -c 0 cset name='VA_DEC0 Volume' 0
	amixer -c 0 cset name='VA_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='VA DMIC MUX0' ZERO
}

# Does not work - missing DTS for USB switch ports?
headset_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' SWR_MIC
	# Should go to ADC2 on WCD93xx (SWR_INPUT1)
	amixer -c 0 cset name='TX SMIC MUX0' SWR_MIC1
	# DEC1 must be set before DEC0 for the latter to be changeable
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='ADC2_MIXER Switch' 1
	amixer -c 0 cset name='ADC2 MUX' CH2_AMIC2
	amixer -c 0 cset name='ADC2 Switch' 1
	amixer -c 0 cset name='ADC2 Volume' 18
	# TX1 matches ADC2
	amixer -c 0 cset name='TX1 MODE' ADC_LP
	amixer -c 0 cset name='MBHC Switch' 1
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
	# Not really needed
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
}

headset_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC2_MIXER Switch' 0
	amixer -c 0 cset name='ADC2 MUX' CH2_AMIC_DISABLE
	amixer -c 0 cset name='ADC2 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX1 MODE' ADC_INVALID
}

visense_testing_on() {
	amixer -c 0 cset name='SpkrLeft PA Volume' 20
	amixer -c 0 cset name='SpkrRight PA Volume' 20
	amixer -c 0 cset name='WSA RX0 MUX' AIF1_PB
	amixer -c 0 cset name='WSA RX1 MUX' AIF1_PB
	amixer -c 0 cset name='WSA_RX0 INP0' RX0
	amixer -c 0 cset name='WSA_RX1 INP0' RX1
	amixer -c 0 cset name='WSA_COMP1 Switch' 1
	amixer -c 0 cset name='WSA_COMP2 Switch' 1
	amixer -c 0 cset name='SpkrLeft WSA MODE' 0
	amixer -c 0 cset name='SpkrLeft COMP Switch' 1
	amixer -c 0 cset name='SpkrLeft BOOST Switch' 1
	amixer -c 0 cset name='SpkrLeft DAC Switch' 1
	amixer -c 0 cset name='SpkrRight WSA MODE' 0
	amixer -c 0 cset name='SpkrRight COMP Switch' 1
	amixer -c 0 cset name='SpkrRight BOOST Switch' 1
	amixer -c 0 cset name='SpkrRight DAC Switch' 1
	amixer -c 0 cset name='WSA_RX0 Digital Volume' 85
	amixer -c 0 cset name='WSA_RX1 Digital Volume' 85

	amixer -c 0 cset name='WSA_AIF_VI Mixer WSA_SPKR_VI_1' 1
	amixer -c 0 cset name='WSA_AIF_VI Mixer WSA_SPKR_VI_2' 1
	amixer -c 0 cset name='SpkrLeft VISENSE Switch' 1
	amixer -c 0 cset name='SpkrRight VISENSE Switch' 1

	amixer -c 0 cset name='WSA_CODEC_DMA_RX_0 Audio Mixer MultiMedia2' 1
	amixer -c 0 cset name='MultiMedia3 Mixer WSA_CODEC_DMA_TX_0' 1
	( arecord -D plughw:0,2 -f S16_LE -c 2 -r 48000 -d 5 out_h.wav & ) ; aplay -D plughw:0,1 ~/samples/stereo.wav
}

visense_testing_off() {
	amixer -c 0 cset name='WSA RX0 MUX' ZERO
	amixer -c 0 cset name='WSA RX1 MUX' ZERO
	amixer -c 0 cset name='WSA_RX0 INP0' ZERO
	amixer -c 0 cset name='WSA_RX1 INP0' ZERO
	amixer -c 0 cset name='WSA_COMP1 Switch' 0
	amixer -c 0 cset name='WSA_COMP2 Switch' 0
	amixer -c 0 cset name='SpkrLeft COMP Switch' 0
	amixer -c 0 cset name='SpkrLeft BOOST Switch' 0
	amixer -c 0 cset name='SpkrLeft DAC Switch' 0
	amixer -c 0 cset name='SpkrRight COMP Switch' 0
	amixer -c 0 cset name='SpkrRight BOOST Switch' 0
	amixer -c 0 cset name='SpkrRight DAC Switch' 0

	amixer -c 0 cset name='WSA_AIF_VI Mixer WSA_SPKR_VI_1' 0
	amixer -c 0 cset name='WSA_AIF_VI Mixer WSA_SPKR_VI_2' 0
	amixer -c 0 cset name='SpkrLeft VISENSE Switch' 0
	amixer -c 0 cset name='SpkrRight VISENSE Switch' 0
}

# headset=0, speaker=1, mic=2
if ! [ -c /dev/snd/pcmC0D0p ]; then
	echo "Missing /dev/snd/pcmC0D0p"
	exit 1
fi

speakers_on
aplay -D plughw:0,1 /usr/share/sounds/alsa/Front_Center.wav
speakers_off

headset_on
aplay -D plughw:0,0 /usr/share/sounds/alsa/Front_Center.wav
headset_off

headset_record_on
echo "Recording for 5 seconds - AMIC2/headphones"
arecord -D plughw:0,2 -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
headset_record_off
speakers_on
aplay -D plughw:0,1 out_h.wav
speakers_off

dmic0_va_record_on
echo "Recording for 5 seconds - DMIC0"
arecord -D plughw:0,3 -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
dmic_va_record_off
speakers_on
aplay -D plughw:0,1 out_h.wav
speakers_off

dmic1_va_record_on
echo "Recording for 5 seconds - DMIC1"
arecord -D plughw:0,3 -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
dmic_va_record_off
speakers_on
aplay -D plughw:0,1 out_h.wav
speakers_off

dmic2_va_record_on
echo "Recording for 5 seconds - DMIC2"
arecord -D plughw:0,3 -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
dmic_va_record_off
speakers_on
aplay -D plughw:0,1 out_h.wav
speakers_off

dmic3_va_record_on
echo "Recording for 5 seconds - DMIC3"
arecord -D plughw:0,3 -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
dmic_va_record_off
speakers_on
aplay -D plughw:0,1 out_h.wav
speakers_off
