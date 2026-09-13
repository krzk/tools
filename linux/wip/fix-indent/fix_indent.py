#!/usr/bin/env python3
"""Fix 'indent-consistent' warnings in DT binding YAML examples."""
import importlib.machinery
import importlib.util
import sys

import ruamel.yaml

loader = importlib.machinery.SourceFileLoader('dtstyle', 'scripts/dtc/dt-check-style')
spec = importlib.util.spec_from_loader('dtstyle', loader)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

LineType = mod.LineType


class Ctx:
    def __init__(self, lines, text, file_type):
        self.lines = lines
        self.text = text
        self.file_type = file_type
        self.mode = 'relaxed'


def shift(indent, delta):
    if '\t' in indent:
        return None
    return ' ' * max(0, len(indent) + delta)


def fix_file(path, verbose=False):
    yaml = ruamel.yaml.YAML()
    with open(path, encoding='utf-8') as f:
        raw = f.read()
    try:
        data = yaml.load(raw)
    except Exception as e:
        print('%s: cannot parse: %s' % (path, e), file=sys.stderr)
        return 0
    if not isinstance(data, dict) or 'examples' not in data:
        return 0
    examples = data['examples']
    if not hasattr(examples, '__iter__'):
        return 0

    file_lines = raw.split('\n')
    changed = 0
    skipped = 0

    for i, ex in enumerate(examples):
        if not isinstance(ex, str):
            continue
        text = str(ex)
        try:
            base = examples.lc.item(i)[0] + 2
        except Exception:
            base = 1
        dls = mod.classify_lines(text)
        ctx = Ctx(dls, text, 'yaml')
        unit, _ = mod._detect_indent_unit(ctx)
        if unit is None or unit not in ('  ', '    '):
            continue

        fixes = {}
        pending = None
        for dl in dls:
            lt = dl.linetype
            if lt in (LineType.BLANK, LineType.PREPROCESSOR):
                continue
            if lt in (LineType.COMMENT_BODY, LineType.COMMENT_END):
                if pending is not None:
                    ni = shift(dl.indent_str, pending)
                    if ni is not None and ni != dl.indent_str:
                        fixes[dl.lineno] = (ni, dl)
                if lt == LineType.COMMENT_END:
                    pending = None
                continue
            pending = None
            if not dl.indent_str:
                continue
            expected = unit * dl.depth
            if dl.indent_str == expected:
                continue
            if '\t' in dl.indent_str:
                skipped += 1
                continue
            fixes[dl.lineno] = (expected, dl)
            delta = len(expected) - len(dl.indent_str)
            for cont in dl.continuations:
                ni = shift(cont.indent_str, delta)
                if ni is not None and ni != cont.indent_str:
                    fixes[cont.lineno] = (ni, cont)
            if lt == LineType.COMMENT_START:
                pending = delta

        for lineno, (new_indent, dl) in fixes.items():
            idx = base + lineno - 2
            if idx < 0 or idx >= len(file_lines):
                print('%s: line %d out of range' % (path, idx), file=sys.stderr)
                return 0
            fl = file_lines[idx]
            if fl.strip() != dl.raw.strip():
                print('%s:%d: mismatch %r vs %r' % (path, idx + 1, fl, dl.raw),
                      file=sys.stderr)
                return 0
            total_lead = len(fl) - len(fl.lstrip())
            prefix_len = total_lead - len(dl.indent_str)
            if prefix_len < 0:
                print('%s:%d: bad prefix' % (path, idx + 1), file=sys.stderr)
                return 0
            prefix = fl[:prefix_len]
            content = fl[total_lead:]
            file_lines[idx] = prefix + new_indent + content
            changed += 1

    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(file_lines))
    if skipped:
        print('%s: skipped %d tab-indented lines' % (path, skipped),
              file=sys.stderr)
    return changed


def main():
    total = 0
    for path in sys.argv[1:]:
        n = fix_file(path)
        if n:
            print('%s: %d lines' % (path, n))
            total += n
    print('total %d lines changed' % total)
    return 0


if __name__ == '__main__':
    sys.exit(main())
