#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import math
from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 32

# Mapping from text directions to rotation degrees (assuming SOUTH is 0 degrees / base)
DIR_ROTATIONS = {
    "юг": 0,
    "south": 0,
    "восток": 90,
    "east": 90,
    "север": 180,
    "north": 180,
    "запад": 270,
    "west": 270,
    "юго-восток": 45,
    "southeast": 45,
    "северо-восток": 135,
    "northeast": 135,
    "северо-запад": 225,
    "northwest": 225,
    "юго-запад": 315,
    "southwest": 315,
}

COLORS = {
    "floor": (200, 200, 200),
    "wall": (100, 100, 100),
    "door": (150, 100, 50),
    "window": (173, 216, 230, 150),
    "table": (139, 69, 19),
    "chair": (160, 82, 45),
    "bed": (70, 130, 180),
    "rack": (192, 192, 192),
    "locker": (105, 105, 105),
    "machine": (218, 165, 32),
    "computer": (0, 255, 127),
    "vendor": (255, 99, 71),
    "default": (255, 0, 255),  # Magenta for unknown
    "landmark": (0, 255, 255, 128),
}

REAL_ASSET_ALIASES = {
    "floor": "floor",
    "wall": "riveted",
    "door": "door_closed",
    "bed": "roller_down",
    "table": "table",
}

OBJECT_CATEGORY_HINTS = [
    ("roller", "bed"),
    ("bed", "bed"),
    ("table", "table"),
    ("desk", "table"),
    ("door", "door"),
]

