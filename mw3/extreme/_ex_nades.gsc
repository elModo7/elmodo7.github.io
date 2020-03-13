
init()
{
	if(!level.ex_nademonitor) return;

	if(level.ex_teamplay)
	{
		game["satchel_allies"] = 0;
		game["satchel_axis"] = 0;
		game["frag_allies"] = 0;
		game["frag_axis"] = 0;
		game["smoke_allies"] = 0;
		game["smoke_axis"] = 0;
		game["fire_allies"] = 0;
		game["fire_axis"] = 0;
		game["gas_allies"] = 0;
		game["gas_axis"] = 0;
	}
	else
	{
		game["satchel_all"] = 0;
		game["frag_all"] = 0;
		game["smoke_all"] = 0;
		game["fire_all"] = 0;
		game["gas_all"] = 0;
	}

	// safety check to prevent overlapping onFrame events
	level.ex_nademonitor_active = 0;

	[[level.ex_registerLevelEvent]]("onFrame", ::onFrame);
}

onFrame(eventID)
{
	if(level.ex_nademonitor_active) return;
	level.ex_nademonitor_active = 1;

	nades = getentarray("grenade", "classname");
	for(i = 0; i < nades.size; i ++)
	{
		nade = nades[i];
		if(!isDefined(nade.monitored))
		{
			nade.monitored = true;
			nade thread monitorNade();
		}
	}

	level.ex_nademonitor_active = 0;
}

monitorNade()
{
	self.entity_no = self getentitynumber();
	//level thread debugNade(self);

	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if(self istouching(player))
		{
			self.nLauncher = player;
			if(!isDefined(player.pers["isbot"])) self.explode_contact = (player useButtonPressed());
				else self.explode_contact = false;
			break;
		}
	}

	if(!isDefined(self.nLauncher)) return;

	if(isDefined(self.nLauncher.pers["isbot"]) && !isAlive(self.nLauncher))
	{
		//logprint("NADE DEBUG: nade " + self.entity_no + " belongs to dead mbot. REMOVED!\n");
		if(isDefined(self)) self delete();
		return;
	}

	self.nWeapon = self.nLauncher getcurrentoffhand();

	if( (level.ex_nademon_frag || level.ex_nademon_frag_cpx || level.ex_nademon_frag_eoc) && extreme\_ex_weapons::isWeaponType(self.nWeapon, "fraggrenade"))
		level thread monitorFragNade(self, self.nWeapon, self.nLauncher);
	else if( (level.ex_nademon_satchel || level.ex_nademon_satchel_cpx || level.ex_nademon_satchel_eoc) && extreme\_ex_weapons::isWeaponType(self.nWeapon, "satchelcharge"))
		level thread monitorSatchelCharge(self, self.nWeapon, self.nLauncher);
	else if(level.ex_nademon_smoke && extreme\_ex_weapons::isWeaponType(self.nWeapon, "smokegrenade"))
		level thread monitorSmokeNade(self, self.nWeapon, self.nLauncher);
	else if(extreme\_ex_weapons::isWeaponType(self.nWeapon, "firegrenade"))
		level thread monitorFireNade(self, self.nWeapon, self.nLauncher);
	else if(extreme\_ex_weapons::isWeaponType(self.nWeapon, "gasgrenade"))
		level thread monitorGasNade(self, self.nWeapon, self.nLauncher);
}

debugNade(entity)
{
	entity_no = entity.entity_no;

	sec = 0;
	while(isDefined(entity))
	{
		wait( [[level.ex_fpstime]](1) );
		sec++;
		logprint("NADE DEBUG: nade " + entity_no + " alive for " + sec + " seconds\n");
		//if(sec%10 == 0) extreme\_ex_entities::dumpMapEntities();
	}

	logprint("NADE DEBUG: nade " + entity_no + " is gone\n");
}

