#!/bin/bash
#
# Copyright (c) 2016-2023 Krzysztof Kozlowski
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

REMOTE="$(git rev-parse --abbrev-ref --symbolic-full-name master@{upstream})"
REMOTE="${REMOTE%%/*}"
REMOTE_URL="$(git remote get-url ${REMOTE})"

CC_KRZK="Krzysztof Kozlowski <krzk@kernel.org>, Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>"

if [[ $REMOTE_URL == *"/krzk/linux.git"* ]]; then
	TO="Arnd Bergmann <arnd@arndb.de>, soc@lists.linux.dev"
	CC="linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org"
	CC="Alim Akhtar <alim.akhtar@samsung.com>, Peter Griffin <peter.griffin@linaro.org>, $CC, $CC_KRZK"
	if [[ $TAG == *"-clk-"* ]]; then
		SUBJECT="clk: samsung:"
		TO="Michael Turquette <mturquette@baylibre.com>, Stephen Boyd <sboyd@kernel.org>"
		CC="Sylwester Nawrocki <snawrocki@kernel.org>, $CC"
		CC="Chanwoo Choi <cw00.choi@samsung.com>, linux-clk@vger.kernel.org, $CC"
	elif [[ $TAG == *"-drivers-"* ]]; then
		SUBJECT="samsung: drivers"
	elif [[ $TAG == *"-dt-"* ]]; then
		SUBJECT="ARM: dts: samsung:"
	elif [[ $TAG == *"-dt64-"* ]]; then
		SUBJECT="arm64: dts: samsung:"
	elif [[ $TAG == *"-fixes-"* ]]; then
		SUBJECT="ARM: samsung:"
	elif [[ $TAG == *"-soc-"* ]]; then
		SUBJECT="ARM: samsung:"
	fi
elif [[ $REMOTE_URL == *"/krzk/linux-dt.git"* ]]; then
	if [[ $TAG == *"qcom-pinctrl"* ]]; then
		TO="Linus Walleij <linus.walleij@linaro.org>"
		CC="Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, Konrad Dybcio <konrad.dybcio@somainline.org>, linux-arm-msm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, $CC_KRZK"
		SUBJECT="pinctrl: dt-bindings: qcom:"
	elif [[ $TAG == *"dt-bindings-"* ]]; then
		TO="Rob Herring <robh@kernel.org>"
		CC="devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, $CC_KRZK"
		SUBJECT="dt-bindings:"
	elif [[ $TAG == *"dt-"* ]]; then
		TO="Arnd Bergmann <arnd@arndb.de>, soc@lists.linux.dev"
		CC="linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, $CC_KRZK"
		SUBJECT="ARM: dts: "
	elif [[ $TAG == *"dt64-"* ]]; then
		TO="Arnd Bergmann <arnd@arndb.de>, soc@lists.linux.dev"
		CC="linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, $CC_KRZK"
		SUBJECT="arm64: dts: "
	else
		TO="Arnd Bergmann <arnd@arndb.de>, soc@lists.linux.dev"
		CC="linux-kernel@vger.kernel.org, $CC_KRZK"
		SUBJECT="drivers:"
	fi
elif [[ $REMOTE_URL == *"/krzk/linux-mem-ctrl.git"* ]]; then
	TO="Arnd Bergmann <arnd@arndb.de>, soc@lists.linux.dev"
	CC="linux-kernel@vger.kernel.org, $CC_KRZK"
	if [[ $TAG == *"-fixes-"* ]]; then
		SUBJECT="memory: fixes:"
	else
		SUBJECT="memory:"
	fi
elif [[ $REMOTE_URL == *"/krzk/linux-w1.git"* ]]; then
	TO="Greg Kroah-Hartman <gregkh@linuxfoundation.org>"
	CC="linux-kernel@vger.kernel.org, $CC_KRZK"
	if [[ $TAG == *"-fixes-"* ]]; then
		SUBJECT="w1: fixes:"
	else
		SUBJECT="w1:"
	fi
elif [[ $REMOTE_URL == *"/pinctrl/samsung.git"* ]]; then
	TO="Linus Walleij <linus.walleij@linaro.org>"
	CC="linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org"
	CC="Sylwester Nawrocki <snawrocki@kernel.org>, Alim Akhtar <alim.akhtar@samsung.com>, Peter Griffin <peter.griffin@linaro.org>, $CC, $CC_KRZK"
	SUBJECT="pinctrl: samsung:"
else
	usage
fi

git tag -v $TAG &> /dev/null || die "Wrong tag or signature"

echo "Output to: $OUT"
echo "Subject: [GIT PULL] $SUBJECT xxx for v6.x
From: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
To: $TO
Cc: $CC

Hi,



Best regards,
Krzysztof

" > $OUT
git request-pull $START $REMOTE $TAG >> $OUT
