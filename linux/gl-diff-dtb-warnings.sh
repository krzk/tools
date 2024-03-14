#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

[ -z "$1" ] && { echo "Missing arch!"; exit 1; }

arch="$1"

job="job-dtbs-check"
logfile="platform-warnings.log"

# url <branch> <arch>
url() {
	local branch="$1"
	local arch="$2"

	echo "https://gitlab.com/robherring/linux-dt/-/jobs/artifacts/${branch}/raw/${logfile}?job=${job}%3A+%5B${arch}%5D"
}

curl -Ls -o orig.log $(url linus ${arch})
curl -Ls -o next.log $(url next ${arch})
diff -ubB orig.log next.log
