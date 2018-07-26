# -*- python -*-
# ex: set filetype=python:
#

from buildbot.plugins import steps, util

# Dynamic (executed during runtime of builder) helper:
def build_boot_for_tests(step):
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

f_env_odroid = {'PATH': '/opt/tools/buildbot:/opt/tools/pi:/usr/local/bin:${PATH}'}

# Run some of the PM-QA tests. I don't want heating tests
# (thermal, cpufreq) because they stress the board needlessly.
def step_boot_run_pm_tests(target, config):
    st = []
    st.append(steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/usr/sbin/make -C /opt/pm-qa/cpuhotplug check'],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=f_env_odroid, name='PM-QA cpuhotplug tests: ' + target,
        haltOnFailure=True, doStepIf=build_boot_for_tests))
    st.append(steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/usr/sbin/make -C /opt/pm-qa/cpuidle check'],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=f_env_odroid, name='PM-QA cpuidle tests: ' + target,
        haltOnFailure=True, doStepIf=build_boot_for_tests))
    st.append(steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/usr/sbin/make -C /opt/pm-qa/cputopology check'],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=f_env_odroid, name='PM-QA cputopology tests: ' + target,
        haltOnFailure=True, doStepIf=build_boot_for_tests))
    return st

def step_boot_run_test(target, config, test):
    return steps.ShellCommand(
        command=['build-slave-target-cmd.sh', target, config,
                 '/opt/tools/tests/' + test + '.sh',
                 target, config],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=f_env_odroid, name='Test: ' + test + ' @' + target,
        haltOnFailure=False,
        doStepIf=build_boot_for_tests)

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

def steps_boot(builder_name, target, config, run_tests=False, run_pm_tests=False):
    st = []
    mastersrc_dir = u'bins-deploy/%(prop:trigger_builder)s/%(prop:revision)s'
    st.append(steps.ShellCommand(
        command=['rm', '-fr', 'lib', 'deploy-modules-out.tar.gz', 'initramfs-odroidxu3.img'],
        env=f_env_odroid, name='Remove old binaries'))
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
    st.append(steps.ShellCommand(
        command=['build-slave-deploy.sh', target, config, util.Property('revision'), 'modules-tmp'],
        haltOnFailure=True, env=f_env_odroid,
        name='Deploy on server binaries for booting'))
    st.append(steps.SetPropertyFromCommand(
        command='ls modules-tmp/lib/modules', property='kernel_version', haltOnFailure=True))
    st.append(steps.ShellCommand(
        command=['build-slave-boot.sh', target, config],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=f_env_odroid, name='Boot: ' + target, haltOnFailure=True))
    if run_tests:
        # Run tests only on exynos_defconfig because on multi_v7 some tests hang
        # the buildbot console and some fail because of missing modules
        # (like sound).
        # This requires also decent kernel, so do not run on stable (limited
        # by doStepIf=build_boot_for_tests).
        # See: Matrix of configurations
        st = st + steps_boot_run_tests(target, config)
        if run_pm_tests:
            st = st + step_boot_run_pm_tests(target, config)

    st.append(steps.ShellCommand(
        command=['build-slave-poweroff.sh', target, config],
        logfiles={'serial0': 'serial.log'},
        lazylogfiles=True,
        env=f_env_odroid, name='Power off: ' + target, haltOnFailure=False,
        alwaysRun=True))

    return st
