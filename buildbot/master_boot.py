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

TARGET_SERIAL_DEV = {
    'arndaleocta': 'by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0',
    'odroidhc1': 'by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D4562A-if00-port0',
    'odroidu3': 'by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D45567-if00-port0',
    'odroidx': 'by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00521AAE-if00-port0',
    'odroidmc1': 'by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00CFE461-if00-port0',
}

TARGET_SSH_USER = 'buildbot'
SERIAL_LOG = 'serial.log'
TIMEOUT_PING = '20'
TIMEOUT_SSH = '30'

TARGET_CONFIG = {
    'arndaleocta': {
        'machine': 'Insignal Arndale Octa evaluation board based on EXYNOS5420',
        'serial': 'ttySAC3',
    },
    'odroidhc1': {
        'machine': 'Hardkernel Odroid HC1',
        'serial': 'ttySAC2',
    },
    'odroidu3': {
        'machine': 'Hardkernel ODROID-U3 board based on Exynos4412',
        'serial': 'ttySAC1',
    },
    'odroidx': {
        'machine': 'Hardkernel ODROID-X board based on Exynos4412',
        'serial': 'ttySAC1',
    },
    'odroidmc1': {
        'machine': 'Hardkernel Odroid HC1',
        'serial': 'ttySAC2',
    },
}

def cmd_serial(target, close=False):
    """
    Returns
        list of strings with cmd
    """
    cmd = ['picocom', '-b', '115200', '--flow', 'none', '--exit']
    if not close:
        cmd.append('--noreset')
    cmd.append('/dev/serial/' + TARGET_SERIAL_DEV[target])

    return cmd

def cmd_ssh(target, command):
    """
    Arguments:
        name - name of step
        target - which board
        command - list with command to execute (passed to ssh)
    Returns
        list of strings with cmd
    """
    return ['ssh', '-o', 'ConnectTimeout %s' % TIMEOUT_SSH,
            '%s@%s' % (TARGET_SSH_USER, target)] + command

def step_serial_open(target):
    """
    Returns:
        step
    """

    return steps.ShellCommand(command=cmd_serial(target, close=False),
                              name='Open serial port',
                              alwaysRun=False,
                              haltOnFailure=True)

def step_serial_close(target):
    """
    Returns:
        step
    """

    return steps.ShellCommand(command=cmd_serial(target, close=True),
                              name='Close serial port',
                              alwaysRun=True,
                              haltOnFailure=False)

def systemd_color(expected):
    return '\x1b[0;1;39m{}\x1b[0m'.format(expected)

def systemd_log(expected_msg, expected_target):
    return "'{0} {1}', '{0} \x1b[0;1;39m{1}\x1b[0m', '{0} [1b][0;1;39m{1}[1b][0m',".format(expected_msg, expected_target)

def pexpect_start(target, log_file, verbose, no_special_chars):
    """ Return string with Python code for new pexpect session inside a "try" block.

    Arguments:
        target - which board
        log_file - where to store serial logs coming from picocom
        verbose - be verbose and print everything (including serial connection logs) to stdout
        no_special_chars - convert all special (non-printable) characters to hex value and do not
                           write to log file (cause this would still store special characters there);
                           when enabled you probably should set verbose=True as well to get the
                           output of log
    Returns:
        string with Python code
    """
    pexpect_logfile = 'None'
    if verbose:
        pexpect_logfile = 'sys.stdout'
    picocom_args = 'picocom -b 115200 --noinit --noreset --flow none'
    if no_special_chars:
        picocom_args += ' --imap spchex'
    else:
        picocom_args += ' --log ' + log_file
    cmd = """
import os
import re
import subprocess
import sys
import time
import pexpect

serial = '/dev/serial/""" + TARGET_SERIAL_DEV[target] + """'
try:
    try:
        os.remove('""" + log_file + """')
    except OSError:
        pass
    child = pexpect.spawn('""" + picocom_args + """ ' + serial,
                          logfile=""" + pexpect_logfile + """,
                          encoding='utf-8', codec_errors='backslashreplace')
    child.expect_exact('Terminal ready')
"""
    return cmd

