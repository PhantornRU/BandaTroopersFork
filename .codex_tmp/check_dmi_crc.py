import struct, hashlib

def get_png_chunks(path):
    with open(path, 'rb') as f:
        data = f.read()
    offset = 8
    chunks = []
    while offset < len(data) - 4:
        length = struct.unpack('>I', data[offset:offset+4])[0]
        chunk_type = data[offset+4:offset+8].decode('ascii', errors='replace')
        chunk_data = data[offset+8:offset+8+length]
        chunk_crc = struct.unpack('>I', data[offset+8+length:offset+12+length])[0]
        data_md5 = hashlib.md5(chunk_data).hexdigest()[:12] if chunk_data else 'empty'
        chunks.append((chunk_type, length, data_md5, hex(chunk_crc)))
        offset += 12 + length
    return chunks

for fname in ['icons/obj/vehicles/hardpoints/tank.dmi', 'icons/obj/vehicles/hardpoints/twe_tank.dmi']:
    print(f'=== {fname} ===')
    for ct, ln, md5, crc in get_png_chunks(fname):
        print(f'  {ct}: len={ln}, data_md5={md5}, stored_crc={crc}')
    # File MD5
    with open(fname, 'rb') as f:
        print(f'  FILE MD5: {hashlib.md5(f.read()).hexdigest()}')
    print()
