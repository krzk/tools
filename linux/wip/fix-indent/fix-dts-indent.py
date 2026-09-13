#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Fix 'indent-consistent' warnings reported by scripts/dtc/dt-check-style
in tab-indented DTS sources (.dts/.dtsi/.dtso).

The expected indentation of a line is one tab per nesting level, so the
fix is mechanical: replace the leading whitespace with '\\t' * depth.
Two things make it less trivial than a sed one-liner:

1. Continuation lines of a multi-line property are *not* indented by
   depth; they align to the column of the first '<' or '"' after the
   '='. Re-indenting the leading line moves that column, so every
   continuation has to be recomputed. Alignment is expressed as
   'maximal tabs, then spaces' (tabstop 8) so the result neither breaks
   continuation-alignment nor trips the 'more than 7 spaces' rule.

2. dt-check-style tracks nesting depth with a line classifier that
   mis-parses a label sitting alone on a line, e.g.

        camera0_state_on:
        camera_rear_default: camera-rear-default-state {

   The first line becomes a PROPERTY and the second its CONTINUATION,
   so the '{' never increments depth and every following line in the
   file is reported with a bogus expected depth. Blindly "fixing"
   those would destroy correct code, so this script refuses to touch
   anything at or after the first such construct in a file and tells
   you how many lines it skipped.

Usage:
    scripts/dtc/fix-dts-indent.py [--dry-run] FILE...
"""

import argparse
import importlib.machinery
import importlib.util
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_CHECKER = os.path.join(_HERE, 'dt-check-style')

_TABSTOP = 8


def _load_checker():
    """Import dt-check-style as a module to reuse its line classifier."""
    loader = importlib.machinery.SourceFileLoader('dt_check_style', _CHECKER)
    spec = importlib.util.spec_from_loader('dt_check_style', loader)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_mod = _load_checker()
LineType = _mod.LineType

# A line consisting of nothing but "label:" -- see note 2 above.
_re_label_only = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_-]*:$')


class _Ctx:
    """Minimal stand-in for the checker's rule context."""

    def __init__(self, lines, text, file_type):
        self.lines = lines
        self.text = text
        self.file_type = file_type
        self.mode = 'relaxed'


def _display_col(text):
    """Visual column width of text with tabs expanded to tabstop 8."""
    col = 0
    for ch in text:
        if ch == '\t':
            col = (col // _TABSTOP + 1) * _TABSTOP
        else:
            col += 1
    return col


def _indent_for_col(col):
    """Leading whitespace reaching display column 'col' using maximal
    tabs followed by at most 7 spaces, which is what the kernel DTS
    style expects for alignment."""
    return '\t' * (col // _TABSTOP) + ' ' * (col % _TABSTOP)


def _first_desync_lineno(lines):
    """Line number of the first construct that desynchronizes the
    checker's depth tracking, or None."""
    for dl in lines:
        if dl.linetype != LineType.PROPERTY:
            continue
        if not _re_label_only.match(dl.stripped):
            continue
        if any(c.code.endswith('{') for c in dl.continuations):
            return dl.lineno
    return None


def _continuation_fixes(dl, new_indent):
    """Yield (lineno, new_indent) for the continuation lines of property
    'dl' assuming its leading line is re-indented to 'new_indent'.

    Mirrors check_continuation_alignment() in dt-check-style so the
    result satisfies that rule as well.
    """
    if not dl.continuations:
        return

    new_raw = new_indent + dl.raw.lstrip()
    eq = new_raw.find('=')
    if eq < 0:
        return

    rest = _mod._strip_strings_and_comments(new_raw[eq + 1:]).rstrip()
    m = re.search(r'\s*([<"])', rest)
    if not m:
        return

    target_col = _display_col(
        _mod._strip_strings_and_comments(new_raw[:eq + 1 + m.start(1)]))
    value_complete = rest.endswith('",') or rest.endswith('>,')

    for cont in dl.continuations:
        offset = 0 if value_complete else 1
        yield (cont.lineno, _indent_for_col(target_col + offset))
        if len(cont.code):
            value_complete = (cont.code.endswith('",') or
                              cont.code.endswith('>,'))


def _comment_body_indent(depth, stripped):
    """Indent for a continuation line of a /* */ block comment. The
    kernel style puts the leading '*' one space past the '/*'."""
    if stripped.startswith('*'):
        return '\t' * depth + ' '
    return '\t' * depth


def fix_file(path, dry_run=False):
    """Re-indent 'path'. Returns (n_fixed, n_skipped)."""
    with open(path, encoding='utf-8') as f:
        text = f.read()

    lines = _mod.classify_lines(text)
    ctx = _Ctx(lines, text, 'dts')

    unit, _ = _mod._detect_indent_unit(ctx)
    if unit != '\t':
        # Not a tab-indented file; indent-unit-dts covers this and
        # check_indent_consistent bails out too.
        return (0, 0)

    warned = set(ln for ln, _ in _mod.check_indent_consistent(ctx))
    if not warned:
        return (0, 0)

    limit = _first_desync_lineno(lines)
    skipped = len([ln for ln in warned if limit is not None and ln >= limit])

    fixes = {}
    pending_comment_depth = None

    for dl in lines:
        lt = dl.linetype

        # Body of a block comment whose opener we re-indented.
        if lt in (LineType.COMMENT_BODY, LineType.COMMENT_END):
            if pending_comment_depth is not None:
                new = _comment_body_indent(pending_comment_depth, dl.stripped)
                if new != dl.indent_str:
                    fixes[dl.lineno] = new
            if lt == LineType.COMMENT_END:
                pending_comment_depth = None
            continue

        pending_comment_depth = None

        if lt in (LineType.BLANK, LineType.PREPROCESSOR):
            continue
        if lt == LineType.CONTINUATION:
            continue          # handled together with its leading line
        if dl.lineno not in warned:
            continue
        if limit is not None and dl.lineno >= limit:
            continue

        expected = '\t' * dl.depth
        if dl.indent_str == expected:
            continue

        fixes[dl.lineno] = expected
        for lineno, new in _continuation_fixes(dl, expected):
            fixes[lineno] = new
        if lt == LineType.COMMENT_START:
            pending_comment_depth = dl.depth

    if not fixes:
        return (0, skipped)

    out = text.split('\n')
    for lineno, new_indent in fixes.items():
        idx = lineno - 1
        old = out[idx]
        body = old.lstrip()
        if not body:
            continue
        out[idx] = new_indent + body

    if not dry_run:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(out))

    return (len(fixes), skipped)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('-n', '--dry-run', action='store_true',
                    help='report what would change without writing')
    ap.add_argument('files', nargs='+', metavar='FILE')
    args = ap.parse_args()

    total_fixed = 0
    total_skipped = 0
    for path in args.files:
        if not path.endswith(('.dts', '.dtsi', '.dtso')):
            continue
        try:
            fixed, skipped = fix_file(path, args.dry_run)
        except Exception as exc:                      # noqa: BLE001
            print('%s: %s' % (path, exc), file=sys.stderr)
            continue
        if fixed or skipped:
            note = ''
            if skipped:
                note = (' (%d warning(s) left alone: depth tracking is '
                        'unreliable after a label on its own line)' % skipped)
            print('%s: %d line(s)%s' % (path, fixed, note))
        total_fixed += fixed
        total_skipped += skipped

    print('total: %d line(s) re-indented, %d warning(s) left alone'
          % (total_fixed, total_skipped))
    return 0


if __name__ == '__main__':
    sys.exit(main())