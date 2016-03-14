#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

die() {
	echo "Fail: $1"
	exit 1
}

set -e -E

test $# -gt 1 || die "Wrong number of parameters"

TARGET="$1"
NAME="$2"
REVISION="$3"
MODULES_DIR="~/modules-install"
TOOLS_DIR="/opt/tools"

# On arch ping6 and ping were merged so '-4' and '-6' arguments are supported.
# However on pi, the IPv6 is disabled and running just 'ping' causes error:
# ping: socket: Address family not supported by protocol (raw socket required by specified options).
# Detect if '-4' is supported, if it is, then use it
get_ping() {
	ping -h |& grep vV64 > /dev/null
	if [ $? -eq 0 ]; then
		echo 'ping -4'
	else
		echo 'ping'
	fi
}

echo "Deploying ${NAME}/${REVISION} to $TARGET"

test -d lib && die "Not clean: 'lib' present"
test -f initramfs-odroidxu3.img && die "Not clean: 'initramfs-odroidxu3.img' present"
# REVISION not used actually
#test -d "/tmp/modules-buildslave/${NAME}-${REVISION}" && die "Not clean: '/tmp/modules-buildslave/${NAME}-${REVISION}' present"

umask 022

echo "Unpacking modules..."
tar -xzf deploy-modules-out.tar.gz
# Be sure that there are no symlinks
find lib/modules/ -type 'l' -delete
chmod -R a+r lib/modules/
find lib/modules/ -type 'd' -exec chmod a+x '{}' \;

KERNEL_NAME=$(ls lib/modules)
MODULES_DEST_DIR="${MODULES_DIR}/${KERNEL_NAME}"
test -d "lib/modules/${KERNEL_NAME}" || die "Cannot get kernel name. Got: $KERNEL_NAME"
echo "Got kernel name: $KERNEL_NAME"

echo "Making initramfs and image"
mkinitcpio --moduleroot . --kernel "${KERNEL_NAME}" \
	--generate initramfs-odroidxu3.img \
	--config ${TOOLS_DIR}/buildbot/${NAME}/mkinitcpio.conf

mkimage -n "U-boot Odroid XU3 ramdisk" -A arm -O linux -T ramdisk -C gzip \
	-d initramfs-odroidxu3.img /srv/tftp/uboot-initramfs-odroidxu3.img

#cp -r "lib/modules/${KERNEL_NAME}" /srv/nfs/modules-odroidxu3/

chgrp -R tftp /srv/tftp/zImage /srv/tftp/exynos5422-odroidxu3-lite.dtb /srv/tftp/uboot-initramfs-odroidxu3.img /srv/tftp/*
chmod -R a+r /srv/tftp/uboot-initramfs-odroidxu3.img
chmod -R g+w /srv/tftp/*

echo "Deploying modules to $TARGET"
# These may fail because target being offline
set +e +E
$(get_ping) -c 1 -W 3 $TARGET > /dev/null
if [ $? -eq 1 ]; then
	echo "$TARGET is offline, modules won't be installed"
	exit 0
fi

ssh "$TARGET" rm -fr "$MODULES_DIR"
ssh "$TARGET" mkdir -p "$MODULES_DEST_DIR"
ssh "$TARGET" rm -fr "${MODULES_DEST_DIR}"
scp -r "lib/modules/${KERNEL_NAME}" "${TARGET}:${MODULES_DEST_DIR}"
ssh "$TARGET" sudo ${TOOLS_DIR}/buildbot/build-slave-install-modules.sh "$KERNEL_NAME"

exit $?
