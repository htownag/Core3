-- Deliverable 5 — extraction death corpse container template.
--
-- Clones object/tangible/container/general/satchel.iff — same base as the
-- extraction bag. Spawned by Patch-C's dropExtractionBagToCorpse at the
-- death coords when a player dies on tython.
--
-- Clone-target history: first attempt cloned
-- object_tangible_container_corpse_shared_player_corpse (vanilla
-- player-corpse template), but that inherits gameObjectType 1 (GENERIC)
-- which has no C++ factory registered for arbitrary zoneServer->createObject
-- calls. Second attempt cloned the satchel with explicit gameObjectType =
-- 8194 which I wrongly assumed was GOT_MISC_CONTAINER — 8194 is actually
-- CHEMICAL (0x2002). The real CONTAINER value is 0x2005 = 8197
-- (SceneObjectType.h:112). Third attempt: inherit the satchel's
-- gameObjectType directly, no override. Same path as extraction_bag.lua
-- which works. Visual is a satchel on the ground, which makes more UX
-- sense for "dropped loot bag" than a player-body ghost anyway.
--
-- containerComponent = "PlaceableLootContainerComponent": the battle-tested
-- Core3 pattern for world-placed loot crates (placable_loot_crate.lua and
-- variants all use it). Hard-codes MOVEOUT=true for every creature and
-- MOVEIN=false (read-only after spawn), which is exactly the semantics we
-- want for a dropped loot bag. Our initial Patch-C bag->corpse fill uses
-- SceneObject::transferObject directly, which bypasses canAddObject, so
-- the component's MOVEIN=false doesn't block server-side population.
-- Earlier attempts with the default ContainerComponent + setDefaultAllowPermission
-- silently failed on drag-out; this component skips the permission-bit
-- machinery entirely.
--
-- containerVolumeLimit matches the bag (50 slots), so a full bag dumps
-- without truncation.
--
-- Despawn is driven by C++ ExtractionCorpseDespawnTask scheduled at spawn
-- time (15 min), NOT by a template timer.

object_tangible_container_extraction_corpse = object_tangible_container_general_shared_satchel:new {
	containerVolumeLimit = 50,
	containerComponent = "PlaceableLootContainerComponent",
}

ObjectTemplates:addTemplate(
	object_tangible_container_extraction_corpse,
	"object/tangible/container/extraction_corpse.iff"
)
