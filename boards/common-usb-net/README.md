Copyright (c) 2023 Krzysztof Kozlowski  
Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>  
                            <krzk@kernel.org>

SPDX-License-Identifier: GPL-2.0

USB networking via USB CDC ECM gadget (or RNDIS).

# Install

    sudo cp -r common-usb-net/etc/ common-usb-net/usr/ /
    sudo systemctl daemon-reload
    sudo systemctl enable usb-gadget-net.service
    sudo systemctl start usb-gadget-net.service
    sudo systemctl enable systemd-networkd
    sudo systemctl start systemd-networkd
    # Resolved is needed for networkd
    sudo apt-get install systemd-resolved
    sudo systemctl enable systemd-resolved
    sudo systemctl start systemd-resolved
