## initramfs-odroid-armv7hf-base.cpio
Initramfs (with binaries) created on existing Arch ARM Linux system
(armv7hf architecture).  For sources please refer to [1] [2].

The initramfs was created with (from machine booted with modules present, e.g. from multi_v7 defconfig):
```
sudo pacman -S mkinitcpio-nfs-utils
sudo cp src-etc/initcpio/hooks/net_nfs4 /etc/initcpio/hooks/
sudo cp src-etc/initcpio/install/net_nfs4 /etc/install/hooks/

fakeroot mkinitcpio --kernel none --generate initramfs-odroid-armv7hf-base.cpio.gz \
    --config /opt/tools/buildbot/initramfs/src-etc/mkinitcpio.conf
mkdir tmpout
cd tmpout && ../cpio -idv < ../initramfs-odroid-armv7hf-base.cpio
rm -fr opt
fakeroot find -mindepth 1 -printf '%P\0' | LANG=C cpio -0 -o -H newc -R 0:0 -F "../initramfs-odroid-armv7hf-base.cpio"
cd ..
```

## initramfs-odroid-armv7hf-addons
Additional binaries taken from existing Arch ARM Linux system
(armv7hf architecture).  For sources please refer to [1] [2].


## src-etc
Configuration files for creating initramfs-odroid-armv7hf-base.cpio.


## Manual updates
```
mkdir tmpout
cd tmpout && cpio -idv < ../initramfs-odroid-armv7hf-base.cpio && cd ..
```
```
cd tmpout && fakeroot find -mindepth 1 -printf '%P\0' | LANG=C cpio -0 -o -H newc -R 0:0 -F "../initramfs-odroid-armv7hf-base.cpio" && cd ..
```

## References
* [1] https://github.com/archlinuxarm
* [2] https://archlinuxarm.org
