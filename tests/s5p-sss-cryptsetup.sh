#!/bin/bash
#
# Copyright (c) 2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

set -e -E -x
. $(dirname ${BASH_SOURCE[0]})/inc-common.sh

LOOPS=1
if [ "$1" == "--intensive" ]; then
	LOOPS=20
fi
CRYPT_MODE_CBC="--cipher=aes-cbc-essiv:sha256 --hash=sha256"
CRYPT_MODE_XTS="--cipher=aes-xts-plain64:sha512 --hash=sha512"
TEST_DATA_SIZE="32M"
# Size of crypt device should be at least TEST_DATA_SIZE+LUKS headers
CRYTP_DEV_SIZE="34M"

s5p_sss_cryptsetup_cleanup() {
	print_msg "Exit trap, cleaning up..."
	s5p_sss_cryptsetup_unprepare $dev
	trap - EXIT
}

# s5p_sss_cryptsetup_prepare <dev_name> <mode (as cryptsetup argument list)> [luksformat]
s5p_sss_cryptsetup_prepare() {
	local name="s5p-sss cryptsetup"
	local dev="$1"
	local mode="$2"
	local luks="$3"

	local status="$(cryptsetup status $dev | head -n 1)"
	if [ "$status" != "/dev/mapper/testcrypt is inactive." ]; then
		print_msg "ERROR: Crypt device $dev is being used"
		return 1
	fi

	test -f /tmp/${dev} && { print_msg "ERROR: /tmp/${dev} already exists"; return 1 ; }
	test -f /tmp/${dev}-keyfile && { print_msg "ERROR: /tmp/${dev}-keyfile already exists"; return 1 ; }

	dd if=/dev/zero of=/tmp/${dev} bs=${CRYTP_DEV_SIZE} count=0 seek=1 status=none

	if [ "$luks" != "" ]; then
		dd if=/dev/urandom of=/tmp/${dev}-keyfile bs=1 count=32
		cryptsetup -v -q $mode \
			--key-file=/tmp/${dev}-keyfile --master-key-file=/tmp/${dev}-keyfile \
			--keyfile-size=32 --key-size=256 \
			luksFormat /tmp/${dev}
		local status=`file /tmp/${dev} | grep -c "/tmp/${dev}: LUKS encrypted file, ver 1"`
		if [ "$status" != "1" ]; then
			print_msg "ERROR: Crypt device $dev not detected as LUKS"
			return 1
		fi
		cryptsetup -v -q $mode \
			--key-file=/tmp/${dev}-keyfile --master-key-file=/tmp/${dev}-keyfile \
			--keyfile-size=32 --key-size=256 --type luks \
			open /tmp/${dev} $dev
	else
		cryptsetup -v -q $mode \
			--key-file=/dev/urandom --master-key-file=/dev/urandom \
			--keyfile-size=32 --key-size=256 --type plain \
			open /tmp/${dev} $dev
	fi
	cryptsetup status $dev
	local detected_type="$(cryptsetup status $dev | grep 'type:')"
	local expected_type="  type:    PLAIN"
	if [ "$luks" != "" ]; then
		local expected_type="  type:    LUKS1"
	fi
	if [ "$detected_type" != "$expected_type" ]; then
		# FIXME: cleanup in trap hook?
		s5p_sss_cryptsetup_unprepare $dev
		print_msg "ERROR: Wrong type of crypt device (\"$detected_type\" != \"$expected_type\")"
		return 1
	fi

	return 0
}

s5p_sss_cryptsetup_unprepare() {
	local name="s5p-sss cryptsetup"
	local dev="$1"

	# Need to echo so shell will not exit if cleanup command fails
	cryptsetup close $dev || print_msg "Closing $dev failed"

	rm -f /tmp/${dev} /tmp/${dev}-keyfile
}

s5p_sss_cryptsetup_run() {
	local name="s5p-sss cryptsetup"
	local dev="$1"

	for i in `seq 0 50`; do
		echo "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890" \
			| dd of=/dev/mapper/${dev} bs=1 seek=$((expr $i * 160)) status=none
	done
	sync && sync && sync

	dd if=/dev/mapper/${dev} of=/dev/null bs=${TEST_DATA_SIZE} count=1
	sync && sync && sync

	dd if=/dev/zero of=/dev/mapper/${dev} bs=${TEST_DATA_SIZE} count=1
	sync && sync && sync

	dd if=/dev/mapper/${dev} of=/dev/null bs=${TEST_DATA_SIZE} count=1
	sync && sync && sync
}

test_s5p_sss_cryptsetup() {
	local name="s5p-sss cryptsetup"
	local dev="testcrypt"
	print_msg "Testing..."

	s5p_sss_cryptsetup_prepare $dev "$CRYPT_MODE_CBC"
	for i in `seq 1 $LOOPS`; do
		test $LOOPS -gt 1 && print_msg "Test ${i}/${LOOPS}"
		s5p_sss_cryptsetup_run $dev
	done
	s5p_sss_cryptsetup_unprepare $dev

	s5p_sss_cryptsetup_prepare $dev "$CRYPT_MODE_XTS"
	for i in `seq 1 $LOOPS`; do
		test $LOOPS -gt 1 && print_msg "Test ${i}/${LOOPS}"
		s5p_sss_cryptsetup_run $dev
	done
	s5p_sss_cryptsetup_unprepare $dev

	s5p_sss_cryptsetup_prepare $dev "$CRYPT_MODE_CBC" yes
	for i in `seq 1 $LOOPS`; do
		test $LOOPS -gt 1 && print_msg "Test ${i}/${LOOPS}"
		s5p_sss_cryptsetup_run $dev
	done
	s5p_sss_cryptsetup_unprepare $dev

	s5p_sss_cryptsetup_prepare $dev "$CRYPT_MODE_XTS" yes
	for i in `seq 1 $LOOPS`; do
		test $LOOPS -gt 1 && print_msg "Test ${i}/${LOOPS}"
		s5p_sss_cryptsetup_run $dev
	done
	s5p_sss_cryptsetup_unprepare $dev

	print_msg "OK"
}

trap "s5p_sss_cryptsetup_cleanup" EXIT
test_s5p_sss_cryptsetup
trap - EXIT
