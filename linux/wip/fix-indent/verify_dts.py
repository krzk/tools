#!/usr/bin/env python3
"""Verify changed DTS files differ from HEAD only in leading whitespace.

Also confirms no changed line sits inside a multi-line string literal,
where leading whitespace would be semantically significant.
"""
import re
import subprocess
import sys


def strip_comments_keep_strings(line, in_block):
    out = []
    i = 0
    n = len(line)
    while i < n:
        if in_block:
            end = line.find('*/', i)
            if end < 0:
                return (''.join(out), True)
            i = end + 2
            in_block = False
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
            in_block = True
            continue
        out.append(c)
        i += 1
    return (''.join(out), in_block)


def open_string_lines(text):
    in_block = False
    bad = []
    for idx, line in enumerate(text.split('\n'), start=1):
        code, in_block = strip_comments_keep_strings(line, in_block)
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
            bad.append(idx)
    return bad


def main():
    files = [l for l in subprocess.run(
        ['git', 'diff', '--name-only'], capture_output=True, text=True,
        check=True).stdout.split('\n') if l]
    problems = 0
    for f in files:
        old = subprocess.run(['git', 'show', 'HEAD:%s' % f],
                             capture_output=True, text=True,
                             check=True).stdout
        with open(f, encoding='utf-8') as fh:
            new = fh.read()

        lo = old.split('\n')
        ln = new.split('\n')
        if len(lo) != len(ln):
            print('%s: line count changed %d -> %d' % (f, len(lo), len(ln)))
            problems += 1
            continue
        for i, (a, b) in enumerate(zip(lo, ln), start=1):
            if a == b:
                continue
            if a.strip() != b.strip():
                print('%s:%d: content changed, not just indent' % (f, i))
                print('   old=%r' % a)
                print('   new=%r' % b)
                problems += 1
            if b != b.rstrip():
                print('%s:%d: trailing whitespace introduced' % (f, i))
                problems += 1
        # Brace balance must be identical
        for ch in '{}':
            if old.count(ch) != new.count(ch):
                print('%s: %r count changed' % (f, ch))
                problems += 1
        bad = open_string_lines(new)
        if bad:
            print('%s: multi-line string literal at %s' % (f, bad[:5]))
            problems += 1
    print('checked %d files, %d problems' % (len(files), problems))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())