#!/usr/bin/env python3
#
# Copyright (c) 2015,2016 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# TODO: parametrize GPIO number
#

import RPi.GPIO as GPIO
import sys
import time

pin = 2

def gpio_setup():
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)

def gpio_on():
    print("Turning on...")
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW)

def gpio_off():
    print("Turning off...")
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.HIGH)

def gpio_status():
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
    print("Usage: " + str(sys.argv[0]) + " <command>")
    print("   command: on, off, restart, status")
    sys.exit()

def main():
    if (len(sys.argv) != 3):
        print_help()

    gpio_setup()

    if (sys.argv[1] == "on"):
        gpio_on()
    elif (sys.argv[1] == "off"):
        gpio_off()
    elif (sys.argv[1] == "restart"):
        gpio_off()
        time.sleep(2)
        gpio_on()
    elif (sys.argv[1] == "status"):
        gpio_status()
    else:
        print_help()

main()
