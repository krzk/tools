# -*- python -*-
# ex: set filetype=python:
#
# Copyright (c) 2016-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

from buildbot.plugins import steps, util

cmd_make = '%(prop:builddir:-~/)s/tools/buildbot/build-slave.sh'

def cmd_make_config(config=None):
    if config == None:
        config = 'defconfig'
    elif config in ['allyes', 'allmod', 'def']:
        config = config + 'config'
    else:
        config = str(config) + '_defconfig'
    return [util.Interpolate(cmd_make), config]

def steps_build_common(env, config=None):
    st = []
    step_name = str(config) + ' config' if config else 'defconfig'
    step_name = 'make ' + step_name
    st.append(steps.Git(repourl='https://github.com/krzk/tools.git',
                        name='Clone krzk tools sources',
                        mode='incremental',
                        alwaysUseLatest=True,
                        branch='master',
                        getDescription=False,
                        workdir='tools',
                        haltOnFailure=True,
                        env=util.Property('git_env')))
    st.append(steps.Git(repourl=util.Property('repository'),
                        name='Clone the sources',
                        # Run full/fresh checkout to get rid of any old DTBs or binaries from
                        # KBUILD_OUTPUT. For example when compiling stable kernel without
                        # given DTB, old DTB from linux-next might remain.
                        # Removal of them is necessary for boot tests so they do not re-use
                        # wrong binaries... and anyway it is nice to test clean build.
                        mode='full',
                        method='fresh',
                        haltOnFailure=True,
                        env=util.Property('git_env')))
    st.append(steps.SetPropertyFromCommand(command=[util.Interpolate(cmd_make), '-s', 'kernelversion'],
                                           property='kernel_version', haltOnFailure=True,
                                           env=env, name='Set property: kernel version'))
    st.append(steps.Compile(command=cmd_make_config(config),
                            haltOnFailure=True, env=env, name=step_name))
    return st

def steps_build_linux_kernel(env, build_step_name='Build kernel'):
    st = []
    st.append(steps.Compile(command=[util.Interpolate(cmd_make)], haltOnFailure=True, env=env, name=build_step_name))
    return st

def steps_build_upload_artifacts(name, config, boot, out_dir, buildbot_url):
    st = []
    masterdest_pub_dir = 'deploy-pub/' + name + '/%(prop:revision)s/'
    masterdest_bin_dir = 'deploy-bin/' + name + '/%(prop:revision)s/'
    st.append(steps.FileUpload(workersrc=out_dir + '.config',
                               masterdest=util.Interpolate(masterdest_pub_dir + 'config'),
                               mode=0o0644,
                               url=util.Interpolate(buildbot_url + 'pub/' + masterdest_pub_dir),
                               haltOnFailure=True, name='Upload config'))
    st.append(steps.FileUpload(workersrc=out_dir + 'include/generated/autoconf.h',
                               masterdest=util.Interpolate(masterdest_pub_dir + 'autoconf.h'),
                               mode=0o0644,
                               url=util.Interpolate(buildbot_url + 'pub/' + masterdest_pub_dir),
                               haltOnFailure=True, name='Upload autoconf.h'))
    if boot and config:
        upload_files_src_objects = ['Module.symvers',
                                    'System.map',
                                    'modules.builtin',
                                    #'vmlinux.symvers', # Not in kernel v4.4
                                    'vmlinux']
        upload_files_src_objects = [(out_dir + i) for i in upload_files_src_objects]
        st.append(steps.ShellCommand(command=['xz', '--threads=0',
                                     upload_files_src_objects],
                                     haltOnFailure=True,
                                     name='Compress compiled objects'))
        upload_files_src_objects = [(i + '.xz') for i in upload_files_src_objects]

        upload_files_src_mandatory = ['arch/arm/boot/zImage',
                                      'arch/arm/boot/dts/exynos4412-odroidu3.dtb',
                                      'arch/arm/boot/dts/exynos4412-odroidx.dtb',
                                      'arch/arm/boot/dts/exynos5420-arndale-octa.dtb',
                                      'arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb',
                                      'modules-out.tar.gz',
                                      ]
        upload_files_src_mandatory = [(out_dir + i) for i in upload_files_src_mandatory]
        upload_files_src_mandatory.extend(upload_files_src_objects)
        st.append(steps.MultipleFileUpload(workersrcs=upload_files_src_mandatory,
                                           masterdest=util.Interpolate(masterdest_bin_dir),
                                           mode=0o0644,
                                           haltOnFailure=True,
                                           name='Upload kernel, modules and required DTBs'))

        # XU, XU4 and HC1 might be missing for older kernels -  In case of failure do not halt,
        # do not fail and mark build as warning. flunkOnFailure is by default True.
        upload_files_src_optional = ['arch/arm/boot/dts/exynos5410-odroidxu.dtb',
                                     'arch/arm/boot/dts/exynos5422-odroidhc1.dtb',
                                     'arch/arm/boot/dts/exynos5422-odroidxu4.dtb',
                                     ]
        upload_files_src_optional = [(out_dir + i) for i in upload_files_src_optional]
        st.append(steps.MultipleFileUpload(workersrcs=upload_files_src_optional,
                                           masterdest=util.Interpolate(masterdest_bin_dir),
                                           mode=0o0644,
                                           haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
                                           name='Upload optional DTBs'))
    st.append(steps.MasterShellCommand(command=['chmod', 'a+rx', 'deploy-pub/' + name,
                                                util.Interpolate(masterdest_pub_dir)],
                                       name='Set world-readable permissions on uploaded files for web server'))
    masterdest_src_doc_cmd = 'echo "Source URL: %(prop:repository)s\nRevision: %(prop:revision)s" > ' + masterdest_pub_dir + 'sources.txt; '
    masterdest_src_doc_cmd += 'chmod a+r ' + masterdest_pub_dir + 'sources.txt'
    st.append(steps.MasterShellCommand(command=util.Interpolate(masterdest_src_doc_cmd),
                                       name='Document source location'))

    return st