//------------------------------------------------------------------------------
// Frag nades
//------------------------------------------------------------------------------
monitorFragNade(entity, weapon, launcher)
{
	level endon("ex_gameover");

	if(level.ex_teamplay) frag_group = launcher.pers["team"];
		else frag_group = "all";

	if(level.ex_nademon_frag)
	{
		frag_active = game["frag_" + frag_group];

		if(frag_active >= level.ex_nademon_frag)
		{
			if(level.ex_nademon_frag_maxwarn)
				launcher iprintlnbold(&"WEAPON_MAX_FRAG_GRENADE");

			count = launcher getAmmoCount(weapon);
			launcher setWeaponClipAmmo(weapon, count + 1);
			if(isDefined(entity)) entity delete();
			return;
		}

		game["frag_" + frag_group] = game["frag_" + frag_group] + 1;
	}

	origin = entity.origin;
	origin1 = (0, 0, 0);

	while(isDefined(entity) && !isDefined(entity.is_exploding))
	{
		origin = entity.origin;

		if(level.ex_nademon_frag_eoc && origin1 != (0, 0, 0))
		{
			x = 2 * origin[0] - origin1[0];
			y = 2 * origin[1] - origin1[1];
			z = 2 * origin[2] - origin1[2];
			virtorigin = (x, y, z);
			trace = bullettrace(origin, virtorigin, true, undefined);

			if(trace["fraction"] != 1 && entity.explode_contact) entity thread explodeFragNade(weapon, launcher, trace["surfacetype"]);
		}

		origin1 = origin;

		wait( [[level.ex_fpstime]](0.05) );
	}

	if(level.ex_nademon_frag_cpx)
	{
		thread extreme\_ex_tripwires::checkProximityTrips(origin, level.ex_nademon_frag_cpx);
		thread extreme\_ex_landmines::checkProximityLandmines(origin, level.ex_nademon_frag_cpx);
		thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin, launcher, level.ex_nademon_frag_cpx);
	}

	if(level.ex_nademon_frag)
	{
		duration = 5 * (level.ex_nademon_frag_duramod / 100);
		if(isDefined(entity) && !isDefined(entity.is_exploding)) wait( [[level.ex_fpstime]](duration) );
		game["frag_" + frag_group] = game["frag_" + frag_group] - 1;
	}

	wait( [[level.ex_fpstime]](5) );
	if(isDefined(entity)) entity delete();
}

explodeFragNade(weapon, launcher, surfacetype)
{
	self.is_exploding = true;

	iMaxdamage = 200;
	iMindamage = 50;

	if(level.ex_wdmodon && isDefined(level.ex_wdm[weapon]))
	{
		iMaxdamage = int((iMaxDamage / 100) * level.ex_wdm[weapon]);
		iMindamage = int((iMinDamage / 100) * level.ex_wdm[weapon]);
	}

	self playsound("grenade_explode_default");
	self extreme\_ex_utils::scriptedFxRadiusDamage(launcher, (0, 0, 0), "MOD_GRENADE_SPLASH", weapon, 256, iMaxdamage, iMindamage, "generic", surfacetype, true);
	if(isDefined(self)) self delete();
}

//------------------------------------------------------------------------------
// Satchel charges
//------------------------------------------------------------------------------
monitorSatchelCharge(entity, weapon, launcher)
{
	level endon("ex_gameover");

	if(level.ex_teamplay) satchel_group = launcher.pers["team"];
		else satchel_group = "all";

	if(level.ex_nademon_satchel)
	{
		satchel_active = game["satchel_" + satchel_group];

		if(satchel_active >= level.ex_nademon_satchel)
		{
			if(level.ex_nademon_satchel_maxwarn)
				launcher iprintlnbold(&"WEAPON_MAX_SATCHEL_CHARGE");

			count = launcher getAmmoCount(weapon);
			launcher setWeaponClipAmmo(weapon, count + 1);
			if(isDefined(entity)) entity delete();
			return;
		}

		game["satchel_" + satchel_group] = game["satchel_" + satchel_group] + 1;
	}

	origin = entity.origin;
	origin1 = (0, 0, 0);

	while(isDefined(entity) && (!isDefined(entity.is_exploding)))
	{
		origin = entity.origin;

		if((level.ex_nademon_satchel_eoc) && (origin1 != (0, 0, 0)))
		{
			x = 2 * origin[0] - origin1[0];
			y = 2 * origin[1] - origin1[1];
			z = 2 * origin[2] - origin1[2];
			virtorigin = (x, y, z);
			trace = bullettrace(origin, virtorigin, true, undefined);

			if(trace["fraction"] != 1 && entity.explode_contact) entity thread explodeSatchelCharge(weapon, launcher, trace["surfacetype"]);
		}

		origin1 = origin;

		wait( [[level.ex_fpstime]](0.05) );
	}

	if(level.ex_nademon_satchel_cpx)
	{
		thread extreme\_ex_tripwires::checkProximityTrips(origin, level.ex_nademon_satchel_cpx);
		thread extreme\_ex_landmines::checkProximityLandmines(origin, level.ex_nademon_satchel_cpx);
		thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin, launcher, level.ex_nademon_satchel_cpx);
	}

	if(level.ex_nademon_satchel)
	{
		duration = 5 * (level.ex_nademon_satchel_duramod / 100);
		if(isDefined(entity) && !isDefined(entity.is_exploding)) wait( [[level.ex_fpstime]](duration) );
		game["satchel_" + satchel_group] = game["satchel_" + satchel_group] - 1;
	}

	wait( [[level.ex_fpstime]](5) );
	if(isDefined(entity)) entity delete();
}

