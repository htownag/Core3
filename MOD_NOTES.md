# Mod Notes — ultrareview-extraction

This branch is the C++ patch track for **ExtractionMod-SWGEmu**, an extraction-PVP mod on top of SWGEmu Core3.

**Project repo** (design docs, workplans, Lua overlay content): [`htownag/ExtractionMod-SWGEmu`](https://github.com/htownag/ExtractionMod-SWGEmu)

## Patch table (revised 2026-04-22)

A pre-Phase-1 research sprint against Core3 HEAD (2026-04-22) reduced the originally-planned 6-patch surface to 4 C++ patches plus one pure-Lua replacement. See the project repo's [`workplans/phase-1-research-notes.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/workplans/phase-1-research-notes.md) for the full rationale, and [`docs/ultraplan.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/docs/ultraplan.md) 2026-04-22 revision section for the decision trail.

| Patch | File(s) | Purpose | LOC |
|---|---|---|---|
| **A** | `Zone.idl` + `ZoneImplementation.cpp` + 6 call sites:<br>`PlanetManager.idl:117`<br>`packets/zone/CmdStartScene.h:28`<br>`packets/object/PlayersNearYou.h:45`<br>`packets/ui/ClientMfdStatusUpdateMessage.h:24`<br>`packets/player/CharacterSheetResponseMessage.h:37`<br>`packets/player/CharacterSheetResponseMessage.h:58` | Zone terrain + client name override. Adds `Zone::getTerrainName()` + `Zone::getClientZoneName()` virtuals; patches the 6 call sites to use them. Enables Path B cloned-zone: server tracks `extraction_outpost`, client renders as `lok`. | ~60 |
| **B** | `LootManagerImplementation.cpp:757` (leaf overload) | Sets PLANET_BOUND flag on `optionsBitmask` for loot created on `extraction_outpost`. All 3 `createLoot` overloads funnel to this leaf. | ~20 |
| **C** | `PlayerManagerImplementation::sendPlayerToCloner` + new `ExtractionCorpseDespawnTask.h` | Death corpse-drop: on `extraction_outpost`, bag contents spawn as a lootable corpse container at death coords, 15-min despawn timer. | ~80 |
| **D** | `TravelTerminalImplementation::handleObjectMenuSelect` + new `PlayerManager::extractionBagPreDeparture` helper | Shuttle pre-departure atomic transfer: bag contents → player inventory (overflow to bank), PLANET_BOUND flag cleared. Fires BEFORE animation begins. | ~30 |

**Total C++ surface: ~190 LOC across 4 files.** Original ultraplan estimate was ~380–460 LOC across 6 files.

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

(Two small exceptions, documented per-deliverable: `config-local.lua` needs `"extraction_outpost"` added to `ZonesEnabled`, and `bin/scripts/managers/planet/planet_manager.lua` may need an entry-shuttle fare-table edit for Deliverable 11 — both will be revisited as post-load hooks before first public release.)

## Related files on this branch

- [`DEV_LOOP.md`](DEV_LOOP.md) — iteration workflow for editing mod-overlay / C++ / config, with restart steps.
- [`.github/workflows/build.yml`](.github/workflows/build.yml) — Lua syntax CI (luac -p) on every push. C++ build CI deferred until after Patch-A lands.

## Links

- Upstream Core3: https://github.com/swgemu/Core3
- This fork: https://github.com/htownag/Core3
- Project repo (design + overlay + research): https://github.com/htownag/ExtractionMod-SWGEmu

---

*Last updated: 2026-04-22 (Phase 1 Deliverable 0 close-out). Each subsequent patch landing appends a commit + updates this table's LOC column as written.*
