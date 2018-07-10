# initramfs-odroid-armv7hf-base.cpio
Initramfs (with binaries) created on existing Arch ARM Linux system
(armv7hf architecture).  For sources please refer to [1] [2].

The initramfs was created with:
```
sudo pacman -S mkinitcpio-nfs-utils

fakeroot mkinitcpio --kernel none --generate initramfs-odroid-armv7hf-base.cpio.gz \
    --config /opt/tools/buildbot/initramfs/src-etc/mkinitcpio.conf
```

# initramfs-odroid-armv7hf-addons
Additional binaries taken from existing Arch ARM Linux system
(armv7hf architecture).  For sources please refer to [1] [2].


# src-etc
Configuration files for creating initramfs-odroid-armv7hf-base.cpio.


# References
[1] https://github.com/archlinuxarm
[2] https://archlinuxarm.org
