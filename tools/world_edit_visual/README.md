# World Edit Visual Workbench

World Edit Visual Workbench is a file-based developer harness for exercising the real World Edit `building_layout` generator in a running DM server. It reads JSON cases from a runtime inbox, applies them on a bounded visual canvas, and writes structured reports plus semantic render data that can be turned into PNG previews.

The workbench does not simulate generation in Python. Python tools only copy cases, render `semantic.json`, watch outputs, and build an index.

## Runtime Paths

Canonical runtime paths are repo-root paths:

- `data/world_edit_visual/enabled.txt` enables the DM workbench at World Edit modpack initialization.
- `data/world_edit_visual/inbox/*.json` is the case inbox watched by the running DM runtime.
- `data/world_edit_visual/out/<case_id>/report.json` is the structured case report.
- `data/world_edit_visual/out/<case_id>/semantic.json` is the semantic canvas export.
- `data/world_edit_visual/out/<case_id>/semantic.png` is produced by the Python renderer, not by DM.
- `data/world_edit_visual/out/<case_id>/external_profile.json` is produced by the watcher after rendering.

Do not treat `tools/world_edit_visual/data/...` as canonical runtime state. The runtime flag and inbox/out directories are under repo-root `data/world_edit_visual`.

## Setup

Run commands from the repository root.

1. Install Python dependencies for rendering:

   ```powershell
   py -3 -m pip install Pillow
   ```

   `render_semantic.py` imports `PIL.Image` and `PIL.ImageDraw`.

2. Create runtime directories and enable the workbench:

   ```powershell
   py -3 tools/world_edit_visual/prepare_cases.py tools/world_edit_visual/cases
   ```

   `prepare_cases.py` creates `data/world_edit_visual/inbox`, `data/world_edit_visual/out`, `data/world_edit_visual/enabled.txt`, and per-case output folders, then copies case JSON files into the inbox.

3. Build and start the game runtime normally for this repo. The workbench starts only when `data/world_edit_visual/enabled.txt` exists before world initialization.

## Running Cases

Copy one sample case to the inbox:

```powershell
tools\world_edit_visual\run_case.bat tools\world_edit_visual\cases\building_living_rectangle_colony.json
```

Copy all sample cases:

```powershell
tools\world_edit_visual\run_all.bat
```

The batch files create `data/world_edit_visual/inbox`, `data/world_edit_visual/out`, and `data/world_edit_visual/enabled.txt` if needed, then copy cases into the inbox. They do not start DreamDaemon; keep a compatible DM runtime running separately.

The DM workbench polls the inbox and writes one output folder per case id:

```text
data/world_edit_visual/out/<case_id>/
  report.json
  semantic.json
```

## Rendering And Index

Render one semantic export:

```powershell
py -3 tools/world_edit_visual/render_semantic.py --semantic-json data/world_edit_visual/out/building_living_rectangle_colony/semantic.json --report-json data/world_edit_visual/out/building_living_rectangle_colony/report.json --out data/world_edit_visual/out/building_living_rectangle_colony/semantic.png
```

Watch outputs and render each new `semantic.json` once:

```powershell
py -3 tools/world_edit_visual/watch_cases.py
```

Build the Markdown index:

```powershell
py -3 tools/world_edit_visual/build_index.py
```

The index is written to `tools/world_edit_visual/index.md` and links each reported case to `semantic.png` and `report.json`.

## Generated Files And Cleanup

Source files that should remain reviewable:

- `tools/world_edit_visual/*.py`
- `tools/world_edit_visual/*.bat`
- `tools/world_edit_visual/cases/*.json`
- `tools/world_edit_visual/inbox/.gitkeep`
- `tools/world_edit_visual/out/.gitkeep`
- `tools/world_edit_visual/.gitignore`
- this `README.md`

Runtime files that are generated locally and should not be committed:

- `data/world_edit_visual/enabled.txt`
- `data/world_edit_visual/inbox/*.json`
- `data/world_edit_visual/out/<case_id>/report.json`
- `data/world_edit_visual/out/<case_id>/semantic.json`
- `data/world_edit_visual/out/<case_id>/semantic.png`
- `data/world_edit_visual/out/<case_id>/progress.json`
- `tools/world_edit_visual/index.md`
- `tools/world_edit_visual/__pycache__/`
- accidental `tools/world_edit_visual/data/...` mirrors

Why this split exists:

- `data/world_edit_visual` is runtime state for DreamDaemon. It records the last local run, not stable source.
- `tools/world_edit_visual/index.md` is a review sheet generated from runtime reports. Rebuild it with `py -3 tools/world_edit_visual/build_index.py` when needed.
- `tools/world_edit_visual/inbox` and `tools/world_edit_visual/out` are only placeholder folders for convenience. The real DM runtime does not read from them.
- `tools/world_edit_visual/data` is never canonical; if it appears, it is a local mistake or experiment and can be deleted.

Safe cleanup command for Workbench-only generated files:

```powershell
Remove-Item -Recurse -Force data/world_edit_visual -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force tools/world_edit_visual/data -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force tools/world_edit_visual/__pycache__ -ErrorAction SilentlyContinue
Remove-Item -Force tools/world_edit_visual/index.md -ErrorAction SilentlyContinue
```

## Case Schema

Cases are JSON files. Required fields are `id`, `generator`, `canvas`, and `shape`; the current workbench accepts only `generator: "building_layout"`.

Example:

