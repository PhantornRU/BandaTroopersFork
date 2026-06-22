import os
import re

root = r'd:/GitHub/BandaTroopersFork/modular/round_cinematics'
pattern = re.compile(r'^(\t)[\w_]+ = list\(\n(\1\t[^\s)]+( ?= ?[\w\d]+)?,\n)*\1\t[^\s)]+( ?= ?[\w\d]+)?\)', re.MULTILINE)

hits = []
for dirpath, _, filenames in os.walk(root):
    for fn in filenames:
        if not fn.endswith('.dm'):
            continue
        path = os.path.join(dirpath, fn)
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            data = f.read()
        for m in pattern.finditer(data):
            line = data[:m.start()].count('\n') + 1
            snippet = m.group(0).replace('\n', '\\n')
            hits.append((path, line, snippet[:180]))

if not hits:
    print('NO_MATCHES')
else:
    for path, line, snippet in hits:
        print(f'{path}:{line}: {snippet}')
    print(f'TOTAL={len(hits)}')
