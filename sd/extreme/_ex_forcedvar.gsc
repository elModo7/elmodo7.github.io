
init()
{
	if(!level.ex_forceclientdvars) return;

	level.ex_forceddvars = [];

	// mantle hints
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "cg_drawmantlehint";
	level.ex_forceddvars[index].value = level.ex_mantlehint;

	// crosshairs
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "cg_drawcrosshair";
	level.ex_forceddvars[index].value = level.ex_crosshair;

	// crosshair turret
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "cg_drawturretcrosshair";
	level.ex_forceddvars[index].value = level.ex_crosshair;

	// crosshair names
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "cg_drawcrosshairnames";
	level.ex_forceddvars[index].value = level.ex_crosshairnames;

	// crosshair color change
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "cg_crosshairEnemyColor";
	level.ex_forceddvars[index].value = level.ex_enemycross;

	// stance indicator
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	if(level.ex_hudstance)
	{
		level.ex_forceddvars[index].dvar = "hud_fade_stance";
		level.ex_forceddvars[index].value = 1.7;
	}
	else
	{
		level.ex_forceddvars[index].dvar = "hud_fade_stance";
		level.ex_forceddvars[index].value = .05;
	}

	// ambient light tweak
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "r_lighttweakambient";
	level.ex_forceddvars[index].value = level.ex_brightmodels;

	// LOD scale (forced to 1)
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "r_lodscale";
	level.ex_forceddvars[index].value = 1;

	// sound (forced to 1, sound will not function correctly without it)
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "mss_Q3fs";
	level.ex_forceddvars[index].value = 1;

	// rate setting
	index = level.ex_forceddvars.size;
	level.ex_forceddvars[index] = spawnstruct();
	level.ex_forceddvars[index].dvar = "rate";
	level.ex_forceddvars[index].value = level.ex_forcerate;

	// max packets
	if(level.ex_maxpackets)
	{
		index = level.ex_forceddvars.size;
		level.ex_forceddvars[index] = spawnstruct();
		level.ex_forceddvars[index].dvar = "cl_maxpackets";
		level.ex_forceddvars[index].value = level.ex_maxpackets;
	}

	// max fps
	if(level.ex_maxfps)
	{
		index = level.ex_forceddvars.size;
		level.ex_forceddvars[index] = spawnstruct();
		level.ex_forceddvars[index].dvar = "com_maxfps";
		level.ex_forceddvars[index].value = level.ex_maxfps;
	}

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, 5);
}

onRandom(eventID)
{
	self endon("ex_gameover");

	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if(isPlayer(player) && isAlive(player) && player.sessionstate == "playing")
		{
			if(level.ex_forceclientdvars == 3 && isDefined(player.forceddvars)) continue;

			for(j = 0; j < level.ex_forceddvars.size ; j++)
				player setClientCvar(level.ex_forceddvars[j].dvar, level.ex_forceddvars[j].value);

			if(level.ex_forceclientdvars == 3) player.forceddvars = true;
		}
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
