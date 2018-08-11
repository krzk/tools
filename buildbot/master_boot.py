# -*- python -*-
# ex: set filetype=python:
#

from buildbot.plugins import steps, util

TARGET_SERIAL_DEV = {
    'odroidhc1': 'usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D4562A-if00-port0',
    'odroidu3': 'usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00D45567-if00-port0',
    'odroidxu': 'usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00521AAE-if00-port0',
    'odroidxu3': 'usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_00CFE461-if00-port0',
}

ENV_PATH = {'PATH': '/opt/tools/buildbot:/opt/tools/pi:/usr/local/bin:${PATH}'}

TARGET_SSH_USER = 'buildbot'
SERIAL_LOG = 'serial.log'
CONN_TIMEOUT = '20'

EXPECTED = {
    'odroidhc1': {
        'cpus': '8',
        'machine': 'Hardkernel Odroid HC1',
        'serial': 'ttySAC2',
    },
    'odroidu3': {
        'cpus': '4',
        'machine': 'Hardkernel ODROID-U3 board based on Exynos4412',
        'serial': 'ttySAC1',
    },
    'odroidxu': {
        'cpus': '4',
        'machine': 'Hardkernel Odroid XU',
        'serial': 'ttySAC2',
    },
    'odroidxu3': {
        'cpus': '8',
        'machine': 'Hardkernel Odroid XU3 Lite',
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
    cmd.append('/dev/serial/by-id/' + TARGET_SERIAL_DEV[target])

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
    return ['ssh', '-o', 'ConnectTimeout %s' % CONN_TIMEOUT,
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

def pexpect_start(target, log_file, verbose):
    """ Return string with Python code for new pexpect session inside a "try" block.

    Arguments:
        target - which board
        log_file - where to store serial logs coming from picocom
        verbose - be verbose and print everything (including serial connection logs) to stdout
    Returns:
        string with Python code
    """
    pexpect_logfile = 'None'
    if verbose:
        pexpect_logfile = 'sys.stdout'
    cmd = """
import os
import re
import subprocess
import sys
import time
import pexpect

serial = '/dev/serial/by-id/""" + TARGET_SERIAL_DEV[target] + """'
try:
    try:
        os.remove('""" + log_file + """')
    except OSError:
        pass
    child = pexpect.spawn('picocom -b 115200 --noinit --noreset --flow none --log """ + log_file + """ ' + serial,
                          logfile=""" + pexpect_logfile + """)
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
    for i in range(20):
        if child.isalive():
            time.sleep(0.1)
    child.close(force=True)
"""
    return cmd

def step_pexpect(name, target, python_code, interpolate=False,
                 do_step_if=True, always_run=False,
                 verbose=False):
    """ Return step for executing Python code with pexpect.

    Arguments:
        name - name of step
        target - which board
        python_code - Python code to execute after setting up pexpect (this can be actually any Python code)
    Optional arguments:
        interpolate - put the python_cmd within buildbot.util.Interpolate (default: False)
        do_step_if - optional callable whether step should be done (passed to doStepIf) (default: True)
        always_run - whether step should be executed always and do not halt on failure (default: False)
        verbose - be verbose and print everything (including serial connection logs) to stdout
    Returns:
        step
    """
    if interpolate:
        full_cmd = util.Interpolate(pexpect_start(target, SERIAL_LOG, verbose) + "\n" + python_code + "\n" + pexpect_finish())
    else:
        full_cmd = pexpect_start(target, SERIAL_LOG, verbose) + "\n" + python_code + "\n" + pexpect_finish()

    return steps.ShellCommand(command=['/usr/bin/env', 'python', '-c', full_cmd],
                              name=name,
                              logfiles={'serial0': SERIAL_LOG},
                              doStepIf=do_step_if,
                              alwaysRun=always_run,
                              haltOnFailure=not always_run)

def step_subprocess(name, target, command, always_run=False):
    """ Return step for executing one command in subprocess while
    still getting all the logs and handling serial with pexpect

    Arguments:
        name - name of step
        target - which board
        command - list with command to execute (passed to subprocess.call())
    Optional arguments:
        always_run - whether step should be executed always and do not halt on failure (default: False)
    Returns:
        step
    """
    pexpect_cmd = """
    subprocess.run(""" + str(command) + """, check=True)
    """

    return step_pexpect(name=name, target=target, python_code=pexpect_cmd, always_run=always_run)

def step_ssh(name, target, command):
    """ Return step for executing one command on the target via SSH

    Arguments:
        name - name of step
        target - which board
        command - list with command to execute (passed to subprocess.run())
    Returns:
        step
    """
    return step_subprocess(name, target, cmd_ssh(target, command))

def step_boot_to_prompt(target, config):
    """ Return step for booting the target to user-space prompt

    Returns:
        step
    """
    pexpect_cmd = """
    process = subprocess.run(['sudo', 'gpio-pi.py', '""" + target + """', 'restart'])
    if process.returncode:
        raise Exception('Cannot restart target (rc: %d)' % process.returncode)

    child.expect_exact('U-Boot ')
    child.expect_exact('CPU: ')
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
    child.expect_exact('CPU: ')
    child.expect_exact('Hit any key to stop autoboot')
    child.expect_exact('reading tftpboot-boot.scr')
    child.expect_exact('Booting from fetched data')
    child.expect_exact('reading tftpboot-exynos4412-odroidu3.dtb')
    child.expect_exact('reading tftpboot-uInitrd')
    child.expect_exact('reading tftpboot-zImage')
    """

    if target != 'odroidxu':
        pexpect_cmd += """child.expect_exact('Kernel image @ ')"""

    pexpect_cmd += """
    child.expect_exact('## Loading init Ramdisk from Legacy Image at 45000000 ...')
    child.expect_exact('Image Name:   U-Boot Odroid ARMv7 ramdisk')
    child.expect_exact('Image Type:   ARM Linux RAMDisk Image (gzip compressed)')
    """
    if target != 'odroidxu':
        pexpect_cmd += """child.expect_exact('Verifying Checksum ... OK')"""
    pexpect_cmd += """
    child.expect_exact('## Flattened Device Tree blob at 44000000')

    print('Target """ + target + """ reached: Boot kernel')
    child.expect_exact('Starting kernel ...')
    child.expect_exact('Booting Linux on physical CPU')
    # TODO: Add check in tests
    # Older (e.g. v4.4) kernels: fdt: Machine model: Hardkernel Odroid XU3 Lite
    # New kernels: OF: fdt: Machine model: Hardkernel Odroid XU3 Lite
    child.expect_exact('Machine model: """ + EXPECTED[target]['machine'] + """')
    child.expect_exact('SMP: Total of """ + EXPECTED[target]['cpus'] + """ processors activated')
    child.expect_exact('IP-Config: Complete:')
    child.expect_exact('bootserver=192.168.1.10, rootserver=192.168.1.10, rootpath=')

    print('Target """ + target + """ reached: Mount NFS root')
    child.expect_exact(':: running hook [udev]')
    child.expect_exact(':: running hook [net_nfs4]')
    child.expect_exact('IP-Config: eth0 complete (from 192.168.1.10):')
    child.expect_exact('NFS-Mount: 192.168.1.10:/srv/nfs/""" + target + """')
    child.expect_exact('Waiting 10 seconds for device /dev/nfs ...')

    print('Target """ + target + """ reached: Mounted NFS root, start system')
    # NFS mount sometimes take a lot of time so add additional intermediate expects
    # and use higher timeouts.
    # New kernels: random: crng init done
    # Old (v4.4) kernels: random: nonblocking pool is initialized
    # child.expect_exact('random: crng init done', timeout=60)
    child.expect_exact(':: running cleanup hook [udev]', timeout=60)
    child.expect_exact('systemd[1]: Detected architecture arm.', timeout=60)
    child.expect_exact('Set hostname to <""" + target + """>.')
    child.expect_exact('Reached target Swap.')
    child.expect_exact('Started udev Kernel Device Manager')
    # Detection of all devices (including storage) can take up to 15 seconds
    # (Odroid HC1) on Pi3 Ethernet.
    # On Pi3 Wireless this takes up to one minute
    child.expect_exact('Reached target Local File Systems.', timeout=120)

    print('Target """ + target + """ reached: Mounted local file systems')
    child.expect_exact('Reached target Login Prompts.')
    child.expect_exact('Reached target Graphical Interface.')

    print('Target """ + target + """ reached: Reached login interface')
    child.expect('Arch Linux [0-9a-z\.-]+ \\(""" + EXPECTED[target]['serial'] + """\\)')
    child.expect_exact('""" + target + """ login:')
    """
    return step_pexpect(name='Boot: ' + target, target=target, python_code=pexpect_cmd)

def step_test_ping(target, config):
    """ Return step for pinging target

    Returns:
        step
    """
    return step_subprocess('Test: ping', target,
                           ['ping', '-c', '1', '-W', CONN_TIMEOUT, target])

def step_test_uname(target, config):
    """ Return step for executing uname on the target via SSH and checking
    if it matches expected kernel

    Returns:
        step
    """
    pexpect_cmd = """
    process = subprocess.run(""" + str(cmd_ssh(target, ['uname', '-a'])) + """,
                             check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             encoding='utf-8', errors='ignore')
    expected_output = '^Linux """ + target + """ %(prop:kernel_version:-)s #2 SMP PREEMPT [0-9a-zA-Z: ]+ armv7l GNU/Linux$'
    print('checking if uname matches expected: ' + expected_output)
    print('uname output: ' + process.stdout)
    if not re.search(expected_output, process.stdout):
        raise Exception('uname of target does not match expected (output: ' + process.stdout + ')')
    """
    return step_pexpect(name='Test: uname', target=target, python_code=pexpect_cmd, interpolate=True)

def step_test_dmesg_errors(target, config):
    """ Return step for getting dmesg errors on the target via SSH

    Returns:
        step
    """
    return step_ssh('Test: dmesg errors', target, ['dmesg', '-l', 'err'])

def step_test_dmesg_warnings(target, config):
    """ Return step for getting dmesg warnings on the target via SSH

    Returns:
        step
    """
    return step_ssh('Test: dmesg warnings', target, ['dmesg', '-l', 'warn'])

def steps_shutdown(target, config):
    """ Return steps for shutting down the target

    Returns:
        list of steps
    """
    st = []

    # TODO: use expect to wait for target death so XU will not reboot
    st.append(step_subprocess('Power off: ' + target,target,
                              ['/opt/tools/buildbot/target-poweroff.sh', target, config],
                              always_run=True))
    st.append(step_serial_close(target))
    st.append(steps.ShellCommand(command=['sudo', 'gpio-pi.py', target, 'off'],
                                 name='Cut the power: ' + target,
                                 alwaysRun=True,
                                 haltOnFailure=True))
    return st

def if_step_want_tests(step):
    """ Returns true if step is for booting kernel suitable for tests

    Dynamic (executed during runtime of builder) helper
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

    # All rest, so either krzk trees or mainline/next with specific boards (HC1 and U3)
    return True

# Run some of the PM-QA tests. I don't want heating tests
# (thermal, cpufreq) because they stress the board needlessly.
def step_boot_run_pm_tests(target, config):
    st = []
    st.append(steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/usr/sbin/make -C /opt/pm-qa/cpuhotplug check'],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=ENV_PATH, name='PM-QA cpuhotplug tests: ' + target,
        haltOnFailure=True, doStepIf=if_step_want_tests))
    st.append(steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/usr/sbin/make -C /opt/pm-qa/cpuidle check'],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=ENV_PATH, name='PM-QA cpuidle tests: ' + target,
        haltOnFailure=True, doStepIf=if_step_want_tests))
    st.append(steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/usr/sbin/make -C /opt/pm-qa/cputopology check'],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=ENV_PATH, name='PM-QA cputopology tests: ' + target,
        haltOnFailure=True, doStepIf=if_step_want_tests))
    return st

def step_boot_run_test(target, config, test):
    return steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/opt/tools/tests/' + test + '.sh',
                 target, config],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=ENV_PATH, name='Test: ' + test + ' @' + target,
        haltOnFailure=False,
        doStepIf=if_step_want_tests)

def steps_boot_run_tests(target, config):
    st = []
    st.append(step_boot_run_test(target, config, 'drm'))
    if target != 'odroidhc1':
        st.append(step_boot_run_test(target, config, 'pwm-fan'))
    st.append(step_boot_run_test(target, config, 'cpu-online'))
    st.append(step_boot_run_test(target, config, 'thermal'))
    st.append(step_boot_run_test(target, config, 'odroid-xu3-board-name'))
    if target == 'odroidxu3':
        # Intensive and not that important test, run it only on XU3
        st.append(step_boot_run_test(target, config, 'cpu-mmc-stress'))
    st.append(step_boot_run_test(target, config, 's5p-sss'))
    st.append(step_boot_run_test(target, config, 's5p-sss-cryptsetup'))
    st.append(step_boot_run_test(target, config, 'usb'))
    st.append(step_boot_run_test(target, config, 'var-all'))
    st.append(step_boot_run_test(target, config, 'clk-s2mps11'))
    if target != 'odroidhc1':
        st.append(step_boot_run_test(target, config, 'audio'))
    # RTC often fail on NFS root so put it at the end
    # Also RTC of max77686 seems to fail pretty often, so skip U3:
    if target != 'odroidu3':
	    st.append(step_boot_run_test(target, config, 'rtc'))
    # RNG does not work on Odroid, missing clock enable?
    # st.append(step_boot_run_test(target, config, 'rng-exynos'))
    st.append(step_boot_run_test(target, config, 'audss'))

    return st

def steps_download(target):
    st = []
    mastersrc_dir = u'bins-deploy/%(prop:trigger_builder)s/%(prop:revision)s'

    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/zImage'),
        workerdest=u'/srv/tftp/zImage',
        haltOnFailure=True, mode=0664, name='Download zImage'))
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/exynos5422-odroidxu3-lite.dtb'),
        workerdest=u'/srv/tftp/exynos5422-odroidxu3-lite.dtb',
        haltOnFailure=True, mode=0664, name='Download Odroid XU3 DTB'))
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/exynos4412-odroidu3.dtb'),
        workerdest=u'/srv/tftp/exynos4412-odroidu3.dtb',
        haltOnFailure=True, mode=0664, name='Download Odroid U3 DTB'))

    # XU, XU4 and HC1 might be missing for older kernels
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/exynos5410-odroidxu.dtb'),
        workerdest=u'/srv/tftp/exynos5410-odroidxu.dtb',
        haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
        mode=0664, name='Download Odroid XU DTB'))
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/exynos5422-odroidxu4.dtb'),
        workerdest=u'/srv/tftp/exynos5422-odroidxu4.dtb',
        # In case of failure do not halt, do not fail and mark build as warning.
        # flunkOnFailure is by default True.
        haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
        mode=0664, name='Download Odroid XU4 DTB'))
    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/exynos5422-odroidhc1.dtb'),
        workerdest=u'/srv/tftp/exynos5422-odroidhc1.dtb',
        haltOnFailure=False, warnOnFailure=True, flunkOnFailure=False,
        mode=0664, name='Download Odroid HC1 DTB'))

    st.append(steps.FileDownload(
        mastersrc=util.Interpolate(mastersrc_dir + '/modules-out.tar.gz'),
        workerdest='deploy-modules-out.tar.gz',
        haltOnFailure=True, mode=0644, name='Download modules'))

    return st

def steps_boot(builder_name, target, config, run_tests=False, run_pm_tests=False):
    st = []

    st.append(steps.ShellCommand(command=['rm', '-fr', 'lib',
                                          'deploy-modules-out.tar.gz', 'initramfs-odroidxu3.img'],
                                 name='Remove old binaries'))
    st = st + steps_download(target)

    st.append(steps.ShellCommand(command=['/opt/tools/buildbot/build-slave-deploy.sh',
                                          target, config, util.Property('revision'), 'modules-tmp'],
                                 haltOnFailure=True,
                                 name='Deploy on server binaries for booting'))
    st.append(steps.SetPropertyFromCommand(command='ls modules-tmp/lib/modules',
                                           property='kernel_version', haltOnFailure=True))

    st.append(step_serial_open(target))

    st.append(step_subprocess('Power off: ' + target,target,
                              ['/opt/tools/buildbot/target-poweroff.sh', target, config]))

    st.append(step_boot_to_prompt(target, config))
    st.append(step_test_ping(target, config))
    st.append(step_test_uname(target, config))
    st.append(step_test_dmesg_errors(target, config))
    st.append(step_test_dmesg_warnings(target, config))

    # TODO: not ready
    # if run_tests:
    #     # Run tests only on exynos_defconfig because on multi_v7 some tests hang
    #     # the buildbot console and some fail because of missing modules
    #     # (like sound).
    #     # This requires also decent kernel, so do not run on stable (limited
    #     # by doStepIf=if_step_want_tests).
    #     # See: Matrix of configurations
    #     st = st + steps_boot_run_tests(target, config)
    #     if run_pm_tests:
    #         st = st + step_boot_run_pm_tests(target, config)

    st = st + steps_shutdown(target, config)

    return st
