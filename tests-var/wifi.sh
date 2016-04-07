#!/bin/bash

/sbin/rfkill unblock wlan
echo mem > /sys/power/state

cat << EOF > /lib/firmware/wpa_supplicant.conf
#ctrl_interface=wlan0
ctrl_interface=/var/run/wpa_supplicant
eapol_version=1
ap_scan=1
fast_reauth=1
EOF

/usr/sbin/wpa_supplicant -t -B -ddd -Dnl80211 -iwlan0 -c/lib/firmware/wpa_supplicant.conf

wpa_cli scan
wpa_cli scan_result
killall wpa_supplicant

rfkill block wlan


#Stress test
RTC=rtc1
/sbin/hwclock -w -f /dev/$RTC

test_suspend() {
  wpa_cli scan
  sleep 3
  wpa_cli scan_result
  sleep 3
  rtcwake -d $RTC -m mem -s 5 -v
  sleep 5
}

killall wpa_supplicant
for i in `seq 100`; do
  echo "#########################################################"
  echo "ROUND $i"
  /sbin/rfkill unblock wlan
  sleep 2
  /usr/sbin/wpa_supplicant -t -B -d -Dnl80211 -iwlan0 -c/lib/firmware/wpa_supplicant.conf
  sleep 2
  for j in `seq 10`; do
    test_suspend
  done
  sleep 10
  killall wpa_supplicant
  sleep 1
  rfkill block wlan
  sleep 2
  echo "#########################################################"
done

