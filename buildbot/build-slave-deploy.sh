#!/bin/bash
#
# Copyright (c) 2015-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

. $(dirname ${BASH_SOURCE[0]})/inc-build-slave.sh

set -e -E
# Be verbose for Buildbot debugging
set -x

test $# -eq 4 || die "Wrong number of parameters"

TARGET="$1"
NAME="$2"
REVISION="$3"
MODULES_TMP="$4"
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
rm -fr $MODULES_TMP
mkdir -p $MODULES_TMP
tar -xzf deploy-modules-out.tar.gz -C $MODULES_TMP
# Be sure that there are no symlinks
find ${MODULES_TMP}/lib/modules/ -type 'l' -delete
chmod -R a+r ${MODULES_TMP}/
find ${MODULES_TMP}/lib/modules/ -type 'd' -exec chmod a+x '{}' \;

# Prepare initrd:
KERNEL_NAME=$(ls ${MODULES_TMP}/lib/modules)
test -d "${MODULES_TMP}/lib/modules/${KERNEL_NAME}" || die "Cannot get kernel name. Got: $KERNEL_NAME"
echo "Got kernel name: $KERNEL_NAME"

echo "Making initramfs and image"
make-initramfs.sh ${TOOLS_DIR}/buildbot/initramfs/initramfs-odroid-armv7hf-base.cpio \
		  $MODULES_TMP \
		  ${TOOLS_DIR}/buildbot/initramfs/initramfs-odroid-armv7hf-addons \
		  /srv/tftp/uboot-initramfs-odroidxu3.img
#mkinitcpio --moduleroot . --kernel "${KERNEL_NAME}" \
#	--generate initramfs-odroidxu3.img \
#	--config ${TOOLS_DIR}/buildbot/${NAME}/mkinitcpio.conf
#
#mkimage -n "U-boot Odroid XU3 ramdisk" -A arm -O linux -T ramdisk -C gzip \
#	-d initramfs-odroidxu3.img /srv/tftp/uboot-initramfs-odroidxu3.img

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
cp -r "${MODULES_TMP}/lib/modules/${KERNEL_NAME}" "$MODULES_DEST_DIR"
chown -R buildbot:buildbot "${MODULES_DEST_DIR}/${KERNEL_NAME}"
chmod -R g+rw,a+r "${MODULES_DEST_DIR}/${KERNEL_NAME}"

exit $?
