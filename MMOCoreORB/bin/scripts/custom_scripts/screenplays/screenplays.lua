-- ExtractionMod-SWGEmu: custom_scripts screenplays include-shell.
--
-- Core3's bin/scripts/screenplays/screenplays.lua:734 includes this file
-- via `includeFile("../custom_scripts/screenplays/screenplays.lua")`.
--
-- Path resolution gotcha: includeFile is resolved relative to the
-- TOPMOST including file's directory, not this file's directory.
-- The topmost is bin/scripts/screenplays/screenplays.lua, so all
-- paths from here must start with "../custom_scripts/screenplays/..."
-- to escape back up + re-enter our subtree.

includeFile("../custom_scripts/screenplays/extraction_mod/hello.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/tython_zone_area.lua")                -- D10 rename: was tython_regions.lua / TythonRegions; now disambiguated from canonical regions file
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_bag_container.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_region_observer.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/tython_shuttle_creature.lua")        -- D6 successor; building moved to tython.ws (2026-04-26)
includeFile("../custom_scripts/screenplays/extraction_mod/tython_outpost_props.lua")           -- AUTO-GENERATED: server-only outpost decor (installations, vehicles, resource containers) extracted from TJT placement
includeFile("../custom_scripts/screenplays/extraction_mod/tython_imperial_outpost.lua")        -- HAND-AUTHORED: Imperial outpost decoration screenplay (faction turrets, generators, harvester, factory, AT-AT landmark, lamps, decorative droids) — buildings + walls live in tython.ws
includeFile("../custom_scripts/screenplays/extraction_mod/tython_outpost_messages.lua")        -- ENTEREDAREA + EXITEDAREA observers for "You have entered/left the X" outpost messages
-- includeFile("../custom_scripts/screenplays/extraction_mod/tython_outpost_paving.lua")     -- DISABLED 2026-04-28: concrete_slab_tatooine_16x8 template renders as a giant block, not flat paving. Re-enable with different template if revisited.
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_encounter_templates.lua") -- D8 (must load before D7 rotation)
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_encounter_rotation.lua")  -- D7
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_starter_quest.lua")       -- D11.5 main screenplay (must load before its conv handlers)
includeFile("../custom_scripts/screenplays/extraction_mod/starter_smuggler_conv_handler.lua")  -- D11.5 conv handler (screenplay state, sees conv_handler base + ExtractionStarterQuest)
includeFile("../custom_scripts/screenplays/extraction_mod/starter_rebel_officer_conv_handler.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/starter_hooded_stranger_conv_handler.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_coordinator_conv_handler.lua")  -- D11.5 coordinator query handler

-- Deliverable 11.6 (D11.6) Imperial starter quest. Screenplay file loads first
-- so its globals are defined when the 5 conv handlers reference them.
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_starter_imperial_quest.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/imperial_recruiter_conv_handler.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/imperial_major_conv_handler.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/imperial_isb_attache_conv_handler.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/imperial_inquisitor_conv_handler.lua")
includeFile("../custom_scripts/screenplays/extraction_mod/imperial_field_operative_conv_handler.lua")

-- Future (populates during later Phase 1 deliverables):
-- includeFile("../custom_scripts/screenplays/extraction_mod/extraction_rebel_base.lua")          -- D10
