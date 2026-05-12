#!/usr/bin/env python3

from __future__ import annotations

import json
import os
from pathlib import Path


OUT_DIR = Path("data/world_edit_visual/out")
INDEX = Path("tools/world_edit_visual/index.md")


class WorkbenchIndexBuilder:
    """Build a local Markdown review sheet from runtime reports.

    The index is generated output, not source. Links are written relative to the
    index file because the sheet lives in `tools/world_edit_visual` while the
    canonical DreamDaemon artifacts live under repo-root `data/world_edit_visual`.
    """

    def __init__(self, out_dir: Path = OUT_DIR, index_path: Path = INDEX) -> None:
        self.out_dir = out_dir
        self.index_path = index_path

    def build(self) -> None:
        rows = ["| Case | Status | Errors | Semantic | Report |", "| --- | --- | ---: | --- | --- |"]
        for case_dir in self.case_dirs():
            report_path = case_dir / "report.json"
            report = self.load_report(report_path)
            if not report:
                continue
            errors = len(report.get("errors") or [])
            rows.append(
                f"| {case_dir.name} | {report.get('status', 'unknown')} | {errors} | "
                f"[semantic.png]({self.link_to(case_dir / 'semantic.png')}) | "
                f"[report.json]({self.link_to(report_path)}) |"
            )
        self.index_path.write_text("# World Edit Visual Workbench\n\n" + "\n".join(rows) + "\n", encoding="utf-8")

    def case_dirs(self) -> list[Path]:
        if not self.out_dir.exists():
            return []
        return [case_dir for case_dir in sorted(self.out_dir.iterdir()) if case_dir.is_dir()]

    @staticmethod
    def load_report(report_path: Path) -> dict:
        if not report_path.exists():
            return {}
        return json.loads(report_path.read_text(encoding="utf-8-sig"))

    def link_to(self, target: Path) -> str:
        """Return a Markdown-friendly path from index.md to a runtime artifact."""

        return Path(os.path.relpath(target, self.index_path.parent)).as_posix()


def main() -> int:
    WorkbenchIndexBuilder().build()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
