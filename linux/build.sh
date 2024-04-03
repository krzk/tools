#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2023 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#
# Script for building kernel images for several platforms.
#

die() {
	echo "Fail: $1"
	exit 1
}

usage() {
	echo "Usage: $(basename $0) [options] [-c config_name] [-d dts_name]"
	echo
	echo " Build and package kernel."
	echo
	echo " Config and DTS options:"
	echo " -c <config_name> - Optional name of defconfig to use."
	echo "                    If specified then it will overwrite current '.config'."
	echo "                    If skipped then only olddefconfig is called."
	echo " -d <dts_name>    - Optional DTS to build and append."
	echo " -D <options>     - Disable these config options (comma separated"
	echo "                    list of options without the CONFIG_ prefix)"
	echo " -E <options>     - Enable these config options (comma separated"
	echo "                    list of options without the CONFIG_ prefix)"
	echo " -M <options>     - Enable as modules these config options (comma"
	echo "                    separated list of options without the CONFIG_ prefix)"
	echo " -S <set>         - Run a specific config set."
	echo "                    Valid sets: crypto, tests, buildbot, qcom, qemutest, nfc"
	echo
	echo " Build options:"
	echo " -A <arch>        - Build for architecture, one of:"
	echo "                    alpha, arm, arm64 (default), i386, m68k, mips,"
	echo "                    parisc, powerpc, riscv, s390, sh, sparc, um, x86_64"
	echo "                    Or any other arch with cross-compile set environment"
	echo "                    Use a suitable config for chosen architecture"
	echo " -b <baseramdisk> - Base ramdisk for certain images. Ignored with -R".
	echo " -C               - Run standard kernel checks (checkstack,"
	echo "                    namespacecheck, includecheck, headers_check,"
	echo "                    coccicheck)"
	echo " -I <image_type>  - Make image type for: arch, arndale, e850, qcom, qcom2"
	echo "                    qcom - creates boot image with ramdisk including the modules"
	echo "                           and ramdisk source (${RAMDISK_SRC}), see also -b"
	echo "                    By default images are not created, only build is performed."
	echo " -j <jobs>        - Number of make jobs."
	echo "                    Default: number of processors from /proc/cpuinfo"
	echo " -k               - Disable out-of-tree build (KBUILD_OUTPUT)"
	echo " -l <cmdline>     - Append command line (some images might have default,"
	echo "                    so this only appends)"
	echo " -r <cross cc>    - Set custom cross compiler, examples:"
	echo "                    mips64-linux-gnuabi64-, powerpc64-linux-gnu-, hppa64-linux-gnu-"
	echo " -R <ramdisk>     - Path to ramdisk for certain images."
	echo "                    Default is empty and image might create its own ramdisk."
	echo "                    Overrules -b."
	echo " -s <tool_path>   - run checks (C=1) with given tool (path to Smatch, "
	echo "                    Sparse binary, scripts/coccicheck or special target"
	echo "                    from list below), e.g.:"
	echo "                    -s /opt/smatch/smatch"
	echo " -t <target>      - Run this target (instead of config+build+dtbs), e.g."
	echo "                    dtbs_check, dt_binding_check"
	echo "                    dtbs_check will be run with PATH=\$PATH:/home/\$USER/.local/bin"
	echo " -m <path>        - Install modules into <path>. Set as empty \"\" to skip."
	echo "                    Default: modules-out (under KBUILD_OUTPUT, so: ${KBUILD_OUTPUT}modules-out)"
	echo "                    Can be absolute or relative to current"
	echo "                    KBUILD_OUTPUT (${KBUILD_OUTPUT})"
	echo
	echo " -e <address>     - Load and entry address for kernel for uimage (in hex)."
	echo "                    Default: 0x41008000"
	echo " -h               - print help"
	echo
	echo "Examples:"
	echo "  $(basename $0) -A arm -c exynos"
	echo "  $(basename $0) -c defconfig"
	echo "  $(basename $0) -c defconfig -d qcom/sdm845-mtp -I qcom"
	echo "  $(basename $0) -A alpha -c defconfig"
	echo "  $(basename $0) -A i386 -c i386"
	echo "  $(basename $0) -A m68k -c defconfig"
	echo "  $(basename $0) -A mips -c defconfig"
	echo "  $(basename $0) -A mips -r mips64-linux-gnuabi64- -c defconfig"
	echo "  $(basename $0) -A parisc -c defconfig"
	echo "  $(basename $0) -A parisc -r hppa64-linux-gnu- -c defconfig"
	echo "  $(basename $0) -A powerpc -c defconfig"
	echo "  $(basename $0) -A powerpc -r powerpc64-linux-gnu- -c defconfig"
	echo "  $(basename $0) -A riscv -c defconfig"
	echo "  $(basename $0) -A s390 -c defconfig"
	echo "  $(basename $0) -A sh -c defconfig"
	echo "  $(basename $0) -A sparc -c defconfig"
	echo "  $(basename $0) -A um -c defconfig"
	echo "  $(basename $0) -A x86_64 -c x86_64"
	exit 2
}

have_ccache() {
	which ccache > /dev/null
	echo $?
}

have_eatmydata() {
	which eatmydata > /dev/null
	echo $?
}

TEST_CONFIG=""
CHECK_CMD=""
TARGET=""
DTS_NAME=""
CONFIG_NAME=""
ARCH="arm64"
STD_CHECKS=0
LOAD_ADDRESS="0x41008000"
ENABLE_CONFIG_ITEMS=""
MODULE_CONFIG_ITEMS=""
DISABLE_CONFIG_ITEMS=""
CHOSEN_IMAGE=""
JOBS="-j$(nproc)"
KBUILD_OUTPUT="out/"
CROSS_COMPILE=""
CMDLINE=""
MODULES_INSTALL_PATH="modules-out"
RAMDISK=""
RAMDISK_SRC="${HOME}/etc/boards/initramfs/arm64-rootfs/initramfs-qemuarm64-krzk.cpio"

