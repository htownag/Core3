# Mod Notes — ultrareview-extraction

This branch is the C++ patch track for **ExtractionMod-SWGEmu**, an extraction-PVP mod on top of SWGEmu Core3.

**Project repo** (design docs, workplans, Lua overlay content): [`htownag/ExtractionMod-SWGEmu`](https://github.com/htownag/ExtractionMod-SWGEmu)

## Patch table (revised 2026-04-22)

A pre-Phase-1 research sprint against Core3 HEAD (2026-04-22) reduced the originally-planned 6-patch surface to 4 C++ patches plus one pure-Lua replacement. See the project repo's [`workplans/phase-1-research-notes.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/workplans/phase-1-research-notes.md) for the full rationale, and [`docs/ultraplan.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/docs/ultraplan.md) 2026-04-22 revision section for the decision trail.

| Patch | File(s) | Purpose | LOC | Status |
|---|---|---|---|---|
| **A** | `Zone.idl` + `ZoneImplementation.cpp` + `ZoneServerImplementation.cpp` + 6 call sites:<br>`PlanetManager.idl:117`<br>`packets/zone/CmdStartScene.h:28`<br>`packets/object/PlayersNearYou.h:45`<br>`packets/ui/ClientMfdStatusUpdateMessage.h:24`<br>`packets/player/CharacterSheetResponseMessage.h:37`<br>`packets/player/CharacterSheetResponseMessage.h:58` | Zone terrain + client name override. Adds `clientZoneName` transient field + `getClientZoneName()` / `getTerrainName()` / `setClientZoneName()` on Zone; wires boot-time `setClientZoneName("lok")` for `extraction_outpost` in `ZoneServerImplementation::startGroundZones`. Enables Path B cloned-zone: server tracks `extraction_outpost`, client renders Lok terrain + shows "Lok" in UI. | ~40 actual (spec ~60) | ✅ Landed 2026-04-23 |
| **B** | `LootManagerImplementation.cpp:757` (leaf overload) | Tags loot created on `extraction_outpost` via `obj->setLuaStringData("extractpvp:planet_bound", "1")`. luaStringData is the canonical Core3 per-tangible tag mechanism (used by vanilla village phase4 for `ownerID`/`trackingPlanet`/etc.); no IDL edit, no wire exposure, no optionsBitmask bit squat. All 3 `createLoot` overloads funnel to this leaf per R.4. Scope: leaf only — `createLootSet` (line 815) is an additional path surfaced during Session 1 reading, flagged as known uncovered for v0.1 (no gameplay hooks fire it on extraction_outpost in v0.1). | ~5 actual (spec ~20) | ✅ Landed 2026-04-23 |
| **C** | `PlayerManagerImplementation::sendPlayerToCloner` + new `ExtractionCorpseDespawnTask.h` | Death corpse-drop: on `extraction_outpost`, bag contents spawn as a lootable corpse container at death coords, 15-min despawn timer. | ~80 | pending |
| **D** | `TravelTerminalImplementation::handleObjectMenuSelect` + new `PlayerManager::extractionBagPreDeparture` helper | Shuttle pre-departure atomic transfer: bag contents → player inventory (overflow to bank), PLANET_BOUND flag cleared. Fires BEFORE animation begins. | ~30 | pending |
| **E** | `LuaContainerComponent.{h,cpp}` | Forwards `checkContainerPermission(SceneObject*, CreatureObject*, uint16)` to the Lua class alongside the existing three forwards (canAddObject / transferObject / removeObject). Lua return: -1 fall-through, 0 deny, non-zero non-(-1) allow. Enables dynamic permission gating (e.g., MOVEOUT denial while on a specific zone) without modifying vanilla container behavior. **Required for Rule 2 enforcement** — `ContainerComponent::transferObject:244` ignores the source container's `removeObject` return value, so the only pure-Lua-reachable outbound gate is the MOVEOUT permission check at `TransferItemMiscCommand.h:148`. | ~20 actual | ✅ Landed 2026-04-23 |

**Total C++ surface projected: ~175 LOC across 5 files** (~40 landed in A + ~5 landed in B + ~20 landed in E + ~110 projected in C/D). Original ultraplan estimate was ~380–460 LOC across 6 files. Patch-B shrank from ~20 spec LOC to ~5 actual after Option D (luaStringData). Patch-E was a surprise — discovered during D2 Session 2 when the Lua-only Rule 2 path failed empirically; root-caused to `LuaContainerComponent` missing a `checkContainerPermission` forward. A natural ~20 LOC extension mirroring the existing three forwards; candidate for upstream contribution.

### Patch-3 replaced by Lua

The original plan had Patch-3 as a ~200 LOC C++ subclass of `ContainerComponent` enforcing extraction-bag routing rules. Research found that `SceneObjectImplementation::setContainerComponent(name)` at `src/server/zone/objects/scene/SceneObjectImplementation.cpp:523–540` already falls through string names to a Lua global class via `LuaContainerComponent`. The bag's rules are therefore Lua, not C++, and live in the project repo's `mod-overlay/`. **Nothing in this branch for Patch-3.**

## Rebase policy

Rebase onto `upstream/unstable` weekly during active development. Each patch (A, B, C, D) is a separate commit for clean rebase. If a rebase conflict hits a patch site, resolve against upstream's version and re-apply our diff.

## Patch application order

Dependency order:
- **A first** — zone infrastructure; everything else runs on `extraction_outpost` which A creates.
- **B** — independent of C/D; unblocks Deliverable 2's bag rules (they check the PLANET_BOUND flag).
- **C** — uses A (zone name check); independent of B/D.
- **D** — uses A (zone name check); independent of B/C.

Execution sequence documented in the project repo's [`workplans/phase-1.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/workplans/phase-1.md) and per-deliverable docs under `workplans/phase-1/`.

## Mod overlay drop target

The mod's Lua content — screenplays, templates, loot groups, mobile definitions — lives in the project repo at `mod-overlay/`. At deployment, rsync into `MMOCoreORB/bin/scripts/custom_scripts/` via the script at `scripts/sync-mod.sh` in the project repo. The vanilla Core3 loaders at `bin/scripts/{screenplays,mobile,object,loot}/*.lua` already include from `custom_scripts/`. **No vanilla file edits required for the overlay.**

## Rebase-conflict points — vanilla-tree edits

The mod overlay goal is "zero vanilla edits," but some Core3 subsystems don't have a `custom_scripts/` hook and require direct appends to vanilla files. Each such edit is listed below with its reason; on every upstream rebase, these need to be re-applied by hand.

| # | File | Edit | Reason | Landed in |
|---|---|---|---|---|
| 1 | `MMOCoreORB/bin/conf/config-local.lua` | `"extraction_outpost"` appended to `ZonesEnabled` | `config-local.lua` is NOT tracked in git — per-operator local config — so this is re-added on a fresh setup, not "conflicted." Documented here for continuity. | D1 |
| 2 | `MMOCoreORB/bin/scripts/managers/planet/planet_manager.lua` | `extraction_outpost = { ... }` block appended at tail | `PlanetManagerImplementation::loadLuaConfig` uses `new Lua(); init(); runFile(...)` without registering the `includeFile` helper — so `custom_scripts/` shim is not available in this Lua context. Full-block direct append is the only option until an upstream hook lands. | D1 |
| 3 | `MMOCoreORB/bin/scripts/managers/planet/extraction_outpost_regions.lua` | New file: `extraction_outpost_regions = {}` (empty table) | `PlanetManagerImplementation::loadRegions()` runs `scripts/managers/planet/<zoneName>_regions.lua` for every zone on boot. Missing file → per-boot `ERROR cannot open ...` log spam. Empty table satisfies the loader. Real per-zone `ActiveArea`s for this mod live as screenplays under `custom_scripts/screenplays/extraction_mod/` (different Lua context, includeFile works there). | D1 |
| 4 | `MMOCoreORB/bin/scripts/managers/planet/planet_manager.lua` (possible second edit) | `travelFares` overrides for `extraction_outpost` ↔ vanilla planets | Deliverable 11 (entry shuttle from Coronet). Decision between C++ post-load hook vs Lua-driven overrides is open — lean Lua. If Lua, this file grows a second edit. | planned D11 |

**On rebase:** `git diff upstream/unstable HEAD --stat` and re-apply items 2–4 by hand if they conflict. Item 1 is local-only; item 3 is a new file so it won't conflict.

## Related files on this branch

- [`DEV_LOOP.md`](DEV_LOOP.md) — iteration workflow for editing mod-overlay / C++ / config, with restart steps.
- [`.github/workflows/build.yml`](.github/workflows/build.yml) — Lua syntax CI (luac -p) on every push. C++ build CI deferred until after Patch-A lands.

## Links

- Upstream Core3: https://github.com/swgemu/Core3
- This fork: https://github.com/htownag/Core3
- Project repo (design + overlay + research): https://github.com/htownag/ExtractionMod-SWGEmu

---

*Last updated: 2026-04-23 (Phase 1 Deliverable 1 close-out — Patch-A landed, verified in-client: extraction_outpost boots with Lok terrain, all 4 client UI surfaces read "Lok", vanilla zones regression-clean). Each subsequent patch landing appends a commit + updates this table's Status column.*
