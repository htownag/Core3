/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

/**
 * \file TythonPool.h
 * D9 Tier 1.5 (ExtractionMod-SWGEmu): tython-only resource pool.
 *
 * Patch-I/v2 (2026-04-28 r2): spawns vanilla resource type names
 * (iron_plumbum, steel_kiirium, etc. — NO _tython suffix) and pins
 * each spawn to tython by passing "tython" as the zonerestriction
 * parameter to createResourceSpawn. Relies on Patch-H/v2's effective-
 * ZoneRestriction logic to (a) pin the spawn map to tython only, and
 * (b) trigger the 750/1000 attribute boost. No custom IFF rows needed,
 * so the SWG client recognizes these as standard resource types and
 * the schematic UI accepts them for crafting.
 *
 * Architecturally a simplified single-zone twin of NativePool.
 */

#ifndef TYTHONPOOL_H_
#define TYTHONPOOL_H_

#include "ResourcePool.h"

class ResourceSpawner;

class TythonPool : public ResourcePool {
private:

	/// Slot map keyed by <basetype>_tython type name.
	VectorMap<String, ManagedReference<ResourceSpawn*> > spawns;

	/// Single-zone target. All spawns go here.
	static const String ZONE_NAME;

public:

	TythonPool(ResourceSpawner* spawner);
	~TythonPool();

	/**
	 * Initialize pool from includes (comma-delimited base type names) +
	 * excludes. For each basetype, builds a slot keyed by basetype_tython.
	 */
	void initialize(const String& includes, const String& excludes);

	String healthCheck();
	void print();

private:

	/**
	 * Re-attaches a resurrected spawn (loaded from DB) to its slot.
	 */
	void addResource(ManagedReference<ResourceSpawn*> resourceSpawn, const String& poolSlot);

	/**
	 * Despawn expired slots and create replacements via
	 * resourceSpawner->createResourceSpawn(<basetype>_tython, ...).
	 */
	bool update();

	friend class ResourceSpawner;
};

#endif /* TYTHONPOOL_H_ */
