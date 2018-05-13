#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

test $# -gt 1 || die "Missing target name"

TARGET="$1"
NAME="$2"
TARGET_USER="buildbot"
SSH_TARGET="${TARGET_USER}@${TARGET}"
# Timeout for particular network commands: ping and ssh, in seconds
TIMEOUT=20
# Sleep between ssh_works tries, if ssh quit immediately
TIMEOUT_SSH_REFUSED=3
# Number of seconds for retries for ssh connection
# 360 - 6 minutes for target to boot
SSH_WAIT_FOR_BOOT_TRIES=480
# Logging to serial.log-ttyUSBX
LOG_FILE=serial.log

# Initialize global variables
LOG_PID=""

reboot_target() {
	local target=$1

	echo "Checking if target $target is alive..."
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id > /dev/null
	if [ $? -eq 0 ]; then
		echo "Target $target alive, gracefully powering down..."
		ssh $SSH_TARGET sudo poweroff &> /dev/null
		wait_for_ping_die $target
	else
		echo "Target $target dead, just resetting the power"
	fi

	sudo gpio-pi.py $TARGET restart || die "Restart GPIO failure"
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

# Return 0 on success, 1 on immediate failure, 2 on timeout failure
ssh_works() {
	#ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id &> /dev/null
	local err=""
	local rc=0

	err=$(ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id 2>&1)
	rc=$?
	if [ $rc -eq 0 ]; then
		return 0
	elif [[ "$err" != *"Connection timed out"* ]] && [[ "$err" != *"No route to host"* ]]; then
		return 1
	fi
	return 2
}

wait_for_boot() {
	local target=$1
	local i=0
	local rc=9

	while [ $i -lt $SSH_WAIT_FOR_BOOT_TRIES ]; do
		ssh_works
		rc=$?
		if [ $rc -eq 0 ]; then
			echo "Target $target booted!"
			ssh_get_diag
			return $?
		elif [ $rc -eq 1 ]; then
			# ssh quit immediately, so sleep for some time (shorter than TIMEOUT)
			sleep $TIMEOUT_SSH_REFUSED
			i=$(expr $i + $TIMEOUT_SSH_REFUSED)
		else
			# Timeouted, increase the retries counter
			i=$(expr $i + $TIMEOUT)
		fi
	done

	if [ $i -ge $SSH_WAIT_FOR_BOOT_TRIES ]; then
		echo "Timeout waiting for $target boot ($i tries)"
		return 1
	fi

	return 0
}

kill_old_log_serial
echo "Collecting logs in background from ${TARGET}..."
LOG_PID=$(log_serial $TARGET $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"
test_log_serial_active

trap "main_job_died" EXIT

echo "Rebooting target ${TARGET}..."
reboot_target $TARGET

echo "Wait for boot of ${TARGET}..."
wait_for_boot $TARGET
BOOT_STATUS=$?

echo "Target $TARGET boot error code: $BOOT_STATUS"
if [ $BOOT_STATUS -ne 0 ]; then
	# Target could be stuck in boot spinning in a stupid way with fan
	# on high speed. It is unresponsive so useless. Power it off
	# to save the power.
	#
	# TODO: Boot safe image so next deployment of modules (over SSH)
	# would work.
	echo "Target $TARGET failed to boot, power it off"
	sudo gpio-pi.py $TARGET off
fi

kill_pid_log_serial

exit $BOOT_STATUS
