#!/bin/bash
#
# Copyright (c) 2015 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

set -e -E

test $# -gt 1 || die "Wrong number of parameters"

TARGET="$1"
NAME="$2"
REVISION="$3"
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

# Test for clean environment:
test -d lib && die "Not clean: 'lib' present"
test -f initramfs-odroidxu3.img && die "Not clean: 'initramfs-odroidxu3.img' present"
# REVISION not used actually
#test -d "/tmp/modules-buildslave/${NAME}-${REVISION}" && die "Not clean: '/tmp/modules-buildslave/${NAME}-${REVISION}' present"

umask 022

# Unpack downloaded modules:
echo "Unpacking modules..."
tar -xzf deploy-modules-out.tar.gz
# Be sure that there are no symlinks
find lib/modules/ -type 'l' -delete
chmod -R a+r lib/modules/
find lib/modules/ -type 'd' -exec chmod a+x '{}' \;

# Prepare initrd:
KERNEL_NAME=$(ls lib/modules)
test -d "lib/modules/${KERNEL_NAME}" || die "Cannot get kernel name. Got: $KERNEL_NAME"
echo "Got kernel name: $KERNEL_NAME"

echo "Making initramfs and image"
mkinitcpio --moduleroot . --kernel "${KERNEL_NAME}" \
	--generate initramfs-odroidxu3.img \
	--config ${TOOLS_DIR}/buildbot/${NAME}/mkinitcpio.conf

mkimage -n "U-boot Odroid XU3 ramdisk" -A arm -O linux -T ramdisk -C gzip \
	-d initramfs-odroidxu3.img /srv/tftp/uboot-initramfs-odroidxu3.img

chgrp -R tftp /srv/tftp/*
chmod -R a+r /srv/tftp/uboot-initramfs-odroidxu3.img
chmod -R g+w /srv/tftp/*

# Prepare modules:
# TODO cron modules cleanup jobe from odroid to pi

MODULES_DEST_DIR="/srv/nfs/${TARGET}/lib/modules/"
echo "Installing modules to $MODULES_DEST_DIR"
test -d "$MODULES_DEST_DIR" || die "Destination modules dir '$MODULES_DEST_DIR' does not exist"
rm -fr "${MODULES_DEST_DIR}/${KERNEL_NAME}"
cp -r "lib/modules/${KERNEL_NAME}" "$MODULES_DEST_DIR"

exit $?
