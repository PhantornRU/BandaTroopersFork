import subprocess
from pathlib import Path

base = Path(r'd:/GitHub/BandaTroopersFork')
file_path = 'modular/round_cinematics/code/intro/cryo_intro_context.dm'

cmds = [
    ['git', 'rev-parse', 'HEAD'],
    ['git', 'rev-parse', 'origin/intro_autro'],
    ['git', 'status', '--short', '--', file_path],
    ['git', 'diff', '--name-only', '--', file_path],
    ['git', 'log', '--oneline', '--decorate', '-1'],
]
for cmd in cmds:
    r = subprocess.run(cmd, cwd=base, capture_output=True, text=True, encoding='utf-8', errors='replace')
    print('CMD:', ' '.join(cmd))
    print('RC:', r.returncode)
    print(r.stdout if r.stdout else '(no stdout)')
    print(r.stderr if r.stderr else '(no stderr)')
    print('---')

# show whether HEAD contains the new variable
r = subprocess.run(['git', 'show', f'HEAD:{file_path}'], cwd=base, capture_output=True, text=True, encoding='utf-8', errors='replace')
print('HEAD contains terminal_header?', 'terminal_header' in r.stdout)
print('HEAD contains old literal?', '[html_encode(terminal_name)]: ИНИЦИАЛИЗАЦИЯ...' in r.stdout)
print('WORKTREE contains terminal_header?', 'terminal_header' in (base / file_path).read_text(encoding='utf-8', errors='replace'))
print('WORKTREE contains old literal?', '[html_encode(terminal_name)]: ИНИЦИАЛИЗАЦИЯ...' in (base / file_path).read_text(encoding='utf-8', errors='replace'))
