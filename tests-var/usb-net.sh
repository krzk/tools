#!/bin/bash

# Host:
# /etc/network/interfaces
auto usb0
iface usb0 inet static
address 192.168.129.1
netmask 255.255.255.0

# Target:
ifconfig usb0 192.168.129.3 up
