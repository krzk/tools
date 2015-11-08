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
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# For systemd and SystemV

SYSTEMD=0
BOT=""
SCRIPT="$0"

die() {
	echo "Fail: $1"
	exit 1
}

do_buildbot() {
	local bot_cmd="buildslave"
	test "$2" == "master" && bot_cmd="buildbot"
	cd $HOME
	test -d "sandbox" && source sandbox/bin/activate
	test -d "$2" || die "No buildbot: $2"
	echo "Launching: $bot_cmd $1 $2"
	$bot_cmd $1 $2
}

usage() {
	echo "Usage: $0 {start|stop|reload} [master|slave]"
	echo "  master|slave argument can be determined from executable suffix"
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
