-- ExtractionMod-SWGEmu: custom_scripts mobile include-shell.
--
-- Core3's bin/scripts/mobile/serverobjects.lua:50 includes this file.
-- Populates with mob templates per Phase 1 deliverables.

-- Deliverable 8 — Encounter mob templates (Coven / Shrine / Bunker).
-- Three boss + three grunt templates spawned by D7 encounter rotation.
includeFile("../custom_scripts/mobile/extraction_mod/encounter_nightsister_elite.lua")
includeFile("../custom_scripts/mobile/extraction_mod/encounter_nightsister_grunt.lua")
includeFile("../custom_scripts/mobile/extraction_mod/encounter_dark_jedi_knight.lua")
includeFile("../custom_scripts/mobile/extraction_mod/encounter_force_crystal_hunter.lua")
includeFile("../custom_scripts/mobile/extraction_mod/encounter_death_watch_commander.lua")
includeFile("../custom_scripts/mobile/extraction_mod/encounter_droid_protector.lua")
includeFile("../custom_scripts/mobile/extraction_mod/xesh.lua")

-- Wild creature spawner for tython (cloned from dantooine_world per D6.5
-- terrain pivot). Without this, tython has zero ambient wildlife / lairs.
-- Added 2026-04-26 after Ryan reported empty-zone playtest.
includeFile("../custom_scripts/mobile/spawn/tython/tython_world.lua")

-- Deliverable 11.5 (D11.5) Rebel Extraction Coordinator NPC at Tython outpost.
includeFile("../custom_scripts/mobile/extraction_mod/extraction_coordinator.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/extraction_coordinator_conv.lua")

-- Deliverable 11.5 — Starter quest narrative onboarding.
-- Three NPC creature templates + three conversation trees + handlers.
-- Conversation files reference ExtractionStarterQuest globals; the screenplay
-- is included via screenplays.lua and loads before mobile templates do anything.
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_smuggler.lua")
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_rebel_officer.lua")
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_hooded_stranger.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/starter_smuggler_conv.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/starter_rebel_officer_conv.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/starter_hooded_stranger_conv.lua")

-- Deliverable 11.6 (D11.6) Imperial starter quest narrative onboarding.
-- Five NPC templates (Recruiter, Major, ISB Attache, Inquisitor, Field Operative)
-- + five conversation trees. Handlers live in screenplays.lua.
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_imperial_recruiter.lua")
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_imperial_major.lua")
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_imperial_isb_attache.lua")
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_imperial_inquisitor.lua")
includeFile("../custom_scripts/mobile/extraction_mod/extraction_starter_imperial_field_operative.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/imperial_recruiter_conv.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/imperial_major_conv.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/imperial_isb_attache_conv.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/imperial_inquisitor_conv.lua")
includeFile("../custom_scripts/mobile/conversations/extraction_mod/imperial_field_operative_conv.lua")
