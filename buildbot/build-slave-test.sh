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
SERIAL=/dev/ttyUSB0
LOG_FILE=serial.log

kill_pid_log_serial() {
	if [ -n "$LOG_PID" ]; then
		kill $LOG_PID &> /dev/null
		kill -9 $LOG_PID &> /dev/null
		LOG_PID=""
	fi
}

kill_old_log_serial() {
	local existing="$(ps -C ts -o pid --no-headers)"
	for pid in $existing; do
		echo "Killing existing instance PID $pid of 'ts'"
		kill $pid &> /dev/null
		kill -9 $pid &> /dev/null
	done
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

	stty -F $serial 115200 cs8 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts
	ts < $serial > $log_file &
	echo $!
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

trap "main_job_died" EXIT

run_tests $TARGET

kill_pid_log_serial

exit 0
