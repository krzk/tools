#!/bin/bash
#
# Copyright (c) 2016 Krzysztof Kozlowski
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

usage() {
	echo "$(basename $0) <tag> [start]"
	exit 1
}

test $# -gt 0 || usage
TAG="$1"
START="$2"
START="${START:=master}"
OUT="pull-$(date +%Y.%m.%d)-${TAG}.txt"

git tag -v $TAG &> /dev/null || die "Wrong tag or signature"

echo "Output to: $OUT"
echo "Subject: [GIT PULL] ARM: dts: exynos: xxx for v4.x
From: Krzysztof Kozlowski <k.kozlowski@samsung.com>
To: Olof Johansson <olof@lixom.net>, Arnd Bergmann <arnd@arndb.de>, Kevin Hilman <khilman@kernel.org>, arm@kernel.org
Cc: Kukjin Kim <kgene@kernel.org>, linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, Bartlomiej Zolnierkiewicz <b.zolnierkie@samsung.com>, Krzysztof Kozlowski <krzk@kernel.org>, Krzysztof Kozlowski <k.kozlowski@samsung.com>

Hi,



Best regards,
Krzysztof

" > $OUT
git request-pull $START krzk-korg $TAG >> $OUT
