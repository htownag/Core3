/*
 * ExtractionCorpseDespawnTask.h
 *
 * Patch-C: one-shot despawn timer for extraction-mod death corpse containers.
 * Scheduled by PlayerManagerImplementation::dropExtractionBagToCorpse when a
 * player dies on tython; fires 15 minutes later and destroys the
 * corpse container from world + database.
 *
 * Pattern cloned from DespawnCreatureTask / CampDespawnTask under
 * objects/creature/events/ and objects/area/events/ respectively. Plain Task
 * subclass with a single ManagedReference to the target.
 *
 * See workplans/phase-1/deliverable-05-death-drop.md.
 */

#ifndef EXTRACTIONCORPSEDESPAWNTASK_H_
#define EXTRACTIONCORPSEDESPAWNTASK_H_

#include "engine/core/Task.h"
#include "server/zone/objects/tangible/TangibleObject.h"

class ExtractionCorpseDespawnTask : public Task {
	ManagedReference<TangibleObject*> corpse;

public:
	ExtractionCorpseDespawnTask(TangibleObject* target) : corpse(target) {}

	void run() override {
		if (corpse == nullptr)
			return;

		Locker locker(corpse);

		if (!corpse->isInQuadTree())
			return;

		corpse->destroyObjectFromWorld(true);
		corpse->destroyObjectFromDatabase(true);
	}
};

#endif /* EXTRACTIONCORPSEDESPAWNTASK_H_ */
