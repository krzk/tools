# -*- python -*-
# ex: set filetype=python:
#
# Copyright (c) 2016-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

from master_auth import master_auth_config

from buildbot.plugins import steps, util
import twisted

BUILD_WARN_IGNORE = [ (None, '.*warning: #warning syscall .* not implemented.*', None, None),
                    ]

CMD_MAKE = '%(prop:builddir:-~/)s/tools/buildbot/build-slave.sh'

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

@util.renderer
def repo_git_kernel_org(props):
    repo = props.getProperty('repository')
    return repo.replace('file:///var/lib/mirror', 'git://git.kernel.org')

def cmd_make_config(config=None):
    if config == None:
        config = 'defconfig'
    elif config in ['allyes', 'allmod', 'def']:
        config = config + 'config'
    else:
        config = str(config) + '_defconfig'
    return [util.Interpolate(CMD_MAKE), config]

def step_make_config(env, config=None):
    step_name = str(config) + ' config' if config else 'defconfig'
    step_name = 'make ' + step_name
    return steps.Compile(command=cmd_make_config(config),
                         haltOnFailure=True, env=env, name=step_name)

def step_touch_commit_files():
    cmd = '''
    DIFF_CMD="git diff-tree --diff-filter=ACM --no-commit-id --name-only -r"
    if git rev-parse HEAD^2 ; then
        # It's a merge
        if [ "$(git rev-parse HEAD^2)" = "$(git rev-parse origin/master)" ]; then
            # Merge with master, so get only one parent
            FILES="`$DIFF_CMD HEAD^2..HEAD`"
        elif [ "$(git rev-parse HEAD^1)" = "$(git rev-parse origin/master)" ]; then
            # Merge with master, so get only one parent
            FILES="`$DIFF_CMD HEAD^1..HEAD`"
        else
            # Merge between my branches, touch files changed by both parents
            FILES="`$DIFF_CMD HEAD^1..HEAD` `$DIFF_CMD HEAD^2..HEAD`"
        fi
    else
        FILES="`$DIFF_CMD HEAD`"
    fi
    touch $FILES
    echo $FILES
    '''
    return steps.ShellCommand(command=['/bin/sh', '-c', cmd],
                              haltOnFailure=True,
                              name='touch changed files')

def step_prepare_upload_master(name, dest):
    return steps.ShellCommand(command=['ssh', '-o', 'StrictHostKeyChecking=no', '-p', master_auth_config['upload']['port'],
                                       '{}@{}'.format(master_auth_config['upload']['user'], master_auth_config['upload']['host']),
                                       util.Interpolate('mkdir -p ' + dest),
                                      ],
                              haltOnFailure=True,
                              name=name)

def step_upload_files_to_master(name, src, dest, errors_fatal=False, url=''):
    if errors_fatal:
        halt_on_failure=True
        warn_on_failure=False
        flunk_on_failure=True
    else:
        halt_on_failure=False
        warn_on_failure=True
        flunk_on_failure=False
    command=['scp', '-p', '-o', 'StrictHostKeyChecking=no', '-P', master_auth_config['upload']['port'],
             src,
             util.Interpolate('{}@{}:{}'.format(master_auth_config['upload']['user'], master_auth_config['upload']['host'], dest)),
            ]
    if url:
        return ShellCmdWithLink(command=command,
                                url=url,
                                haltOnFailure=halt_on_failure,
                                warnOnFailure=warn_on_failure,
                                flunkOnFailure=flunk_on_failure,
                                name=name)
    else:
        return steps.ShellCommand(command=command,
                                  haltOnFailure=halt_on_failure,
                                  warnOnFailure=warn_on_failure,
                                  flunkOnFailure=flunk_on_failure,
                                  name=name)

def steps_build_common(env, config=None):
    st = []
    # OpenStack machines have frequent github.com name resolution failures:
    # fatal: unable to access 'https://github.com/krzk/tools.git/': Could not resolve host: github.com
    # Cache the address first.
    st.append(steps.ShellCommand(command=util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/name-resolve-fixup.sh'),
                                 haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
                                 name='Cache DNS addresses (workaround)'))
    st.append(steps.Git(repourl='https://github.com/krzk/tools.git',
                        name='Clone krzk tools sources',
                        mode='incremental',
                        alwaysUseLatest=True,
                        branch='master',
                        getDescription=False,
                        workdir='tools',
                        haltOnFailure=True,
                        env=util.Property('git_env')))
    st.append(steps.Git(repourl=repo_git_kernel_org,
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
    st.append(steps.SetPropertyFromCommand(command='${CROSS_COMPILE}gcc --version | head -n 1',
                                           property='gcc_version', haltOnFailure=True,
                                           env=env, name='Set property: gcc version'))
    st.append(steps.SetPropertyFromCommand(command=[util.Interpolate(CMD_MAKE), '-s', 'kernelversion'],
                                           property='kernel_version', haltOnFailure=True,
                                           env=env, name='Set property: kernel version'))
    st.append(step_make_config(env, config))

    return st

def steps_build_linux_kernel(env, build_step_name='Build kernel', skip_warnings=True):
    st = []
    if skip_warnings:
        st.append(steps.ShellCommand(command=[util.Interpolate(CMD_MAKE)], haltOnFailure=True,
                                     env=env, name=build_step_name))
    else:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE)], haltOnFailure=True,
                                warnOnWarnings=True,
                                suppressionList=BUILD_WARN_IGNORE,
                                env=env, name=build_step_name))
    return st

