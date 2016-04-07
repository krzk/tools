#!/bin/bash

cat /sys/class/power_supply/AC/uevent
cat /sys/class/power_supply/AC/online
acpi -a
