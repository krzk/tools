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
import twisted

upload_config = {
        'host': 'build.krzk.eu',
        'user': 'buildbot_upload',
        'port': '443',
}

cmd_make = '%(prop:builddir:-~/)s/tools/buildbot/build-slave.sh'

class ShellCmdWithLink(steps.ShellCommand):
    renderables = ['url']

    def __init__(self, url, **buildstep_kwargs):
        super().__init__(**buildstep_kwargs)
        self.url = url

    @twisted.internet.defer.inlineCallbacks
    def run(self):
        yield self.addURL('files', self.url)
        res = yield super().run()
        return res

def cmd_make_config(config=None):
    if config == None:
        config = 'defconfig'
    elif config in ['allyes', 'allmod', 'def']:
        config = config + 'config'
    else:
        config = str(config) + '_defconfig'
    return [util.Interpolate(cmd_make), config]

def step_touch_commit_files():
    cmd = '''
    if git rev-parse HEAD^2 ; then
        # It's a merge, touch files changed by both parents
        FILES="`git diff-tree --no-commit-id --name-only -r HEAD^1..HEAD` `git diff-tree --no-commit-id --name-only -r HEAD^2..HEAD`"
    else
        FILES="`git diff-tree --no-commit-id --name-only -r HEAD`"
    fi
    touch $FILES
    echo $FILES
    '''
    return steps.ShellCommand(command=['/bin/sh', '-c', cmd],
                              haltOnFailure=True,
                              name='touch changed files')

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

def steps_build_upload_artifacts_binaries(name, config, out_dir):
    st = []

    masterdest_dir_bin = 'deploy-bin/' + name + '/%(prop:revision)s/'
    st.append(steps.ShellCommand(command=['ssh', '-o', 'StrictHostKeyChecking=no', '-p', upload_config['port'],
                                            '{}@{}'.format(upload_config['user'], upload_config['host']),
                                            util.Interpolate('mkdir -p ' + masterdest_dir_bin),
                                            ],
                                haltOnFailure=True,
                                name='Prepare upload directory: binaries'))

    upload_files_compress = ['Module.symvers',
                                'System.map',
                                'modules.builtin',
                                #'vmlinux.symvers', # Not in kernel v4.4
                                'vmlinux',
                                ]
    upload_files_compress = [(out_dir + i) for i in upload_files_compress]
    st.append(steps.ShellCommand(command=['xz', '--threads=0',
                                            upload_files_compress],
                                    haltOnFailure=True,
                                    name='Compress compiled objects'))
    upload_files_compress = [(i + '.xz') for i in upload_files_compress]

    upload_files_bin = ['arch/arm/boot/zImage',
                        'arch/arm/boot/dts/exynos4412-odroidu3.dtb',
                        'arch/arm/boot/dts/exynos4412-odroidx.dtb',
                        'arch/arm/boot/dts/exynos5420-arndale-octa.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidxu3-lite.dtb',
                        'modules-out.tar.gz',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    upload_files_bin.extend(upload_files_compress)
    st.append(steps.ShellCommand(command=['scp', '-p', '-o', 'StrictHostKeyChecking=no', '-P', upload_config['port'],
                                            upload_files_bin,
                                            util.Interpolate('{}@{}:{}'.format(upload_config['user'], upload_config['host'], masterdest_dir_bin)),
                                            ],
                                    haltOnFailure=True,
                                    name='Upload kernel, modules and required DTBs'))

    # XU, XU4 and HC1 might be missing for older kernels -  In case of failure do not halt,
    # do not fail and mark build as warning. flunkOnFailure is by default True.
    upload_files_bin = ['arch/arm/boot/dts/exynos5410-odroidxu.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidhc1.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidxu4.dtb',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    st.append(steps.ShellCommand(command=['scp', '-p', '-o', 'StrictHostKeyChecking=no', '-P', upload_config['port'],
                                            upload_files_bin,
                                            util.Interpolate('{}@{}:{}'.format(upload_config['user'], upload_config['host'], masterdest_dir_bin)),
                                            ],
                                    haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
                                    name='Upload optional DTBs'))

    return st

def steps_build_upload_artifacts(name, config, boot, out_dir, buildbot_url):
    st = []
    masterdest_dir_pub = 'deploy-pub/' + name + '/%(prop:revision)s/'

    st.append(steps.ShellCommand(command=['ssh', '-o', 'StrictHostKeyChecking=no', '-p', upload_config['port'],
                                          '{}@{}'.format(upload_config['user'], upload_config['host']),
                                          util.Interpolate('mkdir -p ' + masterdest_dir_pub),
                                          ],
                                 haltOnFailure=True,
                                 name='Prepare upload directory: sources'))

    cmd = 'echo "Source URL: %(prop:repository)s\nRevision: %(prop:revision)s" > ' + out_dir + 'sources.txt; '
    cmd += 'cp -p ' + out_dir + '.config ' + out_dir + 'config; '
    cmd += 'chmod a+r ' + out_dir + 'config; '
    cmd += 'chmod a+r ' + out_dir + 'sources.txt; '
    cmd += 'chmod a+r ' + out_dir + 'include/generated/autoconf.h'
    st.append(steps.ShellCommand(command=util.Interpolate(cmd),
                                 name='Prepare source files for uploading'))

    upload_files_pub = ['config',
                        'include/generated/autoconf.h',
                        'sources.txt']
    upload_files_pub = [(out_dir + i) for i in upload_files_pub]
    st.append(ShellCmdWithLink(command=['scp', '-p', '-o', 'StrictHostKeyChecking=no', '-P', upload_config['port'],
                                        upload_files_pub,
                                        util.Interpolate('{}@{}:{}'.format(upload_config['user'], upload_config['host'], masterdest_dir_pub)),
                                        ],
                                 url=util.Interpolate(buildbot_url + 'pub/' + masterdest_dir_pub),
                                 haltOnFailure=True,
                                 name='Upload config and autoconf.h'))

    if boot and config:
        st.extend(steps_build_upload_artifacts_binaries(name, config, out_dir))

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
    step_name_cfg = str(config) + ' config' if config else 'defconfig'
    step_name = 'make dtbs baseline for ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.ShellCommand(command=[util.Interpolate(cmd_make), 'dtbs', 'W=1'],
                                 haltOnFailure=True,
                                 env=env, name=step_name))
    st.append(step_touch_commit_files())
    step_name = 'make dtbs warnings for ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.Compile(command=[util.Interpolate(cmd_make), 'dtbs', 'W=1'],
                            haltOnFailure=True,
                            env=env, name=step_name))
    return st