def pexpect_finish():
    """ Return string with Python code for closing picocom serial and pexpect session.
    This matches the "try" from pexpect_start().

    Returns:
        string with Python code
    """
    cmd = """
finally:
    # C-a + C-x will immediately exit the picocom without flushing data
    # to serial log file. In such case, Buildbot will miss them.
    time.sleep(0.1)
    child.sendcontrol('a')
    child.sendcontrol('x')
    child.expect_exact('Thanks for using picocom')
    # Wait gracefully for shutdown before sending killing signals
    print('Waiting for terminal close')
    for i in range(20):
        if child.isalive():
            time.sleep(0.1)
    child.close(force=True)
    print('Terminal closed')
"""
    return cmd

def pexpect_hard_reset(target, config):
    """ Return string with Python code for hard resetting the power.

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        string with Python code
    """
    pexpect_cmd = """
    process = subprocess.run(['sudo', '/opt/tools/pi/gpio-pi.py', '""" + target + """', 'restart'])
    if process.returncode:
        raise Exception('Cannot restart target (rc: %d)' % process.returncode)
    """
    return pexpect_cmd

def pexpect_gracefull_shutdown(target, config, halt_on_failure=True, reboot=False):
    """ Return string with Python code for graceful shutdown the target over SSH

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Optional arguments:
        halt_on_failure - whether step should halt the build on failure;
                          SSH command turning off the target and any pexpect failures
                          will mark this as failure (default: True)
        reboot - whether step should perform reboot instead of poweroff
    Returns:
        string with Python code
        Remember about no_special_chars=True
    """
    power_cmd = 'reboot' if reboot else 'poweroff'
    pexpect_cmd = """
    process = subprocess.run(""" + str(cmd_ssh(target, ['sudo', power_cmd])) + """,
                             check=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             encoding='utf-8', errors='backslashreplace')
    print('cmd \\'%s\\' returned: %d, output:' % ('""" + power_cmd + """', process.returncode))
    print(process.stdout)
    print('---')
    if not process.returncode or ('Connection to """ + target + """ closed by remote host.' in process.stdout):
        child.expect_exact([""" + \
            systemd_log('Stopped', 'Login Service') + \
            systemd_log('Stopped', 'Network Time Synchronization') + \
            systemd_log('Unmounted', '/home') + \
            systemd_log('Stopped target', 'Swap') + """])
        child.expect_exact([""" + \
            systemd_log('Reached target', 'Shutdown') + \
            systemd_log('Reached target', 'Unmount All Filesystems') + \
            systemd_log('Reached target', 'Final Step') + """])
        child.expect_exact(['Unmounting \\'/oldroot/sys/kernel/config\\'.',
                            'Remounting \\'/oldroot/sys/fs/cgroup/systemd\\' read-only',
                            'shutdown[1]: All filesystems unmounted.',
                            'shutdown[1]: All loop devices detached.'])
        print('Target reached last shutdown log')
        # Wait for final shutdown (it might be 1 second after some of these logs)
        time.sleep(3)
        print('Target reached shutdown state')
    elif """ + ("%d" % halt_on_failure) + """:
        raise Exception('Cannot shutdown target (rc: %d)' % process.returncode)
    """
    return pexpect_cmd

