#!/bin/bash
#
# Copyright (c) 2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

FILE=$1

if [ $# -ne 1 ] || [ "$(basename $FILE)" != "master.cfg" ]; then
	echo "This simple script expects master.cfg."
	exit 1
fi

scp $FILE buildmaster:master/master.cfg
echo "Run: sudo /etc/init.d/buildbot-master reload"
