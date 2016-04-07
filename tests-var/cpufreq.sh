#!/bin/bash

grep . /sys/devices/system/cpu/cpu0/cpufreq/*

# test_cat file expected
test_cat() {
  local val="$(cat $1)"
  test "$val" = "$2" || echo "ERROR: Wrong $1 ($val)"
}
CPUFREQ="/sys/devices/system/cpu/cpu0/cpufreq"
# Trats2
test_cat ${CPUFREQ}/affected_cpus "0 1 2 3"
test_cat ${CPUFREQ}/cpuinfo_max_freq 1400000
test_cat ${CPUFREQ}/cpuinfo_min_freq 200000
test_cat ${CPUFREQ}/related_cpus "0 1 2 3"
test_cat ${CPUFREQ}/scaling_driver cpufreq-dt
test_cat ${CPUFREQ}/scaling_max_freq 1400000
test_cat ${CPUFREQ}/scaling_min_freq 200000
test_cat ${CPUFREQ}/scaling_available_governors "ondemand performance "
echo "performance" > ${CPUFREQ}/scaling_governor
test_cat ${CPUFREQ}/scaling_governor performance
test_cat ${CPUFREQ}/cpuinfo_cur_freq 1400000
test_cat ${CPUFREQ}/scaling_cur_freq 1400000
echo "ondemand" > ${CPUFREQ}/scaling_governor
test_cat ${CPUFREQ}/scaling_governor ondemand
test_cat ${CPUFREQ}/cpuinfo_cur_freq 200000
test_cat ${CPUFREQ}/scaling_cur_freq 200000