def pexpect_boot_to_prompt(target, config):
    """ Return string with Python code for booting the target to user-space prompt.

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        string with Python code
    """
    pexpect_cmd = """
    child.expect_exact('U-Boot ')
    #                  New U-Boot,                      Old vendor U-Boot on Odroid XU
    child.expect_exact(['Hit any key to stop autoboot', 'Press \\'Enter\\' or \\'Space\\' to stop autoboot'])
    child.expect_exact('scanning usb for ethernet devices... 1 Ethernet Device(s) found')
    child.expect_exact('Waiting for Ethernet connection... done.')

    child.expect_exact('TFTP from server 192.168.1.10; our IP address is 192.168.1.')
    child.expect_exact('Filename \\'zImage\\'.')
    # On Pi3 Wireless speed is 180 kB/s, so timeout has to be higher
    child.expect_exact('done', timeout=120)
    child.expect_exact('Bytes transferred = ')

    child.expect_exact('TFTP from server 192.168.1.10; our IP address is 192.168.1.')
    child.expect('Filename \\'exynos[0-9]+-[a-z0-9-]+.dtb\\'.')
    # On Pi3 Wireless speed is 180 kB/s, so timeout has to be higher
    child.expect_exact('done', timeout=120)
    child.expect_exact('Bytes transferred = ')

    child.expect_exact('TFTP from server 192.168.1.10; our IP address is 192.168.1.')
    child.expect('Filename \\'uboot-initramfs-odroidx?u3.img\\'.')
    # On Pi3 Wireless speed is 180 kB/s, so timeout has to be higher
    child.expect_exact('done', timeout=120)
    child.expect_exact('Bytes transferred = ')
    """
    if target == 'odroidu3':
        # Odroid U3 U-Boot reboots after using network
        pexpect_cmd += """
    child.expect_exact('writing tftpboot-uInitrd')
    child.expect_exact('Everything fetched and written to /boot')
    child.expect_exact('resetting ...')
    child.expect_exact('U-Boot ')
    child.expect_exact('Hit any key to stop autoboot')
    child.expect_exact('reading tftpboot-boot.scr')
    child.expect_exact('Booting from fetched data')
    child.expect_exact('reading tftpboot-exynos4412-odroidu3.dtb')
    child.expect_exact('reading tftpboot-uInitrd')
    child.expect_exact('reading tftpboot-zImage')
    """

    if target not in ['odroidxu', 'arndaleocta']:
        pexpect_cmd += """child.expect_exact('Kernel image @ ')"""

    pexpect_cmd += """
    child.expect('## Loading init Ramdisk from Legacy Image at [0-9a-z]+0000 ...')
    child.expect_exact('Image Name:   U-Boot Odroid ARMv7 ramdisk')
    child.expect_exact('Image Type:   ARM Linux RAMDisk Image (gzip compressed)')
    """
    if target not in ['odroidxu', 'arndaleocta']:
        pexpect_cmd += """child.expect_exact('Verifying Checksum ... OK')"""
    pexpect_cmd += """
    child.expect('## Flattened Device Tree blob at [0-9a-z]+0000')

    print('Target """ + target + """ reached: Boot kernel')
    child.expect_exact('Starting kernel ...')
    child.expect_exact('Booting Linux on physical CPU')
    # TODO: Add check in tests
    # Older (e.g. v4.4) kernels: fdt: Machine model: Hardkernel Odroid XU3 Lite
    # New kernels: OF: fdt: Machine model: Hardkernel Odroid XU3 Lite
    child.expect_exact('Machine model: """ + TARGET_CONFIG[target]['machine'] + """')
    """

    if config == 'exynos':
        # Aparently on multi_v7 IP configuration does not appear (modules instead of built-in)
        pexpect_cmd += """
    child.expect_exact('IP-Config: Complete:')
    child.expect_exact('bootserver=192.168.1.10, rootserver=192.168.1.10, rootpath=')
    """

    pexpect_cmd += """
    print('Target """ + target + """ reached: Mount NFS root')
    child.expect_exact([':: running early hook [udev]', ':: running hook [udev]', ':: Triggering uevents...'])
    child.expect_exact(':: running hook [net_nfs4]')
    child.expect_exact(['NFS-Mount: 192.168.1.10:/srv/nfs/""" + target + """',
                        'mount.nfs4 -o vers=4,nolock 192.168.1.10:/srv/nfs/""" + target + """'])

    print('Target """ + target + """ reached: Mounted NFS root, start system')
    # NFS mount sometimes take a lot of time so add additional intermediate expects
    # and use higher timeouts.
    # Sometimes these messages got corrupted and mixed with each other so look for any of them:
    child.expect_exact([':: running cleanup hook [udev]',
                        'System time before build time, advancing clock.',
                        # New kernels:
                        'random: crng init done',
                        # Old (v4.4) kernels:
                        'random: nonblocking pool is initialized'],
                       timeout=60)
    # On certain next kernels (next-20180924), this takes up to 100 seconds:
    child.expect_exact('systemd[1]: Detected architecture arm.', timeout=180)
    child.expect_exact(['Set hostname to <""" + target + """>',
                        'Hostname set to <""" + target + """>'])
    print('Target """ + target + """ reached: Started systemd')
    # Wait for any early targets, before file systems to see if boot progresses
    child.expect_exact(['Reached target Remote File Systems',
                        'Reached target """ + systemd_color('Remote File Systems') + """',
                        'Reached target Paths',
                        'Reached target """ + systemd_color('Paths') + """',
                        'Reached target Swap',
                        'Reached target """ + systemd_color('Swap') + """'],
                       timeout=30)
    print('Target """ + target + """ reached: Intermediate system boot targets')
    # Getting to local file systems can take a lot
    child.expect_exact(['Reached target Local File Systems',
                        'Reached target """ + systemd_color('Local File Systems') + """'],
                       timeout=90)

    print('Target """ + target + """ reached: Mounted local file systems')
    expect = ['Reached target Login Prompts',
              'Reached target """ + systemd_color('Login Prompts') + """',
              'Reached target Graphical Interface',
              'Reached target """ + systemd_color('Graphical Interface') + """',
              'A start job is running for Flush']
    index = child.expect_exact(expect)
    if index == 4:
        # Sometimes, e.g. on unclean shutdowns, flushing Journal Persistent Storage takes up to 90 seconds,
        # so then just repeat looking for prompt:
        print('Longer timeout needed for """ + target + """')
        child.expect_exact(expect, timeout=180)

    print('Target """ + target + """ reached: Reached login interface')
    child.expect('Arch Linux [0-9a-z\.-]+ \\(""" + TARGET_CONFIG[target]['serial'] + """\\)')
    child.expect_exact('""" + target + """ login:')
    """
    return pexpect_cmd