```json
{
  "id": "building_living_rectangle_colony",
  "generator": "building_layout",
  "seed": 1001,
  "canvas": {
    "preset": "blank_96",
    "width": 96,
    "height": 96
  },
  "shape": {
    "id": "rectangle",
    "anchors": [
      { "x": 20, "y": 20 },
      { "x": 43, "y": 39 }
    ]
  },
  "config": {
    "program": "living",
    "faction_preset": "colony",
    "direction": "east",
    "respect_blockers": false,
    "replace_blocked_turfs": true
  },
  "expect": {
    "status": "supported"
  },
  "render": {
    "semantic_png": true,
    "after_dmm": false,
    "debug_overlays": true
  },
  "profile": {
    "enabled": true,
    "include_stage_timings": true,
    "include_loop_counters": true
  }
}
```

Top-level fields:

- `id`: output folder name after filename sanitization.
- `generator`: must be `building_layout`.
- `seed`: copied to `building_seed` unless `config.building_seed` is already set.
- `canvas`: `preset`, `width`, and `height`; supported presets are `blank_64`, `blank_96`, and `blank_128`.
- `shape`: `id` plus local canvas `anchors` with `x` and `y`.
- `config`: passed to the real `building_layout` generator params. `program` is also mapped to `archetype_id` when `archetype_id` is absent.
- `expect`: user-facing expectations for manual or scripted review.
- `render`: renderer/export requests. `after_dmm` is warning-only in the MVP.
- `profile`: enables report timing data.

## Outputs

`report.json` uses schema `world_edit_visual_report/v1`. Important fields:

- `status`: `supported`, `locked`, or `error`.
- `stage`: final or failing stage, such as `support_check`, `preview`, `apply`, `post_emit_validation`, or `export`.
- `errors`: structured objects with `code`, `message`, `severity`, `stage`, and optional `x`, `y`, `z`, `details`.
- `warnings`: warning strings, including MVP warnings.
- `metrics`: counts from preview, apply, and post-emit validation.
- `profile`: DM decisecond timings and extracted counters.
- `artifacts`: artifact names such as `report.json`, `semantic.json`, and `semantic.png`.

`semantic.json` uses schema `world_edit_visual_semantic/v1`. Important fields:

- `case_id`, `width`, `height`, and `origin`.
- `tiles`: one entry per canvas tile with absolute and local coordinates, turf/area paths, density/opacity, flags, and objects.
- `tiles[].flags`: `floor`, `wall`, `door`, `reserved_walk`, `blocked`, `changed`, and `error`.
- `tiles[].objects`: object path, density, direction, and any placement metadata found on the emitted plan.
- `rooms`, `routes`, and `markers`: generator metadata used by the renderer for overlays.
- `errors` and optional `profile`.

## Real Generation Path

The DM workbench runs the production `building_layout` path:

```text
JSON case
  -> visual canvas
  -> shape contract and support report
  -> /datum/world_edit_generator/building_layout.build_plan_from_shape_contract()
  -> /datum/world_edit_generator/building_layout.apply_plan()
  -> post_emit_validation metadata
  -> report.json and semantic.json
```

Locked or unsupported shapes stop at support checking and write a locked report. For example, `line` is expected to lock for `building_layout`; it is not converted to fallback rectangle geometry.

## Sample Cases

- `building_line_locked.json`: expected locked case for unsupported `line` shape.
- `building_living_rectangle_colony.json`: explicit rectangle diagnostic case. Current production `building_layout` can fail it at preview validation with `sleep_privacy` route/connectivity errors; this is tracked as `E-WEV-001` in `modular/__agents/.AI_AGENT/CONFIRMED_UNRESOLVED_ERRORS.md`.
- `building_living_point_colony.json`: point smoke case for production generation. Current production `building_layout` can fail it at preview validation with `sanitation` connectivity errors; this is tracked as `E-WEV-002`.

The Workbench intentionally does not hide these generator failures. It records them as `status: "error"` with structured diagnostics, exports `semantic.json`, and lets `semantic.png`/`index.md` show the failing cases.

## MVP Limitations

- The preferred visual canvas is a compiled static canvas map at `modular/world_edit/maps/world_edit_visual_canvas.dmm`. Runtime dynamic z allocation remains fallback-only and is not the acceptance path.
- `after.dmm` export is not implemented in the MVP. If a case requests it, the workbench writes a warning and still exports `semantic.json`.
- Sprite-accurate rendering is out of scope. `semantic.png` is a schematic PNG made from semantic flags and object metadata, without DMI parsing.
- The Python tools do not run generation. They only handle file copying, rendering, watching, and index creation.
- DM timing uses deciseconds. Very fast cases may report `0 ds`; use watcher/external timings for finer wall-clock render timing.
- Parent runtime directories must exist. The batch scripts create the common inbox/out paths.

## Troubleshooting

No output appears:

- Confirm the game runtime was started after `data/world_edit_visual/enabled.txt` was created.
- Confirm cases were copied to `data/world_edit_visual/inbox`, not `tools/world_edit_visual/data/...`.
- Check that the case file has a `.json` suffix and a valid `id`.

The report says `unsupported_visual_generator`:

- Set `"generator": "building_layout"`. Other generators are not accepted by this workbench.

The report says `locked`:

- Check `reason_code` and `errors[0]`. Unsupported shapes, such as the sample `line` case, are expected to lock without changing the canvas.

The report says `no_visual_test_z_available`:

- The runtime could not locate the compiled visual canvas landmark and could not allocate a fallback z-level. Confirm `maps/world_edit_visual_canvas.dmm` is included in `modular/world_edit/_world_edit.dme`.

`semantic.png` is missing:

- Run `py -3 tools/world_edit_visual/render_semantic.py ...` manually or keep `py -3 tools/world_edit_visual/watch_cases.py` running.
- Install Pillow if Python raises `ModuleNotFoundError: No module named 'PIL'`.

`after.dmm` is missing:

- This is expected in the MVP. Use `semantic.json` and `semantic.png`; `after.dmm` requests are warning-only.
