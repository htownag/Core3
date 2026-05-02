/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

/**
 * \file TythonPool.h
 * D9 Tier 1.5 (ExtractionMod-SWGEmu): tython-only resource pool.
 *
 * Patch-I/v3 (2026-04-29 r3): RandomPool-style rotation. Fixed-size pool
 * of N slots; on shift, each empty/expired slot picks a random leaf type
 * from includedResources and creates a fresh spawn pinned to tython. Pool
 * size is configured via tythonpoolsize in resource_manager.lua. Different
 * spawns despawn at staggered times → gradual rotation experience for
 * players ("check tython this week, different resources next week").
 *
 * Spawns are pinned to tython by passing "tython" as the zonerestriction
 * parameter to createResourceSpawn — Patch-H/v2's effectiveZoneRestriction
 * logic (a) restricts the spawn map to tython only, and (b) applies the
 * 750/1000 attribute boost. Includes are vanilla resource type names so
 * the SWG client recognizes them in the schematic UI.
 *
 * Architecturally a single-zone twin of RandomPool, with leaf-name picks
 * (RandomPool uses class names → random subtype; TythonPool uses leaf
 * names directly because zonerestriction gates planet-variant lookup).
 */

#ifndef TYTHONPOOL_H_
#define TYTHONPOOL_H_

#include "ResourcePool.h"

class ResourceSpawner;

class TythonPool : public ResourcePool {
private:

	/// Patch-I/v3: RandomPool-style fixed-size pool. Each slot holds one
	/// rotating ResourceSpawn or nullptr (waiting for next-shift fill).
	Vector<ManagedReference<ResourceSpawn*> > pool;

	/// Single-zone target. All spawns go here.
	static const String ZONE_NAME;

public:

	TythonPool(ResourceSpawner* spawner);
	~TythonPool();

	/**
	 * Initialize pool from includes (comma-delimited base type names) +
	 * excludes + size. Allocates `size` empty slots; update() will fill
	 * them with random picks per shift.
	 */
	void initialize(const String& includes, const String& excludes, int size);

	String healthCheck();
	void print();

private:

	/**
	 * Re-attaches a resurrected spawn (loaded from DB) to the first empty
	 * slot. No slot identity is preserved across restart — a fresh shift
	 * will rotate normally regardless of which slot the spawn lands in.
	 */
	void addResource(ManagedReference<ResourceSpawn*> resourceSpawn, const String& poolSlot);

	/**
	 * For each empty or expired slot, pick a random leaf type from
	 * includedResources and call createResourceSpawn with zonerestriction
	 * = ZONE_NAME ("tython"). Patch-H/v2 applies the stat boost downstream.
	 */
	bool update();

	friend class ResourceSpawner;
};

#endif /* TYTHONPOOL_H_ */
