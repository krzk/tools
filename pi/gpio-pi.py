#!/usr/bin/env python3
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

import RPi.GPIO as GPIO
import sys
import time

targets = {
    "odroidxu3":    2,
    "xu3":          2,
    }

def target_to_pin(target):
    return targets[target]

def gpio_setup():
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)

def gpio_on(pin):
    print("Turning on...")
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW)

def gpio_off(pin):
    print("Turning off...")
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.HIGH)

def gpio_status(pin):
    status = "on"
    direction = GPIO.gpio_function(pin)

    if (direction == GPIO.IN):
        status = "off"
    elif (direction == GPIO.OUT):
        GPIO.setup(pin, GPIO.OUT)
        if (GPIO.input(pin) == GPIO.HIGH):
            status = "off"
    else:
        return "Unknown GPIO" + str(pin) + " function: " + str(direction)

    return "GPIO" + str(pin) + ": " + status

def print_help():
    print("Usage: " + str(sys.argv[0]) + " <target> <command>")
    print("   target:  xu3")
    print("   command: on, off, restart, status")
    print("            (status can be run also without target)")
    sys.exit(0)

def status_all():
    gpio_setup()
    for k, v in targets.items():
        print(k + ": " + gpio_status(v))

def one_target(target, command):
    pin = 0

    try:
        pin = target_to_pin(target)
    except KeyError:
        print ("Unknown target: '" + str(target) + "'")
        sys.exit(1)

    gpio_setup()

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

main()