explodeSatchelCharge(weapon, launcher, surfacetype)
{
	self.is_exploding = true;

	iMaxdamage = 200;
	iMindamage = 50;

	if(level.ex_wdmodon && isDefined(level.ex_wdm[weapon]))
	{
		iMaxdamage = int((iMaxDamage / 100) * level.ex_wdm[weapon]);
		iMindamage = int((iMinDamage / 100) * level.ex_wdm[weapon]);
	}

	self playsound("mortar_explosion");
	self extreme\_ex_utils::scriptedFxRadiusDamage(launcher, (0, 0, 0), "MOD_GRENADE_SPLASH", weapon, 448, iMaxdamage, iMindamage, "satchel", undefined, true);
	if(isDefined(self)) self delete();
}

//------------------------------------------------------------------------------
// Smoke nades
//------------------------------------------------------------------------------
monitorSmokeNade(entity, weapon, launcher)
{
	level endon("ex_gameover");

	if(level.ex_teamplay) smoke_group = launcher.pers["team"];
		else smoke_group = "all";
	smoke_active = game["smoke_" + smoke_group];

	if(smoke_active >= level.ex_nademon_smoke)
	{
		if(level.ex_nademon_smoke_maxwarn)
			launcher iprintlnbold(&"WEAPON_MAX_SMOKE_GRENADE");

		count = launcher getAmmoCount(weapon);
		launcher setWeaponClipAmmo(weapon, count + 1);
		if(isDefined(entity)) entity delete();
		return;
	}

	game["smoke_" + smoke_group] = game["smoke_" + smoke_group] + 1;
	if(extreme\_ex_weapons::isWeaponType(weapon, "vipsmoke")) duration = 85;
		else duration = 45;
	duration = duration * (level.ex_nademon_smoke_duramod / 100);
	wait( [[level.ex_fpstime]](duration) );
	game["smoke_" + smoke_group] = game["smoke_" + smoke_group] - 1;

	wait( [[level.ex_fpstime]](5) );
	if(isDefined(entity)) entity delete();
}

//------------------------------------------------------------------------------
// Napalm (Fire) nades
//------------------------------------------------------------------------------
monitorFireNade(entity, weapon, launcher)
{
	level endon("ex_gameover");

	if(level.ex_teamplay) fire_group = launcher.pers["team"];
		else fire_group = "all";

	if(level.ex_nademon_fire)
	{
		fire_active = game["fire_" + fire_group];

		if(fire_active >= level.ex_nademon_fire)
		{
			if(level.ex_nademon_fire_maxwarn)
				launcher iprintlnbold(&"WEAPON_MAX_FIRE_GRENADE");

			count = launcher getAmmoCount(weapon);
			launcher setWeaponClipAmmo(weapon, count + 1);
			if(isDefined(entity)) entity delete();
			return;
		}

		game["fire_" + fire_group] = game["fire_" + fire_group] + 1;
	}

	// wait for it to stop moving
	origin = (0,0,0);
	while(isDefined(entity) && origin != entity.origin)
	{
		origin = entity.origin;
		wait( [[level.ex_fpstime]](0.1) );
	}

	// wait for cooking to end
	wait( [[level.ex_fpstime]](1.5) );

	//model = spawn("script_model", origin);
	//model.angles = entity.angles;
	//model setmodel("xmodel/health_large");

	thread fireNadeDamage(weapon, launcher, origin);

	if(level.ex_nademon_fire)
	{
		duration = 20 * (level.ex_nademon_fire_duramod / 100);
		wait( [[level.ex_fpstime]](duration) );
		game["fire_" + fire_group] = game["fire_" + fire_group] - 1;
	}

	wait( [[level.ex_fpstime]](5) );
	if(isDefined(entity)) entity delete();
}

