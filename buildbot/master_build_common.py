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

# src is for util.Interpolate
def step_upload_files_to_master(name, src, dest, errors_fatal=False, url=''):
    if errors_fatal:
        halt_on_failure=True
        warn_on_failure=False
        flunk_on_failure=True
    else:
        halt_on_failure=False
        warn_on_failure=True
        flunk_on_failure=False
    sftp_cmd = 'cd {}\n'.format(dest)
    for out in src:
        sftp_cmd += 'put {}\n'.format(out)
    cmd = '''
        echo "{}" | sftp -p -o StrictHostKeyChecking=no -P {} -b - {}@{}'''.format(sftp_cmd,
        master_auth_config['upload']['port'],
        master_auth_config['upload']['user'],
        master_auth_config['upload']['host'])
    if url:
        return ShellCmdWithLink(command=util.Interpolate(cmd),
                                url=url,
                                haltOnFailure=halt_on_failure,
                                warnOnFailure=warn_on_failure,
                                flunkOnFailure=flunk_on_failure,
                                name=name)
    else:
        return steps.ShellCommand(command=util.Interpolate(cmd),
                                  haltOnFailure=halt_on_failure,
                                  warnOnFailure=warn_on_failure,
                                  flunkOnFailure=flunk_on_failure,
                                  name=name)

def steps_prepare_upload_master(name, dest):
    st = []
    st.append(steps.MasterShellCommand(command=['mkdir', '-p', util.Interpolate(dest)],
                                       haltOnFailure=True,
                                       name=name))
    cmd = 'chgrp {} {} $(dirname {})'.format(master_auth_config['upload']['user'], dest, dest)
    st.append(steps.MasterShellCommand(command=util.Interpolate(cmd),
                                       haltOnFailure=True,
                                       name=name + ' (chgrp)'))
    cmd = 'chmod g+rwx,o+rx {} $(dirname {})'.format(dest, dest)
    st.append(steps.MasterShellCommand(command=util.Interpolate(cmd),
                                       haltOnFailure=True,
                                       name=name + ' (chmod)'))
    return st

def steps_build_clean(env, always_run=False):
    st = []
    st.append(steps.ShellCommand(command=['rm', '-fr', env['KBUILD_OUTPUT']],
                                 haltOnFailure=True,
                                 alwaysRun=always_run,
                                 name='Remove kbuild output directory'))
    return st

def steps_build_common(env, kbuild_output, config=None):
    st = []
    # OpenStack machines have frequent github.com name resolution failures:
    # fatal: unable to access 'https://github.com/krzk/tools.git/': Could not resolve host: github.com
    # Cache the address first.
    st.append(steps.ShellCommand(command=util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/name-resolve-fixup.sh'),
                                 haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
                                 name='Cache DNS addresses (workaround)'))
    st.extend(steps_build_clean(env))
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

def steps_build_upload_artifacts(name, config, out_dir, buildbot_url):
    st = []
    masterdest_dir_pub = 'deploy-pub/' + name + '/%(prop:revision)s/'

    st.extend(steps_prepare_upload_master('Prepare upload directory: sources', masterdest_dir_pub))

    cmd = 'echo "Source URL: %(prop:repository_src:-%(prop:repository)s)s\nRevision: %(prop:revision)s" > ' + out_dir + 'sources.txt; '
    cmd += 'cp -p ' + out_dir + '.config ' + out_dir + 'config; '
    cmd += 'chmod a+r,g+w ' + out_dir + 'config; '
    cmd += 'chmod a+r,g+w ' + out_dir + 'sources.txt; '
    cmd += 'chmod a+r,g+w ' + out_dir + 'include/generated/autoconf.h'
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
    return st

