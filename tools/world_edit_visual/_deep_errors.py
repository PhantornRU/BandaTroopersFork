#!/usr/bin/env python3
"""Deep-dive into error cases: extract candidate report metrics."""
import json, os

BASE = "data/world_edit_visual/out"

for case in sorted(os.listdir(BASE)):
    rp = os.path.join(BASE, case, "report.json")
    if not os.path.isfile(rp):
        continue
    r = json.load(open(rp, "r", encoding="utf-8-sig"))
    if r.get("status") != "error":
        continue
    errs = r.get("errors", [])
    if not errs:
        continue
    meta = errs[0].get("details", {}).get("metadata", {})
    lcr_list = meta.get("layout_candidate_reports", [])
    if not lcr_list:
        print(f"{case}: NO candidate reports")
        continue
    lcr = lcr_list[0]
    print(f"=== {case} ===")
    print(f"  error_count={lcr.get('error_count')}")
    print(f"  reachability_failure_count={lcr.get('reachability_failure_count')}")
    print(f"  mandatory_room_missing_count={lcr.get('mandatory_room_missing_count')}")
    print(f"  mandatory_room_no_access_count={lcr.get('mandatory_room_no_access_count')}")
    print(f"  mandatory_fixture_access_unreachable_count={lcr.get('mandatory_fixture_access_unreachable_count')}")
    print(f"  forbidden_fallback_count={lcr.get('forbidden_fallback_count')}")
    print(f"  empty_floor_ratio={lcr.get('empty_floor_ratio')}")
    print(f"  signature_score={lcr.get('signature_score')}")
    print(f"  connectivity_score={lcr.get('connectivity_score')}")
    print(f"  repeat_index={lcr.get('repeat_index')}")
    print(f"  room_count={lcr.get('room_count')}")
    print(f"  errors={lcr.get('errors')}")
    print()
