
init()
{
	if(level.ex_specials)
	{
		// [1] Max Health
		if(level.ex_specials_maxhealth) registerPerk("maxhealth", game["spc_health_hudicon"]);

		// [2] Max Ammo
		if(level.ex_specials_maxammo) registerPerk("maxammo", game["spc_ammo_hudicon"]);

		// [3] Bullet Proof Vest
		if(level.ex_vest) registerPerk("vest", game["spc_vest_hudicon"]);

		// [4] [5] Defense Bubbles
		if(level.ex_bubble)
		{
			level.bubbles = [];
			if(level.ex_bubble == 1 || level.ex_bubble == 3) registerPerk("bubble_small", game["spc_bubble_hudicon"]);
			if(level.ex_bubble == 2 || level.ex_bubble == 3) registerPerk("bubble_big", game["spc_bubble_hudicon"]);

		}

		// [6] Tactical Insertion
		if(level.ex_insertion)
		{
			level.insertions = [];
			registerPerk("insertion", game["spc_insertion_hudicon"]);
		}

		// [7] Sentry Gun
		if(level.ex_sentrygun)
		{
			level.sentryguns = [];
			registerPerk("sentrygun", game["spc_sentry_hudicon"]);
		}

		// [8] Gunship
		if(level.ex_gunship_special) registerPerk("gunship", game["spc_gunship_hudicon"]);

		// [9] Helicopter
		if(level.ex_heli) registerPerk("heli", game["spc_heli_hudicon"]);
	}

	if(level.ex_gunship || level.ex_gunship_special || (level.ex_heli && level.ex_heli_damagehud)) level thread monitorProjectiles();

	if(level.ex_specials) [[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	if(level.ex_gunship || level.ex_specials) [[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	if(level.ex_gunship || level.ex_specials) [[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	if(level.ex_gunship || level.ex_specials) [[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	if(level.ex_gunship || level.ex_specials) [[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);

	// check if it makes sense to start monitor for delays
	if(!level.ex_specials || !isDefined(level.ex_perkcatalog) || !isDefined(level.ex_perks)) return;

	team_delay = 0;
	for(i = 1; i <= 9; i++) team_delay += game["specials_team_delay" + i];

	player_delay = 0;
	for(i = 1; i <= 9; i++) team_delay += game["specials_player_delay" + i];

	if(team_delay || player_delay) [[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	for(i = 0; i < level.ex_perkcatalog.size; i++)
	{
		if(level.ex_perkcatalog[i].axis_delay > 0) level.ex_perkcatalog[i].axis_delay--;
		if(level.ex_perkcatalog[i].allies_delay > 0) level.ex_perkcatalog[i].allies_delay--;
	}

	for(i = 0; i < level.ex_maxclients; i++)
		for(j = 0; j < level.ex_perkcatalog.size; j++)
			if(level.ex_perks[i][level.ex_perkcatalog[j].name].player_delay > 0) level.ex_perks[i][level.ex_perkcatalog[j].name].player_delay--;
}

monitorProjectiles()
{
	for(;;)
	{
		rockets = getentarray("rocket", "classname");
		for(i = 0; i < rockets.size; i ++)
		{
			rocket = rockets[i];
			if(!isDefined(rocket.monitored)) rocket thread tagProjectile();
		}

		wait( [[level.ex_fpstime]](0.05) );
	}
}

tagProjectile()
{
	self.monitored = true;

	closest_player = undefined;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionstate == "playing")
		{
			if(!isPlayer(closest_player)) closest_player = player;
			if(closer(self.origin, player.origin, closest_player.origin)) closest_player = player;
		}
	}

	if(isPlayer(closest_player))
	{
		if(isDefined(level.ex_gunship_player) && closest_player == level.ex_gunship_player)
		{
			level thread extreme\_ex_gunship::gunshipMonitorProjectile(self, 1);
			//logprint("DEBUG: projectile was fired from normal gunship by " + closest_player.name + "\n");
		}
		else if(isDefined(level.ex_gunship_splayer) && closest_player == level.ex_gunship_splayer)
		{
			level thread extreme\_ex_gunship::gunshipMonitorProjectile(self, 2);
			//logprint("DEBUG: projectile was fired from specialty gunship by " + closest_player.name + "\n");
		}
		else
		{
			weapon = closest_player getcurrentweapon();
			if(extreme\_ex_weapons::isWeaponType(weapon, "rl"))
			{
				if(isDefined(level.helicopter) && closest_player usebuttonpressed() && closest_player.pers["team"] != level.helicopter.team)
				{
					level thread extreme\_ex_specials_helicopter::heliMonitorProjectile(self, closest_player);
					//logprint("DEBUG: projectile was fired from rocket launcher by " + closest_player.name + " (heat seaker)\n");
				}
				else if(level.ex_gunship || level.ex_specials || level.ex_longrange)
				{
					level thread zookMonitorProjectile(self);
					//logprint("DEBUG: projectile was fired from rocket launcher by " + closest_player.name + " (assisted)\n");
				}
				//else logprint("DEBUG: projectile was fired from rocket launcher by " + closest_player.name + " (normal)\n");
			}
			//else logprint("DEBUG: projectile was fired from LR rifle by " + closest_player.name + "\n");
		}
	}
}

zookMonitorProjectile(entity)
{
	lastorigin = entity.origin;
	while(isDefined(entity))
	{
		lastorigin = entity.origin;
		wait( [[level.ex_fpstime]](0.05) );
	}

	playfx(level.ex_effect["artillery"], lastorigin);
	level thread extreme\_ex_utils::playSoundLoc("grenade_explode_default", lastorigin);
}

registerPerk(perk, shader)
{
	if(!isDefined(level.ex_perkcatalog)) level.ex_perkcatalog = [];
	index = level.ex_perkcatalog.size;
	level.ex_perkcatalog[index] = spawnstruct();
	level.ex_perkcatalog[index].name = perk;
	level.ex_perkcatalog[index].shader = shader;
	level.ex_perkcatalog[index].axis_delay = 0;
	level.ex_perkcatalog[index].allies_delay = 0;

	if(!isDefined(level.ex_perks))
	{
		level.ex_perks = [];
		for(i = 0; i < level.ex_maxclients; i++) level.ex_perks[i] = [];
	}

	for(i = 0; i < level.ex_maxclients; i++)
	{
		level.ex_perks[i][perk] = spawnstruct();
		level.ex_perks[i][perk].bought = 0;
		level.ex_perks[i][perk].used = 0;
		level.ex_perks[i][perk].active = 0;
		level.ex_perks[i][perk].player_delay = 0;
	}
}

playerResetPerk(entity)
{
	entity = self getEntityNumber();
	for(i = 0; i < level.ex_perkcatalog.size; i++)
	{
		level.ex_perks[entity][level.ex_perkcatalog[i].name].bought = 0;
		level.ex_perks[entity][level.ex_perkcatalog[i].name].used = 0;
		level.ex_perks[entity][level.ex_perkcatalog[i].name].active = 0;
		level.ex_perks[entity][level.ex_perkcatalog[i].name].player_delay = 0;
	}
}

playerBoughtPerk(perk)
{
	entity = self getEntityNumber();
	level.ex_perks[entity][perk].bought++;
	//logprint("DEBUG: player " + self.name + " bought perk " + perk + " (total " + level.ex_perks[entity][perk].bought + ")\n");
}

playerStartUsingPerk(perk)
{
	entity = self getEntityNumber();
	level.ex_perks[entity][perk].used++;
	level.ex_perks[entity][perk].active++;
	setPerkTeamDelay(self.pers["team"], perk);
	//logprint("DEBUG: player " + self.name + " activated perk " + perk + " (total " + level.ex_perks[entity][perk].active + ")\n");
}

playerStopUsingPerk(perk)
{
	entity = self getEntityNumber();
	if(level.ex_perks[entity][perk].active)
	{
		level.ex_perks[entity][perk].active--;
		setPerkPlayerDelay(entity, perk);
	}
	//logprint("DEBUG: player " + self.name + " deactivated perk " + perk + " (total " + level.ex_perks[entity][perk].active + ")\n");
}

levelStopUsingPerk(entity, perk)
{
	if(level.ex_perks[entity][perk].active)
	{
		level.ex_perks[entity][perk].active--;
		setPerkPlayerDelay(entity, perk);
	}
	//logprint("DEBUG: level deactivated perk " + perk + " for entity " + entity + " (total " + level.ex_perks[entity][perk].active + ")\n");
}

levelResetUsingPerk(entity, perk)
{
	level.ex_perks[entity][perk].active = 0;
	//logprint("DEBUG: level deactivated perk " + perk + " for entity " + entity + " (total " + level.ex_perks[entity][perk].active + ")\n");
}

setPerkTeamDelay(team, perk)
{
	switch(perk)
	{
		case "maxhealth": delay = game["specials_team_delay1"]; break;
		case "maxammo": delay = game["specials_team_delay2"]; break;
		case "vest": delay = game["specials_team_delay3"]; break;
		case "bubble_small": delay = game["specials_team_delay4"]; break;
		case "bubble_big": delay = game["specials_team_delay5"]; break;
		case "insertion": delay = game["specials_team_delay6"]; break;
		case "sentrygun": delay = game["specials_team_delay7"]; break;
		case "gunship": delay = game["specials_team_delay8"]; break;
		case "heli": delay = game["specials_team_delay9"]; break;
		default : delay = 0; break;
	}
	for(i = 0; i < level.ex_perkcatalog.size; i++)
	{
		if(level.ex_perkcatalog[i].name == perk)
		{
			if(team == "axis") level.ex_perkcatalog[i].axis_delay = delay;
				else level.ex_perkcatalog[i].allies_delay = delay;
			break;
		}
	}
}

setPerkPlayerDelay(entity, perk)
{
	switch(perk)
	{
		case "maxhealth": delay = game["specials_player_delay1"]; break;
		case "maxammo": delay = game["specials_player_delay2"]; break;
		case "vest": delay = game["specials_player_delay3"]; break;
		case "bubble_small": delay = game["specials_player_delay4"]; break;
		case "bubble_big": delay = game["specials_player_delay5"]; break;
		case "insertion": delay = game["specials_player_delay6"]; break;
		case "sentrygun": delay = game["specials_player_delay7"]; break;
		case "gunship": delay = game["specials_player_delay8"]; break;
		case "heli": delay = game["specials_player_delay9"]; break;
		default : delay = 0; break;
	}
	level.ex_perks[entity][perk].player_delay = delay;
}

onPlayerConnected()
{
	self playerResetPerk();
}

onPlayerSpawned()
{
	if(level.ex_bubble && level.ex_bubble_test) self thread extreme\_ex_specials_bubble::bubblePerkDelayed(level.ex_bubble_test_delay);
	if(level.ex_sentrygun && level.ex_sentrygun_test) self thread extreme\_ex_specials_sentrygun::sentrygunPerkDelayed(level.ex_sentrygun_test_delay);
	if(level.ex_gunship && level.ex_gunship_test) self thread extreme\_ex_gunship::gunshipPerkDelayed(level.ex_gunship_test_delay);
	if(level.ex_heli && level.ex_heli_test) self thread extreme\_ex_specials_helicopter::heliPerkDelayed(level.ex_heli_test_delay);
	if(level.ex_specials) self thread playerGiveBackPerks();
}

onPlayerKilled()
{
	if(level.ex_gunship) level thread extreme\_ex_gunship::gunshipDetachPlayerLevel(self);
	if(level.ex_specials)
	{
		entity = self getEntityNumber();
		if(level.ex_vest) self thread playerStopUsingPerk("vest");
		if(level.ex_sentrygun && (level.ex_sentrygun_remove & 2) == 2) level thread extreme\_ex_specials_sentrygun::sentrygunRemoveFrom(self);
		if(level.ex_gunship_special)
		{
			self thread playerStopUsingPerk("gunship");
			level thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayerLevel(self);
		}
	}
}

onPlayerDisconnected(entity)
{
	// called from _ex_clientcontrol::exPlayerDisconnect() to get entity parameter
	if(level.ex_specials)
	{
		if(level.ex_vest) level thread extreme\_ex_specials::levelResetUsingPerk(entity, "vest");
		if(level.ex_gunship_special) level thread extreme\_ex_specials::levelResetUsingPerk(entity, "gunship");
	}
}

onJoinedTeam()
{
	if(level.ex_gunship) level thread extreme\_ex_gunship::gunshipDetachPlayerLevel(self);
	if(level.ex_gunship_special) level thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayerLevel(self);
}

onJoinedSpectators()
{
	if(level.ex_gunship) level thread extreme\_ex_gunship::gunshipDetachPlayerLevel(self);
	if(level.ex_gunship_special) level thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayerLevel(self);
}

playerGiveBackPerks(entity)
{
	entity = self getEntityNumber();
	for(i = 0; i < level.ex_perkcatalog.size; i++)
	{
		perk = level.ex_perkcatalog[i].name;
		bought = level.ex_perks[entity][perk].bought;
		used = level.ex_perks[entity][perk].used;
		if(used < bought)
		{
			switch(perk)
			{
				case "maxhealth": break;
				case "maxammo": break;
				case "vest": if(game["specials_keep3"]) self thread extreme\_ex_specials_vest::vestPerk(0);break;
				case "bubble_small": if(game["specials_keep4"]) self thread extreme\_ex_specials_bubble::bubblePerk("small", 0); break;
				case "bubble_big": if(game["specials_keep5"]) self thread extreme\_ex_specials_bubble::bubblePerk("big", 0); break;
				case "insertion": if(game["specials_keep6"]) self thread extreme\_ex_specials_insertion::insertionPerk(0); break;
				case "sentrygun": if(game["specials_keep7"]) self thread extreme\_ex_specials_sentrygun::sentrygunPerk(0); break;
				case "gunship": if(game["specials_keep8"]) self thread extreme\_ex_specials_gunship::gunshipSpecialPerk(0); break;
				case "heli": if(game["specials_keep9"]) self thread extreme\_ex_specials_helicopter::heliPerk(0); break;
			}
		}
	}
}

quickrequests(response)
{
	self endon("disconnect");

	if(!isDefined(response)) return;
	if(!level.ex_specials || level.ex_entities_defcon == 2)
	{
		self iprintlnbold(&"SPECIALS_NO_STORE");
		return;
	}

	if(level.ex_specials_minpoints && self.score < level.ex_specials_minpoints)
	{
		self iprintlnbold(&"SPECIALS_NO_STORE_YET", level.ex_specials_minpoints);
		return;
	}

	// keep checkPrice() last on list, because it will handle payment
	if(!checkFeature(response) ||
	   !checkStock(response) ||
	   !checkPerk(response) ||
	   !checkPlayerDelay(response) ||
	   !checkTeamDelay(response) ||
	   !checkLimitBought(response) ||
	   !checkLimitActive(response) ||
	   !checkLimitTeamActive(response) ||
	   !checkPrice(response)) return;

	switch(response)
	{
		case "1":
			self thread playerBoughtPerk("maxhealth");
			self thread hudNotifySpecial("maxhealth");
			self thread playerStartUsingPerk("maxhealth");
			self.health = 100;
			self thread playerStopUsingPerk("maxhealth");
			self thread hudNotifySpecialRemove("maxhealth", 5);
			break;
		case "2":
			self thread playerBoughtPerk("maxammo");
			self thread hudNotifySpecial("maxammo");
			self thread playerStartUsingPerk("maxammo");
			self thread extreme\_ex_weapons::updateLoadout(2);
			self thread playerStopUsingPerk("maxammo");
			self thread hudNotifySpecialRemove("maxammo", 5);
			break;
		case "3":
			self thread playerBoughtPerk("vest");
			self thread extreme\_ex_specials_vest::vestPerk(0);
			break;
		case "4":
			self thread playerBoughtPerk("bubble_small");
			self thread extreme\_ex_specials_bubble::bubblePerk("small", 0);
			break;
		case "5":
			self thread playerBoughtPerk("bubble_big");
			self thread extreme\_ex_specials_bubble::bubblePerk("big", 0);
			break;
		case "6":
			self thread playerBoughtPerk("insertion");
			self thread extreme\_ex_specials_insertion::insertionPerk(0);
			break;
		case "7":
			self thread playerBoughtPerk("sentrygun");
			self thread extreme\_ex_specials_sentrygun::sentrygunPerk(0);
			break;
		case "8":
			self thread playerBoughtPerk("gunship");
			self thread extreme\_ex_specials_gunship::gunshipSpecialPerk(0);
			break;
		case "9":
			self thread playerBoughtPerk("heli");
			self thread extreme\_ex_specials_helicopter::heliPerk(0);
			break;
		default :
			self iprintlnbold(&"SPECIALS_NO_VALIDRESPONSE");
			break;
	}
}

checkFeature(special)
{
	switch(special)
	{
		case "1": feature = level.ex_specials_maxhealth; break;
		case "2": feature = level.ex_specials_maxammo; break;
		case "3": feature = level.ex_vest; break;
		case "4": feature = (level.ex_bubble == 1 || level.ex_bubble == 3); break;
		case "5": feature = (level.ex_bubble == 2 || level.ex_bubble == 3); break;
		case "6": feature = level.ex_insertion; break;
		case "7": feature = level.ex_sentrygun; break;
		case "8": feature = (level.ex_gunship_special && !isDefined(level.ex_gunship_splayer)); break;
		case "9": feature = (level.ex_heli && !isDefined(level.ex_heli_splayer)); break;
		default : feature = false; break;
	}
	if(!feature)
	{
		self iprintlnbold(&"SPECIALS_NO_FEATURE");
		return(false);
	}
	return(true);
}

checkStock(special)
{
	stock = game["specials_stock" + special];
	if(!stock)
	{
		self iprintlnbold(&"SPECIALS_NO_STOCK");
		return(false);
	}
	return(true);
}

checkPerk(special)
{
	switch(special)
	{
		case "1": feature = (self.health != 100); break;
		case "2": feature = level.ex_specials_maxammo; break;
		case "3": feature = (!isDefined(self.ex_vest) || !self.ex_vest); break;
		case "4": feature = (!isDefined(self.ex_bubble) || !self.ex_bubble); break;
		case "5": feature = (!isDefined(self.ex_bubble) || !self.ex_bubble); break;
		case "6": feature = (!isDefined(self.ex_insertion) || !self.ex_insertion); break;
		case "7": feature = (!isDefined(self.ex_sentrygun) || !self.ex_sentrygun); break;
		case "8": feature = (!isDefined(self.ex_gunship) || !self.ex_gunship); break;
		case "9": feature = (!isDefined(self.ex_heli) || !self.ex_heli); break;
		default : feature = false; break;
	}
	if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") feature = false;
	if(!feature)
	{
		self iprintlnbold(&"SPECIALS_NO_PERK");
		return(false);
	}
	return(true);
}

checkPlayerDelay(special)
{
	entity = self getEntityNumber();
	switch(special)
	{
		case "1": player_delay = level.ex_perks[entity]["maxhealth"].player_delay; break;
		case "2": player_delay = level.ex_perks[entity]["maxammo"].player_delay; break;
		case "3": player_delay = level.ex_perks[entity]["vest"].player_delay; break;
		case "4": player_delay = level.ex_perks[entity]["bubble_small"].player_delay; break;
		case "5": player_delay = level.ex_perks[entity]["bubble_big"].player_delay; break;
		case "6": player_delay = level.ex_perks[entity]["insertion"].player_delay; break;
		case "7": player_delay = level.ex_perks[entity]["sentrygun"].player_delay; break;
		case "8": player_delay = level.ex_perks[entity]["gunship"].player_delay; break;
		case "9": player_delay = level.ex_perks[entity]["heli"].player_delay; break;
		default : player_delay = 0; break;
	}
	if(player_delay)
	{
		self iprintlnbold(&"SPECIALS_NO_PLAYERDELAY", player_delay);
		return(false);
	}
	return(true);
}

checkTeamDelay(special)
{
	if(!level.ex_teamplay) return(true);

	switch(special)
	{
		case "1": team_delay = getTeamDelay("maxhealth", self.pers["team"]); break;
		case "2": team_delay = getTeamDelay("maxammo", self.pers["team"]); break;
		case "3": team_delay = getTeamDelay("vest", self.pers["team"]); break;
		case "4": team_delay = getTeamDelay("bubble_small", self.pers["team"]); break;
		case "5": team_delay = getTeamDelay("bubble_big", self.pers["team"]); break;
		case "6": team_delay = getTeamDelay("insertion", self.pers["team"]); break;
		case "7": team_delay = getTeamDelay("sentrygun", self.pers["team"]); break;
		case "8": team_delay = getTeamDelay("gunship", self.pers["team"]); break;
		case "9": team_delay = getTeamDelay("heli", self.pers["team"]); break;
		default : team_delay = 0; break;
	}

	if(team_delay)
	{
		self iprintlnbold(&"SPECIALS_NO_TEAMDELAY", team_delay);
		return(false);
	}
	return(true);
}

getTeamDelay(perk, team)
{
	team_delay = 0;
	for(i = 0; i < level.ex_perkcatalog.size; i++)
	{
	  if(level.ex_perkcatalog[i].name == perk)
		{
			if(team == "axis") team_delay = level.ex_perkcatalog[i].axis_delay;
				else team_delay = level.ex_perkcatalog[i].allies_delay;
			break;
		}
	}
	return(team_delay);
}

checkLimitBought(special)
{
	entity = self getEntityNumber();
	limit = game["specials_player_maxbuy" + special];
	if(!limit) return(true);
	switch(special)
	{
		case "1": feature = (level.ex_perks[entity]["maxhealth"].bought < limit); break;
		case "2": feature = (level.ex_perks[entity]["maxammo"].bought < limit); break;
		case "3": feature = (level.ex_perks[entity]["vest"].bought < limit); break;
		case "4": feature = (level.ex_perks[entity]["bubble_small"].bought < limit); break;
		case "5": feature = (level.ex_perks[entity]["bubble_big"].bought < limit); break;
		case "6": feature = (level.ex_perks[entity]["insertion"].bought < limit); break;
		case "7": feature = (level.ex_perks[entity]["sentrygun"].bought < limit); break;
		case "8": feature = (level.ex_perks[entity]["gunship"].bought < limit); break;
		case "9": feature = (level.ex_perks[entity]["heli"].bought < limit); break;
		default : feature = false; break;
	}
	if(!feature)
	{
		self iprintlnbold(&"SPECIALS_NO_MAXBUY", limit);
		return(false);
	}
	return(true);
}

// alternative for checkLimitBought: limit after perks have been used
checkLimitUsed(special)
{
	entity = self getEntityNumber();
	limit = game["specials_player_maxbuy" + special];
	if(!limit) return(true);
	switch(special)
	{
		case "1": feature = (level.ex_perks[entity]["maxhealth"].used < limit); break;
		case "2": feature = (level.ex_perks[entity]["maxammo"].used < limit); break;
		case "3": feature = (level.ex_perks[entity]["vest"].used < limit); break;
		case "4": feature = (level.ex_perks[entity]["bubble_small"].used < limit); break;
		case "5": feature = (level.ex_perks[entity]["bubble_big"].used < limit); break;
		case "6": feature = (level.ex_perks[entity]["insertion"].used < limit); break;
		case "7": feature = (level.ex_perks[entity]["sentrygun"].used < limit); break;
		case "8": feature = (level.ex_perks[entity]["gunship"].used < limit); break;
		case "9": feature = (level.ex_perks[entity]["heli"].used < limit); break;
		default : feature = false; break;
	}
	if(!feature)
	{
		self iprintlnbold(&"SPECIALS_NO_MAXBUY", limit);
		return(false);
	}
	return(true);
}

checkLimitActive(special)
{
	entity = self getEntityNumber();
	limit = game["specials_player_maxact" + special];
	if(!limit) return(true);
	switch(special)
	{
		case "1": feature = (level.ex_perks[entity]["maxhealth"].active < limit); break;
		case "2": feature = (level.ex_perks[entity]["maxammo"].active < limit); break;
		case "3": feature = (level.ex_perks[entity]["vest"].active < limit); break;
		case "4": feature = (level.ex_perks[entity]["bubble_small"].active < limit); break;
		case "5": feature = (level.ex_perks[entity]["bubble_big"].active < limit); break;
		case "6": feature = (level.ex_perks[entity]["insertion"].active < limit); break;
		case "7": feature = (level.ex_perks[entity]["sentrygun"].active < limit); break;
		case "8": feature = (level.ex_perks[entity]["gunship"].active < limit); break;
		case "9": feature = (level.ex_perks[entity]["heli"].active < limit); break;
		default : feature = false; break;
	}
	if(!feature)
	{
		self iprintlnbold(&"SPECIALS_NO_MAXACT", limit);
		return(false);
	}
	return(true);
}

checkLimitTeamActive(special)
{
	if(!level.ex_teamplay) return(true);

	limit = game["specials_team_maxact" + special];
	if(!limit) return(true);
	switch(special)
	{
		case "1": feature = (getLimitTeamActive("maxhealth") < limit); break;
		case "2": feature = (getLimitTeamActive("maxammo") < limit); break;
		case "3": feature = (getLimitTeamActive("vest") < limit); break;
		case "4": feature = (getLimitTeamActive("bubble_small") < limit); break;
		case "5": feature = (getLimitTeamActive("bubble_big") < limit); break;
		case "6": feature = (getLimitTeamActive("insertion") < limit); break;
		case "7": feature = (getLimitTeamActive("sentrygun") < limit); break;
		case "8": feature = (getLimitTeamActive("gunship") < limit); break;
		case "9": feature = (getLimitTeamActive("heli") < limit); break;
		default : feature = false; break;
	}
	if(!feature)
	{
		self iprintlnbold(&"SPECIALS_NO_MAXTEAM", limit);
		return(false);
	}
	return(true);
}

getLimitTeamActive(perk)
{
	total = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isDefined(player.pers["team"])) continue;
		if(player.pers["team"] == self.pers["team"])
		{
			entity = player getEntityNumber();
			total += level.ex_perks[entity][perk].active;
		}
	}
	return(total);
}

checkPrice(special)
{
	price = game["specials_price" + special];
	if(self.score < 0)
	{
		self iprintlnbold(&"SPECIALS_NO_POINTS_SUBZERO");
		return(false);
	}
	else if(self.score < price)
	{
		self iprintlnbold(&"SPECIALS_NO_POINTS", price);
		return(false);
	}

	// adjust stock
	game["specials_stock" + special]--;

	// keep specials_cash above adjusting score, otherwise it will force a rank demotion
	if(price > 0)
	{
		self.pers["specials_cash"] = self.pers["specials_cash"] + price;
		self.score = self.score - price;
		if(isDefined(self.pers["score"])) self.pers["score"] = self.score;

		// if using the arcade hud points, adjust the score for it
		if(level.ex_arcade) self thread extreme\_ex_arcade::checkScoreUpdate();
	}

	return(true);
}

playerSpecialtyCvars()
{
	if(level.ex_specials_maxammo) self setClientCvar("ui_specials_perk2", "" + game["specials_text2"]);
		else self setClientCvar("ui_specials_perk2", "" + game["specials_text_na"]);

	if(level.ex_vest) self setClientCvar("ui_specials_perk3", "" + game["specials_text3"]);
		else self setClientCvar("ui_specials_perk3", "" + game["specials_text_na"]);

	if(level.ex_sentrygun) self setClientCvar("ui_specials_perk7", "" + game["specials_text7"]);
		else self setClientCvar("ui_specials_perk7", "" + game["specials_text_na"]);

	if(level.ex_heli) self setClientCvar("ui_specials_perk9", "" + game["specials_text9"]);
		else self setClientCvar("ui_specials_perk9", "" + game["specials_text_na"]);

	if(level.ex_insertion) self setClientCvar("ui_specials_perk6", "" + game["specials_text6"]);
		else self setClientCvar("ui_specials_perk6", "" + game["specials_text_na"]);


}

hudNotifySpecial(perk)
{
	self endon("kill_thread");

	special = 0;
	shader = "black";
	for(i = 0; i < level.ex_perkcatalog.size; i++)
	{
		if(level.ex_perkcatalog[i].name == perk)
		{
			special = i + 1;
			shader = level.ex_perkcatalog[i].shader;
		}
	}

	// first check if this hud elem is already on screen
	hudelem = "spc_icon" + special;
	if(!isDefined(self.pers[hudelem]))
	{
		// move other perk hud elems to the right
		for(i = 1; i <= level.ex_perkcatalog.size; i++)
		{
			checkelem = "spc_icon" + i;
			if(isDefined(self.pers[checkelem]))
			{
				self.pers[checkelem] moveOverTime(.25);
				self.pers[checkelem].y = self.pers[checkelem].y - 30;
			}
		}

		self.pers[hudelem] = newClientHudElem(self);
		self.pers[hudelem].archived = true;
		self.pers[hudelem].horzAlign = "fullscreen";
		self.pers[hudelem].vertAlign = "fullscreen";
		self.pers[hudelem].alignx = "center";
		self.pers[hudelem].aligny = "middle";
		self.pers[hudelem].x = 620;
		self.pers[hudelem].y = 335;
		self.pers[hudelem].alpha = level.ex_iconalpha;
		self.pers[hudelem] setShader(shader, 16, 16);
		self.pers[hudelem] scaleOverTime(.5, 24, 24);
	}
}

hudNotifySpecialRemove(perk, delay)
{
	self endon("kill_thread");

	if(isDefined(delay)) wait( [[level.ex_fpstime]](delay) );

	special = 0;
	for(i = 0; i < level.ex_perkcatalog.size; i++)
		if(level.ex_perkcatalog[i].name == perk) special = i + 1;

	hudelem = "spc_icon" + special;
	if(isDefined(self.pers[hudelem]))
	{
		hudelem_y = self.pers[hudelem].y;
		self.pers[hudelem] destroy();

		for(i = 1; i <= level.ex_perkcatalog.size; i++)
		{
			hudelem = "spc_icon" + i;
			if(isDefined(self.pers[hudelem]) && self.pers[hudelem].y > hudelem_y)
			{
				self.pers[hudelem] moveOverTime(.25);
				self.pers[hudelem].y = self.pers[hudelem].y + 30;
			}
		}
	}
}

hudNotifyProtected()
{
	if(!isDefined(self.ex_spc_proticon))
	{
		self.ex_spc_proticon = newClientHudElem(self);
		self.ex_spc_proticon.archived = true;
		self.ex_spc_proticon.horzAlign = "fullscreen";
		self.ex_spc_proticon.vertAlign = "fullscreen";
		self.ex_spc_proticon.alignx = "center";
		self.ex_spc_proticon.aligny = "middle";
		self.ex_spc_proticon.x = 620;
		self.ex_spc_proticon.y = 385;
		self.ex_spc_proticon.alpha = level.ex_iconalpha;
		self.ex_spc_proticon setShader(game["mod_protect_hudicon"], 22, 22);
	}
}

hudNotifyProtectedRemove()
{
	if(isDefined(self.ex_spc_proticon)) self.ex_spc_proticon destroy();
}

hudNotifyTestFlash(color)
{
	level endon("ex_gameover");
	self endon("disconnect");

	hudNotifyTestFlashRemove();

	self.ex_test_icon = newClientHudElem(self);
	self.ex_test_icon.archived = false;
	self.ex_test_icon.horzAlign = "fullscreen";
	self.ex_test_icon.vertAlign = "fullscreen";
	self.ex_test_icon.alignx = "center";
	self.ex_test_icon.aligny = "middle";
	self.ex_test_icon.x = 620;
	self.ex_test_icon.y = 385;
	self.ex_test_icon.color = color;
	self.ex_test_icon.alpha = 1;
	self.ex_test_icon setShader("white", 22, 22);

	wait( [[level.ex_fpstime]](1) );
	hudNotifyTestFlashRemove();
}

hudNotifyTestFlashRemove()
{
	if(isDefined(self.ex_test_icon)) self.ex_test_icon destroy();
}