class SpriteRenderer:
    def __init__(self, semantic: dict, output_path: str, assets_dir: str):
        self.semantic = semantic
        self.output_path = output_path
        self.assets_dir = Path(assets_dir)
        self.assets_dir.mkdir(parents=True, exist_ok=True)
        
        self.width = int(semantic.get("width", 10))
        self.height = int(semantic.get("height", 10))
        
        if self.width <= 0 or self.height <= 0:
            self.width = 10
            self.height = 10
            
        self.image = Image.new("RGBA", (self.width * TILE_SIZE, self.height * TILE_SIZE), (0, 0, 0, 255))
        self.asset_cache = {}

    def load_named_asset(self, name: str) -> Image.Image | None:
        asset_file = self.assets_dir / f"{name}.png"
        if not asset_file.exists():
            return None
        try:
            img = Image.open(asset_file).convert("RGBA")
            if img.size != (TILE_SIZE, TILE_SIZE):
                img = img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)
            return img
        except Exception as e:
            print(f"Failed to load asset {asset_file}: {e}")
            return None

    def get_asset(self, name: str, category: str = "default") -> Image.Image:
        if name in self.asset_cache:
            return self.asset_cache[name]

        img = self.load_named_asset(name)
        if img is not None:
            self.asset_cache[name] = img
            return img

        alias_name = REAL_ASSET_ALIASES.get(category)
        if alias_name:
            alias_img = self.load_named_asset(alias_name)
            if alias_img is not None:
                self.asset_cache[name] = alias_img
                return alias_img

        # Generate fallback asset
        color = COLORS.get(category, COLORS["default"])
        img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        
        # Draw base shape
        if category == "wall":
            draw.rectangle([0, 0, TILE_SIZE-1, TILE_SIZE-1], fill=color, outline=(50,50,50))
        elif category == "floor":
            draw.rectangle([0, 0, TILE_SIZE-1, TILE_SIZE-1], fill=color, outline=(180,180,180))
            # some pattern
            draw.point([TILE_SIZE//2, TILE_SIZE//2], fill=(150,150,150))
        elif category == "door":
            draw.rectangle([2, 8, TILE_SIZE-3, TILE_SIZE-9], fill=color, outline=(50,30,10))
        elif category == "window":
            draw.rectangle([0, 14, TILE_SIZE-1, 18], fill=color, outline=(100,150,200))
        elif category == "landmark":
            draw.ellipse([8, 8, TILE_SIZE-9, TILE_SIZE-9], fill=color, outline=(0,200,200))
            draw.text((10, 10), "L", fill=(0,0,0))
        else:
            # Generic object: rectangle with a "front" indicator (arrow pointing south by default)
            draw.rectangle([4, 4, TILE_SIZE-5, TILE_SIZE-5], fill=color, outline=(20,20,20))
            # Arrow pointing down (SOUTH is base)
            draw.polygon([(TILE_SIZE//2, TILE_SIZE-6), (TILE_SIZE//2-4, TILE_SIZE-12), (TILE_SIZE//2+4, TILE_SIZE-12)], fill=(255,0,0))
            # First letter
            draw.text((8, 8), name[0].upper() if name else "?", fill=(255,255,255))
            
        self.asset_cache[name] = img
        return img

    def classify_object_category(self, path: str, basename_lower: str) -> str:
        if "landmark" in basename_lower:
            return "landmark"
        for needle, category in OBJECT_CATEGORY_HINTS:
            if needle in basename_lower or needle in path.lower():
                return category
        for k in COLORS:
            if k in basename_lower:
                return k
        return "default"

    def get_rotation(self, dir_val: str | int | None) -> int:
        if dir_val is None:
            return 0
        if isinstance(dir_val, int):
            # BYOND dirs: 1=N, 2=S, 4=E, 8=W
            mapping = {1: 180, 2: 0, 4: 90, 8: 270, 5: 135, 6: 45, 9: 225, 10: 315}
            return mapping.get(dir_val, 0)
            
        dir_str = str(dir_val).lower().strip()
        return DIR_ROTATIONS.get(dir_str, 0)

    def render(self):
        for tile in self.semantic.get("tiles", []):
            # Coordinate system: BYOND is 1-indexed, bottom-left origin.
            # Pillow is 0-indexed, top-left origin.
            x = int(tile.get("local_x", 1)) - 1
            y_byond = int(tile.get("local_y", 1)) - 1
            y = self.height - 1 - y_byond
            
            if not (0 <= x < self.width and 0 <= y < self.height):
                continue
                
            px = x * TILE_SIZE
            py = y * TILE_SIZE
            
            flags = tile.get("flags", {})
            objects = tile.get("objects", [])
            
            # 1. Render Floor
            if flags.get("floor"):
                floor_img = self.get_asset("floor", "floor")
                self.image.paste(floor_img, (px, py), floor_img if floor_img.mode == 'RGBA' else None)
            else:
                # Black space or empty space
                pass
                
            # 2. Render Geometry (Wall / Window / Door)
            if flags.get("wall"):
                wall_img = self.get_asset("wall", "wall")
                self.image.paste(wall_img, (px, py), wall_img if wall_img.mode == 'RGBA' else None)
            elif flags.get("window"):
                win_img = self.get_asset("window", "window")
                self.image.paste(win_img, (px, py), win_img if win_img.mode == 'RGBA' else None)
            elif flags.get("door"):
                door_img = self.get_asset("door", "door")
                # Look for door object to get dir, otherwise assume horizontal/vertical based on neighbors?
                # For simplicity, we just check objects for door dir
                door_dir = 0
                for obj in objects:
                    if "door" in obj.get("path", "").lower():
                        door_dir = self.get_rotation(obj.get("dir"))
                        break
                if door_dir != 0:
                    door_img = door_img.rotate(door_dir, resample=Image.NEAREST)
                self.image.paste(door_img, (px, py), door_img if door_img.mode == 'RGBA' else None)
                
            # 3. Render Objects
            for obj in objects:
                path = obj.get("path", "")
                basename = path.rsplit("/", 1)[-1] if "/" in path else path
                basename_lower = basename.lower()
                
                # Determine category
                category = self.classify_object_category(path, basename_lower)
                            
                obj_img = self.get_asset(basename_lower, category)
                
                # Rotate object
                obj_dir = self.get_rotation(obj.get("dir"))
                if obj_dir != 0:
                    obj_img = obj_img.rotate(obj_dir, resample=Image.NEAREST)
                    
                self.image.paste(obj_img, (px, py), obj_img if obj_img.mode == 'RGBA' else None)
                
        self.image.save(self.output_path)
        print(f"Rendered sprites to {self.output_path}")

def load_json(path: str | None) -> dict:
    if not path:
        return {}
    if not Path(path).exists():
        return {}
    with open(path, "r", encoding="utf-8-sig") as handle:
        return json.load(handle)

def main():
    parser = argparse.ArgumentParser(description="Render semantic JSON to a sprite-based image.")
    parser.add_argument("--semantic-json", required=True, help="Path to semantic.json")
    parser.add_argument("--output", required=True, help="Path to save the output PNG")
    parser.add_argument("--assets-dir", default="tools/world_edit_visual/assets", help="Directory for PNG assets")
    args = parser.parse_args()

    semantic = load_json(args.semantic_json)
    if not semantic:
        print(f"Error: Could not load {args.semantic_json}")
        return

    renderer = SpriteRenderer(semantic, args.output, args.assets_dir)
    renderer.render()

if __name__ == "__main__":
    main()
