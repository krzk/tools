# -*- python -*-
# ex: set filetype=python:
#
# Copyright (c) 2016-2023 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

from master_auth import master_auth_config

from buildbot.plugins import steps, util
from buildbot import process
import twisted
import re
import shlex

BUILD_WARN_IGNORE = [
    (None, '.*warning: #warning syscall .* not implemented.*', None, None),
    (None, re.escape("warning: 'arch/riscv/kernel/vdso/vdso.so.dbg': invalid PT_DYNAMIC size"), None, None),
    (None, re.escape("warning: 'arch/riscv/kernel/vdso/vdso.so.dbg': PT_DYNAMIC dynamic table is invalid: SHT_DYNAMIC will be used"), None, None),
    # v6.16-rc1:
    (None, 'warning: arch/powerpc/boot/zImage.pseries has a LOAD segment with RWX permissions', None, None),
    # v6.16-rc1:
    (None, 'warning: arch/powerpc/boot/zImage.epapr has a LOAD segment with RWX permissions', None, None),
    ('.*exynos5433.dtsi$', re.escape("Warning (graph_child_address): /soc@0/decon@13800000/ports: graph node has single child node 'port@0', #address-cells/#size-cells are not necessary"), None, None),
    ('.*exynos5433.dtsi$', re.escape("Warning (graph_child_address): /soc@0/dsi@13900000/ports: graph node has single child node 'port@0', #address-cells/#size-cells are not necessary"), None, None),
    ('.*exynos5433-tm2-common.dtsi$', re.escape("Warning (graph_child_address): /soc@0/decon@13880000/ports: graph node has single child node 'port@0', #address-cells/#size-cells are not necessary"), None, None),
    # Fix probably in linux-next after v6.16-rc1 (so for v6.17):
    ('.*emif.c:67$', re.escape("struct member 'lpmode' not described in 'emif_data'"), None, None),
    ]
CMD_MAKE = '%(prop:builddir:-~/)s/tools/buildbot/build-slave.sh'

