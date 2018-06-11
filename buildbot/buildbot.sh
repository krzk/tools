#!/bin/bash
### BEGIN INIT INFO
# Provides:          buildbot
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Buildbot master and slave
### END INIT INFO
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#
# For systemd and SystemV

SYSTEMD=0
BOT=""
SCRIPT="$0"

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin

# Load the VERBOSE setting and other rcS variables
# Present on Ubuntu and Debian, not in Arch
if [ -f /lib/init/vars.sh ]; then
	. /lib/init/vars.sh
fi

die() {
	echo "Fail: $1"
	exit 1
}

do_buildbot() {
	local bot_cmd="buildbot-worker"
	test "$2" == "master" && bot_cmd="buildbot"
	test "$2" == "slave" && bot_cmd="buildslave"
	cd $HOME
	test -d "sandbox" && source sandbox/bin/activate
	test -d "$2" || die "No buildbot: $2"
	echo "Launching: $bot_cmd $1 $2"
	$bot_cmd $1 $2
}

usage() {
	echo "Usage: $0 {start|stop|reload} [master|worker|slave]"
	echo "  master|worker|slave argument can be determined from executable suffix"
	exit 1
}

launch_service() {
	if [ $SYSTEMD -eq 1 ]; then
		do_buildbot $1 $BOT
	else
		start-stop-daemon --start -c buildbot:buildbot --exec $SCRIPT -- $1 $BOT
	fi
}

if [ $# -eq 2 ]; then
	BOT="$2"
	SYSTEMD=1
else
	# SystemV init-like does not provide second argument, make up one
	BOT="$0"
	BOT="${BOT##*-}"
	BOT="${BOT%%.*}"
	test -n "$BOT" || die "Missing executable suffix, like '-master'"
	test "$BOT" != "$0" || die "Wrong executable suffix, like '-master'"
fi

case "$1" in
	start)
		launch_service "start"
		exit $?
		;;
	stop)
		launch_service "stop"
		exit $?
		;;
	reload|reconfig)
		launch_service "reconfig"
		exit $?
		;;
	*)
		usage
		;;
esac

exit 0
