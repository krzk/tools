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
# Copyright (c) 2015-2025 Krzysztof Kozlowski
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

# Source buildmaster configuration
OPTIONS=""
[[ -r /etc/default/buildmaster ]] && . /etc/default/buildmaster

die() {
	echo "Fail: $1"
	exit 1
}

# Read the system's locale and set cron's locale. This is only used for
# setting the charset of mails generated by cron. To provide locale
# information to tasks running under cron, see /etc/pam.d/cron.
#
# We read /etc/environment, but warn about locale information in
# there because it should be in /etc/default/locale.
parse_environment ()
{
	for ENV_FILE in /etc/environment /etc/default/locale; do
		[ -r "$ENV_FILE" ] || continue
		[ -s "$ENV_FILE" ] || continue

		for var in LANG LANGUAGE LC_ALL LC_CTYPE; do
			value=$(grep -E "^${var}=" "$ENV_FILE" | tail -n1 | cut -d= -f2)
			[ -n "$value" ] && eval export $var="$value"

			if [ -n "$value" ] && [ "$ENV_FILE" = /etc/environment ]; then
				echo "/etc/environment has been deprecated for locale information; use /etc/default/locale for $var=$value instead"
			fi
		done
	done

	# Get the timezone set.
	if [ -z "$TZ" ] && [ -e /etc/timezone ]; then
		TZ=$(cat /etc/timezone)
	fi
}

do_buildbot() {
	local bot_cmd="buildbot-worker"
	test "$2" == "master" && bot_cmd="buildbot"
	test "$2" == "slave" && bot_cmd="buildslave"

	parse_environment
	cd "$HOME" || exit
	test -d "sandbox" && source sandbox/bin/activate
	test -d "$2" || die "No buildbot: $2"
	if [ "$1" != "start" ]; then
		OPTIONS=""
	fi
	echo "Launching: $bot_cmd $1 $OPTIONS $2"
	"$bot_cmd" "$1" $OPTIONS "$2"
}

usage() {
	echo "Usage: $0 {start|stop|reload} [master|worker|slave]"
	echo "  master|worker|slave argument can be determined from executable suffix"
	exit 1
}

launch_service() {
	if [ $SYSTEMD -eq 1 ]; then
		do_buildbot "$1" "$BOT"
	else
		start-stop-daemon --start -c buildbot:buildbot --exec "$SCRIPT" -- "$1" $OPTIONS "$BOT"
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
