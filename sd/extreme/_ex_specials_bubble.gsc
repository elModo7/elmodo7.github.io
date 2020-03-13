#include extreme\_ex_specials;

bubblePerkDelayed(delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	types = [];
	if(level.ex_bubble == 1 || level.ex_bubble == 3) types[types.size] = "small";
	if(level.ex_bubble == 2 || level.ex_bubble == 3) types[types.size] = "big";
	self thread bubblePerk(types[randomInt(types.size)], 0);
}

bubblePerk(type, delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if(!isDefined(self.ex_bubble)) self.ex_bubble = false;
	if(self.ex_bubble) return;
	self.ex_bubble = true;

	if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_bubbleunlock", level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_BUBBLE_READY");

	if(type == "small") self hudNotifySpecial("bubble_small");
		else self hudNotifySpecial("bubble_big");

	while(true)
	{
		wait( [[level.ex_fpstime]](.05) );
		if(!self isOnGround()) continue;
		// quick and dirty way to prevent bubble and gunship specialties at the same time
		if(level.ex_gunship_special && isDefined(self.ex_gunship_special) && self.ex_gunship_special) continue;
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

	if(type == "small") self hudNotifySpecialRemove("bubble_small");
		else self hudNotifySpecialRemove("bubble_big");

	self.ex_bubble = false;

	angles = (0, self.angles[1], 0);
	origin = self.origin;

	level thread bubbleCreate(type, self, origin, angles);
	if(type == "small")
	{
		self thread playerStartUsingPerk("bubble_small");
		wait( [[level.ex_fpstime]](level.ex_bubble_timer_small) );
	}
	else
	{
		self thread playerStartUsingPerk("bubble_big");
		wait( [[level.ex_fpstime]](level.ex_bubble_timer_big) );
	}
}

bubbleCreate(type, owner, origin, angles)
{
	index = bubbleAllocate();

	switch(type)
	{
		case "small":
			level.bubbles[index].timer = level.ex_bubble_timer_small * 20;
			level.bubbles[index].bubble = spawn("script_model", origin + (0, 0, 20));
			level.bubbles[index].bubble hide();
			level.bubbles[index].bubble setmodel("xmodel/huaf_bubble_small");
			level.bubbles[index].bubble.angles = angles;
			level.bubbles[index].bubble_trig = spawn("trigger_radius", origin, 0, 34, 34);
			break;
		case "big":
			level.bubbles[index].timer = level.ex_bubble_timer_big * 20;
			level.bubbles[index].bubble = spawn("script_model", origin);
			level.bubbles[index].bubble hide();
			level.bubbles[index].bubble setmodel("xmodel/huaf_bubble_big");
			level.bubbles[index].bubble.angles = angles;
			level.bubbles[index].bubble_trig = spawn("trigger_radius", origin, 0, 88, 88);
			break;
	}

	// set owner after creating entities so proximity code can handle it
	level.bubbles[index].owner = owner;
	level.bubbles[index].ownernum = owner getEntityNumber();
	level.bubbles[index].team = owner.pers["team"];
	level.bubbles[index].type = type;
	level.bubbles[index].bubble playsound("bubble_create");
	level.bubbles[index].bubble show();

	if(type == "small") level thread bubbleSmallThink(index);
		else level thread bubbleBigThink(index);
}

bubbleAllocate()
{
	for(i = 0; i < level.bubbles.size; i++)
	{
		if(level.bubbles[i].inuse == 0)
		{
			level.bubbles[i].inuse = 1;
			return(i);
		}
	}

	level.bubbles[i] = spawnstruct();
	level.bubbles[i].inuse = 1;
	return(i);
}

bubbleRemoveFrom(player)
{
	for(i = 0; i < level.bubbles.size; i++)
		if(level.bubbles[i].inuse && isDefined(level.bubbles[i].owner) && level.bubbles[i].owner == player) thread bubbleFree(i);
}

bubbleFree(index)
{
	if(isDefined(level.bubbles) && isDefined(level.bubbles[index]))
	{
		if(level.bubbles[index].type == "small") thread levelStopUsingPerk(level.bubbles[index].ownernum, "bubble_small");
			else thread levelStopUsingPerk(level.bubbles[index].ownernum, "bubble_big");
		level.bubbles[index].owner = undefined;
		if(isDefined(level.bubbles[index].bubble_trig)) level.bubbles[index].bubble_trig delete();
		if(isDefined(level.bubbles[index].bubble)) level.bubbles[index].bubble delete();
		level.bubbles[index].inuse = 0;
	}
}

bubbleSmallThink(index)
{
	level.bubbles[index].bubble playloopsound("bubble_loop");
	level.bubbles[index].bubble thread bubbleRotate(index, 3);

	for(;;)
	{
		// remove bubble if it reached end of life
		if(level.bubbles[index].timer <= 0) break;

		// remove bubble if owner left
		if(!isPlayer(level.bubbles[index].owner)) break;

		// check owner
		player = level.bubbles[index].owner;
		if(isAlive(player) && player isTouching(level.bubbles[index].bubble_trig))
		{
			player.ex_bubble_protected = index;
			player thread hudNotifyProtected();
		}
		else if(isDefined(player.ex_bubble_protected) && player.ex_bubble_protected == index)
		{
			player.ex_bubble_protected = undefined;
			player thread hudNotifyProtectedRemove();
		}

		level.bubbles[index].timer--;
		wait( [[level.ex_fpstime]](.05) );
	}

	// destroy sequence
	level.bubbles[index].bubble stoploopsound();
	level.bubbles[index].bubble notify("bubble_kill");
	level.bubbles[index].bubble playsound("bubble_destroy");
	level.bubbles[index].bubble rotateyaw(-360, 3, 0, 2);
	wait( [[level.ex_fpstime]](3) );

	player = level.bubbles[index].owner;
	if(isPlayer(player) && isDefined(player.ex_bubble_protected) && player.ex_bubble_protected == index)
	{
		player.ex_bubble_protected = undefined;
		player thread hudNotifyProtectedRemove();
	}

	playfx(level.ex_effect["bubble_burst_small"], level.bubbles[index].bubble.origin);
	bubbleFree(index);
}

