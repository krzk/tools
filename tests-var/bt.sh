#!/bin/bash

# test_cat file expected
test_cat() {
	local val="$(cat $1)"
	test "$val" = "$2" || echo "ERROR: Wrong $1 ($val)"
}

RFKILL="/sys/class/rfkill/rfkill0"
grep . ${RFKILL}/*

test_cat ${RFKILL}/hard "0"
test_cat ${RFKILL}/index "0"
test_cat ${RFKILL}/name "bcm4334-bt"
test_cat ${RFKILL}/persistent "1"
test_cat ${RFKILL}/soft "1"
test_cat ${RFKILL}/state "0"
test_cat ${RFKILL}/type "bluetooth"

rfkill unblock "bluetooth"

test_cat ${RFKILL}/hard "0"
test_cat ${RFKILL}/soft "0"

test "$(rfkill list | wc -l)" = "3" || echo "ERROR: Wrong rfkill list"

/usr/bin/setbd || echo "ERROR: setbd fail"
/usr/sbin/rfkill unblock bluetooth
/usr/bin/bcmtool_4330b1 /dev/ttySAC0 -FILE=/usr/etc/bluetooth/BCM4334W_001.002.003.0997.1027_B58_ePA.hcd -BAUD=3000000 -ADDR=/csa/bluetooth/.bd_addr -SETSCO=0,0,0,0,0,0,0,3,3,0 -LP

/usr/bin/hcitool dev | grep hci0
test "$(/usr/bin/hcitool dev | wc -l)" = "2" || echo "ERROR: /usr/bin/hcitool dev"

/usr/bin/hciconfig features
test "$(/usr/bin/hciconfig features | grep hci0 | wc -l)" = "1" || echo "ERROR: /usr/bin/hciconfig features"
test "$(/usr/bin/hciconfig features | grep "UP RUNNING" | wc -l)" = "1" || echo "ERROR: /usr/bin/hciconfig features"

/usr/bin/hcitool scan
/usr/sbin/rfkill block bluetooth
