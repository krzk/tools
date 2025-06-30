# -*- python -*-
# ex: set filetype=python:
#
# Copyright (c) 2019,2025 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

def step_is_kernel_newer(step, exp_major, exp_minor):
    """ Return True if step is part of building/booting kernel version >= exp_major.exp_minor
    Arguments:
        step - buildbot.step
        exp_major - expected major version or newer
        exp_minor - expected minor version or newer
    Returns:
        bool
    """

    ver = step.getProperty('kernel_version')
    if (not ver) or (not len(ver)):
        return False
    vers = ver.split('.')
    if len(vers) < 2:
        return False
    ver_major = int(vers[0])
    ver_minor = int(vers[1])
    if not ver_major:
        return False
    if ver_major > exp_major:
        return True
    if (ver_major == exp_major) and (ver_minor >= exp_minor):
        return True
    return False
