#!/usr/bin/env python3
"""Confirm no changed example line lies inside a multi-line DTS string literal.

Leading whitespace is semantically irrelevant in DTS *except* inside a
string literal spanning lines. If no example contains such a literal,
re-indentation cannot change the compiled result.
"""
import subprocess
import sys

import ruamel.yaml


def strip_comments_keep_strings(line, in_block_comment):
    out = []
    i = 0
    n = len(line)
    while i < n:
        if in_block_comment:
            end = line.find('*/', i)
            if end < 0:
                return (''.join(out), True)
            i = end + 2
            in_block_comment = False
            continue
        c = line[i]
        if c == '"':
            j = i + 1
            while j < n:
                if line[j] == '\\':
                    j += 2
                    continue
                if line[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(line[i:j])
            i = j
            continue
        if c == '/' and i + 1 < n and line[i + 1] == '/':
            break
        if c == '/' and i + 1 < n and line[i + 1] == '*':
            i += 2
            in_block_comment = True
            continue
        out.append(c)
        i += 1
    return (''.join(out), in_block_comment)


def unterminated_string_lines(body):
    in_block_comment = False
    for idx, line in enumerate(body.split('\n'), start=1):
        code, in_block_comment = strip_comments_keep_strings(
            line, in_block_comment)
        cnt = 0
        i = 0
        while i < len(code):
            if code[i] == '\\':
                i += 2
                continue
            if code[i] == '"':
                cnt += 1
            i += 1
        if cnt % 2:
            yield idx


def main():
    files = [l for l in subprocess.run(
        ['git', 'diff', '--name-only'], capture_output=True, text=True,
        check=True).stdout.split('\n') if l]
    problems = 0
    total_ex = 0
    for f in files:
        with open(f, encoding='utf-8') as fh:
            new = fh.read()
        yaml = ruamel.yaml.YAML()
        data = yaml.load(new)
        ex = data.get('examples') or []
        for i, e in enumerate(ex):
            if not isinstance(e, str):
                continue
            total_ex += 1
            bad = list(unterminated_string_lines(str(e)))
            if bad:
                print('%s: example %d multi-line string literal at %s'
                      % (f, i, bad))
                problems += 1
    print('scanned %d examples in %d files, %d with multi-line strings'
          % (total_ex, len(files), problems))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())