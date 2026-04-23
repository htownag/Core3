-- hello.lua — Deliverable 0 smoke test for the custom_scripts/ hook.
--
-- Purpose: confirm that Core3's upstream-sanctioned mod extension point
-- (bin/scripts/custom_scripts/screenplays/screenplays.lua) actually loads
-- our files and runs their start() entry point at server boot.
--
-- Expected server-console output on startup:
--   HelloExtractionMod:start() fired -- custom_scripts hook works
--
-- If this does NOT appear on startup, research note R.8 is wrong and
-- we need to re-investigate BEFORE Deliverable 1 begins.
--
-- Delete this file + its includeFile line in screenplays.lua once
-- Deliverable 1 is underway.

HelloExtractionMod = ScreenPlay:new {
    numberOfActs = 1,
}

registerScreenPlay("HelloExtractionMod", true)

function HelloExtractionMod:start()
    printf("HelloExtractionMod:start() fired -- custom_scripts hook works\n")
end