DTBS_CHECK_KNOWN_WARNINGS = {
    'all': {
        'arm': {
            'exynos': [
                # Pending on mailing list (old patchset)
                ('.*exynos5250-snow.dtb$', re.escape("/i2c-arbitrator/i2c-arb/power-regulator@48: failed to match any schema with compatible: ['ti,tps65090']"), None, None),
                ('.*exynos5250-snow-rev5.dtb$', re.escape("/i2c-arbitrator/i2c-arb/power-regulator@48: failed to match any schema with compatible: ['ti,tps65090']"), None, None),
                ('.*exynos5420-peach-pit.dtb$', re.escape("/soc/spi@12d40000/cros-ec@0/i2c-tunnel/power-regulator@48: failed to match any schema with compatible: ['ti,tps65090']"), None, None),
                ('.*exynos5800-peach-pi.dtb$', re.escape("/soc/spi@12d40000/cros-ec@0/i2c-tunnel/power-regulator@48: failed to match any schema with compatible: ['ti,tps65090']"), None, None),
                # Appear on next/pending-fixes, scheduled for v5.10-rc1
                ('.*exynos4.*.dtb$', re.escape("keypad@100a0000: 'linux,keypad-no-autorepeat' does not match any of the regexes: '^key-[0-9a-z]+$', 'pinctrl-[0-9]+'"), None, None),
                ('.*exynos4412-smdk4412.dtb$', re.escape("keypad@100a0000: 'key-A', 'key-B', 'key-C', 'key-D', 'key-E', 'linux,keypad-no-autorepeat' do not match any of the regexes: '^key-[0-9a-z]+$', 'pinctrl-[0-9]+'"), None, None),
                # Appearing with dtschema 2025.6 and should be fixed for v6.17
                ('.*exynos3250-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): \$nodename:0: 'i2c-gpio-.' does not match.*", None, None),
                ('.*exynos3250-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): Unevaluated properties are not allowed \('#address-cells', '#size-cells', .*", None, None),
                ('.*exynos4210-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): \$nodename:0: 'i2c-gpio-.' does not match.*", None, None),
                ('.*exynos4210-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): Unevaluated properties are not allowed \('#address-cells', '#size-cells', .*", None, None),
                ('.*exynos4[24]12-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): \$nodename:0: 'i2c-gpio-.' does not match.*", None, None),
                ('.*exynos4[24]12-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): Unevaluated properties are not allowed \('#address-cells', '#size-cells', .*", None, None),
            ],
            's3c6400': [
            ],
            's5pv210': [
                # For dtschema >=2025.6
                ('.*s5pv210-aquila.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-aquila.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                # For dtschema <=2025.2
                ('.*s5pv210-aquila.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                ('.*s5pv210-fascinate4g.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-fascinate4g.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-fascinate4g.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                ('.*s5pv210-galaxys.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-galaxys.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-galaxys.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                ('.*s5pv210-goni.dtb$', re.escape("/soc/i2c@e1800000/sensor@30: failed to match any schema with compatible: ['siliconfile,noon010pc30']"), None, None),
                ('.*s5pv210-goni.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-goni.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-goni.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                ('.*s5pv210-smdkc110.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-smdkc110.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-smdkc110.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                ('.*s5pv210-smdkv210.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-smdkv210.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-smdkv210.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                ('.*s5pv210-torbreck.dtb$', "i2s@e[0-9a-f]+ \(samsung,s3c6410-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-torbreck.dtb$', "i2s@e[0-9a-f]+ \(samsung,s5pv210-i2s\): #sound-dai-cells: 1 was expected", None, None),
                ('.*s5pv210-torbreck.dtb$', "i2s@e[0-9a-f]+: #sound-dai-cells:(0:0:)? 1 was expected", None, None),
                # Appearing with dtschema 2025.6 and should be fixed for v6.17
                ('.*s5pv210-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): \$nodename:0: 'i2c-gpio-.' does not match.*", None, None),
                ('.*s5pv210-.*.dtb$', "i2c-gpio-. \(i2c-gpio\): Unevaluated properties are not allowed \('#address-cells', '#size-cells', .*", None, None),
            ],
        },
        'arm64': {
            'defconfig': [
                # Pending on mailing lists (probably v6.11-rc1)
                ('.*gs101-oriole.dtb$', re.escape("/soc@0/phy@11100000: failed to match any schema with compatible: ['google,gs101-usb31drd-phy']"), None, None),
                # Pending on mailing lists, probably v6.14-rc1 - https://lore.kernel.org/all/20241206-gs101-phy-lanes-orientation-phy-v4-2-f5961268b149@linaro.org/
                ('.*gs101-oriole.dtb$', re.escape("phy@11100000: 'orientation-switch' does not match any of the regexes: 'pinctrl-[0-9]+'"), None, None),
                ('.*gs101-raven.dtb$', re.escape("phy@11100000: 'orientation-switch' does not match any of the regexes: 'pinctrl-[0-9]+'"), None, None),
                # Appearing with dtschema 2025.6 and should be fixed for v6.17
                ('.*exynos5433-tm2.*.dtb$', "i2c-gpio-. \(i2c-gpio\): \$nodename:0: 'i2c-gpio-.' does not match.*", None, None),
                ('.*exynos5433-tm2.*.dtb$', "i2c-gpio-. \(i2c-gpio\): Unevaluated properties are not allowed \('#address-cells', '#size-cells', .*", None, None),
            ],
        },
    },
    'krzk': {
        'arm': {
            'exynos': [
                # Applied for v6.10-rc1
                ('.*exynos.*.dtb$', re.escape("/soc/dp-controller@145b0000: failed to match any schema with compatible: ['samsung,exynos5-dp']"), None, None),
            ],
            's3c6400': [
                # Applied for v6.10-rc1 (krzk/clk)
                ('.*s3c6410-.*.dtb$', re.escape("/soc/clock-controller@7e00f000: failed to match any schema with compatible: ['samsung,s3c6410-clock']"), None, None),
            ],
            's5pv210': [
                # Applied for v6.10-rc1
                ('.*s5pv210-.*.dtb$', re.escape("/soc/onenand@b0600000: failed to match any schema with compatible: ['samsung,s5pv210-onenand']"), None, None),
                ('.*s5pv210-.*.dtb$', re.escape("/soc/nand-controller@b0600000: failed to match any schema with compatible: ['samsung,s5pv210-onenand']"), None, None),
                ('.*s5pv210-.*.dtb$', re.escape("/soc/dmc@f0000000: failed to match any schema with compatible: ['samsung,s5pv210-dmc']"), None, None),
                ('.*s5pv210-.*.dtb$', re.escape("/soc/dmc@f1400000: failed to match any schema with compatible: ['samsung,s5pv210-dmc']"), None, None),
            ],
        },
        'arm64': {
            'defconfig': [
            ],
        },
    },
}

DT_BINDING_CHECK_KNOWN_WARNINGS = [
    ('.*snps,dwmac.yaml$', 'mac-mode: missing type definition', None, None),
    ('.*adi,ad7173.yaml$', 'oneOf: Missing additionalProperties/unevaluatedProperties constraint', None, None),
    ('.*xlnx,zynqmp-r5fss.yaml$', 'Missing additionalProperties/unevaluatedProperties constraint', None, None),
    ('.*st,stm32-romem.yaml$', 'Missing additionalProperties/unevaluatedProperties constraint', None, None),
    ('.*hi3798cv200-perictrl.example.dtb$', re.escape("/example-0/peripheral-controller@8a20000/phy@850: failed to match any schema with compatible: ['hisilicon,hi3798cv200-combphy']"), None, None),
    ('.*brcm,avs-ro-thermal.example.dtb$', re.escape("/example-0/avs-monitor@7d5d2000: failed to match any schema with compatible: ['brcm,bcm2711-avs-monitor', 'syscon', 'simple-mfd']"), None, None),
    # Fixed with: https://lore.kernel.org/all/20241112-fd-dp-fux-warning-v2-1-8cc4960094bd@linaro.org/
    ('.*qcom,sa8775p-mdss.example.dtb$', re.escape('displayport-controller@af54000: reg: [[183844864, 260], [183845376, 192], [183848960, 1904], [183853056, 156]] is too short'), None, None),
    # v6.16-rc1:
    ('.*/pinctrl/xlnx,versal-pinctrl.yaml$', 'allOf: Missing additionalProperties/unevaluatedProperties constraint', None, None),
    # v6.16-rc1:
    ('.*/regulator/infineon,ir38060.yaml$', re.escape("maintainers:0: 'Not Me.' does not match '@'"), None, None),
]

DTBS_CHECK_BOARDS = {
    'arm64': {
        'qcom': [
            'qcom/ipq5332-rdp468',
            'qcom/ipq9574-rdp418',
            'qcom/qdu1000-idp',
            'qcom/qrb2210-rb1',
            'qcom/qrb4210-rb2',
            'qcom/sa8540p-ride',
            'qcom/sa8775p-ride',
            'qcom/sc7280-herobrine-evoker',
            'qcom/sc8280xp-lenovo-thinkpad-x13s',
            'qcom/sdm630-sony-xperia-nile-discovery',
            'qcom/sdm670-google-sargo',
            'qcom/sdx75-idp',
            'qcom/sm4250-oneplus-billie2',
            'qcom/sm4450-qrd',
            'qcom/sm6115p-lenovo-j606f',
            'qcom/sm6125-xiaomi-laurel-sprout',
            'qcom/sm8250-hdk',
            'qcom/sm8350-hdk',
            'qcom/sm8450-hdk',
            'qcom/sm8450-qrd',
            'qcom/sm8550-mtp',
            'qcom/sm8550-qrd',
        ],
    },
}

DTBS_CHECK_WARNING_PATTERN = "^(.*?\.dtb): (.*)$"
DT_BINDING_CHECK_WARNING_PATTERN = "^(.*?\.yaml|.*?\.example\.dtb): (.*)$"

def warnExtractFromRegexpGroups(self, line, match):
    """
    Extract file name and warning text as groups (1,2)
    of warningPattern match."""
    file = match.group(1)
    text = match.group(2)
    return (file, None, text)

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

def step_set_prop_if_file_exists(name, prop, files):
    """ Return step for setting a property if given file exists. The file will be used
    as value of property. Otherwise (if file does not exist) it sets empty property.
    Does not fail the test.

    Arguments:
        name - name for the step
        prop - name of property to set
        files - list of files to check, strings suitable for util.Interpolate()
    Returns:
        step
    """
    cmd = ''
    for file in files:
        cmd += '[ -f "%s" ] && ls -1 "%s" && exit 0\n' % (file, file)
    cmd += 'exit 0'
    return steps.SetPropertyFromCommand(command=util.Interpolate(cmd),
                                        property=prop,
                                        haltOnFailure=True,
                                        name=name)

def step_set_prop_if_changed_path(name, prop, path):
    """ Return step for setting a property if commit changes given path and under.
    The path will be used as value of property. Otherwise (if commit does not change path)
    it sets empty property. Does not fail the test.

    Arguments:
        name - name for the step
        prop - name of property to set
        path - path to look for changes under, must be shell friendly
    Returns:
        step
    """
    cmd = '''
    DIFF_CMD="git diff-tree --diff-filter=ACDMRT --no-commit-id --name-only -r"
    git rev-parse HEAD^2 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
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
    for file in ${FILES}; do
        if [ "$file" != "${file#''' + shlex.quote(path) + '''}" ]; then
            echo $file
            exit 0
        fi
    done
    exit 0
    '''
    return steps.SetPropertyFromCommand(command=util.Interpolate(cmd),
                                        property=prop,
                                        haltOnFailure=True,
                                        name=name)

def is_set_arm_boot_dts_vendor_subdirs(step):
    if step.getProperty('arm_boot_dts_vendor_subdirs') and (len(str(step.getProperty('arm_boot_dts_vendor_subdirs'))) > 0):
        return True
    return False

def is_set_dt_bindings_changed(step):
    if step.getProperty('dt_bindings_changed') and (len(str(step.getProperty('dt_bindings_changed'))) > 0):
        return True
    return False

def step_make_config(env, config=None):
    step_name = str(config) + ' config' if config else 'defconfig'
    step_name = 'make ' + step_name
    return steps.Compile(command=cmd_make_config(config),
                         haltOnFailure=True, env=env, name=step_name)

def step_touch_commit_files():
    cmd = '''
    DIFF_CMD="git diff-tree --diff-filter=ACMRT --no-commit-id --name-only -r"
    git rev-parse HEAD^2 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
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
def step_upload_files_to_master(name, src, dest, errors_fatal=False, url='', do_step_if=True):
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
                                doStepIf=do_step_if,
                                hideStepIf=lambda results, s: results==process.results.SKIPPED,
                                haltOnFailure=halt_on_failure,
                                warnOnFailure=warn_on_failure,
                                flunkOnFailure=flunk_on_failure,
                                name=name)
    else:
        return steps.ShellCommand(command=util.Interpolate(cmd),
                                  doStepIf=do_step_if,
                                  hideStepIf=lambda results, s: results==process.results.SKIPPED,
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

def steps_prepare_build_storage(name, dest):
    st = []
    st.append(steps.ShellCommand(command=['mkdir', '-p', util.Interpolate(dest)],
                                 haltOnFailure=True,
                                 name=name))
    cmd = 'chmod a+rx {} $(dirname {})'.format(dest, dest)
    st.append(steps.ShellCommand(command=util.Interpolate(cmd),
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
    # Workers use grokmirror same way as buildbot-master, so same repository path will work
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
    st.append(steps.SetPropertyFromCommand(command='${CROSS_COMPILE}gcc --version | head -n 1',
                                           property='gcc_version', haltOnFailure=True,
                                           env=env, name='Set property: gcc version'))
    st.append(steps.SetPropertyFromCommand(command=[util.Interpolate(CMD_MAKE), '-s', 'kernelversion'],
                                           property='kernel_version', haltOnFailure=True,
                                           env=env, name='Set property: kernel version'))
    st.append(steps.SetPropertyFromCommand(command=['dt-validate', '--version'],
                                           property='dtschema_version', haltOnFailure=True,
                                           env=env, name='Set property: dtschema version'))
    st.append(step_set_prop_if_file_exists('Set property: ARM DTS vendor subdirs',
                                           'arm_boot_dts_vendor_subdirs',
                                           ['arch/arm/boot/dts/samsung/Makefile']))
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

def steps_build_arm_var_multi_v4_v5_adjust_config(env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'ARCH_MULTI_V4', '-e', 'ARCH_MOXART',
                 '-e', 'ARCH_MULTI_V4T', '-e', 'ARCH_NSPIRE',
                 '-e', 'ARCH_MULTI_V5', '-e', 'MACH_ASM9260',
                 '-e', 'ARCH_MULTI_V5', '-e', 'ARCH_WM8505',
                ],
        haltOnFailure=True,
        env=env, name='Toggle arm v4 and v5 platforms compile test config'))
    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_arm_var_multi_v6_v7_adjust_config(env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'ARCH_MULTI_V7', '-e', 'ARM_LPAE', '-e', 'ARCH_AXXIA',
                 '-e', 'ARCH_MULTI_V6', '-e', 'ARCH_WM8750',
                 '-e', 'ARCH_MULTI_V7', '-e', 'ARCH_WM8850',
                ],
        haltOnFailure=True,
        env=env, name='Toggle arm v6 and v7 platforms compile test config'))
    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_mem_ctrl_adjust_config(env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'SRAM', '-e', 'MEMORY', '-e', 'PM_DEVFREQ',
                 # FPGA_DFL_EMIF dependencies:
                 '-e', 'FPGA', '-e', 'FPGA_DFL',
                ],
        haltOnFailure=True,
        env=env, name='Toggle memory controller compile test config'))
    st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-worker-add-config.sh'),
                                              env['KBUILD_OUTPUT'], 'memory', 'memory'],
                                 haltOnFailure=True,
                                 env=env,
                                 name='Add memory controller to config'))
    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_pinctrl_adjust_config(env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'PINCTRL'
                ],
        haltOnFailure=True,
        env=env, name='Toggle pin controller compile test config'))
    st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-worker-add-config.sh'),
                                              env['KBUILD_OUTPUT'], 'pinctrl', 'samsung'],
                                 haltOnFailure=True,
                                 env=env,
                                 name='Add pinctrl/samsung to config'))
    st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-worker-add-config.sh'),
                                              env['KBUILD_OUTPUT'], 'pinctrl', 'qcom'],
                                 haltOnFailure=True,
                                 env=env,
                                 name='Add pinctrl/qcom to config'))

    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_w1_adjust_config(env, kbuild_output, make_olddefconfig=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    st.append(steps.ShellCommand(
        command=['scripts/config', '--file', util.Interpolate(kbuild_output + '.config'),
                 '-e', 'COMPILE_TEST', '-e', 'OF',
                 '-e', 'W1', '-e', 'CONNECTOR', '-e', 'W1_CON'
                ],
        haltOnFailure=True,
        env=env, name='Toggle w1 compile test config'))
    st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-worker-add-config.sh'),
                                              env['KBUILD_OUTPUT'], 'w1', 'w1'],
                                 haltOnFailure=True,
                                 env=env,
                                 name='Add w1 to config'))
    if make_olddefconfig:
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env, name='Make olddefconfig'))
    return st

def steps_build_all_drivers_adjust_config(env, kbuild_output):
     st = []
     st.extend(steps_build_arm_var_multi_v6_v7_adjust_config(env, kbuild_output, make_olddefconfig=False))
     st.extend(steps_build_mem_ctrl_adjust_config(env, kbuild_output, make_olddefconfig=False))
     st.extend(steps_build_pinctrl_adjust_config(env, kbuild_output, make_olddefconfig=False))
     st.extend(steps_build_w1_adjust_config(env, kbuild_output, make_olddefconfig=True))
     return st

def steps_build_selected_folders(builder_name, env, make_flags=None, touch_changed=True):
    st = []
    if not env['KBUILD_OUTPUT']:
        raise ValueError('Missing KBUILD_OUTPUT path in environment')
    paths_to_build = ['arch/arm/',
                      # make won't build DTBs but include it for completeness
                      'arch/arm64/boot/dts/',
                      'drivers/clk/samsung/',
                      'drivers/firmware/samsung/',
                      'drivers/interconnect/samsung/',
                      'drivers/memory/',
                      'drivers/phy/samsung/'
                      'drivers/pinctrl/samsung/', 'drivers/pinctrl/qcom/',
                      'drivers/pmdomain/samsung/'
                      'drivers/soc/samsung/',
                      'drivers/thermal/samsung/',
                      'drivers/w1/']
    cmd = [util.Interpolate(CMD_MAKE)]
    if make_flags:
        cmd.append(str(make_flags))
    cmd.extend(paths_to_build)
    cmd_name = 'Build selected paths'
    if touch_changed:
        st.append(steps.ShellCommand(command=cmd,
                                     haltOnFailure=True, env=env, name=cmd_name))
        st.append(step_touch_commit_files())
        cmd_name='Rebuild selected paths'
    st.append(steps.Compile(command=cmd,
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=BUILD_WARN_IGNORE,
                            env=env, name=cmd_name))
    return st

def steps_build_selected_folders_warnings(builder_name, env):
    return steps_build_selected_folders(builder_name, env, make_flags='W=1', touch_changed=True)

def steps_build_selected_folders_no_touch(builder_name, env):
    return steps_build_selected_folders(builder_name, env, touch_changed=False)

def steps_build_selected_folders_no_touch_warnings(builder_name, env):
    return steps_build_selected_folders(builder_name, env, make_flags='W=1', touch_changed=False)

def steps_dt_binding_check(env, kbuild_output):
    st = []
    st += steps_build_common(env, kbuild_output)
    st.append(step_set_prop_if_changed_path('Set property: changed bindings',
                                            'dt_bindings_changed',
                                            # Don't care about headers - no impact on schema bindings expected
                                            'Documentation/devicetree/bindings/'))
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'dt_binding_check'],
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=DT_BINDING_CHECK_KNOWN_WARNINGS,
                            warningPattern=DT_BINDING_CHECK_WARNING_PATTERN,
                            warningExtractor=warnExtractFromRegexpGroups,
                            doStepIf=is_set_dt_bindings_changed,
                            env=env, name='make dt_binding_check'))
    return st

def steps_dtbs_check(env, kbuild_output, platform, config=None, git_reset=True, only_changed_files=True, next_or_mainline=False):
    st = []
    if git_reset:
        st += steps_build_common(env, kbuild_output, config)
    else:
        st.append(step_make_config(env, config))
    schema_dirs = []
    if platform == 'samsung':
        schema_dirs = ['']
    elif platform == 'qcom':
        schema_dirs = ['bus/',
                       'cache/',
                       'crypto/',
                       'dma/',
                       'display/connector/',
                       'eeprom/',
                       'extcon/',
                       'firmware/',
                       'gpio/',
                       'gpu/',
                       'hwlock/',
                       'hwmon/',
                       'i2c/',
                       'input/gpio',
                       'interconnect/',
                       'interrupt-controller/',
                       'iio/',
                       'ipmi/',
                       'media/',
                       'memory-controllers/',
                       'misc/',
                       'mmc/',
                       'mtd/',
                       'net/',
                       'nvmem/',
                       'pinctrl/',
                       'pwm/',
                       'power/',
                       'regulator/',
                       'reserved-memory/',
                       'reset/',
                       'rng/',
                       'rtc/',
                       'serial/',
                       'slimbus/',
                       'soundwire/',
                       'spi/',
                       'sram/',
                       'w1/',
                       'watchdog/',
                       'trivial-devices.yaml',
                       'vendor-prefixes.yaml',
                       ]

    if not config:
        st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-worker-strip-config.sh'),
                                              env['KBUILD_OUTPUT'], platform],
                                     haltOnFailure=True,
                                     env=env,
                                     name='Strip unneeded platforms from config'))
        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'olddefconfig'],
                                haltOnFailure=True,
                                env=env,
                                name='Make olddefconfig'))

    step_name_cfg = str(config) + ' config' if config else 'defconfig'
    real_config = config if config else 'defconfig'
    if only_changed_files:
        for schema in schema_dirs:
            step_name = 'make dtbs_check baseline: ' + env['ARCH'] + '/' + step_name_cfg + '/' + schema.strip('/')
            cmd_dtbs_check = [util.Interpolate(CMD_MAKE), 'dtbs_check']
            if schema:
                cmd_dtbs_check.append(f'DT_SCHEMA_FILES={schema}')
            st.append(steps.ShellCommand(command=cmd_dtbs_check,
                                         haltOnFailure=True,
                                         env=env, name=step_name[:50]))
        st.append(step_touch_commit_files())

    for schema in schema_dirs:
        step_name = 'make dtbs_check warnings: ' + env['ARCH'] + '/' + step_name_cfg + '/' + schema.strip('/')
        cmd_dtbs_check = [util.Interpolate(CMD_MAKE), 'dtbs_check']
        if schema:
            cmd_dtbs_check.append(f'DT_SCHEMA_FILES={schema}')
        suppression_list = []
        if env['ARCH'] in DTBS_CHECK_KNOWN_WARNINGS['all']:
            if real_config in DTBS_CHECK_KNOWN_WARNINGS['all'][env['ARCH']]:
                suppression_list = DTBS_CHECK_KNOWN_WARNINGS['all'][env['ARCH']][real_config]
        if not next_or_mainline:
            if env['ARCH'] in DTBS_CHECK_KNOWN_WARNINGS['krzk']:
                if real_config in DTBS_CHECK_KNOWN_WARNINGS['krzk'][env['ARCH']]:
                    suppression_list.extend(DTBS_CHECK_KNOWN_WARNINGS['krzk'][env['ARCH']][real_config])
        st.append(steps.Compile(command=cmd_dtbs_check,
                                haltOnFailure=True,
                                warnOnWarnings=True,
                                suppressionList=suppression_list,
                                warningPattern=DTBS_CHECK_WARNING_PATTERN,
                                warningExtractor=warnExtractFromRegexpGroups,
                                env=env, name=step_name[:50]))
    return st

def steps_dtbs_check_boards(env, kbuild_output, boards, config=None, git_reset=True):
    st = []
    if git_reset:
        st += steps_build_common(env, kbuild_output, config)
    else:
        st.append(step_make_config(env, config))

    for board in boards:
        step_name = 'make dtbs_check for {}'.format(board)

        st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'CHECK_DTBS=y',
                                         '{}.dtb'.format(board)],
                                haltOnFailure=True,
                                warnOnWarnings=True,
                                warningPattern=DTBS_CHECK_WARNING_PATTERN,
                                warningExtractor=warnExtractFromRegexpGroups,
                                env=env, name=step_name[:50]))
    return st

def steps_dtbs_warnings(env, kbuild_output, config=None):
    st = []
    step_name_cfg = str(config) + ' config' if config else 'defconfig'
    step_name = 'make dtbs baseline: ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.ShellCommand(command=[util.Interpolate(CMD_MAKE), 'dtbs', 'W=1'],
                                 haltOnFailure=True,
                                 env=env, name=step_name))
    st.append(step_touch_commit_files())
    step_name = 'make dtbs warnings: ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'dtbs', 'W=1'],
                            haltOnFailure=True,
                            warnOnWarnings=True,
                            suppressionList=BUILD_WARN_IGNORE,
                            env=env, name=step_name))
    step_name = 'make dtbs_install: ' + env['ARCH'] + '/' + step_name_cfg
    st.append(steps.Compile(command=[util.Interpolate(CMD_MAKE), 'dtbs_install',
                                     util.Interpolate('INSTALL_DTBS_PATH=' + kbuild_output + 'dtbs-install')],
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