def step_pexpect(name, target, python_code, interpolate=False,
                 do_step_if=True, always_run=False, halt_on_failure=True,
                 verbose=False, no_special_chars=False):
    """ Return step for executing Python code with pexpect.

    Arguments:
        name - name of step
        target - which board
        python_code - Python code to execute after setting up pexpect (this can be actually any Python code)
    Optional arguments:
        interpolate - put the python_cmd within buildbot.util.Interpolate (default: False)
        do_step_if - optional callable whether step should be done (passed to doStepIf) (default: True)
        always_run - whether step should be executed always (default: False)
        halt_on_failure - whether step should halt the build on failure (default: True)
        verbose - be verbose and print everything (including serial connection logs) to stdout (default: False)
        no_special_chars - convert all special (non-printable) characters to hex value and do not
                           write to log file (cause this would still store special characters there);
                           when enabled you probably should set verbose=True as well to get the
                           output of log (default: False)
    Returns:
        step
    """
    if interpolate:
        full_cmd = util.Interpolate(pexpect_start(target, SERIAL_LOG, verbose, no_special_chars) + "\n" + python_code + "\n" + pexpect_finish())
    else:
        full_cmd = pexpect_start(target, SERIAL_LOG, verbose, no_special_chars) + "\n" + python_code + "\n" + pexpect_finish()

    return steps.ShellCommand(command=['/usr/bin/env', 'python', '-c', full_cmd],
                              name=name,
                              logfiles={'serial0': SERIAL_LOG},
                              doStepIf=do_step_if,
                              alwaysRun=always_run,
                              haltOnFailure=halt_on_failure)

