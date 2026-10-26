#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>

if ! systemctl is-active --quiet docker.socket; then
	systemctl start docker.socket
fi

docker build -t krzk/debian-dev .
