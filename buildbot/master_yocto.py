# -*- python -*-
# ex: set filetype=python:
#
# Copyright (c) 2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

from buildbot.plugins import steps, util

import shlex

# from master_build_common import steps_prepare_upload_master, \
#                                 step_upload_files_to_master

def step_shell_script(cmd):
    shell_cmd = ['/bin/bash']
    shell_cmd.append('-eEx')
    shell_cmd.extend(['-c', cmd])

    return shell_cmd

def step_yocto_cmd(name, machine, cmd):
    cmd = f'MACHINE={machine} {cmd}'
    shell_cmd = '''
        #!/bin/bash
        umask 022
        source init-env
        echo Running: ''' + shlex.quote(cmd) + '''
        ''' + cmd

    return steps.ShellCommand(command=step_shell_script(shell_cmd),
                              name=name,
                              haltOnFailure=True)

def steps_yocto_prepare_downloads():
    st = []
    st.append(steps.MakeDirectory(dir='../downloads-cache',
                                  name='Make downloads cache directory',
                                  haltOnFailure=True))
    # TODO: parametrize "build" (default workdir - BuildFactory attribute)
    cmd = '''
    test -h %(prop:builddir:-~/)s/build/build/downloads || rm -fr %(prop:builddir:-~/)s/build/build/downloads
    ln -s --force --no-dereference %(prop:builddir:-~/)s/../downloads-cache %(prop:builddir:-~/)s/build/build/downloads
    '''
    st.append(steps.ShellCommand(command=util.Interpolate(cmd),
                                 name='Link downloads cache directory',
                                 haltOnFailure=True))
    return st

def steps_yocto_builder(machine, image):
    st = []
    st.append(steps.Git(repourl=util.Property('repository'),
                        name='Clone the sources',
                        submodules=True,
                        # Need to get rid of any other submodules (e.g. from building other revisions)
                        # but not the build directory to still have the sstate
                        mode='full',
                        method='clean',
                        haltOnFailure=True))
    st.extend(steps_yocto_prepare_downloads())
    st.append(step_yocto_cmd(f'Build: {image}',
                             machine,
                             f'bitbake {image}'))
    return st
