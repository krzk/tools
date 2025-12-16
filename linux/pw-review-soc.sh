#!/bin/bash
#
# Copyright 2018 Rob Herring <robh@kernel.org>
# Copyright (c) 2025 Krzysztof Kozlowski <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

: ${PW_PROJECT:="$(git config --get b4.pw-project)"}
PW_REVIEW_PATH="$HOME/pw-review/$PW_PROJECT"
LORE_MBOX_PATH="$PW_REVIEW_PATH/mbox"

GREEN='\033[1;32m'
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

die() {
	echo "Fail: $1"
	exit 1
}

get_patch_pw_id() {
	IFS=' '
	(cut -d' ' -f1 | xargs) <<< "$*"
}

get_patch_msgid() {
	sed -n -e 's/.* <\([^ ]*\)> ".*/\1/p' <<< "$*"
}

[ -n "$PW_PROJECT" ] || die "Missing PW_PROJECT"
[ ! -d "$LORE_MBOX_PATH" ] && mkdir -p "$LORE_MBOX_PATH"

pw_update_state() {
	local id
	# parameters: <state> <ids>
	pw_state="$1"
	local ids="$2"
	IFS=' '

	[ -z "$ids" ] && return

	pwclient update -s "$pw_state" $ids
}

prompt_for_okay() {
	local temp
	echo -n "$1 [y/N]?"
	read -n 1 temp
	echo ""
	[ "$temp" = "y" ]
}

open_mail_msg() {
	local msgid=$1
	mbox=${LORE_MBOX_PATH}/$(sed -e 's/[=/]/_/g' <<< "${msgid}").mbx
	b4 mbox -o "${LORE_MBOX_PATH}" "$msgid" 2> /dev/null

	# mutt doesn't handle these correctly
	sed -i -e '/^To:\sunlisted-recipients.*/d' "${mbox}"

	# Escape msg-id
	local mutt_msgid=$(sed -e 's/\+/\\\\\+/g' -e 's/=/\\=/g' -e 's/\%/\\\%/g' -e 's/\~/\\\~/g' -e 's/{/\\\\{/g' -e 's/}/\\\\}/g' <<< "$msgid")
	mutt -f "${mbox}" -e "push <search>~i\ '${mutt_msgid}'<enter><enter>"
}

process_patch() {
	local id="$*"
	local pw_id=$(get_patch_pw_id "$id")

	echo -e "${BLUE}$id${NC}"

	again=""; pw_state=""
	while [ -z "$again" -a -z "$pw_state" ]; do
		again=""; pw_state=""

		msgid=$(get_patch_msgid "$id")

		[ -z "$again" ] && open_mail_msg "$msgid"

		echo -ne "[E]dit again\n" \
			 "Next [P]atch\n" \
			 "Set patch state to:\n" \
			 "[C]hanges Requested/[U]nder Review/[A]ccepted/[N]ot Applicable/[S]uperseded/[R]ejected/R[F]C\n" \
			 "[G]-quit or <enter> key to skip state change: "
		read -n 1 state
		echo ""
		case "$state" in
		e|E)
			;;
		c|C)
			pw_state="Changes Requested" # Requested
			;;
		u|U)
			pw_state="Under Review" # Review
			;;
		a|A)
			pw_state="Accepted"
			;;
		n|N)
			pw_state="Not Applicable"
			again="no"
			;;
		s|S)
			pw_state="Superseded"
			;;
		r|R)
			pw_state="Rejected"
			;;
		F|f)
			pw_state="RFC"
			;;
		g|G)
			prompt_for_okay "Are you sure" && exit 1
			;;
		p|P)
			again="no"
			;;

		*)
			;;
		esac

		if [ -n "${pw_state}" ]; then
			wait
			(pw_update_state "${pw_state}" "${pw_id}") &
		fi
	done
}

process_patches() {
	local ids="$*"
	local IFS=$'\n'

	for id in $ids; do
		process_patch $id
	done
}

PATCHES="$(pwclient list -p "$PW_PROJECT" -s new -f '%{id} %{msgid} "%{name}"')"
process_patches "$PATCHES"
