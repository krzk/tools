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
	sleep 0.1
	amixer -c 0 cset name='WSA_RX0 Digital Volume' 85
	amixer -c 0 cset name='WSA_RX1 Digital Volume' 85
	sleep 0.1
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
	sleep 0.1
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
	sleep 0.1
	amixer -c 0 cset name='RX_CODEC_DMA_RX_0 Audio Mixer MultiMedia1' 1
	# Must stay off:
	sleep 0.1
	amixer -c 0 cset name='HPHL_COMP Switch' 0
	amixer -c 0 cset name='HPHR_COMP Switch' 0
	sleep 0.3
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

hdmi_on() {
	amixer -c 0 cset iface=MIXER,name='PRIMARY_MI2S_RX Audio Mixer MultiMedia1' 1
}

dmic0_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' MSM_DMIC
	amixer -c 0 cset name='TX DMIC MUX0' DMIC0
	# DEC1 must be set before DEC0 for the latter to be changeable
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	amixer -c 0 cset name='TX_DEC0 Volume' 85

	# TODO: amixer -c 0 cset name='TX SMIC MUX0' SWR_MIC0 needed?
	amixer -c 0 cset name='TX DEC1 MUX' MSM_DMIC
	#amixer -c 0 cset name='TX DMIC MUX0' DMIC2
	#amixer -c 0 cset name='TX DMIC MUX1' DMIC3

	amixer -c 0 cset name='TX DMIC MUX1' DMIC1
	#amixer -c 0 cset name='TX_DEC1 Volume' 85
	amixer -c 0 cset name='DMIC0 Switch' 1 # Not sure if needed
	#amixer -c 0 cset name='DMIC1 Switch' 1 # Not sure if needed
	#amixer -c 0 cset name='DMIC1_MIXER Switch' 1 # Not sure if needed
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
}

dmic0_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
	#amixer -c 0 cset name='TX DMIC MUX1' ZERO
	amixer -c 0 cset name='TX DEC0 MUX' ZERO
}

# Works:
amic1_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' SWR_MIC
	# SWR_MIC0 (so TX SWR_INPUT0) should match audio-route in DTS to ADC1 on WCD938x
	amixer -c 0 cset name='TX SMIC MUX0' SWR_MIC0
	# DEC1 must be set before DEC0 for the latter to be changeable
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	# TX0 matches ADC1
	amixer -c 0 cset name='TX0 MODE' ADC_NORMAL
	amixer -c 0 cset name='ADC1_MIXER Switch' 1
	amixer -c 0 cset name='HDR12 MUX' NO_HDR12
	# No ADC1 MUX
	amixer -c 0 cset name='ADC1 Switch' 1
	amixer -c 0 cset name='ADC1 Volume' 18
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
	# Not really needed
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
}

amic1_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC1_MIXER Switch' 0
	amixer -c 0 cset name='ADC1 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX0 MODE' ADC_INVALID
}

# Works:
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

# Works:
amic3_record_on() {
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
	amixer -c 0 cset name='ADC2 MUX' INP3
	amixer -c 0 cset name='ADC2 Switch' 1
	amixer -c 0 cset name='ADC2 Volume' 18
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
	# Not really needed
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
}

amic3_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC2_MIXER Switch' 0
	amixer -c 0 cset name='ADC2 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX1 MODE' ADC_INVALID
}

# Does not work
amic4_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' SWR_MIC
	# Should go to ADC3 on WCD938x (SWR_INPUT2)
	amixer -c 0 cset name='TX SMIC MUX0' SWR_MIC2
	# DEC1 must be set before DEC0 for the latter to be changeable
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	# TX2 matches ADC3
	amixer -c 0 cset name='TX2 MODE' ADC_NORMAL
	amixer -c 0 cset name='ADC3_MIXER Switch' 1
	amixer -c 0 cset name='HDR34 MUX' NO_HDR34
	amixer -c 0 cset name='ADC3 MUX' INP4
	amixer -c 0 cset name='ADC3 Switch' 1
	amixer -c 0 cset name='ADC3 Volume' 18
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
	# Not really needed
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
}

amic4_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC3_MIXER Switch' 0
	amixer -c 0 cset name='ADC3 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX2 MODE' ADC_INVALID
}

# Does not work
amic5_record_on() {
	amixer -c 0 cset name='TX DEC0 MUX' SWR_MIC
	# Should go to ADC4 on WCD938x (SWR_INPUT3)
	amixer -c 0 cset name='TX SMIC MUX0' SWR_MIC3
	# DEC1 must be set before DEC0 for the latter to be changeable
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 1
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 1
	# TX2 matches ADC3
	amixer -c 0 cset name='TX3 MODE' ADC_NORMAL
	amixer -c 0 cset name='ADC4_MIXER Switch' 1
	amixer -c 0 cset name='HDR34 MUX' NO_HDR34
	amixer -c 0 cset name='ADC4 MUX' INP5
	amixer -c 0 cset name='ADC4 Switch' 1
	amixer -c 0 cset name='ADC4 Volume' 18
	amixer -c 0 cset name='DEC0 MODE' ADC_DEFAULT
	amixer -c 0 cset name='TX_DEC0 Volume' 100
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 1
	# Not really needed
	amixer -c 0 cset name='TX DMIC MUX0' ZERO
}

amic5_record_off() {
	amixer -c 0 cset name='MultiMedia3 Mixer TX_CODEC_DMA_TX_3' 0
	amixer -c 0 cset name='ADC4_MIXER Switch' 0
	amixer -c 0 cset name='ADC4 Switch' 0
	amixer -c 0 cset name='TX SMIC MUX0' 'ZERO'
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC0' 0
	amixer -c 0 cset name='TX_AIF1_CAP Mixer DEC1' 0
	amixer -c 0 cset name='TX3 MODE' ADC_INVALID
}

# Pre HDMI - no hdmi-playback-dai-link
HEADSET=0
SPEAKER=1
MIC=2
if ! [ -c /dev/snd/pcmC0D${HEADSET}p ]; then
	echo "Missing /dev/snd/pcmC0D${HEADSET}p"
	exit 1
fi

speakers_on
aplay -D plughw:0,${SPEAKER} /usr/share/sounds/alsa/Front_Center.wav
aplay -D plughw:0,${SPEAKER} /home/linaro/stereo.wav
speakers_off

# Headset:
headset_on
aplay -D plughw:0,${HEADSET} /usr/share/sounds/alsa/Front_Center.wav
aplay -D plughw:0,${HEADSET} /home/linaro/stereo.wav
headset_off

# HDMI
#hdmi_on
#aplay -D plughw:0,8 /usr/share/sounds/alsa/Front_Center.wav

# Record:
echo "Recording for 5 seconds - amic1 (board)"
amic1_record_on
arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
amic1_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

echo "Recording for 5 seconds - headphones"
headset_record_on
arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
headset_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

amic3_record_on
arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
amic3_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

amic4_record_on
arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
amic4_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

amic5_record_on
arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_h.wav
amic5_record_off
speakers_on
aplay -D plughw:0,${SPEAKER} out_h.wav
speakers_off

#echo "Recording for 5 seconds - DMIC"
#dmic0_record_on
#arecord -D plughw:0,${MIC} -f S16_LE -c 1 -r 48000 -d 5 out_d.wav
#dmic0_record_off
#speakers_on
#aplay -D plughw:0,${SPEAKER} out_d.wav
#speakers_off
