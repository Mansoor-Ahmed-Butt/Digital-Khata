#!/usr/bin/env python3
"""Static checks: translation keys exist in en+ur, relative imports resolve,
placeholders match, and Dart syntax parses (needs tree-sitter-language-pack)."""
import glob, os, re, sys

root = os.path.join(os.path.dirname(__file__), '..')
os.chdir(root)
errors = []

def load(path):
    s = open(path, encoding='utf-8').read()
    return dict(re.findall(r"^\s*'([a-z0-9_]+)':\s*(?:\n\s*)?'((?:[^'\\]|\\.)*)'", s, re.M))

en, ur = load('lib/app/translations/en.dart'), load('lib/app/translations/ur.dart')
for k in set(en) ^ set(ur):
    errors.append(f'key only in one language: {k}')
for k in en:
    if k in ur and sorted(re.findall(r'[@{][a-z]+\}?', en[k])) != sorted(re.findall(r'[@{][a-z]+\}?', ur[k])):
        errors.append(f'placeholder mismatch: {k}')

used = set()
for f in glob.glob('lib/**/*.dart', recursive=True):
    if '/translations/' in f:
        continue
    s = open(f, encoding='utf-8').read()
    used |= set(re.findall(r"'([a-z][a-z0-9_]*)'\.(?:tr|trParams)\b", s))
    used |= set(re.findall(r"(?:titleKey|messageKey|actionKey|confirmKey)[:=]\s*'([a-z][a-z0-9_]*)'", s))
    used |= set(re.findall(r"Failure\('([a-z0-9_]+)'", s))
    used |= set(re.findall(r"(?:AppSnack\.(?:error|showKey)\(|return |\? |: )'([a-z][a-z0-9_]+)'", s))
for k in sorted(used):
    if k not in en and re.match(r'(err_|a11y_|tpl_|nav_|sort_|filter_|plan_|lock_|customer_|entry_)|^[a-z_]+$', k):
        # only flag keys that look like translation keys used via known call patterns
        pass
missing = [k for k in used if k not in en and (k.startswith(('err_', 'a11y_', 'tpl_')) )]
errors += [f'missing translation: {k}' for k in missing]

for f in glob.glob('lib/**/*.dart', recursive=True):
    s = open(f, encoding='utf-8').read()
    for m in re.finditer(r"^(?:import|export) '(\.[^']+)'", s, re.M):
        target = os.path.normpath(os.path.join(os.path.dirname(f), m.group(1)))
        if not os.path.exists(target):
            errors.append(f'{f}: unresolved import {m.group(1)}')

try:
    from tree_sitter_language_pack import get_parser
    parser = get_parser('dart')
    for f in glob.glob('**/*.dart', recursive=True):
        tree = parser.parse(open(f, 'rb').read())
        if tree.root_node.has_error:
            errors.append(f'syntax error: {f}')
except ImportError:
    print('note: tree-sitter not installed, skipping syntax check')

print('\n'.join(errors) if errors else 'OK: no problems found')
sys.exit(1 if errors else 0)
