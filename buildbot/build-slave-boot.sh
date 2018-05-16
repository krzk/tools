#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

# Be verbose for Buildbot debugging
set -x

test $# -gt 1 || die "Missing target name"

TARGET="$1"
NAME="$2"
TARGET_USER="buildbot"
SSH_TARGET="${TARGET_USER}@${TARGET}"
# Timeout for regular SSH commands, in seconds
TIMEOUT_SSH=30
# Timeout during wait_for_boot loop - for ssh and pings, in seconds
TIMEOUT_WAIT_FOR_BOOT=20
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

	ssh_poweroff_target $target $TARGET_USER $TIMEOUT_WAIT_FOR_BOOT

	echo "Resetting the power to ${target}..."
	sudo gpio-pi.py $target restart || die "Power off GPIO failure"
}

ssh_get_diag() {
	echo "####################################"
	ssh -o "ConnectTimeout $TIMEOUT_SSH" $SSH_TARGET uname -a || return $?
	echo "####################################"
	echo "Dmesg err:"
	ssh -o "ConnectTimeout $TIMEOUT_SSH" $SSH_TARGET dmesg -l err
	echo "####################################"
	echo "Dmesg warn:"
	ssh -o "ConnectTimeout $TIMEOUT_SSH" $SSH_TARGET dmesg -l warn
	echo "####################################"
}

# Return 0 on success, otherwise number of seconds command was sleeping
ssh_works() {
	local err=""
	local rc=0

	err=$(ssh -o "ConnectTimeout $TIMEOUT_WAIT_FOR_BOOT" $SSH_TARGET id 2>&1)
	rc=$?
	if [ $rc -eq 0 ]; then
		return 0
	elif [[ "$err" == *"Connection timed out"* ]]; then
		return $TIMEOUT_WAIT_FOR_BOOT
	elif [[ "$err" == *"No route to host"* ]]; then
		# ssh sleeps short time here (~3 seconds), so assume it will be TIMEOUT_SSH_REFUSED
		return  $TIMEOUT_SSH_REFUSED
	fi
	# Immediate failure
	sleep $TIMEOUT_SSH_REFUSED
	return $TIMEOUT_SSH_REFUSED
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
		else
			# Timeouted, increase the retries counter
			i=$(($i + $rc))
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
	# Expect Buildbot to power off the target in alwaysRun final step.
	echo "Target $TARGET failed to boot"
fi

kill_pid_log_serial

exit $BOOT_STATUS
