#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>

tmp=$(mktemp /tmp/msmtp-mail.XXXXXX)

cat > "$tmp"
(
	msg=$(msmtp "$@" <"$tmp" 2>&1)
	rc=$?
	if [ $rc -ne 0 ]; then
		# Use text-info instead of --error --text: the latter parses Pango
		# markup (msmtp errors contain <addresses> which break it) and does
		# not scroll, so long multi-line output gets lost.
		printf 'Mail saved in: %s\n\n%s\n' "$tmp" "$msg" | zenity --text-info \
			--title "msmtp failed (exit code $rc)" \
			--width 800 --height 400
	else
		rm "$tmp"
	fi
) &

exit 0
