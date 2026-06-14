import zlib, hashlib, glob

# All tank.dmi files
all_dmis = (
    glob.glob('icons/**/tank.dmi', recursive=True) +
    glob.glob('icons/**/twe_tank.dmi', recursive=True) +
    glob.glob('backups/**/twe_tank.dmi', recursive=True)
)

results = {}
for fname in sorted(set(all_dmis)):
    try:
        with open(fname, 'rb') as f:
            raw = f.read()
        crc = zlib.crc32(raw) & 0xFFFFFFFF
        md5 = hashlib.md5(raw).hexdigest()
        results[fname] = (len(raw), crc, md5)
        print(f'{fname}: size={len(raw)}, crc32={hex(crc)}, md5={md5}')
    except FileNotFoundError:
        print(f'{fname}: NOT FOUND')

# Find duplicates
print('\n=== CRC DUPLICATES ===')
seen = {}
for fname, (size, crc, md5) in results.items():
    key = crc
    if key in seen:
        print(f'DUPLICATE CRC: {seen[key]} <-> {fname} (crc32={hex(crc)})')
    else:
        seen[key] = fname
