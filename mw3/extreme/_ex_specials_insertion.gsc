#include extreme\_ex_specials;

insertionPerk(delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if(!isDefined(self.ex_missile)) self.ex_insertion = false;
	if(self.ex_insertion) return;
	self.ex_insertion = true;

	if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_insertionunlock", level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_INSERTION_READY");

	self playlocalsound("taktical_ready");

	self hudNotifySpecial("insertion");

	while(true)
	{
		wait( [[level.ex_fpstime]](.05) );
		if(!self isOnGround()) continue;
		if(self meleebuttonpressed())
		{
			count = 0;
			if(!self tooCloseToEntities(true))
			{
				while(self meleeButtonPressed() && count < 10)
				{
					wait( [[level.ex_fpstime]](.05) );
					count++;
				}

				if(count >= 10) break;
			}
			while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}
	}

	self hudNotifySpecialRemove("insertion");
	self thread playerStartUsingPerk("insertion");

	angles = (0, self.angles[1], 0);
	origin = self.origin;

	level thread insertionCreate(self, origin, angles);
}

insertionCreate(owner, origin, angles)
{
	index = insertionAllocate();

	level.insertions[index].owner = owner;
	level.insertions[index].ownernum = owner getEntityNumber();
	level.insertions[index].team = owner.pers["team"];
	level.insertions[index].origin = origin;
	level.insertions[index].angles = angles;
	level.insertions[index].timer = level.ex_insertion_timer * 20;

	level thread insertionThink(index);
}

insertionAllocate()
{
	for(i = 0; i < level.insertions.size; i++)
	{
		if(level.insertions[i].inuse == 0)
		{
			level.insertions[i].inuse = 1;
			return(i);
		}
	}

	level.insertions[i] = spawnstruct();
	level.insertions[i].inuse = 1;
	return(i);
}

insertionGetFrom(player)
{
	insertion_info["exists"] = false;

	for(i = 0; i < level.insertions.size; i++)
	{
		if(level.insertions[i].inuse && isDefined(level.insertions[i].owner) && level.insertions[i].owner == player)
		{
			insertion_info["exists"] = true;
			insertion_info["origin"] = level.insertions[i].origin;
			insertion_info["angles"] = level.insertions[i].angles;
		}
	}

	return(insertion_info);
}

insertionRemoveFrom(player)
{
	for(i = 0; i < level.insertions.size; i++)
		if(level.insertions[i].inuse && isDefined(level.insertions[i].owner) && level.insertions[i].owner == player) thread insertionFree(i);
}

insertionFree(index)
{
	if(isDefined(level.insertions) && isDefined(level.insertions[index]))
	{
		thread levelStopUsingPerk(level.insertions[index].ownernum, "insertion");
		if(isPlayer(level.insertions[index].owner)) level.insertions[index].owner.ex_insertion = false;
		level.insertions[index].inuse = 0;
	}
}

insertionThink(index)
{
	for(;;)
	{
		// remove insertion if it reached end of life
		if(level.insertions[index].timer <= 0) break;

		// remove insertion if owner left
		if(!isPlayer(level.insertions[index].owner)) break;

		// remove insertion if owner changed team
		if(level.ex_teamplay && level.insertions[index].owner.pers["team"] != level.insertions[index].team) break;

		if(level.ex_insertion_fx && level.insertions[index].timer % 20 == 0) playfx(level.ex_effect["insertion_marker"], level.insertions[index].origin);

		level.insertions[index].timer--;
		wait( [[level.ex_fpstime]](.05) );
	}

	insertionFree(index);
}

tooCloseToEntities(report)
{
	spawnpointname = undefined;

	if(level.ex_insertion_dist_flag)
	{
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
		{
			if(self.pers["team"] == "axis") flag_name = "allied_flag";
				else if(self.pers["team"] == "allies") flag_name = "axis_flag";
					else return(true);

			flags = getentarray(flag_name, "targetname");
			for(i = 0; i < flags.size; i++)
			{
				flag = flags[i];
				if(isDefined(self) && distance(self.origin, flag.origin) < level.ex_insertion_dist_flag)
				{
					if(report) self iprintln(&"SPECIALS_TOOCLOSE_FLAG");
					return(true);
				}
			}
		}
	}

	return(false);
}
