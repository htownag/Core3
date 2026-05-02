/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

/**
 * \file TythonPool.cpp
 * D9 Tier 1.5 (ExtractionMod-SWGEmu): tython-only resource pool impl.
 * Patch-I/v3 — RandomPool-style rotation (see TythonPool.h header).
 */

#include "TythonPool.h"
#include "server/zone/managers/resource/resourcespawner/ResourceSpawner.h"

const String TythonPool::ZONE_NAME = "tython";

TythonPool::TythonPool(ResourceSpawner* spawner) : ResourcePool(spawner) {
	setLoggingName("TythonPool");
}

TythonPool::~TythonPool() {
	pool.removeAll();
}

void TythonPool::initialize(const String& includes, const String& excludes, int size) {

	ResourcePool::initialize(includes, excludes);

	// Patch-I/v3: allocate `size` empty slots. Each slot holds one rotating
	// ResourceSpawn that gets refilled with a random leaf on shift.
	for (int i = 0; i < size; ++i)
		pool.add(nullptr);
}

void TythonPool::addResource(ManagedReference<ResourceSpawn*> resourceSpawn, const String& poolSlot) {

	// Patch-I/v3: RandomPool-style add — fill first empty slot. Slot
	// identity is not preserved across restart; the first shift will
	// rotate naturally regardless of which slot a re-attached spawn occupies.
	bool hasRoom = false;

	for (int i = 0; i < pool.size(); ++i) {
		ManagedReference<ResourceSpawn*> spawninpool = pool.get(i);
		if (spawninpool == nullptr) {
			pool.setElementAt(i, resourceSpawn);
			hasRoom = true;
			break;
		}
	}

	if (!hasRoom)
		resourceSpawn->setSpawnPool(ResourcePool::NOPOOL, "");
}

bool TythonPool::update() {

	int despawnedCount = 0, spawnedCount = 0;
	StringBuffer buffer;
	buffer << "TythonPool updating: ";

	for (int i = 0; i < pool.size(); ++i) {

		ManagedReference<ResourceSpawn*> resourceSpawn = pool.get(i);

		if (resourceSpawn == nullptr || !resourceSpawn->inShift()) {

			if (resourceSpawn != nullptr) {
				resourceSpawner->despawn(resourceSpawn);
				despawnedCount++;
			}

			// Patch-I/v3: pick a random leaf type from includes; pin to
			// tython via the zonerestriction parameter (Patch-H/v2 honors it
			// for spawn-map zone enforcement + attribute 750/1000 boost).
			String resourceType = includedResources.elementAt(System::random(includedResources.size() - 1)).getKey();
			ManagedReference<ResourceSpawn*> newSpawn = resourceSpawner->createResourceSpawn(resourceType, excludedResources, ZONE_NAME);
			if (newSpawn != nullptr) {
				Locker locker(newSpawn);
				newSpawn->setSpawnPool(ResourcePool::TYTHONPOOL, "");
				spawnedCount++;
				pool.setElementAt(i, newSpawn);
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
	buffer << "****** Tython Pool (" << pool.size() << ") ************" << endl;
	bool healthy = true;

	for (int i = 0; i < pool.size(); ++i) {
		ManagedReference<ResourceSpawn*> spawn = pool.get(i);
		String resourceType = "";

		bool isRightType = false;

		if (spawn != nullptr) {
			resourceType = spawn->getType();
			// In v3, any include-list leaf is acceptable in any slot (no
			// slot-identity check). isType walks the spawn's full class chain.
			for (int j = 0; j < includedResources.size(); ++j) {
				String included = includedResources.elementAt(j).getKey();
				if (spawn->isType(included)) {
					isRightType = true;
					break;
				}
			}
		}

		if (!isRightType) healthy = false;

		if (spawn != nullptr) {
			buffer << "   " << i << ". " << resourceType << " : "
				   << (isRightType ? "Pass" : "Fail") << "  " << spawn->getName()
				   << " Zones: " << String::valueOf(spawn->getSpawnMapSize())
				   << " (" << spawn->getType() << ")" << endl;
			if (spawn->getSpawnMapSize() == 0) healthy = false;
		} else {
			buffer << "   " << i << ". (empty slot)" << endl;
			healthy = false;
		}
	}
	buffer << "***********" << (healthy ? "HEALTHY!" : "ERRORS!") << "*****************" << endl;
	return buffer.toString();
}

void TythonPool::print() {
	info("**** Tython Pool ****", true);

	for (int i = 0; i < pool.size(); ++i) {
		ManagedReference<ResourceSpawn*> spawn = pool.get(i);

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