while getopts "Chkl:t:S:s:p:c:d:A:b:E:e:D:M:j:I:r:R:m:" flag
do
	case "$flag" in
		S)
			TEST_CONFIG="$OPTARG"
			;;
		s)
			CHECK_CMD="$OPTARG"
			if [[ "$CHECK_CMD" == *smatch ]]; then
				CHECK_CMD+=" -p=kernel"
			fi
			;;
		t)
			TARGET="$OPTARG"
			;;
		d)
			DTS_NAME="$OPTARG"
			;;
		c)
			CONFIG_NAME="$OPTARG"
			;;
		A)
			ARCH="$OPTARG"
			;;
		b)
			RAMDISK_SRC=`realpath "$OPTARG"`
			;;
		C)
			STD_CHECKS=1
			;;
		e)
			LOAD_ADDRESS="$OPTARG"
			;;
		E)
			ENABLE_CONFIG_ITEMS="$OPTARG"
			;;
		M)
			MODULE_CONFIG_ITEMS="$OPTARG"
			;;
		D)
			DISABLE_CONFIG_ITEMS="$OPTARG"
			;;
		I)
			CHOSEN_IMAGE="$OPTARG"
			;;
		j)
			JOBS="-j${OPTARG}"
			;;
		r)
			CROSS_COMPILE="$OPTARG"
			;;
		R)
			RAMDISK="$OPTARG"
			;;
		k)
			KBUILD_OUTPUT=""
			;;
		l)
			CMDLINE="$OPTARG"
			;;
		m)
			MODULES_INSTALL_PATH="$OPTARG"
			;;
		h)
			usage
			;;
		*)
			usage
			;;
	esac
done

get_default_image_name() {
	case "$ARCH" in
	arm)
		echo "zImage"
		;;
	arm64)
		echo "Image"
		;;
	i386|x86_64)
		echo "bzImage"
		;;
	mips)
		echo "vmlinux"
		;;
	esac
	echo ""
}

get_image_name() {
	local image_name="$(make -s image_name)"
	if [ $? -ne 0 ]; then
		image_name="$(get_default_image_name)"
	fi

	test "$ARCH" = "mips" && image_name="${image_name}.bin.gz"
	echo "$image_name"
}

# Select proper architecture and set cross compile settings
test "$ARCH" = "alpha" -o "$ARCH" = "arm" -o "$ARCH" = "arm64" -o \
	"$ARCH" = "i386" -o \
	"$ARCH" = "m68k" -o  "$ARCH" = "mips" -o  "$ARCH" = "parisc" -o \
	"$ARCH" = "powerpc" -o  "$ARCH" = "riscv" -o  "$ARCH" = "s390" -o \
	"$ARCH" = "sh" -o  "$ARCH" = "sparc" -o  "$ARCH" = "um" -o \
	"$ARCH" = "x86_64" \
	|| echo "Unknown architecture '$ARCH'"
export ARCH
ARCH_DIR="$ARCH"
ARCH_MKIMAGE="$ARCH"
ARCH_BOOT_IMAGE_DIR="arch/${ARCH_DIR}/boot/"
if [ -n "$CROSS_COMPILE" ]; then
	export CROSS_COMPILE
elif [ "$ARCH" = "alpha" ]; then
	export CROSS_COMPILE="alpha-linux-gnu-"
elif [ "$ARCH" = "arm" ]; then
	export CROSS_COMPILE="arm-linux-gnueabi-"
elif [ "$ARCH" = "arm64" ]; then
	export CROSS_COMPILE="aarch64-linux-gnu-"
elif [ "$ARCH" = "m68k" ]; then
	export CROSS_COMPILE="m68k-linux-gnu-"
elif [ "$ARCH" = "mips" ]; then
	export CROSS_COMPILE="mips-linux-gnu-"
elif [ "$ARCH" = "parisc" ]; then
	export CROSS_COMPILE="hppa-linux-gnu-"
elif [ "$ARCH" = "powerpc" ]; then
	export CROSS_COMPILE="powerpc-linux-gnu-"
elif [ "$ARCH" = "riscv" ]; then
	export CROSS_COMPILE="riscv64-linux-gnu-"
elif [ "$ARCH" = "s390" ]; then
	export CROSS_COMPILE="s390x-linux-gnu-"
elif [ "$ARCH" = "sh" ]; then
	export CROSS_COMPILE="sh4-linux-gnu-"
elif [ "$ARCH" = "sparc" ]; then
	export CROSS_COMPILE="sparc64-linux-gnu-"
elif [ "$ARCH" = "um" ]; then
	# nothing
	ARCH_BOOT_IMAGE_DIR=""
else
	# i386, x86_64
	ARCH_DIR="x86"
	ARCH_MKIMAGE="x86"
fi

# Test for image to create
test -z "$CHOSEN_IMAGE" -o "$CHOSEN_IMAGE" = "arch" \
	-o "$CHOSEN_IMAGE" = "arndale" \
	-o "$CHOSEN_IMAGE" = "qcom" \
	-o "$CHOSEN_IMAGE" = "qcom2" \
	-o "$CHOSEN_IMAGE" = "e850" \
	|| die "Wrong image to create '$CHOSEN_IMAGE'"