def steps_build_upload_artifacts_binaries(name, config, out_dir):
    st = []

    masterdest_dir_bin = 'deploy-bin/' + name + '/%(prop:revision)s/'
    st.append(step_prepare_upload_master('Prepare upload directory: binaries', masterdest_dir_bin))

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
    st.append(step_upload_files_to_master('Upload kernel, modules and required DTBs',
                                          upload_files_bin, masterdest_dir_bin,
                                          errors_fatal=True))

    # XU, XU4 and HC1 might be missing for older kernels -  In case of failure do not halt,
    # do not fail and mark build as warning. flunkOnFailure is by default True.
    upload_files_bin = ['arch/arm/boot/dts/exynos5410-odroidxu.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidhc1.dtb',
                        'arch/arm/boot/dts/exynos5422-odroidxu4.dtb',
                        ]
    upload_files_bin = [(out_dir + i) for i in upload_files_bin]
    st.append(step_upload_files_to_master('Upload optional DTBs',
                                           upload_files_bin, masterdest_dir_bin))

    return st

def steps_build_upload_artifacts(name, config, boot, out_dir, buildbot_url):
    st = []
    masterdest_dir_pub = 'deploy-pub/' + name + '/%(prop:revision)s/'

    st.append(step_prepare_upload_master('Prepare upload directory: sources', masterdest_dir_pub))

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
    st.append(step_upload_files_to_master('Upload config and autoconf.h',
                                          upload_files_pub, masterdest_dir_pub,
                                          errors_fatal=True,
                                          url=util.Interpolate(buildbot_url + 'pub/' + masterdest_dir_pub)))

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
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
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
                 '-e', 'TI_EMIF_SRAM', '-e', 'FPGA_DFL_EMIF',
                 '-e', 'MVEBU_DEVBUS', '-e', 'FSL_CORENET_CF',
                 '-e', 'FSL_IFC', '-e', 'JZ4780_NEMC', '-e', 'MTK_SMI',
                 '-e', 'DA8XX_DDRCTL', '-e', 'PL353_SMC', '-e', 'RENESAS_RPCIF',
                 '-e', 'STM32_FMC2_EBI', '-e', 'SAMSUNG_MC', '-e', 'EXYNOS5422_DMC',
                 '-e', 'EXYNOS_SROM', '-e', 'TEGRA_MC', '-e', 'TEGRA20_EMC',
                 '-e', 'TEGRA30_EMC', '-e', 'TEGRA124_EMC', '-e', 'TEGRA210_EMC_TABLE',
                 '-e', 'TEGRA210_EMC',
                ],
        haltOnFailure=True,
        env=env, name='Toggle memory controller compile test config'))
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                            haltOnFailure=True,
                            env=env, name='Make olddefconfig'))
    return st

def steps_build_selected_folders(builder_name, env):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(command=[util.Interpolate(CMD_MAKE), 'arch/arm/',
                                          # make won't build DTBs but include it for completeness
                                          'arch/arm64/boot/dts/',
                                          'drivers/clk/samsung/', 'drivers/pinctrl/samsung/', 'drivers/memory/',
                                          'drivers/soc/samsung/'],
                                 haltOnFailure=True, env=env, name='Build selected paths'))
    st.append(step_touch_commit_files())
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'arch/arm/',
                                     # make won't build DTBs but include it for completeness
                                     'arch/arm64/boot/dts/',
                                     'drivers/clk/samsung/', 'drivers/pinctrl/samsung/', 'drivers/memory/',
                                     'drivers/soc/samsung/'],
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=BUILD_WARN_IGNORE,
                            env=env, name='Rebuild selected paths'))
    return st

def steps_checkdtbs(env, config=None, git_reset=True):
    st = []
    if git_reset:
        st += steps_build_common(env, config)
    else:
        st.append(step_make_config(env, config))
    step_name_cfg = str(config) + ' config' if config else 'defconfig'
    step_name = 'make dtbs baseline for ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.ShellCommand(command=[util.Interpolate(CMD_MAKE), 'dtbs', 'W=1'],
                                 haltOnFailure=True,
                                 env=env, name=step_name))
    st.append(step_touch_commit_files())
    step_name = 'make dtbs warnings for ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'dtbs', 'W=1'],
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=BUILD_WARN_IGNORE,
                            env=env, name=step_name))
    return st

def steps_build_with_warnings_diff(builder_name, env):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.extend(steps_build_linux_kernel(env, skip_warnings=True))
    st.append(step_touch_commit_files())
    st.extend(steps_build_linux_kernel(env, build_step_name='Rebuild kernel', skip_warnings=False))
    return st
