# Boot with:
setenv opts s3c2410_wdt.soft_noboot=1
# Then kill wd:
sudo killall -9 watchdog
# Wait for timer expire