# Test for config
if [ -n "$CONFIG_NAME" ]; then
	if [ -f "arch/${ARCH_DIR}/configs/${CONFIG_NAME}_defconfig" ]; then
		CONFIG_NAME="${CONFIG_NAME}_defconfig"
	elif [[ ! "$CONFIG_NAME" =~ config$ ]]; then
		die "Wrong config provided: $CONFIG_NAME"
	fi
else
	echo "Missing config_name parameter, making olddefconfig"
fi

# Test for valid DTS
if [ -n "$DTS_NAME" ]; then
	test -f "arch/${ARCH_DIR}/boot/dts/${DTS_NAME}.dts" \
		|| die "File 'arch/${ARCH_DIR}/boot/dts/${DTS_NAME}.dts' does not exist"
else
	# Certain images require DTS
	test "$CHOSEN_IMAGE" = "qcom" -o "$CHOSEN_IMAGE" = "qcom2" \
		-o "$CHOSEN_IMAGE" = "e850" \
		&& die "Image '$CHOSEN_IMAGE' requires dts_name"
	echo "Missing dts_name parameter, ignoring DTS"
fi

if [ -n "$KBUILD_OUTPUT" ]; then
	export KBUILD_OUTPUT
fi

if [ "$TARGET" == "dtbs_check" ] || [ "$TARGET" == "dt_binding_check" ]; then
	PATH="${PATH}:/home/${USER}/.local/bin"
	export PATH
fi

MAKE="make"
if [ "$(have_eatmydata)" == "0" ]; then
	MAKE="eatmydata make"
fi
RAMDISK_TMP=""

# End of most of environment... except the one depending on make
# Pre-config for the next 'make' commands (they need initial config
# and the sources could have changed).
$MAKE olddefconfig $JOBS || echo "Make olddefconfig error"

IMAGE_NAME="$(get_image_name)"
# On most of architectures (x86, arm, arm64) "make image_name" produces full path
IMAGE_NAME="$(basename $IMAGE_NAME)"
IMAGE_PATH="${KBUILD_OUTPUT}${ARCH_BOOT_IMAGE_DIR}${IMAGE_NAME}"
if [ -z "$RAMDISK" ]; then
	RAMDISK_PATH=""
else
	RAMDISK_PATH="$RAMDISK"
fi

IMAGE_OUT_PATH="${KBUILD_OUTPUT}${IMAGE_NAME}"
test -n "$IMAGE_PATH" || die "Error getting kernel image path"
test -n "$IMAGE_NAME" || die "Error getting kernel image name"

if [ "$CHOSEN_IMAGE" == "arch" ]; then
	KERNEL_RELEASE=`$MAKE -s kernelrelease` || die "make kernelrelease error"
	KERNEL_VERSION=`git describe` || die "git describe error"
	test -n "$KERNEL_RELEASE" || die "Error getting kernel release"
fi

# End of environment set up
# Functions:
tmp_cleanup() {
	echo "Exit trap, cleaning up tmp..."
	test -n "$RAMDISK_TMP" && rm -fr "$RAMDISK_TMP"
}

make_dtbs() {
	$MAKE dtbs $JOBS || die "Make dtbs error"
	return 0
}

# Usage: build_dts dts_name
build_dts() {
	local _dts_name="$1"
	if [ -z "$_dts_name" ]; then
		test "$ARCH" = "arm" -o "$ARCH" = "arm64" || return 0
		make_dtbs
		return 0
	fi

	rm -f "${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb"
	make_dtbs
	if [ ! -f "${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb" ]; then
		$MAKE ${_dts_name}.dtb $JOBS || die "Make ${_dts_name}.dtb error"
	fi
}

