#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>
#
# Start tracking a patch series with 'b4 review track', choosing the project
# identifier interactively with fzf.  The message is read from stdin and
# passed unmodified to b4.
#
# Usage: mutt-b4-review.sh < message
#   mutt: macro index 8 "<pipe-message>~/bin/mutt-b4-review.sh<return>"

set -euo pipefail

readonly PROJECTS=(
	"dt"
	"mem-ctrl"
	"pinctrl"
	"review-dt"
	"samsung-soc"
	"w1"
)

# Drain stdin so the writer (mutt) does not get EPIPE when we bail out early
drain_exit() {
	cat >/dev/null || true
	exit "$1"
}

die() {
	echo "$(basename "$0"): $*" >&2
	drain_exit 1
}

if [ -t 0 ]; then
	echo "$(basename "$0"): expecting the message on stdin, not a terminal" >&2
	exit 1
fi

if [ $# -ne 0 ]; then
	die "usage: $(basename "$0") < message"
fi

command -v fzf >/dev/null || die "fzf not found"
command -v b4 >/dev/null || die "b4 not found"

# Do not let environment inject fzf options (e.g. --bind with execute())
unset FZF_DEFAULT_OPTS FZF_DEFAULT_OPTS_FILE FZF_DEFAULT_COMMAND

# fzf reads the list from the pipe below and keys from /dev/tty, so the
# message on our stdin stays untouched for b4.
# fzf exits non-zero on Esc/Ctrl-C or no match - treat as cancel.
choice=$(printf '%s\n' "${PROJECTS[@]}" \
	| fzf --no-multi --prompt='b4 review track -i ' \
		--height=40% --reverse) || drain_exit 0

# Accept only an exact entry from the list, never free-form text
valid=0
for p in "${PROJECTS[@]}"; do
	if [ "$choice" = "$p" ]; then
		valid=1
		break
	fi
done
[ "$valid" -eq 1 ] || die "invalid project choice: ${choice@Q}"

# b4 inherits our stdin and reads the message from it
exec b4 review track -i "$choice"
