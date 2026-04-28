# Mod Notes — ultrareview-extraction

This branch is the C++ patch track for **ExtractionMod-SWGEmu**, an extraction-PVP mod on top of SWGEmu Core3.

**Project repo** (design docs, workplans, Lua overlay content): [`htownag/ExtractionMod-SWGEmu`](https://github.com/htownag/ExtractionMod-SWGEmu)

## Patch table (revised 2026-04-22)

A pre-Phase-1 research sprint against Core3 HEAD (2026-04-22) reduced the originally-planned 6-patch surface to 4 C++ patches plus one pure-Lua replacement. See the project repo's [`workplans/phase-1-research-notes.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/workplans/phase-1-research-notes.md) for the full rationale, and [`docs/ultraplan.md`](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/docs/ultraplan.md) 2026-04-22 revision section for the decision trail.

| Patch | File(s) | Purpose | LOC | Status |
|---|---|---|---|---|
| **A** | same 8 files as original (reverted to pre-Patch-A via targeted `git checkout 68911d6c10^ -- <file>` on each C++/IDL file, then committed as `bfbb7e95c4`) | ~~Zone terrain + client name override~~ | ~40 | ❌ **REVERTED 2026-04-24** in D6 v2 S1 (commit `bfbb7e95c4`). Superseded by **Option T**: `tython_01.tre` (client mod TRE) makes tython a first-class 11th client-known planet, so the cloned-zone UI-rewrite trick is no longer needed. D1 retrospective insights (IDL/boot-ordering/transient field / includeFile limitation / loadRegions file req) preserved in the project repo's `workplans/phase-1/deliverable-06-travel-hook.md` §Preserved D1 knowledge. |
| **B** | `LootManagerImplementation.cpp:757` (leaf overload) | Tags loot created on `tython` via `obj->setLuaStringData("extractpvp:planet_bound", "1")`. luaStringData is the canonical Core3 per-tangible tag mechanism (used by vanilla village phase4 for `ownerID`/`trackingPlanet`/etc.); no IDL edit, no wire exposure, no optionsBitmask bit squat. All 3 `createLoot` overloads funnel to this leaf per R.4. Scope: leaf only — `createLootSet` (line 815) is an additional path surfaced during Session 1 reading, flagged as known uncovered for v0.1 (no gameplay hooks fire it on tython in v0.1). | ~5 actual (spec ~20) | ✅ Landed 2026-04-23 |
| **C** | `PlayerManagerImplementation::killPlayer` (`PlayerManagerImplementation.cpp:~1500`) + `dropExtractionBagToCorpse` helper + new `ExtractionCorpseDespawnTask.h` at `src/server/zone/objects/creature/events/` | Death corpse-drop: on `tython`, the player's extraction bag contents are transferred to a spawned corpse container (template `object/tangible/container/extraction_corpse.iff`, clones `shared_satchel` with `containerComponent = "PlaceableLootContainerComponent"`) at the death coords, a 15-min `ExtractionCorpseDespawnTask` is scheduled, the bag itself stays in the dying player's inventory (empty, for reuse). The PlaceableLootContainerComponent override (same component used by vanilla placable_loot_crate templates) hard-codes MOVEOUT=true and MOVEIN=false, bypassing the permission-bit machinery that silently rejected drag-out during D5 testing. Initial bag→corpse population uses `SceneObject::transferObject(item, -1, false)` which does not call `canAddObject`, so MOVEIN=false does not block server-side fill. Helper lives alongside Patch-F's `findExtractionBagIfRoutable` in the file-scope anonymous-namespace at top of PlayerManagerImplementation.cpp; shares the raw `findExtractionBag(player)` walk with Patch-F. Injected at `killPlayer` entry (not `sendPlayerToCloner` — the latter fires only after the player accepts clone; we want contents to drop at the moment of death regardless of clone choice). Defensive `Locker playerLocker(player)` at helper entry. Cell-death case: tries to spawn corpse inside the cell; falls back to zone drop if cell lookup fails. Despawn task is a minimal 20-LOC `Task` subclass mirroring `DespawnCreatureTask`'s pattern. | ~55 actual | ✅ Landed 2026-04-24 |
| **G** | `TransferItemMiscCommand::doTransferItemMisc` | Extraction-mod drag auto-route. If a tagged (`extractpvp:planet_bound="1"`) tangible is being dragged into the creature's main inventory AND the creature is on `tython` AND they have an Extraction Pack in that inventory, substitutes the Pack as the destination before the downstream checks. Generalizes Patch-F's lootAll-only redirect to cover manual drag from any source container (Dropped Pack, NPC corpse radial, future paths). Keeps the "tagged items can only live in the bag on-zone" invariant for manual transfers. Scoped to Misc command only — Weapon/Armor transfer commands never fire for drag-from-world-container loot (all drags route through Misc), verified via diagnostic logging during D5 testing. | ~25 actual | ✅ Landed 2026-04-24 |
| **D** | `TravelTerminalImplementation::handleObjectMenuSelect` + new `PlayerManager::extractionBagPreDeparture` helper | Shuttle pre-departure atomic transfer: bag contents → player inventory (overflow to bank), `extractpvp:planet_bound` LuaStringData cleared. Fires BEFORE animation begins. | ~30 | D6 v2 S5 — drafted, awaiting compile |
| **E** | `LuaContainerComponent.{h,cpp}` | Forwards `checkContainerPermission(SceneObject*, CreatureObject*, uint16)` to the Lua class alongside the existing three forwards (canAddObject / transferObject / removeObject). Lua return: -1 fall-through, 0 deny, non-zero non-(-1) allow. Enables dynamic permission gating (e.g., MOVEOUT denial while on a specific zone) without modifying vanilla container behavior. **Required for Rule 2 enforcement** — `ContainerComponent::transferObject:244` ignores the source container's `removeObject` return value, so the only pure-Lua-reachable outbound gate is the MOVEOUT permission check at `TransferItemMiscCommand.h:148`. | ~20 actual | ✅ Landed 2026-04-23 |
| **F** | `PlayerManagerImplementation::lootAll` (`PlayerManagerImplementation.cpp:~4275`) | Extraction-mod loot auto-route. Inside the loot-all for-loop, branches the per-item transfer destination: if the item is a planet-bound tangible (D3's `extractpvp:planet_bound="1"` tag) AND the looting player is on `tython` AND they have an extraction bag in their top-level inventory, the bag replaces `playerInventory` as the destination passed to `TransferItemMiscCommand::doTransferItemMisc`. Otherwise vanilla behavior. Helper `findExtractionBagIfRoutable` is file-scope anonymous-namespace; no IDL change. Covers both solo and group loot-all (GroupLootTask.h funnels to this same `lootAll`). Manual drag-and-drop single-item loot is player-controlled and not auto-routed. `pickupOwnedItems` recovery path in LootCommand.h is an [OPEN] edge case deferred for v0.1. | ~25 actual | ✅ Landed 2026-04-23 |
| **H** | `ResourceSpawner::createResourceSpawn` (`MMOCoreORB/src/server/zone/managers/resource/resourcespawner/ResourceSpawner.cpp:~522` — inside the attribute population loop) | D9 Tier 1: tython resource stat-floor boost. Inside the existing `for (i = 0; i < resourceEntry->getAttributeCount(); ++i)` loop, raises the `attrMin` passed to `randomizeValue` to `(int)(attrMax * 0.75f)` whenever `resourceEntry->getZoneRestriction() == "tython"`. Result: any `_tython`-suffixed resource family (added in D9 Tier 1.5 via `resource_tree.iff` edit, not yet shipped) gets a guaranteed 75%-of-max attribute floor on every roll. **Currently INERT until Tier 1.5 lands** — vanilla `resource_tree.iff` has zero `_tython`-suffixed types, so no resource has `zoneRestriction == "tython"` and the boost branch never fires. Mechanism is in place; Tier 1.5 activates it. No IDL change, no header change, no helper function — pure inline edit. Patch script: `scripts/apply-patch-h.py` (idempotent). | ~7 actual | ✅ Landed 2026-04-27 |

**Total C++ surface: ~217 LOC across 9 files** (~40 landed in A + ~5 landed in B + ~20 landed in E + ~25 landed in F + ~55 landed in C + ~25 landed in G + ~40 projected in D). Original ultraplan estimate was ~380–460 LOC across 6 files. Patch-B shrank from ~20 spec LOC to ~5 actual after Option D (luaStringData). Patch-E was a surprise — discovered during D2 Session 2 when the Lua-only Rule 2 path failed empirically; root-caused to `LuaContainerComponent` missing a `checkContainerPermission` forward. A natural ~20 LOC extension mirroring the existing three forwards; candidate for upstream contribution.

### Patch-3 replaced by Lua

The original plan had Patch-3 as a ~200 LOC C++ subclass of `ContainerComponent` enforcing extraction-bag routing rules. Research found that `SceneObjectImplementation::setContainerComponent(name)` at `src/server/zone/objects/scene/SceneObjectImplementation.cpp:523–540` already falls through string names to a Lua global class via `LuaContainerComponent`. The bag's rules are therefore Lua, not C++, and live in the project repo's `mod-overlay/`. **Nothing in this branch for Patch-3.**

## Rebase policy

Rebase onto `upstream/unstable` weekly during active development. Each patch (A, B, C, D) is a separate commit for clean rebase. If a rebase conflict hits a patch site, resolve against upstream's version and re-apply our diff.

## Patch application order

Dependency order:
- **A first** — zone infrastructure; everything else runs on `tython` which A creates.
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
| 1 | `MMOCoreORB/bin/conf/config-local.lua` | `"tython"` appended to `ZonesEnabled` | `config-local.lua` is NOT tracked in git — per-operator local config — so this is re-added on a fresh setup, not "conflicted." Documented here for continuity. | D1 |
| 2 | `MMOCoreORB/bin/scripts/managers/planet/planet_manager.lua` | `tython = { ... }` block appended at tail | `PlanetManagerImplementation::loadLuaConfig` uses `new Lua(); init(); runFile(...)` without registering the `includeFile` helper — so `custom_scripts/` shim is not available in this Lua context. Full-block direct append is the only option until an upstream hook lands. | D1 |
| 3 | `MMOCoreORB/bin/scripts/managers/planet/tython_regions.lua` | New file: `tython_regions = {}` (empty table) | `PlanetManagerImplementation::loadRegions()` runs `scripts/managers/planet/<zoneName>_regions.lua` for every zone on boot. Missing file → per-boot `ERROR cannot open ...` log spam. Empty table satisfies the loader. Real per-zone `ActiveArea`s for this mod live as screenplays under `custom_scripts/screenplays/extraction_mod/` (different Lua context, includeFile works there). | D1 |
| 4 | `MMOCoreORB/bin/scripts/managers/planet/planet_manager.lua` (possible second edit) | `travelFares` overrides for `tython` ↔ vanilla planets | Deliverable 11 (entry shuttle from Coronet). Decision between C++ post-load hook vs Lua-driven overrides is open — lean Lua. If Lua, this file grows a second edit. | planned D11 |
| 5 | `MMOCoreORB/bin/scripts/managers/resource_manager.lua` | `tython` appended to `activeZones` (col 47) | `ResourceManagerImplementation::loadConfigData:94` reads `activeZones` from this file with no `custom_scripts` include hook. Direct edit only. Without this line, no resources spawn on tython AND `ResourceTree::setZoneRestriction:142` substring match on `_tython` in resource type names never triggers. | D9 Tier 1 (2026-04-27) |

**On rebase:** `git diff upstream/unstable HEAD --stat` and re-apply items 2–4 by hand if they conflict. Item 1 is local-only; item 3 is a new file so it won't conflict.

## Related files on this branch

- [`DEV_LOOP.md`](DEV_LOOP.md) — iteration workflow for editing mod-overlay / C++ / config, with restart steps.
- [`.github/workflows/build.yml`](.github/workflows/build.yml) — Lua syntax CI (luac -p) on every push. C++ build CI deferred until after Patch-A lands.

## Links

- Upstream Core3: https://github.com/swgemu/Core3
- This fork: https://github.com/htownag/Core3
- Project repo (design + overlay + research): https://github.com/htownag/ExtractionMod-SWGEmu

---

*Last updated: 2026-04-27 (D9 Tier 1: Patch-H tython resource stat-floor boost landed in `ResourceSpawner.cpp`, plus `tython` added to `activeZones` in `resource_manager.lua`. Patch-H is INERT until D9 Tier 1.5 lands — Tier 1.5 adds 5 `_tython` resource family rows to `resource_tree.iff` via SIE, see `workplans/phase-1/d9-tier-15-resource-tree-authoring.md` in the project repo.) Previously: D6 v2 pivot — Patch-A REVERTED; tython pivots to a first-class 11th client-known planet via `tython_01.tre` mod TRE; D5 close-out Patch-C + Patch-G; D4b close-out Patch-F; D1 close-out Patch-A landed. Each subsequent patch landing appends a commit + updates this table's Status column.*