def step_subprocess(name, target, command,
                    do_step_if=True, always_run=False, halt_on_failure=True):
    """ Return step for executing one command in subprocess while
    still getting all the logs and handling serial with pexpect

    Arguments:
        name - name of step
        target - which board
        command - list with command to execute (passed to subprocess.call())
    Optional arguments:
        do_step_if - optional callable whether step should be done (passed to doStepIf) (default: True)
        always_run - whether step should be executed always (default: False)
        halt_on_failure - whether step should halt the build on failure (default: True)
    Returns:
        step
    """
    pexpect_cmd = """
    subprocess.run(""" + str(command) + """, check=True)
    """

    return step_pexpect(name=name, target=target, python_code=pexpect_cmd, do_step_if=do_step_if,
                        always_run=always_run, halt_on_failure=halt_on_failure)

def step_ssh(name, target, command, do_step_if=True, halt_on_failure=True):
    """ Return step for executing one command on the target via SSH

    Arguments:
        name - name of step
        target - which board
        command - list with command to execute (passed to subprocess.run())
    Optional arguments:
        do_step_if - optional callable whether step should be done (passed to doStepIf) (default: True)
        halt_on_failure - whether step should halt the build on failure (default: True)
    Returns:
        step
    """
    return step_subprocess(name, target, cmd_ssh(target, command),
                           do_step_if=do_step_if, halt_on_failure=halt_on_failure)

def step_boot_to_prompt(target, config):
    """ Return step for booting the target to user-space prompt

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        step
    """
    pexpect_cmd = pexpect_hard_reset(target, config) + pexpect_boot_to_prompt(target, config)
    return step_pexpect(name='Boot: ' + target, target=target, python_code=pexpect_cmd)

def step_test_ping(target, config):
    """ Return step for pinging target

    Returns:
        step
    """
    return step_subprocess('Test: ping', target,
                           ['ping', '-c', '1', '-W', TIMEOUT_PING, target])

def step_test_uname(target, config):
    """ Return step for executing uname on the target via SSH and checking
    if it matches expected kernel

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        step
                print('cmd %s returned: %d, output:' % ('uname -a', process.returncode))
    """
    # Since this is going to interpolate, we cannot use '%' string format inside. Use format().
    pexpect_cmd = """
    process = subprocess.run(""" + str(cmd_ssh(target, ['uname', '-a'])) + """,
                            check=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            encoding='utf-8', errors='backslashreplace')

    print('cmd \\'{0}\\' returned: {1}, output:'.format('umame -a', process.returncode))
    print(process.stdout)
    print('---')
    if not process.returncode:
        expected_output = '^Linux """ + target + """ %(prop:kernel_version:-)s #[0-9] SMP (PREEMPT )?[0-9a-zA-Z: ]+ armv7l GNU/Linux$'
        print('checking if uname matches expected: ' + expected_output)
        print('uname output: ' + process.stdout)
        if not re.search(expected_output, process.stdout):
            raise Exception('uname of target does not match expected (output: ' + process.stdout + ')')
    else:
        raise Exception('Cannot run cmd target (rc: {0})'.format(process.returncode))
    """
    return step_pexpect(name='Test: uname', target=target, python_code=pexpect_cmd, interpolate=True)

def step_test_dmesg_errors(target, config):
    """ Return step for getting dmesg errors on the target via SSH

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        step
    """
    # TODO: report as warnings?
    return step_ssh('Test: dmesg errors', target, ['dmesg', '-l', 'err'])

def step_test_dmesg_warnings(target, config):
    """ Return step for getting dmesg warnings on the target via SSH

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        step
    """
    # TODO: report as warnings?
    return step_ssh('Test: dmesg warnings', target, ['dmesg', '-l', 'warn'])

def step_gracefull_shutdown(target, config, always_run=False, halt_on_failure=True, reboot=False):
    """ Return step for graceful shutdown the target over SSH

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Optional arguments:
        always_run - whether step should be executed always (default: False)
        halt_on_failure - whether step should halt the build on failure;
                          SSH command turning off the target and any pexpect failures
                          will mark this as failure (default: True)
        reboot - whether step should perform reboot instead of poweroff
    Returns:
        step
    """
    power_title = 'Reboot: ' if reboot else 'Power off: '
    pexpect_cmd = pexpect_gracefull_shutdown(target, config, halt_on_failure=halt_on_failure, reboot=reboot)
    # no_special_chars+verbose are necessary to fix Buildbot 1.2.0-1.3.0 issue with stalled
    # command when non-printable character (coming from board with reboot message) is retrieved
    return step_pexpect(name=power_title + target, target=target, python_code=pexpect_cmd,
                        always_run=always_run, halt_on_failure=halt_on_failure,
                        verbose=True, no_special_chars=True)

