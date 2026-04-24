-- TEMP: open-world travel terminal for D6 testing.
-- Replaced by the Deliverable 10 base-interior terminal when D10 lands.
-- See workplans/phase-1/deliverable-06-travel-hook.md Session 1.
--
-- Coord decision 2026-04-24 (Ryan): (3100, 22, 1600) on extraction_outpost.
-- The planetTravelPoints arrival coord in vanilla planet_manager.lua
-- extraction_outpost block MUST match — inbound passengers land there.

ExtractionTempShuttleport = ScreenPlay:new {
    numberOfActs = 1,
    terminalTemplate = "object/tangible/terminal/terminal_travel.iff",
    spawnX = 3100,
    spawnZ = 18,
    spawnY = 1600,
}
registerScreenPlay("ExtractionTempShuttleport", true)

function ExtractionTempShuttleport:start()
    if not isZoneEnabled("extraction_outpost") then
        return
    end

    -- Idempotent + coord-drift aware: if an existing terminal sits at the
    -- current target coord, skip. If coord drifted (we changed spawnX/Y/Z),
    -- destroy the old terminal and spawn fresh.
    local existingOID = readData("extractpvp:temp_shuttleport_oid")
    if existingOID ~= nil and existingOID ~= 0 then
        local pExisting = getSceneObject(existingOID)
        if pExisting ~= nil then
            local curX = SceneObject(pExisting):getPositionX()
            local curZ = SceneObject(pExisting):getPositionZ()
            local curY = SceneObject(pExisting):getPositionY()
            if math.abs(curX - self.spawnX) < 0.5
                and math.abs(curZ - self.spawnZ) < 0.5
                and math.abs(curY - self.spawnY) < 0.5 then
                return  -- coords match, nothing to do
            end
            -- Coord drifted — wipe the old terminal from world + ODB
            printf("ExtractionTempShuttleport: coord drift (%d,%d,%d) -> (%d,%d,%d); respawning\n",
                   curX, curZ, curY, self.spawnX, self.spawnZ, self.spawnY)
            SceneObject(pExisting):destroyObjectFromWorld()
            SceneObject(pExisting):destroyObjectFromDatabase()
            writeData("extractpvp:temp_shuttleport_oid", 0)
        end
    end

    local pTerminal = spawnSceneObject(
        "extraction_outpost",
        self.terminalTemplate,
        self.spawnX, self.spawnZ, self.spawnY,
        0,                          -- parentID 0 = open world
        1, 0, 0, 0                  -- quaternion (identity heading)
    )

    if pTerminal == nil then
        printf("ExtractionTempShuttleport: failed to spawn terminal at (%d,%d,%d)\n",
               self.spawnX, self.spawnZ, self.spawnY)
        return
    end

    writeData("extractpvp:temp_shuttleport_oid", SceneObject(pTerminal):getObjectID())
    printf("ExtractionTempShuttleport: terminal placed at (%d,%d,%d) OID=%s\n",
           self.spawnX, self.spawnZ, self.spawnY,
           tostring(SceneObject(pTerminal):getObjectID()))
end
