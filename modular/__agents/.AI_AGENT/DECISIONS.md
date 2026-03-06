# DECISIONS

## D-001: Variant gun regressions are fixed through `base_gun_icon`
- If a weapon is a visual/content variant of an existing family, it reuses the family lineart state through `initial(base_gun_icon)` in `gun_lineart.register()`, not through the live runtime sprite path.
- Applied mappings:
  - `pf199 -> m83a2`
  - `m20a_tactical -> m20a`
  - `fal_sniper/fal_short/fal_saw -> fal`
  - `l56d -> m56`

## D-002: `p79s` gets a dedicated lineart state
- `p79s` is not aliased to `m37` or `m79`.
- Reason: it is a separate platform and needs its own lineart state for the asset contract.

## D-003: `forceMove()` stays strict
- `forceMove()` continues to crash on invalid destinations.
- The fix must happen in the confirmed caller, not in the movement core proc.

## D-004: The confirmed `forceMove(null)` caller is attachment detachment during off-map gun init
- Runtime stacks point to `/obj/item/attachable/proc/Detach()` being called while `gun_lineart.register()` instantiates guns with conflicting starter/random attachments.
- When no turf exists for a replaced attachment, the detached transient attachment is deleted instead of being dropped.

## D-005: Live gun sprites keep the original `base_gun_icon` semantics
- `/obj/item/weapon/gun/Initialize()` continues to reset `base_gun_icon = icon_state`.
- Reason: preserving lineart aliases in `Initialize()` would silently reskin live weapon sprites and overlays.