def step_test_reboot(target, config):
    """ Return step for rebooting target (and waiting to come up)

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        step
    """
    # Perform gracefull shutdown and boot in one pexpect because otherwise U-Boot prints
    # could be missed.
    pexpect_cmd = pexpect_gracefull_shutdown(target, config, halt_on_failure=True, reboot=True)
    pexpect_cmd += pexpect_boot_to_prompt(target, config)
    return step_pexpect(name='Reboot: ' + target, target=target,
                        python_code=pexpect_cmd,
                        verbose=False, no_special_chars=False)

def steps_shutdown(target, config):
    """ Return steps for shutting down the target

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
    Returns:
        list of steps
    """
    st = []

    st.append(step_gracefull_shutdown(target, config, always_run=True, halt_on_failure=False))
    st.append(step_serial_close(target))
    st.append(steps.ShellCommand(command=['sudo', '/opt/tools/pi/gpio-pi.py', target, 'off'],
                                 name='Cut the power: ' + target,
                                 alwaysRun=True,
                                 haltOnFailure=True))
    return st

def if_step_want_tests(step):
    """ Returns true if step is for booting kernel suitable for tests

    Dynamic (executed during runtime of builder) helper

    See: Matrix of configurations
    """

    project = str(step.getProperty('project', default='none'))
    # Match stable and stable-rc:
    if 'stable' in project:
        return False
    # Match next and mainline
    if project in ['mainline', 'next']:
        # For mainline and next, run tests only on HC1 and U3. Skip XU3 and XU.
        # Compare here only the name of boards, without config, even though
        # tests might not be executed on certain configs (See: Matrix of configurations)
        if ('boot-odroid-u3-' in step.build.builder.name) or ('boot-odroid-hc1-' in step.build.builder.name):
            return True
        return False

    # Reamining projects: krzk
    if ('boot-odroid-xu-' in step.build.builder.name):
        return False
    return True

def step_test_case(target, config, test, is_fast=False, force_skip=False):
    """ Return step for executing one test

    Arguments:
        target - which board
        config - which config us being tested (e.g. exynos, multi_v7)
        test - name of test to execute (should match /opt/tools/tests/)
    Optional arguments:
        is_fast - whether test is simple and should be executed on all targets and configs (default: False)
        force_skip - whether test should be skipped because it does not match the target;
                     overrides is_simple and if_step_want_tests() (default: False)
    Returns:
        step
    """
    test_allowed = not force_skip

    return step_ssh('Test: ' + test + ' @' + target, target,
                    ['sudo', '/opt/tools/tests/' + test + '.sh', target, config],
                    halt_on_failure=False,
                    do_step_if=lambda step: test_allowed and (is_fast or if_step_want_tests(step)))

def steps_test_suite_fast(target, config):
    st = []
    if config != 'exynos':
        return st

    # Run all non-intensive, non-disruptive and non-dependant tests
    st.append(step_test_case(target, config, 'adc-exynos', is_fast=True))
    # Broken and I do not have time to work on this
    # st.append(step_test_case(target, config, 'arm-pmu', is_fast=True))
    st.append(step_test_case(target, config, 'audio', is_fast=True))
    st.append(step_test_case(target, config, 'board-name', is_fast=True))
    st.append(step_test_case(target, config, 'board-led', is_fast=True))
    st.append(step_test_case(target, config, 'clk-s2mps11', is_fast=True))
    st.append(step_test_case(target, config, 'cpu-online', is_fast=True))
    st.append(step_test_case(target, config, 'drm', is_fast=True))
    st.append(step_test_case(target, config, 's5p-mfc', is_fast=True))
    st.append(step_test_case(target, config, 's5p-sss', is_fast=True))
    st.append(step_test_case(target, config, 'thermal', is_fast=True))
    st.append(step_test_case(target, config, 'usb', is_fast=True))
    st.append(step_test_case(target, config, 'var-all', is_fast=True))

    # Tries unbind-bind which might affect audio, so should be last:
    st.append(step_test_case(target, config, 'audss', is_fast=True))

    return st

