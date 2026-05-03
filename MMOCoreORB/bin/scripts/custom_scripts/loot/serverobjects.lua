-- ExtractionMod-SWGEmu: custom_scripts loot include-shell.
--
-- Core3's bin/scripts/loot/serverobjects.lua:5 includes this file.
-- Populates with loot groups per Phase 1 deliverables.

-- Deliverable 8 — Encounter loot groups (Coven / Shrine / Bunker).
-- Each loot group is referenced by its corresponding boss + grunt mob
-- templates' lootGroups block. All loot rolled here will auto-tag
-- extractpvp:planet_bound = "1" via D3/Patch-B (LootManagerImplementation
-- fires for any loot in the tython zone).
includeFile("../custom_scripts/loot/extraction_mod/groups/encounter_coven_loot.lua")
includeFile("../custom_scripts/loot/extraction_mod/groups/encounter_shrine_loot.lua")
includeFile("../custom_scripts/loot/extraction_mod/groups/encounter_bunker_loot.lua")
includeFile("../custom_scripts/loot/extraction_mod/groups/xesh_loot.lua")
