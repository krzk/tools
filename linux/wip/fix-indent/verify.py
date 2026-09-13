#!/usr/bin/env python3
"""Verify that changed YAML files differ from HEAD only in DTS example indentation."""
import subprocess
import sys

import ruamel.yaml


def load_examples(text, name):
    yaml = ruamel.yaml.YAML()
    data = yaml.load(text)
    if not isinstance(data, dict):
        print('%s: not a dict' % name)
        return None
    return data


def dump_norm(data):
    """Normalise: for examples, strip leading whitespace of every line."""
    ex = data.get('examples')
    out = []
    if ex is None:
        return out
    for e in ex:
        if not isinstance(e, str):
            out.append(('nonstr', str(e)))
            continue
        out.append(('str', '\n'.join(l.strip() for l in str(e).split('\n'))))
    return out


def keys_norm(data):
    return {k: v for k, v in data.items() if k != 'examples'}


def main():
    files = [l for l in subprocess.run(
        ['git', 'diff', '--name-only'], capture_output=True, text=True,
        check=True).stdout.split('\n') if l]
    bad = 0
    for f in files:
        old = subprocess.run(['git', 'show', 'HEAD:%s' % f],
                             capture_output=True, text=True, check=True).stdout
        with open(f, encoding='utf-8') as fh:
            new = fh.read()
        try:
            dold = load_examples(old, f + ' (old)')
            dnew = load_examples(new, f + ' (new)')
        except Exception as e:
            print('%s: YAML parse error: %s' % (f, e))
            bad += 1
            continue
        if dold is None or dnew is None:
            bad += 1
            continue
        # Everything outside examples must be byte-identical in source
        old_no_ex = old.split('\nexamples:')[0]
        new_no_ex = new.split('\nexamples:')[0]
        if old_no_ex != new_no_ex:
            print('%s: content outside examples changed' % f)
            bad += 1
        eo = dump_norm(dold)
        en = dump_norm(dnew)
        if len(eo) != len(en):
            print('%s: example count changed %d -> %d' % (f, len(eo), len(en)))
            bad += 1
            continue
        for i, (a, b) in enumerate(zip(eo, en)):
            if a != b:
                print('%s: example %d content changed beyond indentation' % (f, i))
                bad += 1
        # Brace balance sanity
        for i, e in enumerate(en):
            if e[1].count('{') != e[1].count('}'):
                print('%s: example %d unbalanced braces' % (f, i))
                bad += 1
    print('checked %d files, %d problems' % (len(files), bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())