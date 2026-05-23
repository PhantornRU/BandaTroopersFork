#!/usr/bin/env python3
"""Deep analysis of semantic.json for point_colony."""
import json

d = json.load(open('data/world_edit_visual/out/building_living_point_colony/semantic.json','r',encoding='utf-8-sig'))
tiles = d['tiles']

walls = [t for t in tiles if t['flags'].get('wall')]
doors = [t for t in tiles if t['flags'].get('door')]
floors = [t for t in tiles if t['flags'].get('floor')]
objs = [t for t in tiles if len(t.get('objects',[])) > 0]
changed = [t for t in tiles if t['flags'].get('changed')]
reserved = [t for t in tiles if t['flags'].get('reserved_walk')]

print(f'Total tiles: {len(tiles)}')
print(f'Wall tiles: {len(walls)}')
print(f'Door tiles: {len(doors)}')
print(f'Floor tiles: {len(floors)}')
print(f'Tiles with objects: {len(objs)}')
print(f'Changed tiles: {len(changed)}')
print(f'Reserved walk: {len(reserved)}')

if walls:
    xs = [t['x'] for t in walls]
    ys = [t['y'] for t in walls]
    print(f'Wall X range: {min(xs)}-{max(xs)}, Y range: {min(ys)}-{max(ys)}')

if objs:
    for t in objs[:5]:
        paths = [o['path'] for o in t['objects']]
        print(f'Object at ({t["x"]},{t["y"]}): {paths}')

# Show non-floor tiles (walls, doors, empty)
non_floor = [t for t in tiles if not t['flags'].get('floor')]
print(f'Non-floor tiles: {len(non_floor)}')
if non_floor:
    for t in non_floor[:5]:
        print(f'  Non-floor at ({t["x"]},{t["y"]}): flags={t["flags"]}')

# Show rooms/routes
print(f'Rooms: {len(d.get("rooms",[]))}')
print(f'Routes: {len(d.get("routes",[]))}')
print(f'Markers: {d.get("markers",[])[:3]}')
