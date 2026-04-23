-- Deliverable 2 — ExtractionBagContainerComponent (Session 2: Patch-E rules).
--
-- Resolved by SceneObjectImplementation::setContainerComponent at
-- src/server/zone/objects/scene/SceneObjectImplementation.cpp:523-540.
-- The wrapper (src/server/zone/objects/scene/components/LuaContainerComponent.cpp)
-- dispatches four hook points to methods on this table:
--
--   canAddObject:             int  — -1 fall-through; 0 SUCCESS; 1-15 TransferErrorCode
--   transferObject:           bool — -1 fall-through; 0 block; non-zero non-(-1) allow
--   removeObject:             bool — -1 fall-through; 0 block; non-zero non-(-1) allow (*)
--   checkContainerPermission: bool — -1 fall-through; 0 deny; non-zero non-(-1) allow
--
-- (*) removeObject's return is IGNORED by ContainerComponent::transferObject at
-- line 244 — the base calls removeObject as a side-effect, not a gate. Rule 2
-- must therefore be enforced via checkContainerPermission(MOVEOUT) which IS
-- honored by TransferItemMiscCommand.h:148 before any transfer is attempted.
-- The checkContainerPermission hook is Patch-E (2026-04-23, see MOD_NOTES) — a
-- ~20 LOC addition to LuaContainerComponent mirroring the existing three
-- forwards. Without Patch-E, Rule 2 cannot be enforced in pure Lua.
--
-- ⚠ Missing/nil returns read as 0 (deny/block). Always return explicitly.
--
-- Rule set (see workplans/phase-1/deliverable-02-bag-container.md §2B):
--
--   Rule 1 (planet_bound routing IN) — D4's responsibility. Inventory-side
--     observer rejects planet_bound items entering main inventory.
--
--   Rule 2 (on-zone outbound lock) — checkContainerPermission denies MOVEOUT
--     while the player root-parent's zone is extraction_outpost.
--
--   Rule 3 (bag-itself smuggle protection) — noTrade=1 on the server template
--     blocks trade/auction/droid. Own-bank deposit gap is closed by D4 (tag
--     detection at the destination inventory layer on extraction).

ExtractionBagContainerComponent = {}

local EXTRACTION_ZONE = "extraction_outpost"

-- Return-value constants.
local FALL_THROUGH = -1
local BLOCK_BOOL = 0

-- ContainerPermissions values, from
-- src/server/zone/objects/scene/variables/ContainerPermissions.h:
local PERM_MOVEIN        = 2   -- 1 << 1
local PERM_MOVEOUT       = 4   -- 1 << 2
local PERM_MOVECONTAINER = 8   -- 1 << 3

-- Walk up the container's parent chain to the root; read its zone name.
-- A bag in player inventory resolves: bag → inventory → player (root).
-- Player's getZoneName() returns the zone the player is currently on.
local function getOwnerZoneName(pContainer)
	if pContainer == nil then return "" end
	local sceno = LuaSceneObject(pContainer)
	if sceno == nil then return "" end
	local pRoot = sceno:getRootParent()
	if pRoot == nil then
		return sceno:getZoneName() or ""
	end
	return LuaSceneObject(pRoot):getZoneName() or ""
end

local function isOnExtractionZone(pContainer)
	return getOwnerZoneName(pContainer) == EXTRACTION_ZONE
end

function ExtractionBagContainerComponent:canAddObject(pSceneObject, pObject, containmentType)
	-- Bag accepts all inbound. Rule 1 (planet_bound reject at main inventory)
	-- is D4's concern, not ours.
	return FALL_THROUGH
end

function ExtractionBagContainerComponent:transferObject(pSceneObject, pObject, containmentType)
	return FALL_THROUGH
end

function ExtractionBagContainerComponent:removeObject(pSceneObject, pObject, pDestination)
	-- Base transferObject ignores this return; pure fall-through. Rule 2 is
	-- enforced upstream via checkContainerPermission before we ever reach here.
	return FALL_THROUGH
end

function ExtractionBagContainerComponent:checkContainerPermission(pSceneObject, pCreature, permission)
	-- Rule 2: while on extraction_outpost, deny MOVEOUT of items from the bag.
	-- TransferItemMiscCommand.h:148 honors this return and aborts the transfer
	-- before any removeObject / canAddObject / transferObject fires.
	if permission == PERM_MOVEOUT and isOnExtractionZone(pSceneObject) then
		return BLOCK_BOOL
	end

	-- All other permission checks: let the base ContainerComponent logic run
	-- (owner-ID / group / inherited-from-parent chain).
	return FALL_THROUGH
end
