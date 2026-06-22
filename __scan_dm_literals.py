import os

root = r'd:/GitHub/BandaTroopersFork'
needles = [
    '[html_encode(terminal_name)]: ИНИЦИАЛИЗАЦИЯ...',
    'terminal_header',
]

hits = {n: [] for n in needles}
for dirpath, _, files in os.walk(root):
    for fn in files:
        if not fn.endswith('.dm'):
            continue
        path = os.path.join(dirpath, fn)
        try:
            data = open(path, 'r', encoding='utf-8', errors='replace').read()
        except Exception:
            continue
        for needle in needles:
            if needle in data:
                hits[needle].append(path)

for needle in needles:
    print('NEEDLE:', needle)
    if hits[needle]:
        for p in hits[needle]:
            print(p)
    else:
        print('NO_HITS')
    print('---')
