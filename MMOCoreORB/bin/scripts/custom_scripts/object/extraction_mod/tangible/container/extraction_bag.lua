-- Deliverable 2 — extraction bag server template (Session 2: rules wired).
--
-- Clones object/tangible/container/general/satchel.iff — a vanilla inventory
-- container with no quest/faction baggage. The containerComponent override
-- wires the bag's transfer hooks through the Lua class defined in
-- screenplays/extraction_mod/extraction_bag_container.lua.
--
-- noTrade: blocks trade-window (PlayerManagerImplementation.cpp:2753),
-- auction/bazaar (AuctionManagerImplementation.cpp:448), and droid-transfer
-- (DroidContainerComponent.cpp:49) of the bag itself. Does NOT block own-
-- player-bank deposit (ContainerComponent.cpp:21-60 exempts same-player-
-- parent scenarios) — that smuggle path is closed by D4's planet_bound
-- inventory-side observer instead. See deliverable-02 Session 2 retrospective.
--
-- containerVolumeLimit: 50-slot cap. Tuneable in playtest (D12).

object_tangible_container_extraction_bag = object_tangible_container_general_shared_satchel:new {
	containerComponent = "ExtractionBagContainerComponent",
	containerVolumeLimit = 50,
	noTrade = 1,
}

ObjectTemplates:addTemplate(
	object_tangible_container_extraction_bag,
	"object/tangible/container/extraction_bag.iff"
)
