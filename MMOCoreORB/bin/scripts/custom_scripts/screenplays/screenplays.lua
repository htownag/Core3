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
includeFile("../custom_scripts/screenplays/extraction_mod/extraction_outpost_regions.lua")

-- Future (populates during Phase 1 deliverables):
-- includeFile("../custom_scripts/screenplays/extraction_mod/extraction_bag_container.lua")     -- Deliverable 2
-- includeFile("../custom_scripts/screenplays/extraction_mod/extraction_region_observer.lua")   -- Deliverable 4
-- includeFile("../custom_scripts/screenplays/extraction_mod/extraction_tower_rotation.lua")    -- Deliverable 7
-- includeFile("../custom_scripts/screenplays/extraction_mod/extraction_rebel_base.lua")        -- Deliverable 10
