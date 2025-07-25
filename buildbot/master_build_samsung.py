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

from master_build_common import steps_prepare_build_storage

CMD_MAKE = '%(prop:builddir:-~/)s/tools/buildbot/build-slave.sh'

def steps_build_upload_artifacts_binaries(name, config, out_dir):
    st = []

    upload_files_bin = ['Module.symvers',
                        'System.map',
                        'modules.builtin',
                        'vmlinux',
                        'arch/arm/boot/zImage',
                        'dtb-out.tar.xz',
                        'modules-out.tar.xz',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]

    deploy_dir = f'%(prop:basedir:-./)s/../public_html/deploy-bin/{name}/%(prop:got_revision)s/'
    st.extend(steps_prepare_build_storage('Prepare upload directory: binaries', deploy_dir))

    cmd = ['cp']
    for s in upload_files_bin:
        cmd.append(util.Interpolate(s))
    cmd.append(util.Interpolate(deploy_dir))
    st.append(steps.ShellCommand(command=cmd,
                                 haltOnFailure=True,
                                 name='Copy binaries to build storage'))
    return st

def steps_build_boot_adjust_config(builder_name, env, kbuild_output, config):
    st = []
    if not config:
        raise ValueError('Missing config for booting')
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 # Enable IPV6 for Odroid systemd, AUTOFS4_FS/NFS_V4 will be in exynos_defconfig around v4.5
                 '-e', 'AUTOFS4_FS',
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
                ],
        haltOnFailure=True,
        env=env, name='Toggle config options'))
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                            haltOnFailure=True,
                            env=env, name='Make olddefconfig'))
    return st
