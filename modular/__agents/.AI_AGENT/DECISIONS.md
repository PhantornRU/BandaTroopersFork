# DECISIONS - Variant A Building Layout Furnishing

## D-001: Treat 30.06.26 review as the active Variant A contract
- Decision: Implement the provider/module/solver/counter plan from `30.06.26_review.md` as the current task contract.
- Why: The user explicitly requested `/goal Implement Variant A` and pointed at that review.

## D-002: Production path only
- Decision: Put generation and validation logic in `modular/world_edit/code/generators/building_layout/**`; Workbench changes are limited to metric/report expectations.
- Why: Prior PR99 evidence and current repo rules keep `tools/world_edit_visual` read-only/reporting for generation behavior.

## D-003: Catalogs may be generated from current production declarations
- Decision: The provider and placement module catalogs can be built from existing faction provider paths and current archetype cluster specs, with explicit validation and metadata expansion.
- Why: The plan requires existing build paths/templates and current cluster integration; generating catalog entries from those declarations avoids invented paths while meeting count contracts.

## D-004: Self challenge instead of subagent
- Decision: Do the plan-mapping challenge in the main agent.
- Why: Current user request did not explicitly allow subagents for this slice, and workflow rules require subagents only when requested/allowed.

## D-005: Wall-optional sanitation module in sanitation zone
- Decision: Treat `toilet`/`sanitation` as wall-preferred but wall-optional for Variant A module placement and preflight capacity.
- Why: The target-room living layout can create a valid sanitation room with no adjacent wall slot for the legacy wall-object contract. The acceptance requirement is zero `toilet_outside_sanitation_count`, not mandatory wall attachment.

## D-006: Optional chair-only clusters are skipped
- Decision: Skip optional chair-only semantic clusters in module placement.
- Why: A chair-only optional object module creates `unpaired_chair_count`; table/chair seating should come from table-cluster modules instead.

## Pending Decisions
- None.