# Usage: append_dtb dts_name
append_dtb() {
	local _dts_name="$1"

	echo

	# Just copy if DTS was not set
	if [ -z "$_dts_name" ]; then
		if [ "${IMAGE_PATH}" != "${IMAGE_OUT_PATH}" ]; then
			cp "${IMAGE_PATH}" "${IMAGE_OUT_PATH}" \
				|| die "cp ${IMAGE_PATH} failed"
		fi
		return 0
	fi

	if [ -f "${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb" ]; then
		echo Size of ${IMAGE_NAME} before appending dtb: `stat ${IMAGE_PATH} -c %s` bytes.
		echo "Appending DTS: ${IMAGE_PATH} ${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb"
		echo "   to: $IMAGE_OUT_PATH"

		cat ${IMAGE_PATH} ${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb \
			> ${IMAGE_OUT_PATH} || die "DTB append error"

		echo Size of ${IMAGE_NAME} after appending dtb: `stat ${IMAGE_OUT_PATH} -c %s` bytes.
	else
		echo "Wanted DTS but couldn't find one to append".
		echo "Wanted: ${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb"
	fi
}

run_standard_checks() {
	echo "#################################"
	echo "CHECK: checkstack"
	echo "#################################"
	$MAKE checkstack

	echo "#################################"
	echo "CHECK: namespacecheck"
	echo "#################################"
	$MAKE namespacecheck

	echo "#################################"
	echo "CHECK: includecheck"
	echo "#################################"
	$MAKE includecheck

	echo "#################################"
	echo "CHECK: headers_check"
	echo "#################################"
	$MAKE headers_check

	echo "#################################"
	echo "CHECK: coccicheck"
	echo "#################################"
	$MAKE coccicheck MODE=report
}

make_image_arch() {
	cp $IMAGE_OUT_PATH ${KBUILD_OUTPUT}vmlinuz-${KERNEL_VERSION}
	cp ${KBUILD_OUTPUT}System.map ${KBUILD_OUTPUT}System.map-${KERNEL_VERSION}
}

ls_image_arch() {
	echo
	echo "#################################"
	echo
	echo "Arch files:"
	echo "    ${KBUILD_OUTPUT}vmlinuz-${KERNEL_VERSION}"
	echo "    ${KBUILD_OUTPUT}System.map-${KERNEL_VERSION}"
	echo "Arch install:"
	echo "    make KBUILD_OUTPUT=${KBUILD_OUTPUT} INSTALL_MOD_STRIP=1 $JOBS modules_install"
	echo "    cp ${KBUILD_OUTPUT}vmlinuz-${KERNEL_VERSION} ${KBUILD_OUTPUT}System.map-${KERNEL_VERSION} /boot"
	echo "    mkinitcpio -k $KERNEL_RELEASE -c /etc/mkinitcpio.conf -g /boot/initramfs-${KERNEL_VERSION}.img"
	echo "    grub-mkconfig -o /boot/grub/grub.cfg"
}

make_image_arndale() {
	local _dts_name="$1"

	append_dtb "$_dts_name"
	mkimage -A $ARCH_MKIMAGE -O linux -C none -T kernel -a 0x20008000 -e 0x20008000 \
	       -d ${IMAGE_OUT_PATH} ${KBUILD_OUTPUT}uImage
}

ls_image_arndale() {
	echo
	echo "#################################"
	echo

	echo "Arndale U-Boot image:	$(ls -lh ${KBUILD_OUTPUT}uImage)"
}

make_ramdisk() {
	local ramdisk_out="${KBUILD_OUTPUT}ramdisk-modules.cpio"
	local ramdisk_compress_fmt="gz"
	local ramdisk_compress_cmd="gzip"
	local workdir="$(pwd)"

	if [ -z "$RAMDISK" ]; then
		echo "Making ramdisk based on ${RAMDISK_SRC} ..."
		test -d "$workdir" || die "Cannot get workdir"
		test -f "$RAMDISK_SRC" || die "Ramdisk source '$RAMDISK_SRC' not valid"

		rm -f "$ramdisk_out" "${ramdisk_out}.${ramdisk_compress_fmt}"

		test -n "$MODULES_INSTALL_PATH" && make_modules_install
		RAMDISK_TMP="$(mktemp -d)" || die "mkdir tmp directory for ramdisk error"

		(
			set -e -E
			local modules_src_path="${workdir}/${KBUILD_OUTPUT}${MODULES_INSTALL_PATH}/lib/modules"

			cd "$RAMDISK_TMP"
			cpio -idm --quiet < "${RAMDISK_SRC}"
			echo "Installing modules to ramdisk ($(du -sh ${modules_src_path} | awk '{print $1}'))"
			cp -r ${modules_src_path} ./lib/
			echo "Packing ramdisk ($(du -sh . | awk '{print $1}'))"
			find . 2>/dev/null | LANG=C cpio -o -H newc -R root:root --quiet > "${workdir}/${ramdisk_out}"
		) || die "Make new initramfs with modules error"
		$ramdisk_compress_cmd "$ramdisk_out" || die "$ramdisk_compress_cmd $ramdisk_out error"
		RAMDISK_PATH="${ramdisk_out}.${ramdisk_compress_fmt}"
		echo "Ramdisk $RAMDISK_PATH done ($(du -sh $RAMDISK_PATH | awk '{print $1}'))"
	else
		echo "Using existing ramdisk $RAMDISK ..."
	fi
}

make_image_qcom() {
	local _dts_name="$1"
	# copy_modules requires rw mount (no "ro")
	local cmdline="earlycon console=ttyMSM0,115200n8 root=PARTLABEL=rootfs rootwait=2 init=/sbin/init copy_modules"

	append_dtb "$_dts_name"
	make_ramdisk

	# Some targets might require: --header_version 2
	cmdline="$cmdline $CMDLINE"
	echo "Making kernel image with cmdline: $cmdline"
	mkbootimg --kernel ${IMAGE_OUT_PATH} \
		--ramdisk ${RAMDISK_PATH} \
		--cmdline "$cmdline" \
		--base 0x80000000 \
		--pagesize 4096 \
		--output ${KBUILD_OUTPUT}boot.img \
		|| die "mkbootimg failure"
}

# Same as make_image_qcom but --header_version 2
make_image_qcom2() {
	local _dts_name="$1"
	# copy_modules requires rw mount (no "ro")
	local cmdline="earlycon console=ttyMSM0,115200n8 root=PARTLABEL=rootfs rootwait=2 init=/sbin/init copy_modules"
	# GRUB/Bootloader expects uncompressed Image
	local image_path=${IMAGE_PATH%.gz}

	append_dtb
	make_ramdisk

	# Some targets might require: --header_version 2
	cmdline="$cmdline $CMDLINE"
	echo "Making kernel image with cmdline: $cmdline"
	mkbootimg --kernel ${image_path} \
		--ramdisk ${RAMDISK_PATH} \
		--cmdline "$cmdline" \
		--dtb "${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb" \
		--dtb_offset 0 \
		--base 0x80000000 \
		--pagesize 4096 \
		--header_version 2 \
		--output ${KBUILD_OUTPUT}boot.img \
		|| die "mkbootimg failure"
}

ls_image_qcom() {
	echo
	echo "#################################"
	echo
	echo "Boot:                $(ls -lh ${KBUILD_OUTPUT}boot.img)"
	echo "fastboot set_active a && fastboot flash boot ${KBUILD_OUTPUT}boot.img && fastboot reboot"
}

make_image_e850() {
	local _dts_name="$1"
	# copy_modules requires rw mount (no "ro")
	local cmdline="earlycon root=PARTLABEL=userdata rootwait=2 init=/sbin/init copy_modules"
	# E850 bootloader expects uncompressed Image
	local image_path=${IMAGE_PATH%.gz}

	append_dtb
	make_ramdisk

	cmdline="$cmdline $CMDLINE"
	echo "Making kernel image with cmdline: $cmdline"
	mkbootimg --kernel ${image_path} \
		--ramdisk ${RAMDISK_PATH} \
		--ramdisk_offset 0 \
		--cmdline "$cmdline" \
		--dtb "${KBUILD_OUTPUT}arch/${ARCH_DIR}/boot/dts/${_dts_name}.dtb" \
		--dtb_offset 0 \
		--header_version 2 \
		--output ${KBUILD_OUTPUT}boot.img \
		|| die "mkbootimg failure"
}

ls_image_e850() {
	echo
	echo "#################################"
	echo
	echo "Boot:                $(ls -lh ${KBUILD_OUTPUT}boot.img)"
	echo "fastboot flash boot ${KBUILD_OUTPUT}boot.img && fastboot reboot"
}

# Clean all output artifacts. If any of these will remain then next build
# may fail because intermediate steps won't be produced.
# Example: if we won't clean "Image.gz" on ARM64, the "Image" won't be
# created (because destination "Image.gz" is there already.
make_clean() {
	rm -f ${KBUILD_OUTPUT}uImage \
		$IMAGE_PATH $IMAGE_OUT_PATH
	test "$CHOSEN_IMAGE" = "qcom" -o "$CHOSEN_IMAGE" = "qcom2" \
		-o "$CHOSEN_IMAGE" = "e850" \
		&& rm -f ${KBUILD_OUTPUT}boot.img
}

# Usage: make_image dts_name
make_images() {
	local _dts_name="$1"

	case "$CHOSEN_IMAGE" in
	arch)
		make_image_arch
		ls_image_arch
		;;
	arndale)
		make_image_arndale "$_dts_name"
		ls_image_arndale
		;;
	qcom)
		make_image_qcom "$_dts_name"
		ls_image_qcom
		;;
	qcom2)
		make_image_qcom2 "$_dts_name"
		ls_image_qcom
		;;
	e850)
		make_image_e850 "$_dts_name"
		ls_image_e850
		;;
	*)
		append_dtb "$_dts_name"
		# make_image_xxx installs modules in other cases
		test -n "$MODULES_INSTALL_PATH" && make_modules_install
		;;
	esac
}

