import zlib, hashlib

files = [
    'icons/obj/vehicles/hardpoints/tank.dmi',
    'icons/obj/vehicles/hardpoints/twe_tank.dmi',
    'icons/obj/vehicles/twe_tank.dmi',
    'icons/obj/vehicles/interiors/twe_tank.dmi',
    'icons/obj/vehicles/interiors/twe_tank_chassis.dmi',
]

for fname in files:
    try:
        with open(fname, 'rb') as f:
            raw = f.read()
        print(f'{fname}: size={len(raw)}, crc32={hex(zlib.crc32(raw) & 0xFFFFFFFF)}, md5={hashlib.md5(raw).hexdigest()}')
    except FileNotFoundError:
        print(f'{fname}: NOT FOUND')
