#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzysztof.kozlowski@canonical.com>
#                             <krzk@kernel.org>

import argparse
import os
import pathlib
import re
import sys


def main(arguments):
    parser = argparse.ArgumentParser(description='Check maintainers file')
    parser.add_argument('-f', '--file', help='Maintainers file (absolute path)', type=argparse.FileType('r'),
                        required=True)
    parser.add_argument('-d', '--dir', help='Linux kernel directory', type=pathlib.Path,
                        default='./')

    args = parser.parse_args(arguments)

    for index, line in enumerate(args.file):
        if not line.startswith('F:'):
            continue

        match = re.match('^F:\s+(.+)$', line)
        if match and match.group(1):
            rel_path = match.group(1)
            if '*' in rel_path or '?' in rel_path or '[' in rel_path:
                continue

            abs_path = os.path.join(args.dir, rel_path)
            if abs_path.endswith('/'):
                if not os.path.isdir(abs_path):
                    print(f'{rel_path}: directory does not exist')
            else:
                if os.path.isdir(abs_path):
                    #print(f'{rel_path}: file entry is a directory')
                    continue
                elif not os.path.isfile(abs_path):
                    print(f'{rel_path}: file does not exist')
        else:
            print('Could not match path in "{}"'.format(line.strip()))

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
