#!/usr/bin/env python3
#
# Copyright (c) 2015-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#
# On Raspberry Pi 3 B+, aarch64 (Arch Linux ARM), all Python libraries did not
# work and have troubles:
# 1. RPi.GPIO, RPIO: no support for 3 B+
# 2. wiringx-git: no support for reading pin mode and reading output value (once set)
#
# # Old school sysfs to the rescue...

import os
import sys
import time

TARGETS = {
    "arndaleocta":  10,
    "octa":         10,
    "odroidhc1":    3,
    "hc1":          3,
    "odroidmc1":    2,
    "mc1":          2,
    "odroidu3":     17,
    "u3":           17,
    "odroidx":      9,
    "x":            9,
    "odroidxu":     4,
    "xu":           4,
    }

PIN_BASE = 512

def target_to_pin(target):
    return TARGETS[target]

def gpio_sysfs_get_value(pinb):
    with open("/sys/class/gpio/gpio%d/value" % pinb, "r") as f:
        return f.readline().strip()
    return -1

def gpio_sysfs_set_value(pinb, value):
    with open("/sys/class/gpio/gpio%d/value" % pinb, "w") as f:
        f.write(value)

def gpio_sysfs_set_output(pinb):
    with open("/sys/class/gpio/gpio%d/direction" % pinb, "w") as f:
        f.write("out")

def gpio_sysfs_export(pin):
    pinb = PIN_BASE + pin
    if os.path.isdir("/sys/class/gpio/gpio%d" % pinb):
        return
    with open("/sys/class/gpio/export", "w") as f:
        f.write(str(pinb))

def gpio_on(pin):
    print("Turning on...")
    pinb = PIN_BASE + pin
    gpio_sysfs_export(pin)
    gpio_sysfs_set_output(pinb)
    gpio_sysfs_set_value(pinb, "0")

def gpio_off(pin):
    print("Turning off...")
    pinb = PIN_BASE + pin
    gpio_sysfs_export(pin)
    gpio_sysfs_set_output(pinb)
    gpio_sysfs_set_value(pinb, "1")

def gpio_status(pin):
    status = "on"
    pinb = PIN_BASE + pin
    gpio_sysfs_export(pin)
    with open("/sys/class/gpio/gpio%d/direction" % pinb, "r") as f:
        direction = f.readline().strip()
    if direction == "in":
        status = "off"
    elif direction == "out":
        if gpio_sysfs_get_value(pinb) == "1":
            status = "off"
    else:
        return "Unknown GPIO" + str(pin) + " function: " + str(direction)

    return "GPIO" + str(pin) + ": " + status

def print_help():
    print("Usage: " + str(sys.argv[0]) + " <target> <command>")
    print("   target:  " + ", ".join(TARGETS.keys()))
    print("   command: on, off, restart, status")
    print("            (status can be run also without target)")
    sys.exit(2)

def status_all():
    for k, v in TARGETS.items():
        print(k + ": " + gpio_status(v))

def one_target(target, command):
    pin = 0

    try:
        pin = target_to_pin(target)
    except KeyError:
        print ("Unknown target: '" + str(target) + "'")
        sys.exit(1)

    if (command == "on"):
        gpio_on(pin)
    elif (command == "off"):
        gpio_off(pin)
    elif (command == "restart"):
        gpio_off(pin)
        time.sleep(2)
        gpio_on(pin)
    elif (command == "status"):
        print(gpio_status(pin))
    else:
        print_help()

def main():
    if (len(sys.argv) == 3):
        one_target(sys.argv[1], sys.argv[2])
    elif (len(sys.argv) == 2) and (sys.argv[1] == "status"):
        status_all()
    else:
        print_help()
    sys.exit(0)

main()
