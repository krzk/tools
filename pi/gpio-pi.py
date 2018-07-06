#!/usr/bin/env python3
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

from wiringX import gpio
import sys
import time

gpio.setup(gpio.RASPBERRYPI3)
targets = {
    "odroidxu3":    gpio.PIN8,  # RPI pin 2
    "xu3":          gpio.PIN8,
    "odroidhc1":    gpio.PIN9,  # RPI pin 3
    "hc1":          gpio.PIN9,
    "odroidxu":     gpio.PIN10, # RPI pin 4
    "xu":           gpio.PIN10,
    "odroidu3":     gpio.PIN0,  # RPI pin 17
    "u3":           gpio.PIN0,
    }

def target_to_pin(target):
    return targets[target]

def gpio_on(pin):
    print("Turning on...")
    gpio.pinMode(pin, gpio.PINMODE_OUTPUT)
    gpio.digitalWrite(pin, gpio.LOW)

def gpio_off(pin):
    print("Turning off...")
    gpio.pinMode(pin, gpio.PINMODE_OUTPUT)
    gpio.digitalWrite(pin, gpio.HIGH)

def gpio_status(pin):
    #gpio.pinMode(pin, gpio.PINMODE_INPUT);
    gpio.pinMode(pin, gpio.PINMODE_OUTPUT)
    status = "off"
    if gpio.digitalRead(pin):
        status = "on"
    return "GPIO" + str(pin) + ": " + status

#    status = "on"
#    direction = GPIO.gpio_function(pin)
#
#    if (direction == GPIO.IN):
#        status = "off"
#    elif (direction == GPIO.OUT):
#        GPIO.setup(pin, GPIO.OUT)
#        if (GPIO.input(pin) == GPIO.HIGH):
#            status = "off"
#    else:
#        return "Unknown GPIO" + str(pin) + " function: " + str(direction)
#
#    return "GPIO" + str(pin) + ": " + status

def print_help():
    print("Usage: " + str(sys.argv[0]) + " <target> <command>")
    print("   target:  xu3, xu, u3, hc1")
    print("   command: on, off, restart, status")
    print("            (status can be run also without target)")
    sys.exit(2)

def status_all():
    for k, v in targets.items():
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
