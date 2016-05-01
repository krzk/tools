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
# Will listen on all /dev/ttyUSBX devices
SERIAL=/dev/ttyUSB
# Logging to serial.log-ttyUSBX
LOG_FILE=serial.log

# Initialize global variables
LOG_PID=""

# On arch ping6 and ping were merged so '-4' and '-6' arguments are supported.
# However on pi, the IPv6 is disabled and running just 'ping' causes error:
# ping: socket: Address family not supported by protocol (raw socket required by specified options).
# Detect if '-4' is supported, if it is, then use it
get_ping() {
	ping -h |& grep vV64 > /dev/null
	if [ $? -eq 0 ]; then
		echo 'ping -4'
	else
		echo 'ping'
	fi
}

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

# wait_for_ping_die target
wait_for_ping_die() {
	local target=$1
	local i=0
	local tries=1000

	$(get_ping) -c 1 -W $TIMEOUT $target > /dev/null

	if [ $? -eq 1 ]; then
		echo "Target $target died very fast"
		return 0
	fi

	while [ $i -lt $tries ]; do
		$(get_ping) -c 1 -W $TIMEOUT $target > /dev/null
		if [ $? -ne 0 ]; then
			echo "Target $target (gracefully) off after $i pings"
			# Network is dead but still need to sleep for few
			# seconds to wait for umount before sending hard-reset
			sleep 5
			break
		fi
		i=$(expr $i + 1)
	done

	test $i -lt $tries || echo "Target $target did not die properly, will hard-reset it"

	return 0
}

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
test -c "${SERIAL}0" || die "Missing at least ${SERIAL}0"
LOG_PID=$(log_serial $TARGET $SERIAL $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"
test_log_serial_active

trap "main_job_died" EXIT

echo "Powering off target ${TARGET}..."
poweroff_target $TARGET

kill_pid_log_serial

exit 0
