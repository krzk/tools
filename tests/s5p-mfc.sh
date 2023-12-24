#!/bin/bash
#
# Copyright (c) 2023 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

set -e -E -x
. $(dirname "${BASH_SOURCE[0]}")/inc-common.sh

test_s5p_mfc_v4l2_complianc_dec() {
	local report=""

	report=$(v4l2-compliance --device "/dev/${v4l_dev}" || print_msg "v4l2-compliance errors expected")
	echo "$report" | grep "test VIDIOC_ENUM_FMT/FRAMESIZES/FRAMEINTERVALS: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test VIDIOC_ENUM_FMT/FRAMESIZES/FRAMEINTERVALS: OK"
	echo "$report" | grep "test VIDIOC_REQBUFS/CREATE_BUFS/QUERYBUF: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test VIDIOC_REQBUFS/CREATE_BUFS/QUERYBUF: OK"
}

test_s5p_mfc_v4l2_compliance() {
	local report=""

	report=$(v4l2-compliance --device "/dev/${v4l_dev}" || print_msg "v4l2-compliance errors expected")
	echo "$report" | grep "s5p-mfc" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: s5p-mfc"
	echo "$report" | grep "test VIDIOC_QUERYCAP: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test VIDIOC_QUERYCAP: OK"
	echo "$report" | grep "test invalid ioctls: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test invalid ioctls: OK"
	echo "$report" | grep "test second /dev/${v4l_dev} open: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test second /dev/${v4l_dev} open: OK"
	echo "$report" | grep "test VIDIOC_G/S_PRIORITY: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test VIDIOC_G/S_PRIORITY: OK"
	echo "$report" | grep "test VIDIOC_QUERY_EXT_CTRL/QUERYMENU: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test VIDIOC_QUERY_EXT_CTRL/QUERYMENU: OK"
	echo "$report" | grep "test VIDIOC_QUERYCTRL: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test VIDIOC_QUERYCTRL: OK"
	echo "$report" | grep "test CREATE_BUFS maximum buffers: OK" > /dev/null || error_msg "/dev/${v4l_dev}: not matching: test CREATE_BUFS maximum buffers: OK"
}

test_s5p_mfc() {
	local name="S5P MFC"
	local device=""
	local v4l_devices=""
	local dev_dec=""
	local dev_enc=""
	print_msg "Testing..."

	case "$(get_board_compatible)" in
	hardkernel,odroid-hc1|hardkernel,odroid-xu3|hardkernel,odroid-xu3-lite|hardkernel,odroid-xu4|hardkernel,odroid-xu|insignal,arndale-octa)
		device="11000000.codec"
		;;
	hardkernel,odroid-u3|hardkernel,odroid-x)
		device="13400000.codec"
		;;
	*)
		error_msg "Wrong board"
	esac

	v4l_devices="$(ls -1 /sys/bus/platform/drivers/s5p-mfc/${device}/video4linux/)"

	for v4l_dev in $v4l_devices; do
		local codec_name="$(cat /sys/bus/platform/drivers/s5p-mfc/${device}/video4linux/${v4l_dev}/name)"
		print_msg "Found codec $codec_name on $/dev/${v4l_dev}"

		v4l2-ctl --info --device "/dev/${v4l_dev}"
		test_s5p_mfc_v4l2_compliance "${v4l_dev}"

		case "$codec_name" in
		s5p-mfc-dec)
			test_s5p_mfc_v4l2_complianc_dec "${v4l_dev}"
			;;
		s5p-mfc-enc)
			;;
		*)
			error_msg "Unknown MFC codec"
		esac
	done

	print_msg "OK"
}

test_s5p_mfc
