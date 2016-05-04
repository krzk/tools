#!/bin/bash
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
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
TIMEOUT=3
# Will listen on all /dev/ttyUSBX devices
SERIAL=/dev/ttyUSB
# Logging to serial.log-ttyUSBX
LOG_FILE=serial.log

# Initialize global variables
LOG_PID=""

poweroff_target() {
	local target=$1

	echo "Checking if target $target is alive..."
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id > /dev/null
	if [ $? -eq 0 ]; then
		echo "Target $target alive, gracefully powering down..."
		ssh $SSH_TARGET sudo poweroff &> /dev/null
		wait_for_ping_die $target
	else
		echo "Target $target dead, just cutting the power"
	fi

	echo "Cutting the power to ${target}..."
	sudo gpio-pi.py $TARGET off
}

kill_old_log_serial
echo "Collecting logs in background from ${TARGET}..."
LOG_PID=$(log_serial $TARGET $SERIAL $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"
test_log_serial_active

trap "main_job_died" EXIT

echo "Powering off target ${TARGET}..."
poweroff_target $TARGET

kill_pid_log_serial

exit 0
