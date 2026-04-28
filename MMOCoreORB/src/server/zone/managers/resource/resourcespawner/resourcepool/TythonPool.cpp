/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

/**
 * \file TythonPool.cpp
 * D9 Tier 1.5 (ExtractionMod-SWGEmu): tython-only resource pool impl.
 */

#include "TythonPool.h"
#include "server/zone/managers/resource/resourcespawner/ResourceSpawner.h"

const String TythonPool::ZONE_NAME = "tython";

TythonPool::TythonPool(ResourceSpawner* spawner) : ResourcePool(spawner) {
	setLoggingName("TythonPool");
}

TythonPool::~TythonPool() {
	spawns.removeAll();
}

void TythonPool::initialize(const String& includes, const String& excludes) {

	ResourcePool::initialize(includes, excludes);

	// Patch-I/v2: slot map keyed by VANILLA type name (no _tython suffix).
	// The spawn is pinned to tython via the zonerestriction parameter in
	// update(), not via a custom type-name suffix. This keeps the type name
	// recognizable by the SWG client's pre-baked resource registry.
	for (int j = 0; j < includedResources.size(); ++j) {
		String resource = includedResources.elementAt(j).getKey();
		spawns.put(resource, nullptr);
	}
}

void TythonPool::addResource(ManagedReference<ResourceSpawn*> resourceSpawn, const String& poolSlot) {

	if (poolSlot.isEmpty()) {
		resourceSpawn->setSpawnPool(ResourcePool::NOPOOL, "");
		return;
	}

	int index = spawns.find(poolSlot);
	if (index >= 0) {
		VectorMapEntry<String, ManagedReference<ResourceSpawn*> > newEntry(poolSlot, resourceSpawn);
		spawns.setElementAt(index, newEntry);
	} else {
		resourceSpawn->setSpawnPool(ResourcePool::NOPOOL, "");
	}
}

bool TythonPool::update() {

	int despawnedCount = 0, spawnedCount = 0;
	StringBuffer buffer;
	buffer << "TythonPool updating: ";

	for (int j = 0; j < spawns.size(); ++j) {

		String resourceType = spawns.elementAt(j).getKey();
		ManagedReference<ResourceSpawn*> spawn = spawns.elementAt(j).getValue();

		if (spawn == nullptr || !spawn->inShift()) {

			if (spawn != nullptr) {
				resourceSpawner->despawn(spawn);
				despawnedCount++;
			}

			// Patch-I/v2: pass ZONE_NAME ("tython") as zonerestriction so
			// Patch-H/v2 pins the spawn to tython and applies the stat boost.
			ManagedReference<ResourceSpawn*> newSpawn = resourceSpawner->createResourceSpawn(resourceType, excludedResources, ZONE_NAME);
			if (newSpawn != nullptr) {
				Locker locker(newSpawn);
				newSpawn->setSpawnPool(ResourcePool::TYTHONPOOL, resourceType);
				spawnedCount++;

				VectorMapEntry<String, ManagedReference<ResourceSpawn*> > newEntry(resourceType, newSpawn);
				spawns.setElementAt(j, newEntry);
			} else {
				warning("Couldn't spawn resource type in TythonPool: " + resourceType);
			}
		}
	}

	buffer << "Spawned " << spawnedCount << " Despawned " << despawnedCount;
	resourceSpawner->info(buffer.toString(), true);
	return true;
}

String TythonPool::healthCheck() {

	StringBuffer buffer;
	buffer << "****** Tython Pool (" << spawns.size() << ") ************" << endl;
	bool healthy = true;

	for (int i = 0; i < spawns.size(); ++i) {
		String resourceType = spawns.elementAt(i).getKey();
		ManagedReference<ResourceSpawn*> spawn = spawns.elementAt(i).getValue();

		if (spawn != nullptr) {
			bool pass = spawn->isType(resourceType);
			if (!pass) healthy = false;
			buffer << "   " << i << ". " << resourceType << " : "
				   << (pass ? "Pass" : "Fail") << "  " << spawn->getName()
				   << " Zones: " << String::valueOf(spawn->getSpawnMapSize())
				   << " (" << spawn->getType() << ")" << endl;
			if (spawn->getSpawnMapSize() == 0) healthy = false;
		} else {
			buffer << "   " << i << ". " << resourceType << " : Fail (null)" << endl;
			healthy = false;
		}
	}
	buffer << "***********" << (healthy ? "HEALTHY!" : "ERRORS!") << "*****************" << endl;
	return buffer.toString();
}

void TythonPool::print() {
	info("**** Tython Pool ****", true);

	for (int j = 0; j < spawns.size(); ++j) {
		ManagedReference<ResourceSpawn*> spawn = spawns.get(j);

		StringBuffer msg;
		if (spawn != nullptr) {
			msg << spawn->getName() << " : " << spawn->getType();
		} else {
			msg << "EMPTY";
		}
		info(msg.toString(), true);
	}

	info("**********************", true);
}
