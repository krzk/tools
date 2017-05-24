#!/bin/bash
#
# Copyright (c) 2016,2017 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "$(basename $0) <remote> <tag> [start]"
	echo "    remote - <krzk-korg> or <krzk-pinctrl>"
	exit 1
}

# Two or more args needed
test $# -gt 1 || usage
REMOTE="$1"
TAG="$2"
START="$3"
START="${START:=master}"
OUT="pull-$(date +%Y.%m.%d)-${TAG}.txt"

case "$REMOTE" in
	krzk-korg)
		TO="Olof Johansson <olof@lixom.net>, Arnd Bergmann <arnd@arndb.de>, arm@kernel.org"
		CC="Kukjin Kim <kgene@kernel.org>, linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>"
		SUBJECT="ARM: dts: exynos:"
		;;
	krzk-pinctrl)
		TO="Linus Walleij <linus.walleij@linaro.org>"
		CC="Tomasz Figa <tomasz.figa@gmail.com>, Sylwester Nawrocki <s.nawrocki@samsung.com>, linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org"
		SUBJECT="pinctrl: samsung:"
		;;
	*)
		usage
esac

git tag -v $TAG &> /dev/null || die "Wrong tag or signature"

echo "Output to: $OUT"
echo "Subject: [GIT PULL] $SUBJECT xxx for v4.x
From: Krzysztof Kozlowski <krzk@kernel.org>
To: $TO
Cc: $CC

Hi,



Best regards,
Krzysztof

" > $OUT
git request-pull $START $REMOTE $TAG >> $OUT