fireNadeDamage(weapon, launcher, origin)
{
	level endon("ex_gameover");

	burntime = 15;
	for(j = 0; j < burntime; j++)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator")
				continue;

			if(isDefined(players[i].ex_invulnerable) && players[i].ex_invulnerable)
				continue;

			if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
				if(isPlayer(launcher) && (players[i] != launcher) && (players[i].pers["team"] == launcher.pers["team"]))
					continue;

			dst = distance(origin, players[i].origin);
			damarea = 200 + (j * 10);
			if( dst > damarea || !isAlive(players[i]) ) continue;
			damage = int( 40 * (1 - (dst / damarea)) + 0.5 );

			if(damage < players[i].health)
			{
				players[i] thread burnPlayer(3);
				players[i].health = players[i].health - damage;
			}
			else players[i] thread [[level.callbackPlayerDamage]](launcher, launcher, damage, 1, "MOD_GRENADE_SPLASH", weapon, players[i].origin, (0,0,1), "none", 0);
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

burnPlayer(burntime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_isonfire)) return;
	self.ex_isonfire = 1;

	if(randomint(100) > 30) extreme\_ex_utils::forceto("crouch");
	self playsound("scream");

	burntime = burntime * 4;
	for(i = 0; i < burntime; i++)
	{
		if(isDefined(self))
		{
			switch(randomint(12))
			{
				case  0: tag = "j_hip_le"; break;
				case  1: tag = "j_hip_ri"; break;
				case  2: tag = "j_knee_le"; break;
				case  3: tag = "j_ankle_ri"; break;
				case  4: tag = "j_knee_ri"; break;
				case  5: tag = "j_wrist_ri"; break;
				case  6: tag = "j_head"; break;
				case  7: tag = "j_shoulder_le"; break;
				case  8: tag = "j_shoulder_ri"; break;
				case  9: tag = "j_elbow_le"; break;
				case 10: tag = "j_elbow_ri"; break;
				default: tag = "j_wrist_le"; break;
			}

			playfxontag(level.ex_effect["playerburn2"], self, tag);
			if(!isDefined(self.pers["diana"])) playfxontag(level.ex_effect["playerburn"], self, "j_spine1");
				else playfxontag(level.ex_effect["playerburn"], self, "j_spine2");

			wait( [[level.ex_fpstime]](0.25) );
		}
	}

	if(isAlive(self)) self.ex_isonfire = undefined;
}

//------------------------------------------------------------------------------
// Gas nades
//------------------------------------------------------------------------------
monitorGasNade(entity, weapon, launcher)
{
	level endon("ex_gameover");

	if(level.ex_teamplay) gas_group = launcher.pers["team"];
		else gas_group = "all";

	if(level.ex_nademon_gas)
	{
		gas_active = game["gas_" + gas_group];

		if(gas_active >= level.ex_nademon_gas)
		{
			if(level.ex_nademon_gas_maxwarn)
				launcher iprintlnbold(&"WEAPON_MAX_GAS_GRENADE");

			count = launcher getAmmoCount(weapon);
			launcher setWeaponClipAmmo(weapon, count + 1);
			if(isDefined(entity)) entity delete();
			return;
		}

		game["gas_" + gas_group] = game["gas_" + gas_group] + 1;
	}

	// wait for it to stop moving
	origin = (0,0,0);
	while(isDefined(entity) && origin != entity.origin)
	{
		origin = entity.origin;
		wait( [[level.ex_fpstime]](0.1) );
	}

	// wait for cooking to end
	wait( [[level.ex_fpstime]](1.5) );

	//model = spawn("script_model", origin);
	//model.angles = entity.angles;
	//model setmodel("xmodel/health_large");

	thread gasNadeDamage(weapon, launcher, origin);

	if(level.ex_nademon_gas)
	{
		duration = 20 * (level.ex_nademon_gas_duramod / 100);
		wait( [[level.ex_fpstime]](duration) );
		game["gas_" + gas_group] = game["gas_" + gas_group] - 1;
	}

	wait( [[level.ex_fpstime]](5) );
	if(isDefined(entity)) entity delete();
}

gasNadeDamage(weapon, launcher, origin)
{
	level endon("ex_gameover");

	gastime = 15;
	for(j = 0; j <= gastime; j++)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator")
				continue;

			if(isDefined(players[i].ex_invulnerable) && players[i].ex_invulnerable)
				continue;

			if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
				if(isPlayer(launcher) && (players[i] != launcher) && (players[i].pers["team"] == launcher.pers["team"]))
					continue;

			dst = distance(origin, players[i].origin);
			damarea = 200 + (j * 10);
			if( dst > damarea || !isAlive(players[i]) ) continue;
			damage = int( 40 * (1 - (dst / damarea)) + 0.5 );

			if(damage < players[i].health)
			{
				players[i] thread gasPlayer(3);
				players[i].health = players[i].health - damage;
			}
			else players[i] thread [[level.callbackPlayerDamage]](launcher, launcher, damage, 1, "MOD_GRENADE_SPLASH", weapon, players[i].origin, (0,0,1), "none", 0);
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

gasPlayer(gastime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_puked)) return;
	self.ex_puked = 1;

	if(randomint(100) > 30)
	{
		playfxontag(level.ex_effect["puke"], self, "j_Head");
		extreme\_ex_utils::forceto("crouch");
		self playsound("puke");
	}
	else self playsound("choke");

	wait( [[level.ex_fpstime]](gastime) );
	if(isAlive(self)) self.ex_puked = undefined;
}