bubbleBigThink(index)
{
	level.bubbles[index].bubble playloopsound("bubble_loop");
	level.bubbles[index].bubble thread bubbleRotate(index, 3);

	for(;;)
	{
		// remove bubble if it reached end of life
		if(level.bubbles[index].timer <= 0) break;

		// remove bubble if owner left on DM-style games
		if(!level.ex_teamplay && !isPlayer(level.bubbles[index].owner)) break;

		// check players
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isAlive(player) && player isTouching(level.bubbles[index].bubble_trig) && ((!level.ex_teamplay && player == level.bubbles[index].owner) || (level.ex_teamplay && player.pers["team"] == level.bubbles[index].team)) )
			{
				if(player.health < 100) player.health += 1;
				player.ex_bubble_protected = index;
				player thread hudNotifyProtected();
			}
			else if(isDefined(player.ex_bubble_protected) && player.ex_bubble_protected == index)
			{
				player.ex_bubble_protected = undefined;
				player thread hudNotifyProtectedRemove();
			}
		}

		level.bubbles[index].timer--;
		wait( [[level.ex_fpstime]](.05) );
	}

	// destroy sequence
	level.bubbles[index].bubble stoploopsound();
	level.bubbles[index].bubble notify("bubble_kill");
	level.bubbles[index].bubble playsound("bubble_destroy");
	level.bubbles[index].bubble rotateyaw(-360, 3, 0, 2);
	wait( [[level.ex_fpstime]](3) );

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.ex_bubble_protected) && player.ex_bubble_protected == index)
		{
			player.ex_bubble_protected = undefined;
			player thread hudNotifyProtectedRemove();
		}
	}

	playfx(level.ex_effect["bubble_burst_big"], level.bubbles[index].bubble.origin);
	bubbleFree(index);
}

bubbleRotate(index, time)
{
	self endon("bubble_kill");

	while(1)
	{
		self rotateyaw(-360, time);
		wait( [[level.ex_fpstime]](time) );
	}
}

tooCloseToEntities(report)
{
	spawnpointname = undefined;

	if(level.ex_bubble_dist_spawn)
	{
		switch(level.ex_currentgt)
		{
			case "sd":
			case "esd": return(false);
			case "ctf":
			case "rbctf":
			case "ctfb":
				if(self.pers["team"] == "axis") spawnpointname = "mp_ctf_spawn_allied";
					else if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_axis";
				break;
			case "dm":
			case "hm":
			case "lms":
			case "ihtf": spawnpointname = "mp_dm_spawn"; break;
			case "tdm":
			case "cnq":
			case "rbcnq":
			case "hq":
			case "htf": spawnpointname = "mp_tdm_spawn"; break;
		}

		if(isDefined(spawnpointname))
		{
			spawnpoints = getentarray(spawnpointname, "classname");
			for(i = 0; i < spawnpoints.size; i++)
			{
				spawnpoint = spawnpoints[i];
				if(isDefined(self) && distance(self.origin, spawnpoint.origin) < level.ex_bubble_dist_spawn)
				{
					if(report) self iprintln(&"SPECIALS_TOOCLOSE_SPAWN");
					return(true);
				}
			}
		}
	}

	if(level.ex_bubble_dist_bubble)
	{
		for(i = 0; i < level.bubbles.size; i++)
		{
			if(level.bubbles[i].inuse && distance(level.bubbles[i].bubble.origin, self.origin) < level.ex_bubble_dist_bubble)
			{
				if(report) self iprintln(&"SPECIALS_TOOCLOSE_BUBBLE");
				return(true);
			}
		}
	}

	if(level.ex_bubble_dist_turret)
	{
		turrets = getentarray("misc_turret", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(self) && isDefined(turrets[i]) && distance(turrets[i].origin, self.origin) < level.ex_bubble_dist_turret)
			{
				if(report) self iprintln(&"SPECIALS_TOOCLOSE_TURRET");
				return(true);
			}
		}

		turrets = getentarray("misc_mg42", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(self) && isDefined(turrets[i]) && distance(turrets[i].origin, self.origin) < level.ex_bubble_dist_turret)
			{
				if(report) self iprintln(&"SPECIALS_TOOCLOSE_TURRET");
				return(true);
			}
		}
	}

	if(level.ex_bubble_dist_flag)
	{
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
		{
			if(self.pers["team"] == "axis") flag_name = "axis_flag";
				else if(self.pers["team"] == "allies") flag_name = "allied_flag";
					else return(true);

			flags = getentarray(flag_name, "targetname");
			for(i = 0; i < flags.size; i++)
			{
				flag = flags[i];
				if(isDefined(self) && distance(self.origin, flag.origin) < level.ex_bubble_dist_flag)
				{
					if(report) self iprintln(&"SPECIALS_TOOCLOSE_FLAG");
					return(true);
				}
			}
		}
	}

	return(false);
}
