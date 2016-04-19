#!/bin/bash

# Disable: CRYPTO_MANAGER_DISABLE_TESTS
# Module: CRYPTO_TEST

cat /proc/crypto
dmesg | grep alg
dmesg | grep s5p

sudo modprobe tcrypt sec=1 mode=500
