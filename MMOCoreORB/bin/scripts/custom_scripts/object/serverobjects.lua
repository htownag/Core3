-- ExtractionMod-SWGEmu: custom_scripts object include-shell.
--
-- Core3's bin/scripts/object/serverobjects.lua:89 includes this file.
--
-- Path resolution gotcha: includeFile is resolved relative to the TOPMOST
-- including file's directory (bin/scripts/object/), not this file's. All
-- paths therefore start with "../custom_scripts/object/..." to escape back
-- up and re-enter our subtree.

includeFile("../custom_scripts/object/extraction_mod/tangible/container/extraction_bag.lua")

-- Future (populates during later Phase 1 deliverables):
-- includeFile("../custom_scripts/object/extraction_mod/tangible/container/extraction_corpse.lua")  -- Deliverable 5
