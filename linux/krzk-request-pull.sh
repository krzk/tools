#!/bin/bash
#
# Copyright (c) 2016-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "$(basename $0) <tag> [start]"
	exit 1
}

# One or more args needed
test $# -ge 1 || usage
TAG="$1"
START="$2"
START="${START:=master}"
OUT="pull-$(date +%Y.%m.%d)-${TAG}.txt"

REMOTE="$(git rev-parse --abbrev-ref master@{upstream})"
REMOTE="${REMOTE%%/*}"

case "$REMOTE" in
	krzk-korg)
		TO="Olof Johansson <olof@lixom.net>, Arnd Bergmann <arnd@arndb.de>, arm@kernel.org, soc@kernel.org"
		CC="Kukjin Kim <kgene@kernel.org>, linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>"
		SUBJECT="ARM: dts: exynos:"
		;;
	krzk-pinctrl)
		TO="Linus Walleij <linus.walleij@linaro.org>"
		CC="Tomasz Figa <tomasz.figa@gmail.com>, Sylwester Nawrocki <snawrocki@kernel.org>, linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org"
		SUBJECT="pinctrl: samsung:"
		;;
	*)
		usage
esac

git tag -v $TAG &> /dev/null || die "Wrong tag or signature"

echo "Output to: $OUT"
echo "Subject: [GIT PULL] $SUBJECT xxx for v5.x
From: Krzysztof Kozlowski <krzk@kernel.org>
To: $TO
Cc: $CC

Hi,



Best regards,
Krzysztof

" > $OUT
git request-pull $START $REMOTE $TAG >> $OUT