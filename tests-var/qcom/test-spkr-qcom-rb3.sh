#!/bin/sh
#
# Copyright (C) 2022 Linaro Ltd
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
amixer cset iface=MIXER,name='SLIM RX0 MUX' 'AIF1_PB'
amixer cset iface=MIXER,name='SLIM RX0 MUX' 'ZERO'
amixer cset iface=MIXER,name='SLIM RX1 MUX' 'ZERO'
amixer cset iface=MIXER,name='SLIM RX2 MUX' 'ZERO'
amixer cset iface=MIXER,name='SLIM RX3 MUX' 'ZERO'
amixer cset iface=MIXER,name='SLIM RX4 MUX' 'ZERO'
amixer cset iface=MIXER,name='SLIM RX5 MUX' 'ZERO'
amixer cset iface=MIXER,name='SLIM RX6 MUX' 'AIF1_PB'
amixer cset iface=MIXER,name='SLIM RX7 MUX' 'AIF1_PB'
amixer cset iface=MIXER,name='RX7 Digital Volume' 80
amixer cset iface=MIXER,name='RX8 Digital Volume' 80
amixer cset iface=MIXER,name='RX INT7_1 MIX1 INP0' 'RX6'
amixer cset iface=MIXER,name='RX INT8_1 MIX1 INP0' 'RX7'
amixer cset iface=MIXER,name='COMP7 Switch' 1
amixer cset iface=MIXER,name='COMP8 Switch' 1
#amixer cset iface=MIXER,name='SpkrRight PA Volume' 12
#amixer cset iface=MIXER,name='SpkrLeft PA Volume' 12
#amixer cset iface=MIXER,name='SpkrLeft PA Mute Switch' 0
#amixer cset iface=MIXER,name='SpkrRight PA Mute Switch' 0
amixer cset iface=MIXER,name='SpkrLeft COMP Switch' 1
amixer cset iface=MIXER,name='SpkrLeft BOOST Switch' 1
amixer cset iface=MIXER,name='SpkrLeft VISENSE Switch' 0
amixer cset iface=MIXER,name='SpkrLeft DAC Switch' 1
amixer cset iface=MIXER,name='SpkrRight COMP Switch' 1
amixer cset iface=MIXER,name='SpkrRight BOOST Switch' 1
amixer cset iface=MIXER,name='SpkrRight VISENSE Switch' 0
amixer cset iface=MIXER,name='SpkrRight DAC Switch' 1
amixer cset iface=MIXER,name='SLIMBUS_0_RX Audio Mixer MultiMedia1' 1
aplay /usr/share/sounds/alsa/Front*C*
