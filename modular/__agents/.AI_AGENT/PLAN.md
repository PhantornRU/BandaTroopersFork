# PLAN

## Active task
Rework the `World Edit Panel` UI so it follows the GM workflow
`Select -> Configure -> Preview -> Apply -> History`, reduces context
duplication, and stays compatible with the current runtime/backend contract.

## Scope
- `tgui/packages/tgui/interfaces/WorldEditPanel.tsx`
- Task-state notes for this work item
- Validation through relevant tgui checks

## Out of scope
- Generator business logic changes
- Expanding generator capabilities beyond current backend data
- Reworking undo/rollback semantics
- Unrelated refactors in other tgui interfaces

## Phases
1. Capture current UI contract and pain points. Done.
2. Rebuild IA and action hierarchy in `WorldEditPanel.tsx`. Done.
3. Add backend state only if frontend cannot express state safely. Not needed.
4. Run relevant checks and prepare commit/push to the PR branch. In progress.

## Acceptance criteria
- UI no longer forces the user to bounce across multiple separate workspaces
  for one generator flow.
- Generator, preview, placement, and session context are visible without
  duplicated panels carrying the same meaning.
- Wizard fallback remains available.
- Changes stay limited to the World Edit surface and pass relevant tgui checks.
