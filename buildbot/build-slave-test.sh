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

kill_pid_log_serial() {
	if [ -n "$LOG_PID" ]; then
		kill $LOG_PID &> /dev/null
		kill -9 $LOG_PID &> /dev/null
		LOG_PID=""
	fi
}

kill_old_log_serial() {
	pkill -x ts
	pkill -x ts -9
}

test_log_serial_active() {
	pgrep -x ts > /dev/null || die "Serial logger $SERIAL died"
}

main_job_died() {
	echo "Exit trap, cleaning up..."
	if [ -n "$LOG_PID" ]; then
		echo "Killing serial logging (PID: ${LOG_PID})"
		kill_pid_log_serial
	fi
}

# log_serial target serial log_file
# Echos the PID of logging process
log_serial() {
	local target=$1
	local serial=$2
	local log_file=$3

	for s in ${serial}*; do
		stty -F $s 115200 cs8 ignbrk -brkint -icrnl -imaxbel -opost -onlcr \
			-isig -icanon -iexten -echo -echoe -echok -echoctl -echoke \
			noflsh -ixon -crtscts || exit 1
		ts < $s > "${log_file}-$(basename $s)" &
		echo $!
	done
}

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
