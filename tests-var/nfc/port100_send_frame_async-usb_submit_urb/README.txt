Source:
https://syzkaller.appspot.com/bug?extid=dbec6695a6565a9c6bc0

Converted from:
https://syzkaller.appspot.com/text?tag=ReproSyz&x=17c607f1500000

Conversion command:
syz-prog2c -prog repro.txt -sandbox=none -enable="binfmt_misc,cgroups,close_fds,net_dev,net_reset,sysctl,tun,usb,vhci,wifi" -threaded -repeat 0 -procs=8 -segv -tmpdir
