#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw


TILE = 10


class SemanticPalette:
    """Stable schematic colors shared by all Workbench semantic PNGs.

    These are intentionally not DMI/sprite colors. The renderer is a debugging
    view for review sheets: walls, doors, blockers, changed tiles, errors, and
    functional objects must be easy to scan even when no game icon assets are
    available in CI.
    """

    empty = (20, 20, 20)
    floor = (170, 170, 170)
    wall = (70, 70, 70)
    door = (220, 180, 40)
    reserved = (70, 140, 240)
    changed = (120, 200, 120)
    blocked = (200, 50, 50)
    error = (255, 0, 0)
    text = (255, 255, 255)
    overlay = (0, 0, 0)


def load_json(path: str | None) -> dict:
    if not path:
        return {}
    with open(path, "r", encoding="utf-8-sig") as handle:
        return json.load(handle)


class SemanticRenderer:
    """Draw a semantic.json/report.json pair as a schematic PNG.

    The renderer is kept data-driven on purpose. DM owns generation and exports
    semantic flags; Python only visualizes those flags. That separation prevents
    a pretty PNG from accidentally becoming a second, fake implementation of the
    building generator.
    """

    def __init__(self, semantic: dict, report: dict, tile_size: int = TILE) -> None:
        self.semantic = semantic
        self.report = report
        self.tile_size = tile_size
        self.width = int(semantic["width"])
        self.height = int(semantic["height"])
        self.overlay_h = 34
        self.image = Image.new(
            "RGB",
            (self.width * self.tile_size, self.height * self.tile_size + self.overlay_h),
            SemanticPalette.empty,
        )
        self.draw = ImageDraw.Draw(self.image)

    def render(self, out_path: Path) -> None:
        self.draw_tiles()
        self.draw_rooms()
        self.draw_status_overlay()
        self.draw_error_banner()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        self.image.save(out_path)

    def tile_box(self, local_x: int, local_y: int) -> tuple[int, int, int, int]:
        x = local_x - 1
        y = self.height - local_y
        px0 = x * self.tile_size
        py0 = y * self.tile_size
        px1 = px0 + self.tile_size - 1
        py1 = py0 + self.tile_size - 1
        return px0, py0, px1, py1

    def draw_tiles(self) -> None:
        for tile in self.semantic.get("tiles", []):
            self.draw_tile(tile)

    def draw_tile(self, tile: dict) -> None:
        px0, py0, px1, py1 = self.tile_box(int(tile["local_x"]), int(tile["local_y"]))
        flags = tile.get("flags", {})

        color = SemanticPalette.floor
        if flags.get("wall"):
            color = SemanticPalette.wall
        elif not flags.get("floor"):
            color = SemanticPalette.empty

        self.draw.rectangle([px0, py0, px1, py1], fill=color)

        # Overlay order matters: changed/reserved are outlines, doors/objects are
        # filled markers, blockers/errors must remain visible on top.
        if flags.get("changed"):
            self.draw.rectangle([px0 + 1, py0 + 1, px1 - 1, py1 - 1], outline=SemanticPalette.changed)
        if flags.get("reserved_walk"):
            self.draw.rectangle([px0 + 2, py0 + 2, px1 - 2, py1 - 2], outline=SemanticPalette.reserved)
        if flags.get("door"):
            self.draw.rectangle([px0 + 2, py0 + 2, px1 - 2, py1 - 2], fill=SemanticPalette.door)
        if flags.get("blocked"):
            self.draw.line([px0, py0, px1, py1], fill=SemanticPalette.blocked, width=2)
            self.draw.line([px0, py1, px1, py0], fill=SemanticPalette.blocked, width=2)
        if flags.get("error"):
            self.draw.rectangle([px0, py0, px1, py1], outline=SemanticPalette.error, width=2)

        objects = tile.get("objects", [])
        if objects:
            functional = any(obj.get("functional", True) for obj in objects)
            dot_color = (40, 220, 80) if functional else (255, 80, 40)
            self.draw.ellipse([px0 + 3, py0 + 3, px1 - 3, py1 - 3], fill=dot_color)

    def draw_rooms(self) -> None:
        for room in self.semantic.get("rooms", []):
            bounds = room.get("bounds")
            if not bounds or len(bounds) != 4:
                continue
            min_x, min_y, max_x, max_y = [int(v) for v in bounds]
            px0 = (min_x - 1) * self.tile_size
            py0 = (self.height - max_y) * self.tile_size
            px1 = max_x * self.tile_size - 1
            py1 = (self.height - min_y + 1) * self.tile_size - 1
            outline = (40, 255, 80) if room.get("status", "ok") == "ok" else SemanticPalette.error
            self.draw.rectangle([px0, py0, px1, py1], outline=outline, width=2)
            self.draw.text(
                (px0 + 2, py0 + 2),
                str(room.get("role") or room.get("id") or "room"),
                fill=SemanticPalette.text,
            )

    def draw_status_overlay(self) -> None:
        """Draw the compact review summary at the bottom of every image."""

        status = self.report.get("status") or "unknown"
        profile = self.report.get("profile") or self.semantic.get("profile") or {}
        stages = profile.get("stages") or []
        slowest = max(stages, key=lambda stage: int(stage.get("duration_ds") or 0), default={})
        errors = self.errors()
        metrics = self.report.get("metrics") or {}
        overlay = (
            f"Case: {self.semantic.get('case_id')} | Status: {status} | "
            f"DM: {profile.get('total_estimated_ms', 0)} ms | "
            f"Slowest: {slowest.get('name', '-')} | "
            f"Objects: {metrics.get('generated_object_count', 0)} | Errors: {len(errors)}"
        )
        y0 = self.height * self.tile_size
        self.draw.rectangle([0, y0, self.image.width - 1, self.image.height - 1], fill=SemanticPalette.overlay)
        self.draw.text((4, y0 + 8), overlay, fill=SemanticPalette.text)

    def draw_error_banner(self) -> None:
        """Make failing/locked cases obvious in screenshot sheets."""

        errors = self.errors()
        if not errors:
            return
        self.draw.rectangle([0, 0, self.image.width - 1, 24], fill=(120, 0, 0))
        first = errors[0].get("code") if isinstance(errors[0], dict) else "error"
        self.draw.text((4, 4), f"ERRORS: {len(errors)} ({first})", fill=SemanticPalette.text)

    def errors(self) -> list:
        return self.report.get("errors") or self.semantic.get("errors") or []


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--semantic-json", required=True)
    parser.add_argument("--report-json")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    semantic = load_json(args.semantic_json)
    report = load_json(args.report_json) if args.report_json else {}
    SemanticRenderer(semantic, report).render(Path(args.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
