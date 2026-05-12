#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path


OUT_DIR = Path("data/world_edit_visual/out")


class SemanticRenderWatcher:
    """Watch runtime output folders and render each semantic export once.

    This is intentionally a helper around render_semantic.py, not a generation
    driver. DreamDaemon produces report.json/semantic.json; the watcher only
    reacts to those artifacts, renders PNGs, and records Python-side wall time.
    """

    def __init__(self, out_dir: Path = OUT_DIR, poll_seconds: float = 0.5) -> None:
        self.out_dir = out_dir
        self.poll_seconds = poll_seconds
        self.seen: dict[Path, float] = {}

    def watch(self) -> None:
        while True:
            self.render_ready_cases()
            time.sleep(self.poll_seconds)

    def render_ready_cases(self) -> None:
        for case_dir in self.case_dirs():
            semantic = case_dir / "semantic.json"
            if not semantic.exists():
                continue
            stamp = semantic.stat().st_mtime
            if self.seen.get(semantic) == stamp:
                continue
            self.render_case(case_dir)
            self.seen[semantic] = stamp

    def case_dirs(self) -> list[Path]:
        if not self.out_dir.exists():
            return []
        return [case_dir for case_dir in self.out_dir.iterdir() if case_dir.is_dir()]

    def render_case(self, case_dir: Path) -> None:
        semantic = case_dir / "semantic.json"
        report = case_dir / "report.json"
        png = case_dir / "semantic.png"
        # Keep external timing separate from DM profiler timings. DM timings are
        # useful for generator stages; Python timing covers renderer/index cost.
        start = time.perf_counter()
        cmd = [
            sys.executable,
            "tools/world_edit_visual/render_semantic.py",
            "--semantic-json",
            str(semantic),
            "--out",
            str(png),
        ]
        if report.exists():
            cmd.extend(["--report-json", str(report)])
        subprocess.run(cmd, check=True)
        duration_ms = int((time.perf_counter() - start) * 1000)
        (case_dir / "external_profile.json").write_text(
            json.dumps({"semantic_render_ms": duration_ms}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )


def main() -> int:
    SemanticRenderWatcher().watch()


if __name__ == "__main__":
    raise SystemExit(main())
