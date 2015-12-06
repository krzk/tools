#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
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

test $# -eq 1 || die "Missing slave name"

SLAVE="$1"
SLAVE_USER="buildbot"
SSH_SLAVE="${SLAVE_USER}@${SLAVE}"
TIMEOUT=3
SERIAL=/dev/ttyUSB0
LOG_FILE=serial.log

# wait_for_ping_die slave
wait_for_ping_die() {
	local slave=$1
	local i=0
	local tries=1000

	ping -c 1 -W $TIMEOUT $slave > /dev/null

	if [ $? -eq 1 ]; then
		echo "Slave $slave died very fast"
		return 0
	fi

	while [ $i -lt $tries ]; do
		ping -c 1 -W $TIMEOUT $slave > /dev/null
		if [ $? -ne 0 ]; then
			echo "Slave $slave dead after $i pings"
			break
		fi
		i=$(expr $i + 1)
	done

	test $i -lt $tries || echo "Slave $slave did not die properly"

	return 0
}

reboot_slave() {
	local slave=$1

	echo "Checking if slave $slave is alive..."
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_SLAVE id > /dev/null
	if [ $? -eq 0 ]; then
		echo "Slave $slave alive, powering down..."
		ssh $SSH_SLAVE sudo poweroff &> /dev/null
		wait_for_ping_die $slave
	fi

	sudo gpio-pi.py restart
}

ssh_get_diag() {
	echo "####################################"
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_SLAVE uname -a || return $?
	echo "####################################"
	echo "Dmesg err:"
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_SLAVE dmesg -l err
	echo "####################################"
	echo "Dmesg warn:"
	ssh -o "ConnectTimeout $TIMEOUT" $SSH_SLAVE dmesg -l warn
	echo "####################################"
}

wait_for_boot() {
	local slave=$1
	local i=0
	local tries=30

	while [ $i -lt $tries ]; do
		ssh -o "ConnectTimeout $TIMEOUT" $SSH_SLAVE id &> /dev/null
		if [ $? -eq 0 ]; then
			echo "Slave $slave booted!"
			ssh_get_diag
			return $?
		fi
		i=$(expr $i + 1)
	done

	test $i -lt $tries

	return $?
}

echo "Rebooting slave ${SLAVE}..."
reboot_slave $SLAVE

echo "Collecting logs in background from ${SLAVE}..."
stty -F $SERIAL 115200 cs8 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts
ts < $SERIAL > $LOG_FILE &
LOG_PID=$!
#echo "Logger PID: $LOG_PID"

echo "Wait for boot of ${SLAVE}..."
wait_for_boot $SLAVE
BOOT_STATUS=$?

kill $LOG_PID &> /dev/null
kill -9 $LOG_PID &> /dev/null

echo "Slave $SLAVE boot: $BOOT_STATUS"
exit $BOOT_STATUS
