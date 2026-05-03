-- ExtractionMod-SWGEmu D10: Tython region + combat-zone authoring.
--
-- Loaded by PlanetManagerImplementation::loadRegions() at boot. Defines:
--   - Outpost safe pads (Rebel + Imperial) — NOCOMBATAREA blocks BOTH PVP and PVE
--   - Wilderness forced-PVP — stock PVPAREA + lastPvpAreaCombatActionTimestamp TEF
--   - Planet-wide no-build (Yavin4 pattern — Tython is non-claimable for housing)
--   - NAMEDREGION POIs for D7/D8 encounter spawn-pool hints
--
-- Rebase-conflict point #2: this file is a fork edit (no custom_scripts/
-- fallback in PlanetManagerImplementation::loadRegions). MOD_NOTES.md tracks it.
--
-- Authored 2026-04-28 via SWB Region Editor (jdswebb 0.1.3) for visual
-- placement of the safe-zone CIRCLEs; the rest hand-typed for coord exactness.
-- Flag bitmasks all hand-tuned in post-edit (SWB defaults to UNDEFINEDAREA).
--
-- Polygon overlap is safe: CreatureObjectImplementation::isAttackableBy at :3654
-- short-circuits to false when either party is in NOCOMBATAREA, BEFORE the
-- PVPAREA gate at :3759. Safe-zone CIRCLEs win on overlap with the wilderness
-- rectangle.

require("scripts.managers.planet.regions")

tython_regions = {
    -- ── Safe zones ──────────────────────────────────────────────────────────
    -- Rebel Extraction Outpost. Coords + radius from SWB visual placement
    -- against the actual outpost wall ring (D6.5 TJT authoring).
    {"tython_rebel_outpost_safe", 4506.36, -128.828, {CIRCLE, 80},
        NOCOMBATAREA + NODUELAREA + NOSPAWNAREA + NOBUILDZONEAREA},

    -- Imperial Extraction Outpost. Coords from Ryan 2026-04-28; radius 100m
    -- placeholder until Phase 2 builds the outpost walls and SWB measures
    -- the actual footprint.
    {"tython_imperial_outpost_safe", 3192.45, 4391.13, {CIRCLE, 100},  -- [TUNE radius — wall footprint pending Phase 2 build]
        NOCOMBATAREA + NODUELAREA + NOSPAWNAREA + NOBUILDZONEAREA},

    -- ── Planet-edge no-build buffers (Yavin4 / Dantooine vanilla pattern) ──
    {"northedge_tython_nobuild", -8000, 7640, {RECTANGLE, 8000, 8000},
        NOSPAWNAREA + NOBUILDZONEAREA},
    {"southedge_tython_nobuild", -8000, -8000, {RECTANGLE, 8000, -7640},
        NOSPAWNAREA + NOBUILDZONEAREA},
    {"westedge_tython_nobuild", -8000, -7640, {RECTANGLE, -7640, 7640},
        NOSPAWNAREA + NOBUILDZONEAREA},
    {"eastedge_tython_nobuild", 7640, -7640, {RECTANGLE, 8000, 7640},
        NOSPAWNAREA + NOBUILDZONEAREA},

    -- ── Planet-wide no-build (overlaps everything; Tython non-claimable) ──
    -- Snapshot buildings in tython.ws bypass this gate — they're loaded as
    -- snapshot objects, not via the player structure-placement session.
    {"tython_planetwide_nobuild", -8000, -8000, {RECTANGLE, 8000, 8000},
        NOBUILDZONEAREA},

    -- ── Wilderness forced-PVP ──────────────────────────────────────────────
    -- Single planet-wide rectangle. Safe-zone CIRCLEs above win on overlap
    -- via the :3654 short-circuit. PVP TEF is provided by stock
    -- lastPvpAreaCombatActionTimestamp + FactionManager::TEFTIMER (no patch).
    {"tython_wilderness_pvp", -8000, -8000, {RECTANGLE, 8000, 8000},
        PVPAREA},

    -- ── NAMEDREGION POIs (D7/D8 encounter spawn-pool hints) ────────────────
    -- v0.1 set: 10 hand-curated locations north of the Rebel outpost.
    -- Phase 2 needs a parallel southern set when Imperial outpost ships.
    {"tython_northern_approach", 4500, 871, {CIRCLE, 200}, NAMEDREGION},
    {"tython_northern_bluffs", 4921, 887, {CIRCLE, 200}, NAMEDREGION},
    {"tython_northeast_hills", 5561, 932, {CIRCLE, 200}, NAMEDREGION},
    {"tython_northwest_plateau", 3439, 932, {CIRCLE, 200}, NAMEDREGION},
    {"tython_nne_crystal_field", 5189, 1535, {CIRCLE, 200}, NAMEDREGION},
    {"tython_nnw_forest_edge", 3811, 1535, {CIRCLE, 200}, NAMEDREGION},
    {"tython_far_north_ridge", 4500, 2071, {CIRCLE, 200}, NAMEDREGION},
    {"tython_far_nnw_approach", 3582, 2089, {CIRCLE, 200}, NAMEDREGION},
    {"tython_far_northwest_mire", 2732, 1639, {CIRCLE, 200}, NAMEDREGION},
    {"tython_far_northeast_ruins", 6409, 1780, {CIRCLE, 200}, NAMEDREGION},

    -- ── Playable area boundary (LOCKEDAREA — eject non-admins on entry) ───
    -- Playable rectangle: x ∈ [2232, 8000], y ∈ [-629, 8000].
    -- Includes both outposts + all 10 encounter waypoints with 500m margin.
    -- Outside is L-shaped (western strip + southern strip). LOCKEDAREA fires
    -- ActiveAreaImplementation::ejectFromArea() at :265-300 — teleports the
    -- creature 20m past the boundary with system message "You are not
    -- permitted to enter this area." Privileged players (admins) bypass.
    --
    -- Western lockout: full y range, x ∈ [-8000, 2232].
    {"tython_western_lockout", -8000, -8000, {RECTANGLE, 2232, 8000}, LOCKEDAREA},

    -- Southern lockout: x ∈ [2232, 8000], y ∈ [-8000, -629].
    -- (No overlap with western_lockout; the SW corner of the planet is already
    -- covered by western_lockout's full y range.)
    {"tython_southern_lockout", 2232, -8000, {RECTANGLE, 8000, -629}, LOCKEDAREA},

    -- ── World spawner (binds tython_world spawn group to whole planet) ─────
    -- Every vanilla planet has this exact pattern: zero-size RECTANGLE at
    -- origin + SPAWNAREA + WORLDSPAWNAREA + spawn-group reference + maxLimit.
    -- The WORLDSPAWNAREA flag overrides the degenerate geometry — the
    -- creature manager treats it as "spawn lairs anywhere on the planet" and
    -- pulls from the named spawn group (tython_world, defined in
    -- bin/scripts/custom_scripts/mobile/spawn/tython/tython_world.lua and
    -- registered via addSpawnGroup at boot).
    --
    -- Without this row, tython_world's lairSpawns are registered but never
    -- placed — the symptom Ryan reported as "no wild creatures, ever."
    -- Added 2026-04-28 during D10 verification (the empty-stub regions file
    -- predating D10 had no SPAWNAREA either, masking the issue all of D7-D9).
    --
    -- maxLimit 2048 mirrors dantooine (Tython terrain = Dantooine clone).
    {"tython_world_spawner", 0, 0, {RECTANGLE, 0, 0}, SPAWNAREA + WORLDSPAWNAREA, {"tython_world"}, 2048},
}
