#!/usr/bin/env python3
"""Collect key metrics from all report.json files into a CSV table."""
import json, os, sys

BASE = "data/world_edit_visual/out"
cases = sorted(os.listdir(BASE))

HEADERS = [
    "case", "status", "stage", "footprint", "walls", "floors", "doors",
    "interior_objs", "gen_turfs", "gen_objects", "forbidden_fallback",
    "reachability_fail", "mandatory_pattern_fail", "post_emit_err",
    "reserved_walk_blocked", "direction_fallback", "error_count",
    "report_errors", "first_error"
]

def safe(m, key, default="?"):
    if isinstance(m, dict):
        return m.get(key, default)
    return default

print("| " + " | ".join(HEADERS) + " |")
print("|" + "|".join(["---"] * len(HEADERS)) + "|")

for case in cases:
    rp = os.path.join(BASE, case, "report.json")
    if not os.path.exists(rp):
        continue
    with open(rp, "r", encoding="utf-8-sig") as f:
        r = json.load(f)
    m = r.get("metrics", {}) or {}
    errs = r.get("errors", []) or []
    err_count = len(errs) if isinstance(errs, list) else 0
    first_err = ""
    if errs and isinstance(errs, list):
        e0 = errs[0]
        if isinstance(e0, dict):
            first_err = (e0.get("code") or str(e0))[:100]
        else:
            first_err = str(e0)[:100]

    vals = [
        case,
        r.get("status", "?"),
        r.get("stage", "?"),
        safe(m, "footprint_count"),
        safe(m, "wall_count"),
        safe(m, "floor_count"),
        safe(m, "door_count"),
        safe(m, "interior_object_count"),
        safe(m, "generated_turf_count"),
        safe(m, "generated_object_count"),
        safe(m, "forbidden_fallback_count"),
        safe(m, "reachability_failure_count"),
        safe(m, "mandatory_pattern_failure_count"),
        safe(m, "post_emit_validation_error_count"),
        safe(m, "reserved_walk_blocked_count"),
        safe(m, "direction_fallback_count"),
        safe(m, "error_count"),
        err_count,
        first_err,
    ]
    print("| " + " | ".join(str(v) for v in vals) + " |")
