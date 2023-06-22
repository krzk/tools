# -*- python -*-
# ex: set filetype=python:
#
# Copyright (c) 2016-2023 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

from buildbot.plugins import steps, util

from master_build_common import is_set_arm_boot_dts_vendor_subdirs, steps_prepare_upload_master, \
                                step_upload_files_to_master

CMD_MAKE = '%(prop:builddir:-~/)s/tools/buildbot/build-slave.sh'

def steps_build_upload_artifacts_binaries(name, config, out_dir):
    st = []

    masterdest_dir_bin = 'deploy-bin/' + name + '/%(prop:revision)s/'
    st.extend(steps_prepare_upload_master('Prepare upload directory: binaries', masterdest_dir_bin))

    upload_files_compress = ['Module.symvers',
                                'System.map',
                                'modules.builtin',
                                #'vmlinux.symvers', # Not in kernel v4.4
                                'vmlinux',
                                ]
    upload_files_compress_path = [util.Interpolate(out_dir + i) for i in upload_files_compress]
    st.append(steps.ShellCommand(command=['xz', '--threads=0',
                                          upload_files_compress_path],
                                    haltOnFailure=True,
                                    name='Compress compiled objects'))
    upload_files_compress = [(out_dir + i + '.xz') for i in upload_files_compress]

    upload_files_bin = ['arch/arm/boot/zImage',
                        'arch/arm/boot/dts/exynos4412-odroidu3.dtb',
                        'arch/arm/boot/dts/exynos4412-odroidx.dtb',
                        'arch/arm/boot/dts/exynos5420-arndale-octa.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb',
                        'modules-out.tar.gz',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    upload_files_bin.extend(upload_files_compress)
    st.append(step_upload_files_to_master('Upload kernel, modules and required DTBs',
                                          upload_files_bin, masterdest_dir_bin,
                                          errors_fatal=True,
                                          do_step_if=lambda step: not is_set_arm_boot_dts_vendor_subdirs(step)))

    upload_files_bin = ['arch/arm/boot/zImage',
                        'arch/arm/boot/dts/samsung/exynos4412-odroidu3.dtb',
                        'arch/arm/boot/dts/samsung/exynos4412-odroidx.dtb',
                        'arch/arm/boot/dts/samsung/exynos5420-arndale-octa.dtb',
                        'arch/arm/boot/dts/samsung/exynos5422-odroidxu3-lite.dtb',
                        'modules-out.tar.gz',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    upload_files_bin.extend(upload_files_compress)
    st.append(step_upload_files_to_master('Upload kernel, modules and required DTBs',
                                          upload_files_bin, masterdest_dir_bin,
                                          errors_fatal=True,
                                          do_step_if=is_set_arm_boot_dts_vendor_subdirs))

    # XU, XU4 and HC1 might be missing for older kernels -  In case of failure do not halt,
    # do not fail and mark build as warning. flunkOnFailure is by default True.
    upload_files_bin = ['arch/arm/boot/dts/exynos5410-odroidxu.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidhc1.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidxu4.dtb',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    st.append(step_upload_files_to_master('Upload optional DTBs',
                                          upload_files_bin, masterdest_dir_bin,
                                          do_step_if=lambda step: not is_set_arm_boot_dts_vendor_subdirs(step)))

    upload_files_bin = ['arch/arm/boot/dts/samsung/exynos5410-odroidxu.dtb',
                        'arch/arm/boot/dts/samsung/exynos5422-odroidhc1.dtb',
                        'arch/arm/boot/dts/samsung/exynos5422-odroidxu4.dtb',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    st.append(step_upload_files_to_master('Upload optional DTBs',
                                          upload_files_bin, masterdest_dir_bin,
                                          do_step_if=is_set_arm_boot_dts_vendor_subdirs))

    return st

def steps_build_boot_adjust_config(builder_name, env, kbuild_output, slaves, config):
    st = []
    if not config:
        raise ValueError('Missing config for booting')
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 # Enable IPV6 for Odroid systemd, AUTOFS4_FS/NFS_V4 will be in exynos_defconfig around v4.5
                 '-e', 'IPV6', '-e', 'NFS_V4', '-e', 'AUTOFS4_FS',
                 # Enable fan so it won't be spinning on full speed on multi_v7
                 # (PWM_FAN will be in multi_v7 around v4.5-4.6 but both
                 # won't be in older stables)
                 '-e', 'SENSORS_PWM_FAN', '-e', 'PWM_SAMSUNG',
                 # s5p-sss tests need status of selftest
                 '-d', 'CRYPTO_MANAGER_DISABLE_TESTS',
                 # Want DMATEST and TCRYPT for tests
                 '-e', 'DMATEST', '-m', 'CRYPTO_TEST',
                 # Enable Lockdep and other debugging non-heavy tools
                 '-e', 'SCHED_STACK_END_CHECK', '-e', 'DEBUG_LOCK_ALLOC',
                 '-e', 'DEBUG_ATOMIC_SLEEP', '-e', 'DEBUG_LIST',
                 # Enable build-time debugging
                 '-e', 'DEBUG_SECTION_MISMATCH',
                 '-d', 'SECTION_MISMATCH_WARN_ONLY',
                 # SECCOMP is required by newer Arch ARM systemd
                 '-e', 'SECCOMP',
                 # Broken commit d3b00a802c84 ("NFS: Replace the READ_PLUS decoding code")
                 # No schedule for a fix...
                 # https://lore.kernel.org/all/2add1769-1458-b185-bc78-6d573f61b6fc@linaro.org/
                 '-d', 'NFS_V4_2_READ_PLUS',
                ],
        haltOnFailure=True,
        env=env, name='Toggle config options'))
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                            haltOnFailure=True,
                            env=env, name='Make olddefconfig'))
    return st
