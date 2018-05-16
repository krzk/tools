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
# Timeout during wait_for_boot loop - for ssh and pings, in seconds
TIMEOUT_WAIT_FOR_BOOT=20
# Logging to serial.log-ttyUSBX
LOG_FILE=serial.log

# Initialize global variables
LOG_PID=""

poweroff_target() {
	local target=$1

	ssh_poweroff_target $target $TARGET_USER $TIMEOUT_WAIT_FOR_BOOT

	echo "Cutting the power to ${target}..."
	sudo gpio-pi.py $target off || die "Power off GPIO failure"
}

kill_old_log_serial
echo "Collecting logs in background from ${TARGET}..."
LOG_PID=$(log_serial $TARGET $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"
test_log_serial_active

trap "main_job_died" EXIT

echo "Powering off target ${TARGET}..."
poweroff_target $TARGET

kill_pid_log_serial

exit 0
