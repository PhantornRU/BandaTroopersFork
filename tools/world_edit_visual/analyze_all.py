#!/usr/bin/env python3
"""Quick analysis of all generated cases."""
import json, os, sys

BASE = "data/world_edit_visual/out"
cases = sorted(os.listdir(BASE))

def safe_get(m, key, default="?"):
    if isinstance(m, dict):
        return m.get(key, default)
    return default

for case in cases:
    rp = os.path.join(BASE, case, "report.json")
    if not os.path.exists(rp):
        continue
    r = json.load(open(rp, "r", encoding="utf-8-sig"))
    m = r.get("metrics", {})
    print(f"=== {case} ===")
    print(f"  status={r['status']} stage={r['stage']}")
    print(f"  walls={safe_get(m,'wall_count')} floors={safe_get(m,'floor_count')} doors={safe_get(m,'door_count')} objects={safe_get(m,'interior_object_count')}")
    print(f"  footprint={safe_get(m,'footprint_count')} generated_turfs={safe_get(m,'generated_turf_count')}")
    print(f"  reachability_fail={safe_get(m,'reachability_failure_count')} forbidden_fallback={safe_get(m,'forbidden_fallback_count')}")
    print(f"  reserved_walk_blocked={safe_get(m,'reserved_walk_blocked_count')} post_emit_err={safe_get(m,'post_emit_validation_error_count')}")
    print(f"  mandatory_pattern_fail={safe_get(m,'mandatory_pattern_failure_count')} direction_fallback={safe_get(m,'direction_fallback_count')}")
    errs = r.get("errors", [])
    if isinstance(errs, list) and errs:
        for e in errs[:3]:
            if isinstance(e, dict):
                print(f"  ERROR: {e.get('code','?')[:100]}")
            else:
                print(f"  ERROR: {str(e)[:100]}")
    print()
