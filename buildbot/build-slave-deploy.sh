#!/bin/bash
#
# Copyright (c) 2015-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

set -e -E
# Be verbose for Buildbot debugging
set -x

test $# -gt 1 || die "Wrong number of parameters"

TARGET="$1"
NAME="$2"
REVISION="$3"
TOOLS_DIR="/opt/tools"

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

# Contents of /srv/tftp should be:
# - writeable and chmod/chown by buildbot: buildbot as owner
# - writeable by kozik (over SSH): kozik in buildbot group
# - readable by tftp: a+r
chown -R buildbot:buildbot /srv/tftp
chmod -R g+rw,a+r /srv/tftp

MODULES_DEST_DIR="/srv/nfs/${TARGET}/lib/modules/"
echo "Installing modules to $MODULES_DEST_DIR"
test -d "$MODULES_DEST_DIR" || die "Destination modules dir '$MODULES_DEST_DIR' does not exist"
rm -fr "${MODULES_DEST_DIR}/${KERNEL_NAME}"
cp -r "lib/modules/${KERNEL_NAME}" "$MODULES_DEST_DIR"

exit $?
