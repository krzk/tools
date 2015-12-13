#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
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

test $# -eq 1 || die "Missing target name"

TARGET="$1"
TARGET_USER="buildbot"
SSH_TARGET="${TARGET_USER}@${TARGET}"
# Timeout for particular network commands: ping and ssh, in seconds
TIMEOUT=3
# Number of retries (each with TIMEOUT) for ssh connection
SSH_WAIT_FOR_BOOT_TRIES=50
SERIAL=/dev/ttyUSB0
LOG_FILE=serial.log

# wait_for_ping_die target
wait_for_ping_die() {
	local target=$1
	local i=0
	local tries=1000

	ping -c 1 -W $TIMEOUT $target > /dev/null

	if [ $? -eq 1 ]; then
		echo "Target $target died very fast"
		return 0
	fi

	while [ $i -lt $tries ]; do
		ping -c 1 -W $TIMEOUT $target > /dev/null
		if [ $? -ne 0 ]; then
			echo "Target $target dead after $i pings"
			break
		fi
		i=$(expr $i + 1)
	done

	test $i -lt $tries || echo "Target $target did not die properly"

	return 0
}

reboot_target() {
	local target=$1

	echo "Checking if target $target is alive..."
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id > /dev/null
	if [ $? -eq 0 ]; then
		echo "Target $target alive, powering down..."
		ssh $SSH_TARGET sudo poweroff &> /dev/null
		wait_for_ping_die $target
	fi

	sudo gpio-pi.py restart
}

ssh_get_diag() {
	echo "####################################"
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET uname -a || return $?
	echo "####################################"
	echo "Dmesg err:"
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET dmesg -l err
	echo "####################################"
	echo "Dmesg warn:"
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET dmesg -l warn
	echo "####################################"
}

ssh_works() {
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id &> /dev/null
}

wait_for_boot() {
	local target=$1
	local i=0

	while [ $i -lt $SSH_WAIT_FOR_BOOT_TRIES ]; do
		ssh_works
		if [ $? -eq 0 ]; then
			echo "Target $target booted!"
			ssh_get_diag
			return $?
		fi
		i=$(expr $i + 1)
	done

	test $i -lt $SSH_WAIT_FOR_BOOT_TRIES

	return $?
}

run_tests() {
	local target=$1

	set -e -E
	ssh $SSH_TARGET sudo /opt/tools/tests/all-odroid-xu3.sh

	ssh_works
	set +e +E
}

echo "Rebooting target ${TARGET}..."
reboot_target $TARGET

echo "Collecting logs in background from ${TARGET}..."
stty -F $SERIAL 115200 cs8 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts
ts < $SERIAL > $LOG_FILE &
LOG_PID=$!

echo "Wait for boot of ${TARGET}..."
wait_for_boot $TARGET
BOOT_STATUS=$?

echo "Target $TARGET boot: $BOOT_STATUS"
if [ $BOOT_STATUS -ne 0 ]; then
	# Target could be stuck in boot spinning in a stupid way with fan
	# on high speed. It is unresponsive so useless. Power it off
	# to save the power.
	echo "Target $TARGET failed to boot, power it off"
	sudo gpio-pi.py off
else
	run_tests $TARGET
fi

kill $LOG_PID &> /dev/null
kill -9 $LOG_PID &> /dev/null

exit $BOOT_STATUS
