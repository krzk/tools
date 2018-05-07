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

test $# -gt 2 || die "Missing target/name/cmd"

TARGET="$1"
NAME="$2"
shift 2
CMD="$*"
TARGET_USER="buildbot"
SSH_TARGET="${TARGET_USER}@${TARGET}"
# Timeout for particular network commands: ping and ssh, in seconds
TIMEOUT=10
# Logging to serial.log-ttyUSBX
LOG_FILE=serial.log

# Initialize global variables
LOG_PID=""

ssh_works() {
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_TARGET id &> /dev/null
}

# Run the cmd and fail everything on error
run_cmd_target() {
	local target=$1

	set -e -E
	ssh $SSH_TARGET sudo $CMD

	ssh_works
	set +e +E
}

echo "Running '${CMD}' on ${TARGET} (name: ${NAME})..."

kill_old_log_serial
echo "Collecting logs in background from ${TARGET}..."
LOG_PID=$(log_serial $TARGET $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"
test_log_serial_active

trap "main_job_died" EXIT

run_cmd_target $TARGET

kill_pid_log_serial

exit 0
