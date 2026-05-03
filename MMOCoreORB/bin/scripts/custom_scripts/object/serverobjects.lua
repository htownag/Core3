-- ExtractionMod-SWGEmu: custom_scripts object include-shell.
--
-- Core3's bin/scripts/object/serverobjects.lua:89 includes this file.
--
-- Path resolution gotcha: includeFile is resolved relative to the TOPMOST
-- including file's directory (bin/scripts/object/), not this file's. All
-- paths therefore start with "../custom_scripts/object/..." to escape back
-- up and re-enter our subtree.

includeFile("../custom_scripts/object/extraction_mod/tangible/container/extraction_bag.lua")
includeFile("../custom_scripts/object/extraction_mod/tangible/container/extraction_corpse.lua")

-- Deliverable 11.5 — datamap quest item (clone of mission_datadisk).
includeFile("../custom_scripts/object/extraction_mod/tangible/mission/extraction_starter_datamap.lua")

-- Deliverable 11.6 — Imperial sealed datadisk (clone of mission_datadisk).
includeFile("../custom_scripts/object/extraction_mod/tangible/mission/extraction_starter_imperial_datadisk.lua")

