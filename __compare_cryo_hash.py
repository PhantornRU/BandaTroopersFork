import subprocess
from pathlib import Path

base = Path(r'd:/GitHub/BandaTroopersFork')
path = base / 'modular/round_cinematics/code/intro/cryo_intro_context.dm'

worktree = subprocess.run(['git', 'hash-object', str(path)], cwd=base, capture_output=True, text=True, encoding='utf-8', errors='replace')
head = subprocess.run(['git', 'show', 'HEAD:modular/round_cinematics/code/intro/cryo_intro_context.dm'], cwd=base, capture_output=True)
head_hash = subprocess.run(['git', 'hash-object', '--stdin'], cwd=base, input=head.stdout, capture_output=True)

status = subprocess.run(['git', 'status', '--short', '--', 'modular/round_cinematics/code/intro/cryo_intro_context.dm'], cwd=base, capture_output=True, text=True, encoding='utf-8', errors='replace')

grep = subprocess.run(['bash', 'tools/bandastation_check_grep.sh'], cwd=base, capture_output=True, text=True, encoding='utf-8', errors='replace')

print('WORKTREE_HASH=', worktree.stdout.strip())
print('HEAD_HASH=', head_hash.stdout.strip())
print('STATUS=', repr(status.stdout))
print('GREP_RC=', grep.returncode)
print('GREP_STDOUT=')
print(grep.stdout)
print('GREP_STDERR=')
print(grep.stderr)
