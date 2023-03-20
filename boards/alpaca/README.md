Copyright (c) 2023 Linaro Ltd  
Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>  
                            <krzk@kernel.org>

SPDX-License-Identifier: GPL-2.0

Simple boot-script for turning of Alpaca-controlled boards.

# Dependencies

    sudo apt-get install picocom

# Install

    # Customize SERIAL_qrd:
    sudo vim usr/bin/alpaca-off.sh

    sudo cp -r alpaca/etc/ alpaca/usr/ /
    sudo systemctl daemon-reload
    sudo systemctl enable alpaca-off.service
    sudo systemctl start alpaca-off.service