# make_modules_img() {
# 	local _modules_path="tmp-mod"
# 	local _output_name="$MODULES_IMG"
# 	local _bin_size=0
# 	local _prev_cwd=`pwd`

# 	$MAKE modules_install $JOBS INSTALL_MOD_PATH=${_modules_path} || die "echo Make modules_install error"

# 	echo "Making $_output_name"

# 	# modules image size is dynamically determined
# 	_bin_size=`du -s ${KBUILD_OUTPUT}${_modules_path}/lib | awk {'printf $1;'}`
# 	let _bin_size=${_bin_size}+3*1024 # journal + buffer

# 	cd ${KBUILD_OUTPUT}${_modules_path}/lib || "cd ${KBUILD_OUTPUT}${_modules_path}/lib error"
# 	mkdir -p tmp || "mkdir tmp error"
# 	dd if=/dev/zero of=${_output_name} count=${_bin_size} bs=1024 || die "dd to $_output_name error"
# 	mkfs.ext4 -q -F -t ext4 -b 1024 $_output_name || die "mkfs.ext4 on $_output_name error"
# 	sudo mount -t ext4 ${_output_name} ./tmp -o loop || die "sudo mount $_output_name error"

# 	sudo -n chown $USER ./tmp
# 	cp -fr modules/* ./tmp
# 	sudo -n chown root:root ./tmp -R
# 	sync
# 	sudo -n umount ./tmp || die "sudo umount $_output_name error"

# 	cd "$_prev_cwd"
# 	mv ${KBUILD_OUTPUT}${_modules_path}/lib/${_output_name} ${KBUILD_OUTPUT}${_output_name}
# 	rm -fr ${KBUILD_OUTPUT}${_modules_path}/lib
# }

make_modules_install() {
	local _kern_ver="$(make -s kernelrelease)"

	test -n "$_kern_ver" || die "Cannot get kernel release"

	rm -fr ${KBUILD_OUTPUT}${MODULES_INSTALL_PATH}

	echo "Making modules ready for install for ${_kern_ver}"
	$MAKE $JOBS INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=${MODULES_INSTALL_PATH} V=0 \
		modules_install > /dev/null || die "make modules_install error"
	rm -f ${KBUILD_OUTPUT}${MODULES_INSTALL_PATH}/lib/modules/${_kern_ver}/build
	rm -f ${KBUILD_OUTPUT}${MODULES_INSTALL_PATH}/lib/modules/${_kern_ver}/source
}

# Usage: build_kernel dts_name
build_kernel() {
	local _dts_name="$1"

	echo "#################################"
	echo "BUILDING: $CONFIG_NAME for $ARCH"
	echo "ARCH=\"$ARCH\" CROSS_COMPILE=\"$CROSS_COMPILE\" KBUILD_OUTPUT=\"$KBUILD_OUTPUT\""
	echo "#################################"

	if [ -n "$ENABLE_CONFIG_ITEMS" ] || [ -n "$DISABLE_CONFIG_ITEMS" ] ||
		[ -n "$MODULE_CONFIG_ITEMS" ]; then
		manual_config_items
	fi
	$MAKE olddefconfig $JOBS || echo "Make olddefconfig error"

	if [ -n "$CHECK_CMD" ]; then
		$MAKE C=1 CHECK="$CHECK_CMD" $JOBS || die "Make error"
	else
		$MAKE $JOBS || die "Make error"
	fi

	build_dts "$_dts_name"

	test $STD_CHECKS -eq 1 && run_standard_checks

	make_images "$_dts_name"

	# Either we died already or everything succeeded and we should exit
	# with 0, not with last 'test' result
	return 0
}

