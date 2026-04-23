-- ExtractionMod-SWGEmu Deliverable 1: full-zone ActiveArea for extraction_outpost.
--
-- Hosts a single ActiveArea centered at the zone origin that later deliverables
-- attach ENTEREDAREA / EXITEDAREA observers to (bag grant on entry, cleanup on
-- exit — Deliverable 4). Observers NOT hooked here; this file only declares
-- the area and records its OID for downstream lookups.
--
-- Radius 6000m is a v0.1 guess covering most of Lok's 8192m-square habitable
-- terrain; tune during Deliverable 4's first playtest.
--
-- File lives at bin/scripts/custom_scripts/screenplays/extraction_mod/
-- extraction_outpost_regions.lua after sync. Loaded via
-- screenplays/screenplays.lua:734 → custom_scripts/screenplays/screenplays.lua.

ExtractionOutpostRegions = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("ExtractionOutpostRegions", true)

function ExtractionOutpostRegions:start()
	if not isZoneEnabled("extraction_outpost") then
		return
	end

	local pZoneArea = spawnActiveArea(
		"extraction_outpost",
		"object/active_area.iff",
		0, 0, 0,
		6000,
		0
	)

	if pZoneArea ~= nil then
		writeData("extractpvp:zone_active_area_oid", SceneObject(pZoneArea):getObjectID())
	end
end
