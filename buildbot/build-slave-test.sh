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
PROJECT="$3"
TARGET_USER="buildbot"
SSH_TARGET="${TARGET_USER}@${TARGET}"
TOOLS_DIR="/opt/tools"
# Timeout for particular network commands: ping and ssh, in seconds
TIMEOUT=3
# Will listen on all /dev/ttyUSBX devices
SERIAL=/dev/ttyUSB
# Logging to serial.log-ttyUSBX
LOG_FILE=serial.log

# Initialize global variables
LOG_PID=""

ssh_works() {
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id &> /dev/null
}

# Run the tests and fail everything on error
run_tests() {
	local target=$1

	set -e -E
	ssh $SSH_TARGET sudo ${TOOLS_DIR}/tests/all-odroid-xu3.sh

	ssh_works
	set +e +E
}

if [ "$PROJECT" == "stable" ]; then
	echo "Skipping tests on project ${PROJECT} on ${TARGET} (name: ${NAME})..."
	exit 0
fi
echo "Running tests on ${TARGET} (name: ${NAME}, project: ${PROJECT})..."

kill_old_log_serial
echo "Collecting logs in background from ${TARGET}..."
LOG_PID=$(log_serial $TARGET $SERIAL $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"
test_log_serial_active

trap "main_job_died" EXIT

run_tests $TARGET

kill_pid_log_serial

exit 0