# Usage: build_target target
build_target() {
	local _target="$1"

	echo "#################################"
	echo "BUILDING: $CONFIG_NAME for $ARCH"
	echo "ARCH=\"$ARCH\" CROSS_COMPILE=\"$CROSS_COMPILE\" KBUILD_OUTPUT=\"$KBUILD_OUTPUT\" make $TARGET"
	echo "#################################"

	if [ -n "$ENABLE_CONFIG_ITEMS" ] || [ -n "$DISABLE_CONFIG_ITEMS" ] ||
		[ -n "$MODULE_CONFIG_ITEMS" ]; then
		manual_config_items
		$MAKE olddefconfig $JOBS || echo "Make olddefconfig error"
	fi

	$MAKE $JOBS $_target || die "Make error"

	return 0
}

# config_item_on <items ...>
config_item_on() {
	for item in $*; do
		echo "Enabling $item"
		scripts/config --file ${KBUILD_OUTPUT}.config -k -e "${item}"
	done
}

# config_item_module <items ...>
config_item_module() {
	for item in $*; do
		echo "Enabling $item as module"
		scripts/config --file ${KBUILD_OUTPUT}.config -k -m "${item}"
	done
}

# config_item_off <items ...>
config_item_off() {
	for item in $*; do
		echo "Disabling $item"
		scripts/config --file ${KBUILD_OUTPUT}.config -k -d "${item}"
	done
}

make_config() {
	if [ -n "$CONFIG_NAME" ]; then
		$MAKE ${CONFIG_NAME} || die "Make ${CONFIG_NAME} error"
	fi
}

manual_config_items() {
	local _config_file="${KBUILD_OUTPUT}.config"
	test -f $_config_file || die "$_config_file does not exist"

	local enable_items=$(echo $ENABLE_CONFIG_ITEMS | tr "," "\n")
	config_item_on $enable_items

	local module_items=$(echo $MODULE_CONFIG_ITEMS | tr "," "\n")
	config_item_module $module_items

	local disable_items=$(echo $DISABLE_CONFIG_ITEMS | tr "," "\n")
	config_item_off $disable_items
}

config_tests() {
	config_item_on LOCALVERSION_AUTO

	# Grows kernel significantly:
	# config_item_on DEBUG_INFO
	config_item_on DEBUG_SECTION_MISMATCH HEADER_TEST KERNEL_HEADER_TEST
	config_item_off SECTION_MISMATCH_WARN_ONLY
	config_item_on DEBUG_FS DYNAMIC_DEBUG
	config_item_on DEBUG_ATOMIC_SLEEP DEBUG_PREEMPT SCHED_STACK_END_CHECK
	config_item_on PROVE_LOCKING LOCKUP_DETECTOR DEBUG_LOCK_ALLOC PROVE_RCU
	config_item_on DEBUG_RT_MUTEXES
	config_item_on DEBUG_LIST DEBUG_PLIST
	config_item_on DEBUG_SG
	config_item_on DEBUG_OBJECTS DEBUG_OBJECTS_FREE DEBUG_OBJECTS_TIMERS DEBUG_OBJECTS_WORK DEBUG_OBJECTS_RCU_HEAD DEBUG_OBJECTS_PERCPU_COUNTER
	config_item_off DEBUG_OBJECTS_SELFTEST
	config_item_off DEBUG_KOBJECT_RELEASE
	config_item_on DEBUG_PAGEALLOC DEBUG_PAGEALLOC_ENABLE_DEFAULT
	config_item_off PAGE_POISONING_NO_SANITY PAGE_POISONING_ZERO
	config_item_on SPARSE_RCU_POINTER
	config_item_on DEBUG_NOTIFIERS
	config_item_on DETECT_HUNG_TASK WQ_WATCHDOG
	config_item_off BOOTPARAM_HUNG_TASK_PANIC
	config_item_on DEBUG_TIMEKEEPING
	config_item_on UBSAN UBSAN_BOUNDS UBSAN_MISC UBSAN_ALIGNMENT
	config_item_off UBSAN_NO_ALIGNMENT TEST_UBSAN UBSAN_TRAP
	config_item_on DEBUG_SHIRQ
	config_item_on DEBUG_VM
	config_item_off DEBUG_VM_VMACACHE DEBUG_VM_RB DEBUG_VM_PGFLAGS
	# These are probably turned on by default in config
	config_item_on DEBUG_MUTEXES DEBUG_SPINLOCK
}

# Exactly the same as is being used in Buildbot
config_buildbot() {
	config_item_on LOCALVERSION_AUTO

	config_item_on IPV6
	config_item_on NFS_V4
	config_item_on SENSORS_PWM_FAN
	config_item_on PWM_SAMSUNG
	config_item_off CRYPTO_MANAGER_DISABLE_TESTS
	config_item_on DMATEST
	config_item_module CRYPTO_TEST
	config_item_on SCHED_STACK_END_CHECK
	config_item_on DEBUG_LOCK_ALLOC
	config_item_on DEBUG_ATOMIC_SLEEP
	config_item_on DEBUG_LIST
	config_item_on DEBUG_SECTION_MISMATCH
	config_item_off SECTION_MISMATCH_WARN_ONLY
	config_item_on SECCOMP
}

