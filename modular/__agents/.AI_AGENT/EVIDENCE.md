# EVIDENCE

## Runtime Evidence
- `data/logs/tests.log` currently enumerates the `gun_lineart` offenders:
  - `/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/canc`
  - `/obj/item/weapon/gun/rifle/m20a/merc`
  - `/obj/item/weapon/gun/rifle/m20a/merc/tactical`
  - `/obj/item/weapon/gun/rifle/m20a/merc/unloaded`
  - `/obj/item/weapon/gun/rifle/r81m1a/m1b`
  - `/obj/item/weapon/gun/rifle/r81m1a/m1c`
  - `/obj/item/weapon/gun/rifle/r81m1a/m1c/modded`
  - `/obj/item/weapon/gun/rifle/r81m1a/m1d`
  - `/obj/item/weapon/gun/shotgun/p79s`
  - `/obj/item/weapon/gun/shotgun/p79s/unloaded`
  - `/obj/item/weapon/gun/shotgun/p79s/slug`
  - `/obj/item/weapon/gun/smartgun/l56a2`
  - `/obj/item/weapon/gun/smartgun/l56a2/elite`

## Confirmed `forceMove(null)` Stack
- `data/logs/2026/03-March/06-Friday/round-153/runtime.log`
  - `LW-317 Barrel (/obj/item/attachable/lw317barrel): Detach(null, the LW/RS-317 pulse carbine, 1)`
  - `the suppressor: Attach(the LW/RS-317 pulse carbine)`
  - `the LW/RS-317 pulse carbine: handle starting attachment()`
  - `gunlineart (/datum/asset/spritesheet/gun_lineart): register()`
- `data/logs/2026/03-March/06-Friday/round-149/runtime.log`
  - `the rail flashlight: Detach(null, the M41A2 pulse rifle MK2, 1)`
  - `the laser sight: Attach(the M41A2 pulse rifle MK2)`
  - `the M41A2 pulse rifle MK2: handle random attachments()`
  - `gunlineart (/datum/asset/spritesheet/gun_lineart): register()`

## Current Fix Direction
- Use explicit type-level `base_gun_icon` aliases for variant weapons with existing family lineart, but consume them only from `initial(base_gun_icon)` inside `gun_lineart.register()`.
- Add a dedicated `p79s` lineart state.
- Keep `forceMove()` strict and fix `/obj/item/attachable/proc/Detach()` for off-map attachment replacement.

## Verification
- `git diff --check`
  - Passed after the final lineart-only alias fix.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - Passed: `colonialmarines.dmb - 0 errors, 0 warnings (3/6/26 9:10 pm)`.
- fresh runtime/log verification
  - `data/logs/2026/03-March/06-Friday/round-157/runtime.log` contains no `does not have a valid lineart icon state`.
  - `data/logs/2026/03-March/06-Friday/round-157/runtime.log` contains no `No valid destination passed into forceMove`.
  - `data/logs/2026/03-March/06-Friday/round-157/game.log` reaches `Round started at Fri Mar 06 21:13:42 2026`.

## Residuals
- `dm-test` was stopped after the target runtime path validated cleanly because the run had already progressed into unrelated `missing_icons.dm` failures (`armor_plate_100`, `commandopack`, `m20a_tactical`, several attachment icons).
- Those failures were pre-existing scope-external icon issues and were not part of this lineart/attachment runtime task.
