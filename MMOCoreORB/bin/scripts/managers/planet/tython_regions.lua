-- ExtractionMod-SWGEmu: vanilla-style regions file for tython.
--
-- PlanetManagerImplementation::loadRegions runs
-- scripts/managers/planet/<zoneName>_regions.lua for every zone on boot.
-- Missing file spams error logs; this empty table satisfies the loader.
--
-- Real ActiveArea declarations for the mod live in
-- bin/scripts/custom_scripts/screenplays/extraction_mod/tython_regions.lua
-- (a ScreenPlay, loaded via the custom_scripts hook, not this loader).
--
-- Rebase-conflict point #2 (see MOD_NOTES.md) — this file does not exist in
-- upstream Core3 and does not touch any vanilla file.

tython_regions = {}