# NFC devices/drivers
config_nfc() {
	# NFC
	config_item_on NFC
	config_item_on NFC_DIGITAL NFC_NCI NFC_NCI_UART NFC_HCI NFC_SHDLC
	config_item_module NFC_TRF7970A NFC_SIM NFC_PORT100 NFC_VIRTUAL_NCI
	config_item_module NFC_FDP NFC_FDP_I2C
	config_item_module INTEL_MEI_TXE INTEL_MEI NFC_MEI_PHY
	config_item_module NFC_PN544_I2C NFC_PN544_MEI NFC_PN533_USB NFC_PN533_I2C NFC_PN532_UART
	config_item_module NFC_MICROREAD_I2C NFC_MICROREAD_MEI
	config_item_module NFC_MRVL_USB NFC_MRVL_UART NFC_MRVL_I2C NFC_MRVL_SPI
	config_item_module NFC_ST21NFCA_I2C NFC_ST_NCI_I2C NFC_ST_NCI_SPI
	config_item_module NFC_NXP_NCI NFC_NXP_NCI_I2C
	config_item_module NFC_S3FWRN5_I2C NFC_S3FWRN82_UART NFC_ST95HF
}

# QCOM devices
config_qcom() {
	# USB net
	config_item_on USB_NET_AX8817X USB_LAN78XX USB_CONFIGFS USB_FUNCTIONFS

	# QRD8550
	config_item_on TYPEC QCOM_PMIC_GLINK PHY_QCOM_EUSB2_REPEATER
	config_item_on MEDIA_SUPPORT LEDS_CLASS_FLASH V4L2_FLASH_LED_CLASS LEDS_QCOM_FLASH

	# CRD8380xp ramdisk without modules
	config_item_on BLK_DEV_NVME

	# I2C, peripherals
	config_item_on I2C_QCOM_GENI
	# Storage, USB, PHY
	config_item_on PHY_QCOM_QMP_UFS SCSI_UFS_QCOM PHY_QCOM_QMP PHY_QCOM_PCIE2 PHY_QCOM_QMP_PCIE
	config_item_on PHY_QCOM_USB_SNPS_FEMTO_V2 PHY_QCOM_QMP_COMBO
	config_item_on PHY_QCOM_QUSB2 PHY_QCOM_USB_HSIC PHY_QCOM_USB_HS_28NM PHY_QCOM_USB_SS PHY_QCOM_EDP QCOM_PMIC_EUSB2_REPEATER PHY_QCOM_SNPS_EUSB2
	# More USB
	config_item_on TYPEC_UCSI UCSI_PMIC_GLINK TYPEC_QCOM_PMIC TYPEC_MUX_FSA4480 TYPEC_MUX_NB7VPQ904M
	# core drivers
	config_item_on INTERCONNECT_QCOM_SM8350 INTERCONNECT_QCOM_SM8450 INTERCONNECT_QCOM_SM8550
	# WiFi common
	config_item_on CFG80211 MAC80211
	# WiFi other?
	# config_item_on ATH10K ATH10K_SNOC
	# QCOM_WCNSS_CTRL
	# WiFi RB5
	config_item_on CRYPTO_MICHAEL_MIC ATH11K ATH11K_PCI ATH12K
	# Bluetooth
	config_item_on RFKILL BT BT_HCIBTUSB BT_HCIUART BT_QCOMSMD MFD_QCOM_QCA639X

	# Display
	config_item_on DRM DRM_MSM DRM_DISPLAY_CONNECTOR
	config_item_on DRM_LONTIUM_LT9611 DRM_LONTIUM_LT9611UXC

	# Remoteproc
	config_item_on QCOM_Q6V5_PAS

	# Audio
	config_item_on QCOM_FASTRPC RPMSG_CHAR RPMSG_CTRL
	config_item_on SLIMBUS SOUNDWIRE SOUNDWIRE_QCOM RPMSG_QCOM_GLINK_SMEM SLIM_QCOM_CTRL SLIM_QCOM_NGD_CTRL
	config_item_on QCOM_APR QRTR QRTR_SMD QRTR_TUN QCOM_PDR_HELPERS QCOM_QMI_HELPERS QCOM_Q6V5_ADSP QCOM_Q6V5_MSS QCOM_Q6V5_WCSS
	config_item_on QCOM_SYSMON QCOM_WCNSS_PIL MFD_WCD934X SND_SOC_WCD9335 SND_SOC_WCD934X GPIO_WCD934X SND_SOC_WCD938X_SDW
	config_item_on SND_SOC_QCOM SND_SOC_APQ8016_SBC SND_SOC_QDSP6 SND_SOC_MSM8996 SND_SOC_SDM845 SND_SOC_SM8250
	config_item_on SND_SOC_SC7180 SND_SOC_SC7280 SND_SOC_SC8280XP SND_SOC_SM8450
	config_item_on SND_SOC_WSA881X SND_SOC_WSA883X SND_SOC_WSA884X
	config_item_on SND_SOC_LPASS_WSA_MACRO SND_SOC_LPASS_VA_MACRO SND_SOC_LPASS_RX_MACRO SND_SOC_LPASS_TX_MACRO
	config_item_on PINCTRL_LPASS_LPI PINCTRL_SM8450_LPASS_LPI PINCTRL_SM8350_LPASS_LPI PINCTRL_SM8250_LPASS_LPI PINCTRL_SM8550_LPASS_LPI
	config_item_on PINCTRL_SM8650_LPASS_LPI
	config_item_on SM_DISPCC_8450 QCOM_RMTFS_MEM

	# Audio maybe not upstreamed (need to double check later)
	config_item_on SC_LPASSCSR_8280XP

	# Other
	config_item_on QCOM_OCMEM QCOM_LLCC

	# Useful options for Qualcomm boards used in different contexts, e.g. RB5 as cdba server
	config_item_on USB_SUPPORT USB_ACM USB_SERIAL USB_SERIAL_CP210X USB_SERIAL_FTDI_SIO USB_SERIAL_OPTION
	config_item_on TYPEC_TCPM TYPEC_TCPCI
}

