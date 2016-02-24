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
# Number of retries (each with TIMEOUT) for ssh connection
SSH_WAIT_FOR_BOOT_TRIES=100
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

	if [ $i -ge $SSH_WAIT_FOR_BOOT_TRIES ]; then
		echo "Timeout waiting for $target boot"
		return 1
	fi

	return 0
}

echo "Rebooting target ${TARGET}..."
reboot_target $TARGET

kill_old_log_serial
echo "Collecting logs in background from ${TARGET}..."
LOG_PID=$(log_serial $TARGET $SERIAL $LOG_FILE)
test -n "$LOG_PID" || die "No PID of logger"

trap "main_job_died" EXIT

echo "Wait for boot of ${TARGET}..."
wait_for_boot $TARGET
BOOT_STATUS=$?

echo "Target $TARGET boot: $BOOT_STATUS"
if [ $BOOT_STATUS -ne 0 ]; then
	# Target could be stuck in boot spinning in a stupid way with fan
	# on high speed. It is unresponsive so useless. Power it off
	# to save the power.
	#
	# TODO: Boot safe image so next deployment of modules (over SSH)
	# would work.
	echo "Target $TARGET failed to boot, power it off"
	sudo gpio-pi.py off
fi

kill_pid_log_serial

exit $BOOT_STATUS
