import zlib, hashlib, struct

def get_idat_data(path):
    with open(path, 'rb') as f:
        data = f.read()
    offset = 8
    idat_data = b''
    while offset < len(data) - 4:
        length = struct.unpack('>I', data[offset:offset+4])[0]
        chunk_type = data[offset+4:offset+8].decode('ascii')
        chunk_data = data[offset+8:offset+8+length]
        if chunk_type == 'IDAT':
            idat_data += chunk_data
        offset += 12 + length
    return idat_data

for fname in ['icons/obj/vehicles/hardpoints/tank.dmi', 'icons/obj/vehicles/hardpoints/twe_tank.dmi']:
    with open(fname, 'rb') as f:
        raw = f.read()
    print(f'=== {fname} ===')
    print(f'  File size: {len(raw)} bytes')
    print(f'  File CRC32: {hex(zlib.crc32(raw) & 0xFFFFFFFF)}')
    idat = get_idat_data(fname)
    print(f'  IDAT total size: {len(idat)} bytes')
    print(f'  IDAT CRC32: {hex(zlib.crc32(idat) & 0xFFFFFFFF)}')
    # Check if tank.dmi contains twe_tank.dmi's image data
    print()