def steps_test_suite_slow(target, config):
    st = []
    # Run intensive tests only on exynos_defconfig because on multi_v7 some tests hang
    # the buildbot console and some fail because of missing modules (like sound).
    # This requires also decent kernel, so do not run on stable (limited
    # by doStepIf=if_step_want_tests).
    # See: Matrix of configurations
    if config != 'exynos':
        return st
    st.append(step_test_case(target, config, 'cpu-mmc-stress', force_skip=(target != 'odroidxu3')))
    st.append(step_test_case(target, config, 'pwm-fan'))
    # Intensive and not that important test, run it only on XU3
    # No point to test tcrypt - it does not use s5p-sss anymore
    #st.append(step_test_case(target, config, 's5p-sss-tcrypt'))
    # No point to test cryptsetup - it does not use s5p-sss anymore
    #st.append(step_test_case(target, config, 's5p-sss-cryptsetup'))

    # RNG does not work on Odroid, missing clock enable?
    # st.append(step_test_case(target, config, 'rng-exynos'))

    # RTC often fail on NFS root so put it at the end
    # Also RTC of max77686 seems to fail pretty often, so skip U3:
    st.append(step_test_case(target, config, 'rtc', force_skip=(target == 'odroidu3')))
    st.append(step_test_case(target, config, 'thermal-cooling'))

    return st

def steps_download(target):
    st = []
    mastersrc_dir = 'deploy-bin/%(prop:trigger_builder)s/%(prop:revision)s'

    # Everything going to /srv should be group-writeable so I can update it manually
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/zImage'),
        workerdest=u'/srv/tftp/zImage',
        haltOnFailure=True, mode=0o0664, name='Download zImage'))
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/dtb-out.tar.xz'),
        workerdest='deploy-dtb-out.tar.xz',
        haltOnFailure=True, mode=0o0644, name='Download dtb'))
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/modules-out.tar.xz'),
        workerdest='deploy-modules-out.tar.xz',
        haltOnFailure=True, mode=0o0644, name='Download modules'))

    return st

def steps_boot(builder_name, target, config, run_pm_tests=False):
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

    st.append(steps.ShellCommand(command=['rm', '-fr', 'lib',
                                          'deploy-modules-out.tar.xz', 'deploy-dtb-out.tar.xz',
                                          'initramfs-odroidxu3.img'],
                                 name='Remove old binaries'))
    st = st + steps_download(target)

    st.append(steps.ShellCommand(command=[util.Interpolate('%(prop:builddir:-~/)s/tools/buildbot/build-slave-deploy.sh'),
                                          target, config, util.Property('revision'), 'deploy-tmp'],
                                 haltOnFailure=True,
                                 name='Deploy on server binaries for booting'))
    st.append(steps.SetPropertyFromCommand(command='ls deploy-tmp/lib/modules',
                                           property='kernel_version', haltOnFailure=True))

    st.append(step_serial_open(target))

    st.append(step_gracefull_shutdown(target, config, halt_on_failure=False))

    st.append(step_boot_to_prompt(target, config))
    st.append(step_test_ping(target, config))
    st.append(step_test_uname(target, config))
    st.append(step_test_dmesg_errors(target, config))
    st.append(step_test_dmesg_warnings(target, config))

    st = st + steps_test_suite_fast(target, config)
    st = st + steps_test_suite_slow(target, config)

    # After all the tests check again if ping and SSH are working:
    st.append(step_test_ping(target, config))
    st.append(step_test_uname(target, config))

    # Test reboot
    st.append(step_test_reboot(target, config))
    st.append(step_test_ping(target, config))
    st.append(step_test_uname(target, config))

    st = st + steps_shutdown(target, config)

    return st
