#!/usr/bin/env python3
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

import RPi.GPIO as GPIO
import sys
import time

def target_to_pin(target):
    pin = 0
    if (target == "odroidxu3"):
        pin = 2
    return pin

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
        print("Unknown GPIO" + str(pin) + " function: " + str(direction))
        return

    print("Current GPIO" + str(pin) + ": " + status)

def print_help():
    print("Usage: " + str(sys.argv[0]) + " <target> <command>")
    print("   target:  odroidxu3, odroidu3, odroidxu")
    print("   command: on, off, restart, status")
    sys.exit()

def main():
    pin = 0
    if (len(sys.argv) != 3):
        print_help()

    pin = target_to_pin(sys.argv[1])
    if (pin == 0):
        raise ValueError("Could not match pin for given target: '" + str(sys.argv[1]) + "'")

    gpio_setup()

    if (sys.argv[2] == "on"):
        gpio_on(pin)
    elif (sys.argv[2] == "off"):
        gpio_off(pin)
    elif (sys.argv[2] == "restart"):
        gpio_off(pin)
        time.sleep(2)
        gpio_on(pin)
    elif (sys.argv[2] == "status"):
        gpio_status(pin)
    else:
        print_help()

main()