def steps_build_boot_adjust_config(builder_name, env, slaves, config):
    st = []
    if not config:
        raise ValueError('Missing config for booting')
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', env['KBUILD_OUTPUT'] + '.config',
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
                ],
        haltOnFailure=True,
        env=env, name='Toggle config options'))
    st.append(steps.Compile(command=[util.Interpolate(cmd_make), 'olddefconfig'],
                            haltOnFailure=True,
                            env=env, name='Make olddefconfig'))
    return st

def steps_build_mem_ctrl_adjust_config(builder_name, env):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', env['KBUILD_OUTPUT'] + '.config',
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'SRAM', '-e', 'MEMORY', '-e', 'PM_DEVFREQ',
                 '-e', 'ARM_PL172_MPMC',
                 '-e', 'ATMEL_SDRAMC', '-e', 'ATMEL_EBI',
                 '-e', 'BRCMSTB_DPFE', '-e', 'BT1_L2_CTL',
                 '-e', 'TI_AEMIF', '-e', 'TI_EMIF', '-e', 'OMAP_GPMC',
                 '-e', 'TI_EMIF_SRAM', '-e', 'MVEBU_DEVBUS', '-e', 'FSL_CORENET_CF',
                 '-e', 'FSL_IFC', '-e', 'JZ4780_NEMC', '-e', 'MTK_SMI',
                 '-e', 'DA8XX_DDRCTL', '-e', 'PL353_SMC', '-e', 'RENESAS_RPCIF',
                 '-e', 'STM32_FMC2_EBI', '-e', 'SAMSUNG_MC', '-e', 'EXYNOS5422_DMC',
                 '-e', 'EXYNOS_SROM', '-e', 'TEGRA_MC', '-e', 'TEGRA20_EMC',
                 '-e', 'TEGRA30_EMC', '-e', 'TEGRA124_EMC', '-e', 'TEGRA210_EMC_TABLE',
                 '-e', 'TEGRA210_EMC',
                ],
        haltOnFailure=True,
        env=env, name='Toggle memory controller drivers compile test config options'))
    st.append(steps.Compile(command=[util.Interpolate(cmd_make), 'olddefconfig'],
                            haltOnFailure=True,
                            env=env, name='Make olddefconfig'))
    return st

def steps_build_selected_folders(builder_name, env):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.Compile(command=[util.Interpolate(cmd_make), 'arch/arm/',
                                     # make won't build DTBs but include it for completeness
                                     'arch/arm64/boot/dts/',
                                     'drivers/clk/samsung/', 'drivers/pinctrl/samsung/', 'drivers/memory/',
                                     'drivers/soc/samsung/'],
                            haltOnFailure=True, env=env, name='Build selected paths'))
    return st

def steps_checkdtbs(env, config=None, git_reset=True):
    st = []
    if git_reset:
        st += steps_build_common(env, config)
    step_name = str(config) + ' config' if config else 'defconfig'
    step_name = 'make dtbs with warnings for ' + env['ARCH'] + '/' + step_name
    st.append(steps.Compile(command=[util.Interpolate(cmd_make), 'dtbs', 'W=1'],
                            haltOnFailure=True,
                            env=env, name=step_name))
    return st
