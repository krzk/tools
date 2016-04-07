#!/bin/bash

elementary_test -to animation
/usr/apps/com.samsung.dali-demo/bin/dali-demo
cat /proc/interrupts | grep -i mali
cat /sys/kernel/debug/pm_genpd/pm_genpd_summary

grep . /sys/kernel/debug/mali/*
grep . /sys/kernel/debug/mali/userspace_settings/*
cat /sys/kernel/debug/ump/memory_usage

