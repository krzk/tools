#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

CONFIGS="defconfig"
CONFIGS_ARM="exynos multi_v7 s3c2410 s3c6400"
ARCHS="arm arm64 i386 x86_64"
#DTS="exynos4412-trats2 exynos5420-arndale-octa exynos/exynos7-espresso.dts"
LOGS="logs"

START_COMMIT=""

usage() {
	echo "Usage: $(basename $0) [-c config] -s <start>"
	echo
	echo " Build configurations since <start> GIT revision."
	echo " Currently built configs:"
	echo "  $CONFIGS_ARM (arm)"
	echo "  defconfig (${ARCHS#arm})"
	echo
	echo " -A <arch>      - Build only this arch"
	echo " -c <config>    - Build only this config"
	exit 2
}

die() {
	echo "Fail: $1"
	exit 1
}

while getopts "hc:A:s:" flag
do
	case "$flag" in
		h)
			usage
			;;
		c)
			CONFIGS="$OPTARG"
			CONFIGS_ARM=""
			;;
		A)
			ARCHS="$OPTARG"
			;;
		s)
			START_COMMIT="$OPTARG"
			;;
	esac
done

checkout() {
	local _commit=$1

	git checkout $_commit || die "Checkout error"
}

build_all_commits() {
	local _arch=$1
	local _config=$2

	for commit in $COMMITS
	do
		echo
		echo ~/dev/tools/release.sh -A $_arch -c $_config
		echo
		checkout $commit
		echo
		nice ~/dev/tools/release.sh -A $_arch -c $_config -E "${DRIVERS_ADDON}" > /dev/null 2> "${LOGS}/${_arch}-${_config}-${commit}"
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed build: -A $_arch -c $_config on $commit"
		fi
		echo "##################################################################"
	done
	echo
}

build_arch() {
	local _arch=$1
	local _configs="$CONFIGS"

	if [ "$_arch" = "arm" ]; then
		_configs="${_configs} ${CONFIGS_ARM}"
	fi

	for config in $_configs
	do
		build_all_commits $_arch $config
	done
}

build_all_archs() {
	for arch in $ARCHS
	do
		build_arch $arch
	done
}



test -f drivers/mfd/Kconfig || die "No drivers/mfd/Kconfig"
test -f drivers/power/Kconfig || die "No drivers/power/Kconfig"
DRIVERS_ADDON="$(grep ^config drivers/mfd/Kconfig | sed -e 's/^config //' -e 's/$/,/' | tr -d '\n' | sed -e 's/,$//'),$(grep ^config drivers/power/Kconfig | sed -e 's/^config //' -e 's/$/,/' | tr -d '\n' | sed -e 's/,$//')"

test -n "$START_COMMIT" || usage

echo "Start commit:"
git rev-parse --verify $START_COMMIT || die "Wrong start commit"
echo "End comit:"
git rev-parse --verify HEAD || die "Wrong HEAD"
git rev-parse --abbrev-ref HEAD > /dev/null || die "Could not find current branch"

COMMITS="`git log --pretty=format:"%H" $START_COMMIT...HEAD`"
COMMITS="$COMMITS $START_COMMIT"
CURRENT_BRANCH="`git rev-parse --abbrev-ref HEAD`"

rm -fr $LOGS
mkdir $LOGS || die "mkdir $LOGS error"

checkout $START_COMMIT

build_all_archs

checkout "${CURRENT_BRANCH}"
