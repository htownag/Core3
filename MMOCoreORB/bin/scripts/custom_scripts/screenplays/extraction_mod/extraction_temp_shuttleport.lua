-- TEMP: open-world shuttleport for D6 testing.
-- Replaced by the Deliverable 10 base-interior terminal when D10 lands.
-- See workplans/phase-1/deliverable-06-travel-hook.md Session 1 + §Discovery.
--
-- 2026-04-25 v3 (post-test fix): explicit shuttle creature spawn.
--   Diagnostic from server log: ScheduleShuttleTask never fired for tython,
--   confirming the shuttle CREATURE was never inserted into the zone — only
--   the building was. The shuttleport_tatooine.iff template's "shuttle" is
--   visual-only (part of building appearance/cdf); the *interactive* shuttle
--   creature on vanilla planets comes from .ws world-snapshot files. Tython
--   has no .ws file (snapshot/tython.ws not found), so we explicitly spawn
--   the shuttle creature here. ScheduleShuttleTask then auto-binds it to the
--   "Extraction Outpost Base" PTP (within 128m → distance is 0). After bind,
--   PurchaseTicketCommand sees arrivalShuttle=true and lets Coronet→Tython
--   ticket purchases succeed.
--
-- 2026-04-24 v2 (Fix 3 from Zeltros audit):
--   Spawns a shuttleport BUILDING instead of a bare terminal. The vanilla
--   shuttleport_tatooine.iff template visually includes ticket terminal and
--   ticket collector via its CDF/appearance — these we get for free.
--
-- Config fingerprint (template + coords) is stashed in ODB; any change
-- triggers destroy + respawn on next server boot. Ryan doesn't need to
-- manually /object destroy when we iterate.
--
-- Inbound passengers land at (3100, 18, 1600) which is the building origin.
-- The explicit shuttle creature also spawns there — same coords as the PTP.

ExtractionTempShuttleport = ScreenPlay:new {
    numberOfActs = 1,
    -- Shuttleport building template (Tatooine aesthetic — fits Lok desert terrain).
    -- Alternatives: object/building/corellia/shuttleport_corellia.iff (urban),
    -- object/building/naboo/shuttleport_naboo.iff (lush).
    shuttleportTemplate = "object/building/tatooine/shuttleport_tatooine.iff",
    -- Explicit shuttle creature — bound to PTP by ScheduleShuttleTask.
    shuttleTemplate = "object/creature/npc/theme_park/player_shuttle.iff",
    spawnX = 3100,
    spawnZ = 18,
    spawnY = 1600,
    -- Config fingerprint — bump when template or coords change to force respawn.
    -- v3: bumped to force respawn now that we add the shuttle creature.
    configFingerprint = "shuttleport_tatooine+player_shuttle@3100,18,1600",
}
registerScreenPlay("ExtractionTempShuttleport", true)

function ExtractionTempShuttleport:start()
    if not isZoneEnabled("tython") then
        return
    end

    -- Idempotent respawn logic:
    -- If an existing object exists under our OID AND the config fingerprint
    -- matches what we want to spawn, skip. Otherwise destroy + respawn both
    -- the building and (if present) the shuttle creature.
    local existingBuildingOID = readData("extractpvp:temp_shuttleport_oid")
    local existingShuttleOID  = readData("extractpvp:temp_shuttle_oid")
    local storedFingerprint   = readStringData("extractpvp:temp_shuttleport_fingerprint")

    if existingBuildingOID ~= nil and existingBuildingOID ~= 0 then
        local pExisting = getSceneObject(existingBuildingOID)
        if pExisting ~= nil then
            if storedFingerprint == self.configFingerprint then
                -- Config unchanged; existing objects are what we want.
                return
            end
            -- Config drifted — destroy old (whatever it is) and respawn.
            printf("ExtractionTempShuttleport: config drift [%s] -> [%s]; respawning\n",
                   tostring(storedFingerprint), self.configFingerprint)
            SceneObject(pExisting):destroyObjectFromWorld()
            SceneObject(pExisting):destroyObjectFromDatabase()
            writeData("extractpvp:temp_shuttleport_oid", 0)
        end
    end

    -- Also clean up an old shuttle creature if one is recorded.
    if existingShuttleOID ~= nil and existingShuttleOID ~= 0 then
        local pOldShuttle = getSceneObject(existingShuttleOID)
        if pOldShuttle ~= nil then
            SceneObject(pOldShuttle):destroyObjectFromWorld()
            SceneObject(pOldShuttle):destroyObjectFromDatabase()
        end
        writeData("extractpvp:temp_shuttle_oid", 0)
    end

    -- 1. Spawn the building (visual structure + ticket terminal + collector).
    local pBuilding = spawnSceneObject(
        "tython",
        self.shuttleportTemplate,
        self.spawnX, self.spawnZ, self.spawnY,
        0,                          -- parentID 0 = open world
        1, 0, 0, 0                  -- quaternion (identity heading)
    )

    if pBuilding == nil then
        printf("ExtractionTempShuttleport: failed to spawn %s at (%d,%d,%d)\n",
               self.shuttleportTemplate, self.spawnX, self.spawnZ, self.spawnY)
        return
    end

    writeData("extractpvp:temp_shuttleport_oid", SceneObject(pBuilding):getObjectID())
    printf("ExtractionTempShuttleport: %s placed at (%d,%d,%d) OID=%s\n",
           self.shuttleportTemplate,
           self.spawnX, self.spawnZ, self.spawnY,
           tostring(SceneObject(pBuilding):getObjectID()))

    -- 2. Spawn the interactive shuttle CREATURE at the same coords.
    --    ScheduleShuttleTask fires automatically on insertion and binds this
    --    shuttle to the nearest PTP within 128m (== Extraction Outpost Base
    --    at distance 0).
    local pShuttle = spawnSceneObject(
        "tython",
        self.shuttleTemplate,
        self.spawnX, self.spawnZ, self.spawnY,
        0,                          -- parentID 0 = open world
        1, 0, 0, 0                  -- quaternion (identity heading)
    )

    if pShuttle == nil then
        printf("ExtractionTempShuttleport: failed to spawn shuttle creature %s\n",
               self.shuttleTemplate)
    else
        writeData("extractpvp:temp_shuttle_oid", SceneObject(pShuttle):getObjectID())
        printf("ExtractionTempShuttleport: shuttle creature %s placed at (%d,%d,%d) OID=%s — ScheduleShuttleTask will bind to nearest PTP\n",
               self.shuttleTemplate,
               self.spawnX, self.spawnZ, self.spawnY,
               tostring(SceneObject(pShuttle):getObjectID()))
    end

    writeStringData("extractpvp:temp_shuttleport_fingerprint", self.configFingerprint)
end
