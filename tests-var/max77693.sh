#!/bin/bash

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t debugfs none /sys/kernel/debug

# regulator
cat /sys/kernel/debug/regulator/regulator_summary
ls -al /sys/kernel/debug/regulator/ | grep CHARGER
grep . /sys/class/regulator/regulator.40/*
grep . /sys/class/regulator/regulator.41/*
grep . /sys/class/regulator/regulator.42/*

sleep 5 && grep . /sys/class/regulator/regulator.42/* > /log.txt
cat /log.txt


echo "max77693-pmic" > /sys/bus/platform/drivers/max77693-pmic/unbind
echo "max77693-pmic" > /sys/bus/platform/drivers/max77693-pmic/bind

# charger
cat /sys/class/power_supply/max*/uevent
cat /sys/class/thermal/thermal_zone*/temp

ATTR=/sys/class/power_supply/max77693-charger/device/fast_charge_timer
test "`cat $ATTR`" = "4" || echo "ERROR: Wrong fast charge timer"
echo "2" > $ATTR && echo "ERROR: Should return EINVAL"
test "`cat $ATTR`" = "4" || echo "ERROR: Wrong fast charge timer"
echo "16" > $ATTR || echo "ERROR: Cannot set fast charge timer"
test "`cat $ATTR`" = "16" || echo "ERROR: Wrong fast charge timer"

ATTR=/sys/class/power_supply/max77693-charger/device/top_off_threshold_current
test "`cat $ATTR`" = "150000" || echo "ERROR: Wrong top_off_threshold_current"
echo "50000" > $ATTR && echo "ERROR: Should return EINVAL"
test "`cat $ATTR`" = "150000" || echo "ERROR: Wrong top_off_threshold_current"
echo "351000" > $ATTR && echo "ERROR: Should return EINVAL"
test "`cat $ATTR`" = "150000" || echo "ERROR: Wrong top_off_threshold_current"
for i in 100000 125000 150000 175000 200000 250000 300000 350000; do
  echo "Testing: $i"
  echo "$i" > $ATTR || echo "ERROR: Cannot set top_off_threshold_current $i"
  test "`cat $ATTR`" = "$i" || echo "ERROR: Wrong top_off_threshold_current $i"
done
echo "180000" > $ATTR || echo "ERROR: Cannot set top_off_threshold_current"
test "`cat $ATTR`" = "175000" || echo "ERROR: Wrong top_off_threshold_current"
echo "225000" > $ATTR || echo "ERROR: Cannot set top_off_threshold_current"
test "`cat $ATTR`" = "200000" || echo "ERROR: Wrong top_off_threshold_current"

ATTR=/sys/class/power_supply/max77693-charger/device/top_off_timer
test "`cat $ATTR`" = "30" || echo "ERROR: Wrong top_off_timer"
echo "71" > $ATTR && echo "ERROR: Should return EINVAL"
test "`cat $ATTR`" = "30" || echo "ERROR: Wrong top_off_timer"
for i in 0 10 20 30 40 50 60 70; do
  echo "Testing: $i"
  echo "$i" > $ATTR || echo "ERROR: Wrong top_off_timer $i"
  test "`cat $ATTR`" = "$i" || echo "ERROR: Wrong top_off_threshold_current $i"
done
echo "55" > $ATTR || echo "ERROR: Wrong top_off_timer"
test "`cat $ATTR`" = "50" || echo "ERROR: Wrong top_off_threshold_current $i"

echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/unbind
echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/bind
echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/unbind
echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/bind
echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/unbind
echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/bind
for i in `seq 1000`; do
  echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/unbind
  echo "max77693-charger" > /sys/bus/platform/drivers/max77693-charger/bind
done

sleep 5 && cat /sys/class/power_supply/max*/uevent > /log.txt
cat /log.txt

echo "file drivers/power/max77693_charger.c +p" > /sys/kernel/debug/dynamic_debug/control

# extcon
cat /sys/class/extcon/*/state
sleep 5 && cat /sys/class/extcon/max*-muic/state > /log.txt
cat /log.txt

# Max17047 fuel gauge
grep . /sys/class/power_supply/max170xx_battery/*
sleep 5 && grep . /sys/class/power_supply/max170xx_battery/* > /log.txt
cat /log.txt

ATTR=/sys/class/power_supply/max170xx_battery
test "`cat ${ATTR}/present`" = "1" || echo "ERROR: Wrong present"
test "`cat ${ATTR}/health`" = "Good" || echo "ERROR: Wrong health"
test "`cat ${ATTR}/temp_min`" = "-2147483648" || echo "ERROR: Wrong temp_min"
test "`cat ${ATTR}/temp_max`" = "700" || echo "ERROR: Wrong temp_max"
test "`cat ${ATTR}/voltage_min_design`" = "3120000" || echo "ERROR: Wrong voltage_min_design"

# TODO: initial value?
echo 300 > ${ATTR}/temp_alert_min
test "`cat ${ATTR}/temp_alert_min`" = "300" || echo "ERROR: Wrong temp_alert_min"
echo 0 > ${ATTR}/temp_alert_min
test "`cat ${ATTR}/temp_alert_min`" = "0" || echo "ERROR: Wrong temp_alert_min"

echo 200 > ${ATTR}/temp_alert_max
test "`cat ${ATTR}/temp_alert_max`" = "200" || echo "ERROR: Wrong temp_alert_max"
echo 700 > ${ATTR}/temp_alert_max
test "`cat ${ATTR}/temp_alert_max`" = "700" || echo "ERROR: Wrong temp_alert_max"

# Input/haptic, Trats2
test "`grep max77693_haptic /sys/kernel/debug/pwm | grep requested | wc -l`" = "1" || echo "ERROR: No max77693 pwm haptic"
test "`cat /sys/class/input/input0/uevent | grep NAME`" = 'NAME="max77693-haptic"' || echo "ERROR: Wrong input0 uevent name"
 ./fftest /dev/input/event0

# Input/haptic, max77843
test "`grep haptic /sys/kernel/debug/pwm | grep requested | wc -l`" = "1" || echo "ERROR: No pwm haptic"
test "`cat /sys/class/input/input2/uevent | grep NAME`" = 'NAME="max77693-haptic"' || echo "ERROR: Wrong input uevent name"
./fftest /dev/input/event2
