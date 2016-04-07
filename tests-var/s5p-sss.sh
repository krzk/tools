#!/bin/bash

cat /proc/crypto
dmesg | grep alg
dmesg | grep s5p

sudo modprobe tcrypt sec=1 mode=500