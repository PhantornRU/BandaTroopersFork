# DECISIONS

## D-001: Use a workflow-first redesign instead of cosmetic cleanup
- Decision: Restructure the panel around the linear GM flow.
- Why: The main UX problem is information architecture, not missing styling.

## D-002: Reuse the current backend contract first
- Decision: Build the redesign on top of existing `ui_data()` fields and only
  add backend data if the frontend cannot represent state safely.
- Why: The manager already exposes generator meta, fields, placement state,
  preview/apply state, history, and latest operation data.

## D-003: Keep wizard fallback visible as an escape hatch
- Decision: Preserve `configure_wizard` as a first-class action even when
  inline fields are available.
- Why: It is required by the UI field schema and protects generator-specific
  or degraded configuration flows.

## D-004: Collapse setup and run into one workspace
- Decision: Replace the old `Catalog / Setup / Run / History` split with
  `Browse / Work / History`, plus a shared context header and a persistent
  action rail.
- Why: The old split forced the user to reconstruct state mentally between
  multiple screens.

## D-005: Do not add backend changes in this pass
- Decision: Keep this implementation frontend-only.
- Why: Existing runtime data was sufficient to drive workflow messaging,
  action availability, and session summaries.
