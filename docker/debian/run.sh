#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>

if ! systemctl is-active --quiet docker.socket; then
	systemctl start docker.socket
fi

docker run --rm -it --mount type=bind,source=/home/${USER}/dev/neard,target=/root/neard \
	--workdir /root/neard \
	krzk/debian-dev:latest /bin/bash
