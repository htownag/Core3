-- ExtractionMod-SWGEmu Deliverable 4: auto-grant extraction bag on zone entry.
--
-- Attaches ENTEREDAREA / EXITEDAREA observers to the zone ActiveArea spawned by
-- Deliverable 1 (TythonRegions). On first entry, grants an extraction
-- bag to the player's inventory, renames it "Extraction Pack", sets the hasBag
-- screenplay state (informational only), and sends a system message. On exit,
-- no-op: the bag persists in inventory off-zone and D2 S2's Rule 2
-- (checkContainerPermission zone-guard) makes it inert off-zone anyway,
-- avoiding grant/revoke churn on shuttle cycles.
--
-- Double-grant guard: the player's inventory itself is the source of truth —
-- findExtractionBag uses getContainerObjectByTemplate, returning a match on
-- any instance of the bag template. The hasBag screenplay state is still set
-- at grant-time (spec acceptance criterion + future-proofing for analytics),
-- but the decision gate does NOT consult it. Relying on the state bit was
-- empirically flaky on first-test 2026-04-23 — players re-entering the zone
-- were double-granted despite the state being set on first grant. Inventory
-- check sidesteps the state-persistence question entirely.
--
-- Deferred to later deliverables:
--   - Auto-route of planet_bound items into the bag — planned as D4 Session 2
--     (OBJECTINSERTED observer on inventory). NPC-loot auto-route needs this
--     because D5 only covers player-death drops, not NPC loot corpses.
--   - Row 17 closure (planet_bound items entering main inventory off-zone) —
--     architecturally coupled to auto-route; defer to post-v0.1.
--
-- Canonical wrapper convention (verified against Core3 HEAD warren.lua + village
-- scripts 2026-04-23): use SceneObject() for type checks (isPlayerCreature is
-- on SceneObject, works for any pointer), CreatureObject() for creature methods
-- (setScreenPlayState, sendSystemMessage, getSlottedObject), TangibleObject()
-- for tangible accessors. Do NOT use LuaCreatureObject() as a type check —
-- casting a non-creature pointer yields a proxy whose method lookups return
-- nil, producing "attempt to call a nil value" errors.
--
-- Item-into-inventory convention: use giveItem(pContainer, template, slot,
-- overload), the Lua-exposed DirectorManager::giveItem helper. It wraps
-- zoneServer->createObject (limbo creation, no world placement), then
-- transferObject + sendTo for client refresh. Using spawnSceneObject +
-- transferObject instead leaves the object in the zone's QuadTree at the
-- spawn coords (the satchel-on-the-ground bug we hit empirically 2026-04-23).
--
-- File lives at bin/scripts/custom_scripts/screenplays/extraction_mod/
-- extraction_region_observer.lua after sync. Loaded via
-- screenplays/screenplays.lua -> custom_scripts/screenplays/screenplays.lua.

ExtractionRegionObserver = ScreenPlay:new {
	numberOfActs = 1,
	questString  = "extractpvp_session",
	states = {
		hasBag = 1,
	},
	bagTemplate = "object/tangible/container/extraction_bag.iff",
	bagDisplayName = "Extraction Pack",
}

registerScreenPlay("ExtractionRegionObserver", true)

function ExtractionRegionObserver:start()
	if not isZoneEnabled("tython") then
		return
	end

	local areaOID = readData("extractpvp:zone_active_area_oid")
	if areaOID == nil or areaOID == 0 then
		printf("ExtractionRegionObserver: zone ActiveArea OID not found at key 'extractpvp:zone_active_area_oid'. TythonRegions (D1) must run first; on a fresh DB, a second server restart usually fixes screenplay start() ordering.\n")
		return
	end

	local pArea = getSceneObject(areaOID)
	if pArea == nil then
		printf("ExtractionRegionObserver: could not resolve ActiveArea from OID " .. tostring(areaOID) .. "\n")
		return
	end

	createObserver(ENTEREDAREA, "ExtractionRegionObserver", "onEnter", pArea)
	createObserver(EXITEDAREA,  "ExtractionRegionObserver", "onExit",  pArea)
end

function ExtractionRegionObserver:onEnter(pArea, pEntering)
	if pEntering == nil then return 0 end
	if not SceneObject(pEntering):isPlayerCreature() then return 0 end

	-- Inventory is source of truth. Template-match skips re-grant for any
	-- existing bag regardless of screenplay state.
	if self:findExtractionBag(pEntering) ~= nil then
		return 0
	end

	self:grantBag(pEntering)
	return 0
end

function ExtractionRegionObserver:onExit(pArea, pLeaving)
	-- Intentional no-op. See header comment.
	return 0
end

function ExtractionRegionObserver:grantBag(pPlayer)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if pInventory == nil then
		printf("ExtractionRegionObserver:grantBag -- player has no inventory slotted object\n")
		return
	end

	local pBag = giveItem(pInventory, self.bagTemplate, -1, true)
	if pBag == nil then
		printf("ExtractionRegionObserver:grantBag -- giveItem returned nil for template " .. self.bagTemplate .. "\n")
		return
	end

	SceneObject(pBag):setCustomObjectName(self.bagDisplayName)

	CreatureObject(pPlayer):setScreenPlayState(self.states.hasBag, self.questString)
	CreatureObject(pPlayer):sendSystemMessage("You have been issued an extraction bag. Use it to carry loot off-planet.")
end

function ExtractionRegionObserver:findExtractionBag(pPlayer)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if pInventory == nil then return nil end

	-- Core3 helper: walks the container for a template-path match. Third arg
	-- is recursive (searches sub-containers); true matches the warren / village
	-- convention.
	return getContainerObjectByTemplate(pInventory, self.bagTemplate, true)
end