# QEMU guest plus some additional testing stuff for my trees
config_qemutest() {
	config_item_on LOCALVERSION_AUTO

	config_item_on HYPERVISOR_GUEST
	config_item_on PARAVIRT PARAVIRT_DEBUG PARAVIRT_SPINLOCKS KVM_GUEST
	config_item_off XEN PVH PARAVIRT_TIME_ACCOUNTING JAILHOUSE_GUEST ACRN_GUEST CPU_IDLE_GOV_HALTPOLL HALTPOLL_CPUIDLE
	config_item_off HYPERV
	config_item_on FW_CFG_SYSFS FW_CFG_SYSFS_CMDLINE
	config_item_on PTP_1588_CLOCK_KVM PTP_1588_CLOCK_VMW
	config_item_on I2C_PIIX4 PATA_ACPI IGB IGB_HWMON IXGB
	config_item_on DRM VIRTIO_MENU VIRTIO_PCI VIRTIO_PCI_LEGACY DRM_VIRTIO_GPU VIRTIO_INPUT SCSI_VIRTIO VIRTIO_BLK VIRTIO_CONSOLE
	config_item_on VIRTIO_NET NETCONSOLE VIRTIO_IOMMU
	config_item_on HW_RANDOM_VIRTIO SND_VIRTIO VIRTIO_BALLOON BALLOON_COMPACTION CRYPTO_DEV_VIRTIO

	# Grows kernel significantly, but useful for proper faddr2line:
	config_item_on DEBUG_INFO DEBUG_INFO_REDUCED DEBUG_INFO_COMPRESSED

	config_item_on DEBUG_VM
	config_item_off DEBUG_VM_VMACACHE DEBUG_VM_RB DEBUG_VM_PGFLAGS
	config_item_on DETECT_HUNG_TASK WQ_WATCHDOG
	config_item_on PROVE_LOCKING
	config_item_off PROVE_RAW_LOCK_NESTING DEBUG_LOCKDEP
	config_item_on DEBUG_LOCK_ALLOC
	config_item_on DEBUG_ATOMIC_SLEEP
	config_item_on DEBUG_LIST
	config_item_on DEBUG_SECTION_MISMATCH
	config_item_off SECTION_MISMATCH_WARN_ONLY

	config_item_on X86_X2APIC
	config_item_off X86_NUMACHIP X86_UV MOUSE_PS2_VMMOUSE

	# USB gadget and testing tools
	config_item_on USB_SUPPORT USB_GADGET
	config_item_off USB_GADGET_DEBUG
	config_item_on USB_GADGET_DEBUG_FILES USB_GADGET_DEBUG_FS
	config_item_on USB_GADGETFS USB_FUNCTIONFS USB_RAW_GADGET USB_DUMMY_HCD

	# Other Network testing
	config_item_module NETDEVSIM TUN

	# Bluetooth tests
	#config_item_module BT
	#config_item_module BT_RFCOMM BT_BNEP BT_HIDP
	#config_item_module BT_HCIBTUSB BT_HCIUART BT_HCIVHCI BT_VIRTIO
	#config_item_on BT_RFCOMM_TTY BT_BNEP_MC_FILTER BT_BNEP_PROTO_FILTER BT_HS
	#config_item_module BT_6LOWPAN
	#config_item_on BT_MSFTEXT BT_AOSPEXT
	#config_item_on BT_HCIBTUSB_MTK BT_HCIUART_H4 BT_HCIUART_AG6XX
	#config_item_module BT_HCIBCM203X BT_HCIBPA10X BT_HCIBFUSB BT_HCIDTL1 BT_HCIBT3C
	#config_item_module BT_HCIBLUECARD BT_MRVL BT_ATH3K
}

build_tests() {
	config_tests

	build_kernel $DTS_NAME
}

build_buildbot() {
	config_buildbot

	build_kernel $DTS_NAME
}

build_qemutest() {
	config_qemutest
	config_nfc

	build_kernel $DTS_NAME
}

build_nfc() {
	config_nfc

	build_kernel $DTS_NAME
}

build_crypto() {
	config_item_off CRYPTO_MANAGER_DISABLE_TESTS
	config_item_module CRYPTO_TEST

	build_kernel $DTS_NAME
}

build_qcom() {
	config_qcom

	build_kernel $DTS_NAME
}

# Start of execution (entry point):
if [ "$(have_ccache)" == "0" ]; then
	export CROSS_COMPILE="ccache $CROSS_COMPILE"
fi

trap "tmp_cleanup" EXIT

test -n "$KBUILD_OUTPUT" && install -d $KBUILD_OUTPUT
make_config
make_clean

if [ "$TEST_CONFIG" != "" ]; then
	case  $TEST_CONFIG in
	crypto)
		build_crypto
		;;
	qcom)
		build_qcom
		;;
	tests)
		build_tests
		;;
	buildbot)
		build_buildbot
		;;
	qemutest)
		build_qemutest
		;;
	nfc)
		build_nfc
		;;
	*)
		usage
		;;
	esac
elif [ "$TARGET" != "" ]; then
	build_target $TARGET
else
	build_kernel $DTS_NAME
fi
