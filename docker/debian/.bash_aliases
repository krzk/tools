#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>
#

alias '%'=sudo
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias df='df -h'

which vi > /dev/null 2>&1 || alias vi=/usr/bin/vim
export EDITOR=vim
export HISTSIZE=10000
export HISTFILESIZE=20000

if [ -f ~/.bash_aliases_linux ]; then
	. ~/.bash_aliases_linux
fi
