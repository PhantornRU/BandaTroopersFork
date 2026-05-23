#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path


RUNTIME_ROOT = Path("tools/world_edit_visual")
SAFE_ID = re.compile(r"[^A-Za-z0-9_.-]+")


class CasePreparer:
    """Prepare runtime state before DreamDaemon starts.

    DM-side code only checks that directories exist; it does not shell out to
    mkdir during early startup. Keeping directory creation here makes repeated
    local runs predictable and avoids hanging the headless runtime on platform
    quoting issues.
    """

    def __init__(self, runtime_root: Path = RUNTIME_ROOT) -> None:
        self.runtime_root = runtime_root
        self.inbox_dir = runtime_root / "inbox"
        self.out_dir = runtime_root / "out"

    def prepare(self, case_paths: list[Path]) -> None:
        self.ensure_runtime_dirs()
        for case_path in case_paths:
            case_id = self.case_id(case_path)
            (self.out_dir / case_id).mkdir(parents=True, exist_ok=True)
            shutil.copy2(case_path, self.inbox_dir / case_path.name)

    def ensure_runtime_dirs(self) -> None:
        self.inbox_dir.mkdir(parents=True, exist_ok=True)
        self.out_dir.mkdir(parents=True, exist_ok=True)
        (self.runtime_root / "enabled.txt").write_text("1", encoding="ascii")

    def case_id(self, case_path: Path) -> str:
        """Return the output folder name the DM runtime will expect.

        Invalid JSON still gets a fallback directory based on the filename so
        the workbench can write a structured `invalid_json_case` report instead
        of failing because the output directory is missing.
        """

        try:
            with case_path.open("r", encoding="utf-8-sig") as handle:
                data = json.load(handle)
        except (OSError, json.JSONDecodeError):
            data = {}
        raw_id = str(data.get("id") or case_path.stem)
        safe_id = SAFE_ID.sub("_", raw_id).strip("._")
        return safe_id or case_path.stem


def expand_cases(raw_paths: list[str]) -> list[Path]:
    paths: list[Path] = []
    for raw_path in raw_paths:
        path = Path(raw_path)
        if path.is_dir():
            paths.extend(sorted(path.glob("*.json")))
        else:
            paths.append(path)
    return paths


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("cases", nargs="+")
    args = parser.parse_args()

    CasePreparer().prepare(expand_cases(args.cases))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
