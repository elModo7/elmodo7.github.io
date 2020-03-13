init()
{
	if(!level.ex_deathicons) return;

	precacheShader("headicon_dead");

	level.deathicons["allies"] = spawnstruct();
	level.deathicons["allies"].array = [];
	level.deathicons["axis"] = spawnstruct();
	level.deathicons["axis"].array = [];
	level.deathicons["spectator"] = spawnstruct();
	level.deathicons["spectator"].array = [];

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);
}

onPlayerSpawned()
{
	removeDeathIcon(self.clientid);
}

onPlayerDisconnected()
{
	removeDeathIcon(self.clientid);
}

addDeathIcon(entity, id, team, timeout)
{
	// if killed on parachute, remove cloned body and do not display death icon
	if(isDefined(self.ex_isparachuting))
	{
		wait( [[level.ex_fpstime]](2) );
		entity delete();
		return;
	}

	// if entities monitor in defcon 2, no dead body fx and no death icons
	if(level.ex_entities_defcon == 2) return;

	if(level.ex_deadbodyfx)	entity extreme\_ex_main::HandleDeadBody(team, self);

	if(!level.ex_deathicons) return;

	assert(team == "allies" || team == "axis");

	newdeathicon = newTeamHudElem(team);
	newdeathicon.id = id;
	newdeathicon.x = entity.origin[0];
	newdeathicon.y = entity.origin[1];
	newdeathicon.z = entity.origin[2] + 54;
	newdeathicon.alpha = .61;
	newdeathicon.archived = true;
	newdeathicon setShader("headicon_dead", 7, 7); // 56.8% of on screen headicons size
	newdeathicon setwaypoint(true);
	level.deathicons[team].array[level.deathicons[team].array.size] = newdeathicon;

	newdeathicon = newTeamHudElem("spectator");
	newdeathicon.id = id;
	newdeathicon.x = entity.origin[0];
	newdeathicon.y = entity.origin[1];
	newdeathicon.z = entity.origin[2] + 54;
	newdeathicon.alpha = .61;
	newdeathicon.archived = true;
	newdeathicon setShader("headicon_dead", 7, 7); // 56.8% of on screen headicons size
	newdeathicon setwaypoint(true);
	level.deathicons["spectator"].array[level.deathicons["spectator"].array.size] = newdeathicon;

	if(isdefined(timeout))
	{
		wait( [[level.ex_fpstime]](timeout) );
		removeDeathIcon(id);
	}
}

removeDeathIcon(id)
{
	for(i = 0; i < 3; i++)
	{
		if(i == 0)
			team = "allies";
		else if(i == 1)
			team = "axis";
		else
			team = "spectator";

		removeElement = undefined;

		for(j = 0; j < level.deathicons[team].array.size; j++)
		{
			if(level.deathicons[team].array[j].id != id) continue;

			removeElement = level.deathicons[team].array[j];
			break;
		}
		
		if(isdefined(removeElement))
		{
			lastElement = level.deathicons[team].array.size - 1;

			for(j = 0; j < level.deathicons[team].array.size; j++)
			{
				if(level.deathicons[team].array[j] != removeElement) continue;

				level.deathicons[team].array[j] = level.deathicons[team].array[lastElement];
				level.deathicons[team].array[lastElement] = undefined;
				break;
			}

			removeElement destroy();
		}
	}
}
