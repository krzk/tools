#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

die() {
	echo "Fail: $1"
	exit 1
}

test $# -gt 1 || die "Missing target name"

TARGET="$1"
NAME="$2"
TARGET_USER="buildbot"
SSH_TARGET="${TARGET_USER}@${TARGET}"
# Timeout for particular network commands: ping and ssh, in seconds
TIMEOUT=3
SERIAL=/dev/ttyUSB0
LOG_FILE=serial.log

ssh_works() {
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id &> /dev/null
}

run_tests() {
	local target=$1

	set -e -E
	ssh $SSH_TARGET sudo /opt/tools/tests/all-odroid-xu3.sh

	ssh_works
	set +e +E
}

echo "Collecting logs in background from ${TARGET}..."
stty -F $SERIAL 115200 cs8 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts
ts < $SERIAL > $LOG_FILE &
LOG_PID=$!

run_tests $TARGET

kill $LOG_PID &> /dev/null
kill -9 $LOG_PID &> /dev/null

exit $BOOT_STATUS