def steps_build_mem_ctrl_adjust_config(builder_name, env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'SRAM', '-e', 'MEMORY', '-e', 'PM_DEVFREQ',
                 # drivers/memory/Kconfig
                 '-e', 'ARM_PL172_MPMC',
                 '-e', 'ATMEL_SDRAMC', '-e', 'ATMEL_EBI',
                 '-e', 'BRCMSTB_DPFE', '-e', 'BRCMSTB_MEMC',
                 '-e', 'BT1_L2_CTL',
                 '-e', 'TI_AEMIF', '-e', 'TI_EMIF', '-e', 'OMAP_GPMC',
                 '-e', 'TI_EMIF_SRAM',
                 # FPGA_DFL_EMIF + dependencies:
                 '-e', 'FPGA', '-e', 'FPGA_DFL', '-e', 'FPGA_DFL_EMIF',
                 # drivers/memory/Kconfig
                 '-e', 'MVEBU_DEVBUS', '-e', 'FSL_CORENET_CF',
                 '-e', 'FSL_IFC', '-e', 'JZ4780_NEMC', '-e', 'MTK_SMI',
                 '-e', 'DA8XX_DDRCTL', '-e', 'PL353_SMC', '-e', 'RENESAS_RPCIF',
                 '-e', 'STM32_FMC2_EBI',
                 # drivers/memory/samsung/Kconfig
                 '-e', 'SAMSUNG_MC', '-e', 'EXYNOS5422_DMC',
                 '-e', 'EXYNOS_SROM',
                 # drivers/memory/tegra/Kconfig
                 '-e', 'TEGRA_MC', '-e', 'TEGRA20_EMC',
                 '-e', 'TEGRA30_EMC', '-e', 'TEGRA124_EMC', '-e', 'TEGRA210_EMC_TABLE',
                 '-e', 'TEGRA210_EMC',
                ],
        haltOnFailure=True,
        env=env, name='Toggle memory controller compile test config'))
    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_w1_adjust_config(builder_name, env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'w1', '-e', 'CONNECTOR', '-e', 'W1_CON',
                 # drivers/w1/masters/Kconfig
                 '-e', 'W1_MASTER_MATROX',
                 '-e', 'W1_MASTER_DS2490', '-e', 'W1_MASTER_DS2482',
                 '-e', 'W1_MASTER_MXC', '-e', 'W1_MASTER_GPIO',
                 '-e', 'HDQ_MASTER_OMAP', '-e', 'W1_MASTER_SGI',
                 # drivers/w1/slaves/Kconfig
                 '-e', 'W1_SLAVE_THERM', '-e', 'W1_SLAVE_SMEM',
                 '-e', 'W1_SLAVE_DS2405', '-e', 'W1_SLAVE_DS2408',
                 '-e', 'W1_SLAVE_DS2408_READBACK', '-e', 'W1_SLAVE_DS2413',
                 '-e', 'W1_SLAVE_DS2406', '-e', 'W1_SLAVE_DS2423',
                 '-e', 'W1_SLAVE_DS2805', '-e', 'W1_SLAVE_DS2430',
                 '-e', 'W1_SLAVE_DS2431', '-e', 'W1_SLAVE_DS2433',
                 '-e', 'W1_SLAVE_DS2433_CRC', '-e', 'W1_SLAVE_DS2438',
                 '-e', 'W1_SLAVE_DS250X', '-e', 'W1_SLAVE_DS2780',
                 '-e', 'W1_SLAVE_DS2781', '-e', 'W1_SLAVE_DS28E04',
                 '-e', 'W1_SLAVE_DS28E17',
                ],
        haltOnFailure=True,
        env=env, name='Toggle w1 compile test config'))
    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_all_drivers_adjust_config(builder_name, env, kbuild_output):
     st = []
     st.extend(steps_build_mem_ctrl_adjust_config(builder_name, env, kbuild_output, make_olddefconfig=False))
     st.extend(steps_build_w1_adjust_config(builder_name, env, kbuild_output, make_olddefconfig=True))
     return st

def steps_build_selected_folders(builder_name, env):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(command=[util.Interpolate(CMD_MAKE), 'arch/arm/',
                                          # make won't build DTBs but include it for completeness
                                          'arch/arm64/boot/dts/',
                                          'drivers/clk/samsung/', 'drivers/pinctrl/samsung/', 'drivers/memory/',
                                          'drivers/soc/samsung/', 'drivers/w1/'],
                                 haltOnFailure=True, env=env, name='Build selected paths'))
    st.append(step_touch_commit_files())
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'arch/arm/',
                                     # make won't build DTBs but include it for completeness
                                     'arch/arm64/boot/dts/',
                                     'drivers/clk/samsung/', 'drivers/pinctrl/samsung/', 'drivers/memory/',
                                     'drivers/soc/samsung/', 'drivers/w1/'],
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=BUILD_WARN_IGNORE,
                            env=env, name='Rebuild selected paths'))
    return st

def steps_dtbs_check(env, kbuild_output, config=None, git_reset=True, only_changed_files=True):
    st = []
    if git_reset:
        st += steps_build_common(env, kbuild_output, config)
    else:
        st.append(step_make_config(env, config))
    if not config:
        # Disable all other platforms than Exynos and Tesla FSD
        st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-worker-strip-config.sh'),
                                              env['KBUILD_OUTPUT'], 'samsung'],
                                     haltOnFailure=True,
                                     env=env,
                                     name='Strip unneeded platforms from config'))
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env,
                                name='Make olddefconfig'))

    step_name_cfg = str(config) + ' config' if config else 'defconfig'
    if only_changed_files:
        step_name = 'make dtbs_check baseline for ' + env['ARCH'] + '/' + step_name_cfg
        st.append(steps.ShellCommand(command=[util.Interpolate(CMD_MAKE), 'dtbs_check', 'DT_SCHEMA_FILES=Documentation/devicetree/bindings/'],
                                     haltOnFailure=True,
                                     env=env, name=step_name))
        st.append(step_touch_commit_files())

    step_name = 'make dtbs_check warnings for ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'dtbs_check', 'DT_SCHEMA_FILES=Documentation/devicetree/bindings/'],
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=BUILD_WARN_IGNORE,
                            warningPattern="^.*\.dtb: ",
                            env=env, name=step_name))
    return st

def steps_dtbs_warnings(env, kbuild_output, config=None, git_reset=True):
    st = []
    if git_reset:
        st += steps_build_common(env, kbuild_output, config)
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
