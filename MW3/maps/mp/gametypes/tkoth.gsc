/*------------------------------------------------------------------------------
	Team King Of The Hill
	Objective: 	Score points for your team by defending and attacking the zone
	Map ends:	When one team reaches the zone time limit, or time limit is reached
	Respawning:	At base or PSP A and PSP B
	PSP's can be taken by you and teammates. You will respawn at these points.
	
	Original GameType by http://www.nlgames.org/ 
	Assistance from Gadjex contremestre@gmail.com
	Converted for eXtreme+ by {PST}*Joker
------------------------------------------------------------------------------*/

main()
{	
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_clientcontrol::menuAutoAssign;
	level.allies = extreme\_ex_clientcontrol::menuAllies;
	level.axis = extreme\_ex_clientcontrol::menuAxis;
	level.spectator = extreme\_ex_clientcontrol::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.spawnplayer = ::spawnplayer;
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	switch(game["allies"])
	{
		case "american":
			game["hudicon_allies"] = "hudicon_american";
			break;
		case "british":
			game["hudicon_allies"] = "hudicon_british";
			break;
		case "russian":
			game["hudicon_allies"] = "hudicon_russian";
			break;
	}

	game["hudicon_axis"] = "hudicon_german";

	level.compassflag_allies = "objective";
	level.objpointflag_allies = "objpoint_star";

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
		}
		precacheShader("objpoint_star");
		precacheShader("objpoint_A");
		precacheShader("objectiveA");
		precacheShader("objpoint_B");
		precacheShader("objectiveB");
		precacheShader(game["hudicon_allies"]);
		precacheShader(game["hudicon_axis"]);
		precacheModel("xmodel/prop_flag_" + game["allies"]);
		precacheModel("xmodel/prop_flag_" + game["axis"]);
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"TKOTH_PRESS_TO_SPAWN_AT_YOUR_BASE");
		precacheString(&"TKOTH_PRESS_TO_SPAWN_AT_PSP_A");
		precacheString(&"TKOTH_PRESS_TO_SPAWN_AT_PSP_B");
		precacheString(&"TKOTH_IN_THE_ZONE");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");
	
	// If map is not supported by _mapsetup_tkoth.gsc, it assumes a custom "tkoth" map.
	if(!isdefined(level.spawn))
	{
		level.spawn = "tkoth";
		spawnpointname = "mp_tkoth_spawn_allied";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();

		spawnpointname = "mp_tkoth_spawn_axis";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] PlaceSpawnpoint();
	}
		
	if(level.spawn == "sd")
	{
		spawnpointname = "mp_sd_spawn_attacker";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();

		spawnpointname = "mp_sd_spawn_defender";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] PlaceSpawnpoint();
	}
	else if(level.spawn == "ctf")
	{
		spawnpointname = "mp_ctf_spawn_allied";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();

		spawnpointname = "mp_ctf_spawn_axis";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] PlaceSpawnpoint();
	}
	
	allowed[0] = "tkoth";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.alliestimepassed = 0;
	level.axistimepassed = 0;
	level.oldalliestimepassed = 0;
	level.oldaxistimepassed = 0;
	level.pspaTeam = "";
	level.pspbTeam = "";
	level.pspplyaTeam = 0;
	level.pspplybTeam = 0;

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread initFlags();
		thread startGame();
		thread updateGametypeCvars();
	}

	// launch eXtreme+
	extreme\_ex_main::main();
}

dummy()
{
	waittillframeend;
	if(isdefined(self)) level notify("connecting", self);
}

Callback_PlayerConnect()
{
	thread dummy();
	thread extreme\_ex_clientcontrol::explayerconnect();

	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_connecting";
	self waittill("begin");
	self.statusicon = "";
	
	level notify("connected", self);

	thread extreme\_ex_clientcontrol::explayerjoinedserver();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		extreme\_ex_spawn::spawnIntermission();
		return;
	}

	level endon("intermission");

	scriptMainMenu = game["menu_ingame"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies") 
			self.sessionteam = "allies";
		else 
			self.sessionteam = "axis";

		// Fix for spectate problem
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

		if(isDefined(self.pers["weapon"]))
		{
			spawnPlayer();
		}
		else
		{
			extreme\_ex_spawn::spawnspectator();

			if(self.pers["team"] == "allies")
			{
				self openMenu(game["menu_weapon_allies"]);
				scriptMainMenu = game["menu_weapon_allies"];
			}
			else
			{
				self openMenu(game["menu_weapon_axis"]);
				scriptMainMenu = game["menu_weapon_axis"];
			}
		}
	}
	else
	{
		self setClientCvar("ui_allow_weaponchange", "0");

		if(!isDefined(self.pers["skipserverinfo"]))
		{
			extreme\_ex_clientcontrol::exPlayerPreServerInfo();
			self openMenu(game["menu_serverinfo"]);
			self.pers["skipserverinfo"] = true;
		}

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		extreme\_ex_spawn::spawnspectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

Callback_PlayerDisconnect()
{
	self extreme\_ex_clientcontrol::explayerdisconnect();

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies") setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis") setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator") setplayerteamrank(self, 2, 0);
	}

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;
	
	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir)) 
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * level.ex_friendlyfire_reflect);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 1;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 2;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1) iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
		}

		if(isdefined(eAttacker) && eAttacker != self) 
			eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(level.ex_logdamage && self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfGuid = self getGuid();
		lpselfteam = self.pers["team"];

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackname = eAttacker.name;
			lpattackGuid = eAttacker getGuid();
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackname = "";
			lpattackGuid = "";
			lpattackerteam = "world";
		}

		if(!isDefined(friendly) || friendly == 2)
			logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

		if(isDefined(friendly) && eAttacker.sessionstate != "dead")
		{
			lpselfnum = lpattacknum;
			lpselfname = lpattackname;
			lpselfGuid = lpattackGuid;
			logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
		}
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	tkotk_zone = getent("tkotk_zone", "targetname");
	
	level.zz = self.origin[2];
	level.selfzone = ((level.x),(level.y),(level.zz));
	
	level.zza = attacker.origin[2];
	level.attackerzone = ((level.x),(level.y),(level.zza));
	
	if(self.sessionteam == "spectator") return;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") 
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	if( !level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams)) 
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// switching teams
			if(isdefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1) 
						attacker.score--;
				}
			}

			if(isdefined(attacker.friendlydamage)) 
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// Check if extra points should be given for bash or headshot
			reward_points = 0;
			if(isDefined(sMeansOfDeath))
			{
				if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
					else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
			}

			points = level.ex_points_kill + reward_points;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker.score -= points;
					else attacker.score -= level.ex_points_kill;
			}
			else
			{
				attacker.score += points;
				attacker.pers["bonus"] += reward_points;
			}
		}

		// added for arcade style HUD points
		attacker notify("update_playerscore_hud");

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}
	
	level notify("update_teamscore_hud");
	
	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	if(isDefined(tkotk_zone) && isDefined(tkotk_zone.radius))
	{
		if((distance(self.origin,level.selfzone)) <= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) >= tkotk_zone.radius && attacker != self)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + "tkoth_zone_attack" + "\n");
		}
		else if((distance(self.origin,level.selfzone)) <= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) <= tkotk_zone.radius && attacker != self && lpattackerteam == level.zoneteam)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + "tkoth_zone_defend" + "\n");
		}
		else if((distance(self.origin,level.selfzone)) <= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) <= tkotk_zone.radius && attacker != self && lpattackerteam != level.zoneteam)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + "tkoth_zone_attack" + "\n");
		}
		else if((distance(self.origin,level.selfzone)) >= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) <= tkotk_zone.radius && attacker != self)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + "tkoth_zone_defend" + "\n");
		}
	}

	// Stop thread if map ended on this death
	if(level.mapended) return;
	
	if(isdefined(self.switching_teams)) 
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	if(level.respawndelay) self thread respawn_timer(delay);
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, level.respawndelay);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

	self extreme\_ex_main::exprespawn();
	
	if(level.spawn == "sd")
	{
		if(self.pers["team"] == "allies") spawnpointname = "mp_sd_spawn_attacker";
			else spawnpointname = "mp_sd_spawn_defender";
	}
	else if(level.spawn == "ctf")
	{
		if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
			else spawnpointname = "mp_ctf_spawn_axis";
	}
	else
	{
		if(self.pers["team"] == "allies") spawnpointname = "mp_tkoth_spawn_allied";
			else spawnpointname = "mp_tkoth_spawn_axis";
	}

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
	
	if(level.ex_specials && level.ex_insertion)
	{
		insertion_info = extreme\_ex_specials_insertion::insertionGetFrom(self);
		if(insertion_info["exists"])
		{
			spawnpoint.origin = insertion_info["origin"];
			spawnpoint.angles = insertion_info["angles"];
		}
	}

	if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
		else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
		
	if(!isdefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"TKOTH_OBJ_TEXT", level.zonetimelimit);
		
	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");
}

spawnPlayerA()
{
	self endon("disconnect");
	
	if((!isdefined(self.pers["weapon"])) || (!isdefined(self.pers["team"]))) return;
	
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	
	psp_A = getent("psp_a", "targetname");
	
	self extreme\_ex_main::exprespawn();
	
	if(isDefined(psp_A) && level.pspaTeam == self.pers["team"])
	{
		self spawn(((psp_A.origin[0]-32),(psp_A.origin[1]-32),(psp_A.origin[2]+16)), psp_A.angles);
	}
	else
	{
		if(level.spawn == "sd")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_sd_spawn_attacker";
			else
				spawnpointname = "mp_sd_spawn_defender";
		}
		else if(level.spawn == "ctf")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_ctf_spawn_allied";
			else
				spawnpointname = "mp_ctf_spawn_axis";
		}
		else
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_tkoth_spawn_allied";
			else
				spawnpointname = "mp_tkoth_spawn_axis";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}
	
	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"TKOTH_OBJ_TEXT", level.zonetimelimit);
	
	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");
}

spawnPlayerB()
{ 
	self endon("disconnect");
	
	if((!isdefined(self.pers["weapon"])) || (!isdefined(self.pers["team"]))) return;
	
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	
	psp_B = getent("psp_b", "targetname");
	
	self extreme\_ex_main::exprespawn();
	
	if(isDefined(psp_B) && level.pspbTeam == self.pers["team"])
	{
		self spawn(((psp_B.origin[0]-32),(psp_B.origin[1]-32),(psp_B.origin[2]+16)), psp_B.angles);
	}
	else
	{
		if(level.spawn == "sd")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_sd_spawn_attacker";
			else
				spawnpointname = "mp_sd_spawn_defender";
		}
		else if(level.spawn == "ctf")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_ctf_spawn_allied";
			else
				spawnpointname = "mp_ctf_spawn_axis";
		}
		else
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_tkoth_spawn_allied";
			else
				spawnpointname = "mp_tkoth_spawn_axis";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
		else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}
	
	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"TKOTH_OBJ_TEXT", level.zonetimelimit);

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "spectator";

	if(isDefined(self.dead_origin) && isDefined(self.dead_angles))
	{
		origin = self.dead_origin + (0, 0, 16);
		angles = self.dead_angles;
	}
	else
	{
		origin = self.origin + (0, 0, 16);
		angles = self.angles;
	}

	self spawn(origin, angles);

	if(!isDefined(updtimer)) updtimer = false;
	if(updtimer) self thread updateTimer();

	while(isdefined(self.WaitingToSpawn)) wait( [[level.ex_fpstime]](0.05) );

	self thread waitRespawnButton();
	self waittill("respawn");

	if(self.pers["psppoint"] == "base")
		self thread spawnPlayer();
		
	if(self.pers["psppoint"] == "pspapoint")
		self thread spawnPlayerA();
		
	if(self.pers["psppoint"] == "pspbpoint")
		self thread spawnPlayerB();
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	level.psp_A = getent("psp_a", "targetname");
	level.psp_B = getent("psp_b", "targetname");
	
	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	if(!isdefined(self.respawntext))
	{
		self.respawntext = newClientHudElem(self);
		self.respawntext.horzAlign = "center_safearea";
		self.respawntext.vertAlign = "center_safearea";
		self.respawntext.alignX = "center";
		self.respawntext.alignY = "middle";
		self.respawntext.x = 0;
		self.respawntext.y = -50;
		self.respawntext.archived = false;
		self.respawntext.font = "default";
		self.respawntext.fontscale = 2;
	}
	self.respawntext setText(&"TKOTH_PRESS_TO_SPAWN_AT_YOUR_BASE");

	if(isdefined(level.psp_A) && self.pers["team"] == level.pspaTeam)
	{
		if(!isdefined(self.respawnatext))
		{
			self.respawnatext = newClientHudElem(self);
			self.respawnatext.horzAlign = "center_safearea";
			self.respawnatext.vertAlign = "center_safearea";
			self.respawnatext.alignX = "center";
			self.respawnatext.alignY = "middle";
			self.respawnatext.x = 0;
			self.respawnatext.y = -25;
			self.respawnatext.archived = false;
			self.respawnatext.font = "default";
			self.respawnatext.fontscale = 2;
		}
		self.respawnatext setText(&"TKOTH_PRESS_TO_SPAWN_AT_PSP_A");
	}
		
	if(isdefined(level.psp_B) && self.pers["team"] == level.pspbTeam)
	{
		y = -25;
		if(isdefined(self.respawnatext)) y = 0;

		if(!isdefined(self.respawnbtext))
		{
			self.respawnbtext = newClientHudElem(self);
			self.respawnbtext.horzAlign = "center_safearea";
			self.respawnbtext.vertAlign = "center_safearea";
			self.respawnbtext.alignX = "center";
			self.respawnbtext.alignY = "middle";
			self.respawnbtext.x = 0;
			self.respawnbtext.y = y;
			self.respawnbtext.archived = false;
			self.respawnbtext.font = "default";
			self.respawnbtext.fontscale = 2;
		}
		self.respawnbtext setText(&"TKOTH_PRESS_TO_SPAWN_AT_PSP_B");
	}
	
	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(true)
	{
		if(self useButtonPressed())
		{
			self.pers["psppoint"] = "base";
			break;
		}
		else if(self attackbuttonPressed() && self.pers["team"] == level.pspaTeam)
		{
			self.pers["psppoint"] = "pspapoint";
			break;
		}
		else if(self meleebuttonPressed() && self.pers["team"] == level.pspbTeam)
		{
			self.pers["psppoint"] = "pspbpoint";
			break;
		}
		else wait( [[level.ex_fpstime]](0.05) );
	}

	self notify("remove_respawntext");
	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext)) self.respawntext destroy();
	if(isDefined(self.respawnatext)) self.respawnatext destroy();
	if(isDefined(self.respawnbtext)) self.respawnbtext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

startGame()
{
	level.zonepointtime = getTime();

	if(level.timelimit > 0)
	{
		extreme\_ex_gtcommon::createClock();
		level.clock setTimer(level.timelimit * 60);
	}

	SetupHUD();

	for(;;)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	removeHUD();

	if(level.zoneteam == "allies")
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MP_ALLIES_WIN";
		setTeamScore("allies", 1);
	}
	else if(level.zoneteam == "axis")
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MP_AXIS_WIN";
		setTeamScore("axis", 1);
	}
	else
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MP_THE_GAME_IS_A_TIE";
	}

	winners = "";
	losers = "";

	if(winningteam == "allies")
		level.ex_resultsound = "MP_announcer_allies_win";
	else if(winningteam == "axis")
		level.ex_resultsound = "MP_announcer_axis_win";
	else
		level.ex_resultsound = "MP_announcer_round_draw";
	
	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if((winningteam == "allies") || (winningteam == "axis"))
		{
			lpselfguid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
				winners = (winners + ";" + lpselfguid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
				losers = (losers + ";" + lpselfguid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();
		player setClientCvar("cg_objectiveText", text);
		player extreme\_ex_spawn::spawnIntermission();
		
		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0) return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < level.timelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	waittillframeend;

	if(level.scorelimit <= 0) return;

	if(getTeamScore("allies") < level.scorelimit && getTeamScore("axis") < level.scorelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getCvarFloat("scr_tkoth_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_tkoth_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock)) extreme\_ex_gtcommon::createClock();
				level.clock setTimer(level.timelimit * 60);
			}
			else if(isDefined(level.clock)) level.clock destroy();

			checkTimeLimit();
		}
		wait( [[level.ex_fpstime]](1) );
	}
}

initFlags()
{
	level.tkothZone = getent("tkothZone", "targetname");
	if(!isDefined(level.tkothZone))
	{
		// Spawn a script origin
		level.flag = spawn("script_model",((level.x),(level.y),(level.z)));
		level.flag.targetname = "tkotk_zone";
		level.flag.origin = ((level.x),(level.y),(level.z));
		level.flag.angles = (0,0,0);
		level.flag.home_origin = ((level.x),(level.y),(level.z));
		level.flag.home_angles = (0,0,0);
		level.flag.radius = level.radius;

		// Spawn the flag base model
		level.flag.basemodel = spawn("script_model", ((level.x),(level.y),(level.z)));
		level.flag.basemodel.angles = (0,0,0);
		level.flag.basemodel setmodel("xmodel/prop_flag_base");
	
		// Spawn the flag
		level.flag.flagmodel = spawn("script_model", ((level.x),(level.y),(level.z)));
		level.flag.flagmodel.angles = (0,0,0);
		level.flag.flagmodel setmodel("xmodel/prop_flag_german");
		level.flag.flagmodel hide();

		// Set flag properties
		level.flag.team = "allies";
		level.flag.atbase = true;
		level.flag.stolen = false;
		level.flag.objective = 0;
		level.flag.compassflag = level.compassflag_allies;
		level.flag.objpointflag = level.objpointflag_allies;
	
		level.zone = false;
		level.zoneteam = "";
		level.zonetimerax = false;
		level.zonetimeral = false;
	
		level.pspateam = "";
		level.pspaattempt = "";
	
		level.pspbteam = "";
		level.pspbattempt = "";
	
		level.flag thread flag();
	}
	else
	{
		// Spawn a script origin
		level.flag = spawn("script_model",level.tkothZone.origin);
		level.flag.targetname = "tkotk_zone";
		level.flag.origin = (level.tkothZone.origin);
		level.flag.angles = (0,0,0);
		level.flag.home_origin = level.tkothZone.origin;
		level.flag.home_angles = (0,0,0);
		level.flag.radius = level.tkothZone.radius;

		psp_A = getent("psp_a", "targetname");
		if(isdefined(psp_A))
		{
			level.pspaflag = spawn("script_model",psp_A.origin);
			level.pspaflag.targetname = "pspa_flag";
			level.pspaflag.flagmodel = spawn("script_model", (psp_A.origin[0],psp_A.origin[1],(psp_A.origin[2]+64)));
			level.pspaflag.flagmodel.angles = (psp_A.angles);
			level.pspaflag.flagmodel setmodel("xmodel/prop_flag_german");
			level.pspaflag.objective = 1;
			level.pspaflag.flagmodel hide();
	
			objective_add(1, "current", psp_A.origin, "objectiveA");
			thread maps\mp\gametypes\_objpoints::addObjpoint(psp_A.origin, "1","objpoint_A");
		}
	
		psp_B = getent("psp_b", "targetname");
		if(isdefined(psp_B))
		{
			level.pspbflag = spawn("script_model",psp_B.origin);
			level.pspbflag.targetname = "pspb_flag";
			level.pspbflag.flagmodel = spawn("script_model", (psp_B.origin[0],psp_B.origin[1],(psp_B.origin[2]+64)));
			level.pspbflag.flagmodel.angles = (psp_B.angles);
			level.pspbflag.flagmodel setmodel("xmodel/prop_flag_german");
			level.pspbflag.objective = 2;
			level.pspbflag.flagmodel hide();
	
			objective_add(2, "current", psp_B.origin, "objectiveB");
			thread maps\mp\gametypes\_objpoints::addObjpoint(psp_B.origin, "2","objpoint_B");
		}

		// Spawn the flag base model
		level.flag.basemodel = spawn("script_model", level.tkothZone.origin);
		level.flag.basemodel.angles = (0,0,0);
		level.flag.basemodel setmodel("xmodel/prop_flag_base");
	
		// Spawn the flag
		level.flag.flagmodel = spawn("script_model", level.tkothZone.origin);
		level.flag.flagmodel.angles = (0,0,0);
		level.flag.flagmodel setmodel("xmodel/prop_flag_german");
		level.flag.flagmodel hide();

		// Set flag properties
		level.flag.team = "allies";
		//level.flag.atbase = true;
		//level.flag.stolen = false;
		level.flag.objective = 0;
		level.flag.compassflag = level.compassflag_allies;
		level.flag.objpointflag = level.objpointflag_allies;
	
		level.x = level.tkothZone.origin[0];
		level.y = level.tkothZone.origin[1];
		level.z = level.tkothZone.origin[2];
	
		level.zone = false;
		level.zoneteam = "";
		level.zonetimerax = false;
		level.zonetimeral = false;
	
		level.pspateam = "";
		level.pspaattempt = "";
	
		level.pspbteam = "";
		level.pspbattempt = "";
	
		level.flag thread flag();
	}
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	tkotk_zone = getent("tkotk_zone", "targetname");
	level.tkothZone = getent("tkothZone", "targetname");
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			//coordinates print;
			if(level.debug == 1)
				iprintln(players[i].origin);

			if(!isDefined(level.tkothZone))
			{
				level.zzz = players[i].origin[2];
				tkotk_zone.origin = ((level.x),(level.y),(level.zzz));
			}
			else
			{
				level.x = level.tkothZone.origin[0];
				level.y = level.tkothZone.origin[1];
				level.zzz = players[i].origin[2];
				tkotk_zone.origin = ((level.x),(level.y),(level.zzz));
			}

			if(level.zone == false && level.mapended == false)
			{
				if((distance(players[i].origin,tkotk_zone.origin)) <= tkotk_zone.radius)
				{
					if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
					{
						println("CAPTURED THE ZONE");

						//thread playSoundOnPlayers("ctf_enemy_touchenemy");

						if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == "allies")
						{
							iprintln(&"TKOTH_ALLIES_CAPTURED_ZONE");
							level.zone = true;
							level.zoneteam = "allies";
							tkotk_zone.flagmodel show();
							tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);

							teamscore = getTeamScore(players[i].pers["team"]);
							teamscore += level.zonepoints_capture;
							setTeamScore(players[i].pers["team"], teamscore);
							level notify("update_teamscore_hud");

							thread Zone();
						}
						else
						{
							iprintln(&"TKOTH_AXIS_CAPTURED_ZONE");
							level.zone = true;
							level.zoneteam = "axis";
							tkotk_zone.flagmodel show();
							tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);

							teamscore = getTeamScore(players[i].pers["team"]);
							teamscore += level.zonepoints_capture;
							setTeamScore(players[i].pers["team"], teamscore);
							level notify("update_teamscore_hud");

							thread Zone();
						}
					}
				}
			}
		}
	}

	wait( [[level.ex_fpstime]](0.2) );
	
	psp_A = getent("psp_a", "targetname");
	
	if(isdefined(psp_A))
		thread pspA();
	
	psp_B = getent("psp_b", "targetname");
	
	if(isdefined(psp_B))
		thread pspB();
		
	thread Flag();
}
				
Zone()
{
	tkotk_zone = getent("tkotk_zone", "targetname");
	level.tkothZone = getent("tkothZone", "targetname");
	
	level.zonepointtimepassed = (getTime() - level.zonepointtime) / 1000;
	
	allies_alive = 0;
	axis_alive = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isDefined(level.tkothZone))
		{
			level.zz = players[i].origin[2];
			tkotk_zone.origin = ((level.x),(level.y),(level.zz));
		}
		else
		{
			level.x = level.tkothZone.origin[0];
			level.y = level.tkothZone.origin[1];
			level.zz = players[i].origin[2];
			tkotk_zone.origin = ((level.x),(level.y),(level.zz));
		}

		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing" && (distance(players[i].origin,tkotk_zone.origin)) <= tkotk_zone.radius)
		{
			if(level.zonepointtimepassed >= 10)
			{
				players[i].score += 1;
				// added for arcade style HUD points
				players[i] notify("update_playerscore_hud");
				lpselfnum = players[i] getEntityNumber();
				lpselfguid = players[i] getGuid();
				if(players.size >= 2)
				logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + players[i].pers["team"] + ";" + players[i].name + ";" + "tkoth_zone" + "\n");
			}

			if(!isdefined(players[i].zoneline) && distance(players[i].origin,tkotk_zone.origin) <= tkotk_zone.radius)
			{
				players[i].zoneline = newClientHudElem(players[i]);
				players[i].zoneline.alignX = "center";
				players[i].zoneline.alignY = "middle";
				players[i].zoneline.x = 320;
				players[i].zoneline.y = 25;
				players[i].zoneline.archived = false;
				players[i].zoneline.alpha = 1;
				players[i].zoneline.label = &"TKOTH_IN_THE_ZONE";
			}

			//level.distance = distance(players[i].origin,tkotk_zone.origin);
			//level.zonetrace = 100 - ((level.distance/tkotk_zone.radius)*100);
			//level.zonetrace = int(level.zonetrace);

			//if(isdefined(players[i].zoneline) && distance(players[i].origin,tkotk_zone.origin) <= tkotk_zone.radius)
			//	players[i].zoneline setValue(level.zonetrace);

			if(players[i].pers["team"] == "allies")
				allies_alive++;
			else if(players[i].pers["team"] == "axis")
				axis_alive++;

			if(isdefined(level.inzoneaxis))
				level.inzoneaxis setValue(axis_alive);

			if(isdefined(level.inzoneallies))
				level.inzoneallies setValue(allies_alive);

			if(axis_alive > 0)
				thread zonetimerAxis();

			if(allies_alive > 0)
				thread zonetimerAllies();
		}
		else
		{
			if(isdefined(players[i].zoneline))
				players[i].zoneline destroy();
		}
	}

	if(level.zoneteam == "axis" && axis_alive > 0 && allies_alive <= 0)
	{
		level.alliestimepassed = 0;
		level.zonetimeral = false;
		updateHUD();
	}

	if(level.zoneteam == "allies" && axis_alive <= 0 && allies_alive > 0)
	{
		level.axistimepassed = 0;
		level.zonetimerax = false;
		updateHUD();
	}

	if(level.zoneteam == "axis" && axis_alive <= 0 && allies_alive <= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_AXIS_LOST_ZONE");
		tkotk_zone.flagmodel hide();

		if(isdefined(level.inzoneaxis))
			level.inzoneaxis setValue(axis_alive);

		level.zone = false;
		level.zoneteam = "";

		level.axistimepassed = 0;
		level.zonetimerax = false;
		updateHUD();
	}

	if(level.zoneteam == "axis" && axis_alive <= 0 && allies_alive >= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_ALLIES_TAKENOVER_ZONE");
		tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
		level.zone = true;
		level.zoneteam = "allies";

		level.axistimepassed = 0;
		level.zonetimerax = false;
		updateHUD();

		thread zonetimerAllies();

		alliesteamscore = getTeamScore("allies");
		alliesteamscore += level.zonepoints_takeover;
		setTeamScore("allies", alliesteamscore);
		level notify("update_teamscore_hud");
		checkScoreLimit();
	}

	if(level.zoneteam == "allies" && axis_alive <= 0 && allies_alive <= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_ALLIES_LOST_ZONE");
		tkotk_zone.flagmodel hide();

		if(isdefined(level.inzoneallies))
		level.inzoneallies setValue(allies_alive);

		level.zone = false;
		level.zoneteam = "";

		level.alliestimepassed = 0;
		level.zonetimeral = false;
		updateHUD();
	}

	if(level.zoneteam == "allies" && axis_alive >= 0 && allies_alive <= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_AXIS_TAKENOVER_ZONE");
		tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
		level.zone = true;
		level.zoneteam = "axis";

		level.alliestimepassed = 0;
		level.zonetimeral = false;
		updateHUD();

		thread zonetimerAxis();

		axisteamscore = getTeamScore("axis");
		axisteamscore += level.zonepoints_takeover;
		setTeamScore("axis", axisteamscore);
		level notify("update_teamscore_hud");
		checkScoreLimit();
	}

	if(level.zonepointtimepassed >= 10)
		level.zonepointtime = getTime();
		
	wait( [[level.ex_fpstime]](0.2) );

	psp_A = getent("psp_a", "targetname");
	psp_B = getent("psp_b", "targetname");
	
	if(isdefined(psp_A))
		thread pspA();
	
	if(isdefined(psp_B))
		thread pspB();
	
	thread Zone();
}

zonetimerAxis()
{
	if(level.zonetimerax == true)
	{
		thread zoneLimitAxis();
		return;
	}
	else
	{
		level.zonetimerax = true;
		level.startaxis = getTime();
	}
}

zonetimerAllies()
{
	if(level.zonetimeral == true)
	{
		thread zoneLimitAllies();
		return;
	}
	else
	{
		level.zonetimeral = true;
		level.startallies = getTime();
	}
}

zoneLimitAxis()
{
	axistimepassed = (getTime() - level.startaxis) / 1000;
	level.axistimepassed = int(axistimepassed);
	thread updateHUD();

	if(level.axistimepassed < (level.zonetimelimit * 60)) return;

	level.alliestimepassed = 0;
	level.zonetimeral = false;
	level.axistimepassed = 0;
	level.zonetimerax = false;
	updateHUD();

	axisteamscore = getTeamScore("axis");
	axisteamscore += level.zonepoints_holdmax;
	setTeamScore("axis", axisteamscore);
	level notify("update_teamscore_hud");
	checkScoreLimit();
}

zoneLimitAllies()
{
	alliestimepassed = (getTime() - level.startallies) / 1000;
	level.alliestimepassed = int(alliestimepassed);
	thread updateHUD();

	if(level.alliestimepassed < (level.zonetimelimit * 60)) return;

	level.alliestimepassed = 0;
	level.zonetimeral = false;
	level.axistimepassed = 0;
	level.zonetimerax = false;
	updateHUD();

	alliesteamscore = getTeamScore("allies");
	alliesteamscore += level.zonepoints_holdmax;
	setTeamScore("allies", alliesteamscore);
	level notify("update_teamscore_hud");
	checkScoreLimit();
}

pspA()
{
	psp_A = getent("psp_a", "targetname");
	level.playerpspa = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing" && (distance(players[i].origin,psp_A.origin)) <= psp_A.radius)
		{
			level.playerpspa++;
				
			if((players[i].pers["team"]) != level.pspaAttempt && (players[i].pers["team"]) != level.pspaTeam && level.pspplyaTeam <= 0)
			{
				level.pspplyaTeam = 1;
				if(isdefined(level.pspatimerbar))
				{
					level.pspatimer destroy();
					level.pspatimerbar destroy();
				}

				level.pspaAttempt = (players[i].pers["team"]);

				level.lpselfnuma = players[i] getEntityNumber();
				level.lpselfguida = players[i] getGuid();
				level.lpselfnamea = players[i].name;
				level.lpselfteama = players[i].pers["team"];
				//if(players.size >= 2)
				logPrint("A;" + level.lpselfguida + ";" + level.lpselfnuma + ";" + level.lpselfteama + ";" + level.lpselfnamea + ";" + "psp_attempt" + "\n");
						
				level thread pspaAttempt();
			}
		}
	}

	if(level.playerpspa <= 0)
		level.pspplyaTeam = 0;

	if(level.pspaAttempt!= "")
		level thread pspaTimecheck();
}

pspB()
{
	psp_B = getent("psp_b", "targetname");
	level.playerpspb = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing" && (distance(players[i].origin,psp_B.origin)) <= psp_B.radius)
		{
			level.playerpspb++;

			if((players[i].pers["team"]) != level.pspbAttempt && (players[i].pers["team"]) != level.pspbTeam && level.pspplybTeam <= 0)
			{
				level.pspplybTeam = 1;
				if(isdefined(level.pspbtimerbar))
				{
					level.pspbtimer destroy();
					level.pspbtimerbar destroy();
				}

				level.pspbAttempt = (players[i].pers["team"]);

				level.lpselfnumb = players[i] getEntityNumber();
				level.lpselfguidb = players[i] getGuid();
				level.lpselfnameb = players[i].name;
				level.lpselfteamb = players[i].pers["team"];
				logPrint("A;" + level.lpselfguidb + ";" + level.lpselfnumb + ";" + level.lpselfteamb + ";" + level.lpselfnameb + ";" + "psp_attempt" + "\n");

				level thread pspbAttempt();
			}
		}
	}

	if(level.playerpspb <= 0)
		level.pspplybTeam = 0;

	if(level.pspbAttempt != "")
		level thread pspbTimecheck();
}

pspaAttempt()
{
	if(level.pspaAttempt == "allies") iprintln(&"TKOTH_ALLIES_TRY_TO_TAKE_PSP_A");
		else iprintln(&"TKOTH_AXIS_TRY_TO_TAKE_PSP_A");

	thread playSoundOnPlayers("tkoth_psp");

	pspa_flag = getent("pspa_flag", "targetname");
	level.pspaTeam = "";
	pspa_flag.flagmodel hide();

	level.pspatimerbar = newHudElem();
	level.pspatimerbar.archived = false;
	level.pspatimerbar.horzAlign = "center_safearea";
	level.pspatimerbar.vertAlign = "center_safearea";
	level.pspatimerbar.alignX = "center";
	level.pspatimerbar.alignY = "middle";
	level.pspatimerbar.x = 0;
	level.pspatimerbar.y = 104;
	level.pspatimerbar.alpha = .5;
	level.pspatimerbar.color = (0.2,0.2,0.2);
	level.pspatimerbar setShader("white",102,11);

	level.pspatimer = newHudElem();
	level.pspatimer.archived = false;
	level.pspatimer.horzAlign = "center_safearea";
	level.pspatimer.vertAlign = "center_safearea";
	level.pspatimer.alignX = "left";
	level.pspatimer.alignY = "middle";
	level.pspatimer.x = (102 / -2) + 2;
	level.pspatimer.y = 104;
	level.pspatimer.alpha = .8;
	level.pspatimer setShader("white",0, 9);
	level.pspatimer scaleOverTime(10,100,9);
	
	level.pspastarttime = getTime();
}

pspbAttempt()
{
	if(level.pspbAttempt == "allies") iprintln(&"TKOTH_ALLIES_TRY_TO_TAKE_PSP_B");
		else iprintln(&"TKOTH_AXIS_TRY_TO_TAKE_PSP_B");

	thread playSoundOnPlayers("tkoth_psp");

	pspb_flag = getent("pspb_flag", "targetname");
	level.pspbTeam = "";
	pspb_flag.flagmodel hide();

	level.pspbtimerbar = newHudElem();
	level.pspbtimerbar.archived = false;
	level.pspbtimerbar.horzAlign = "center_safearea";
	level.pspbtimerbar.vertAlign = "center_safearea";
	level.pspbtimerbar.alignX = "center";
	level.pspbtimerbar.alignY = "middle";
	level.pspbtimerbar.x = 0;
	level.pspbtimerbar.y = 120;
	level.pspbtimerbar.alpha = .5;
	level.pspbtimerbar.color = (0.2,0.2,0.2);
	level.pspbtimerbar setShader("white",102,11);

	level.pspbtimer = newHudElem();
	level.pspbtimer.archived = false;
	level.pspbtimer.horzAlign = "center_safearea";
	level.pspbtimer.vertAlign = "center_safearea";
	level.pspbtimer.alignX = "left";
	level.pspbtimer.alignY = "middle";
	level.pspbtimer.x = (102 / -2) + 2;
	level.pspbtimer.y = 120;
	level.pspbtimer.alpha = .8;
	level.pspbtimer setShader("white",0, 9);
	level.pspbtimer scaleOverTime(10,100,9);

	level.pspbstarttime = getTime();
}

pspaTimecheck()
{
	pspa_flag = getent("pspa_flag", "targetname");
	pspatimepassed = (getTime() - level.pspastarttime ) / 1000;
	
	if(pspatimepassed >= 10)
	{
		level.pspatimer destroy();
		level.pspatimerbar destroy();
		level.pspaTeam = level.pspaAttempt;
		level.pspaAttempt = "";
		if(level.pspaTeam == "allies")
		{
			iprintln(&"TKOTH_ALLIES_TAKEOVER_PSP_A");
			updateStatusA(level.pspaTeam);
			logPrint("A;" + level.lpselfguida + ";" + level.lpselfnuma + ";" + level.lpselfteama + ";" + level.lpselfnamea + ";" + "psp_take" + "\n");
			thread playSoundOnPlayers("tkoth_psp");
			pspa_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
			pspa_flag.flagmodel show();
			pspatimepassed = 0;
		}
		else
		{
			iprintln(&"TKOTH_AXIS_TAKEOVER_PSP_A");
			updateStatusA(level.pspaTeam);
			logPrint("A;" + level.lpselfguida + ";" + level.lpselfnuma + ";" + level.lpselfteama + ";" + level.lpselfnamea + ";" + "psp_take" + "\n");
			thread playSoundOnPlayers("tkoth_psp");
			pspa_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
			pspa_flag.flagmodel show();
			pspatimepassed = 0;
		}
	}
}

pspbTimecheck()
{
	pspb_flag = getent("pspb_flag", "targetname");
	pspbtimepassed = (getTime() - level.pspbstarttime ) / 1000;
	
	if(pspbtimepassed >= 10)
	{
		level.pspbtimer destroy();
		level.pspbtimerbar destroy();
		level.pspbTeam = level.pspbAttempt;
		level.pspbAttempt = "";
		if(level.pspbTeam == "allies")
		{
			iprintln(&"TKOTH_ALLIES_TAKEOVER_PSP_B");
			updateStatusB(level.pspbTeam);
			logPrint("A;" + level.lpselfguidb + ";" + level.lpselfnumb + ";" + level.lpselfteamb + ";" + level.lpselfnameb + ";" + "psp_take" + "\n");
			thread playSoundOnPlayers("tkoth_psp");
			pspb_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
			pspb_flag.flagmodel show();
			pspbtimepassed = 0;
		}
		else
		{
			iprintln(&"TKOTH_AXIS_TAKEOVER_PSP_B");
			updateStatusB(level.pspbTeam);
			logPrint("A;" + level.lpselfguidb + ";" + level.lpselfnumb + ";" + level.lpselfteamb + ";" + level.lpselfnameb + ";" + "psp_take" + "\n");
			thread playSoundOnPlayers("tkoth_psp");
			pspb_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
			pspb_flag.flagmodel show();
			pspbtimepassed = 0;
		}
	}
}

playSoundOnPlayers(sound, team)
{
	players = level.players;

	if(isdefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i] playLocalSound(sound);
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound(sound);
	}

	wait( [[level.ex_fpstime]](1) );
	level notify("psopdone");
}

respawn_timer(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	respawndelay = level.respawndelay;
	if(level.ex_respawndelay_subzero && self.score < 0) respawndelay += level.ex_respawndelay_subzero;
	if(level.ex_respawndelay_class && isDefined(self.pers["weapon"]))
	{
		weapon = self.pers["weapon"];
		weapon_hit = 0;
		if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) weapon_hit = level.ex_respawndelay_sniper;
		else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) weapon_hit = level.ex_respawndelay_rifle;
		else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) weapon_hit = level.ex_respawndelay_mg;
		else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) weapon_hit = level.ex_respawndelay_smg;
		else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) weapon_hit = level.ex_respawndelay_shot;
		else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) weapon_hit = level.ex_respawndelay_rl;

		if(!weapon_hit && level.ex_respawndelay_class == 2 && level.ex_wepo_secondary && isDefined(self.pers["weapon2"]))
		{
			weapon = self.pers["weapon2"];
			if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) weapon_hit = level.ex_respawndelay_sniper;
			else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) weapon_hit = level.ex_respawndelay_rifle;
			else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) weapon_hit = level.ex_respawndelay_mg;
			else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) weapon_hit = level.ex_respawndelay_smg;
			else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) weapon_hit = level.ex_respawndelay_shot;
			else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) weapon_hit = level.ex_respawndelay_rl;
		}

		if(weapon_hit) respawndelay += weapon_hit;
	}

	if(!isdefined(self.respawntimer))
	{
		self.respawntimer = newClientHudElem(self);
		self.respawntimer.x = 0;
		self.respawntimer.y = -50;
		self.respawntimer.alignX = "center";
		self.respawntimer.alignY = "middle";
		self.respawntimer.horzAlign = "center_safearea";
		self.respawntimer.vertAlign = "center_safearea";
		self.respawntimer.alpha = 0;
		self.respawntimer.archived = false;
		self.respawntimer.font = "default";
		self.respawntimer.fontscale = 2;
		self.respawntimer.label = (&"MP_TIME_TILL_SPAWN");
		self.respawntimer setTimer(respawndelay + delay);
	}

	wait( [[level.ex_fpstime]](delay) );
	self thread updateTimer();

	wait( [[level.ex_fpstime]](respawndelay) );

	if(isdefined(self.respawntimer))
		self.respawntimer destroy();

	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isdefined(self.respawntimer))
	{
		if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
			self.respawntimer.alpha = 1;
		else
			self.respawntimer.alpha = 0;
	}
}

SetupHUD()
{
	y = 10;
	barsize = 200;

	level.inzoneallies = newHudElem();
	level.inzoneallies.alignX = "right";
	level.inzoneallies.alignY = "middle";
	level.inzoneallies.x = 320 - barsize - 25;
	level.inzoneallies.y = y;
	level.inzoneallies.color = (1,1,1);
	level.inzoneallies.alpha = 1;
	level.inzoneallies.fontscale = 1.6;
	level.inzoneallies setValue(0);

	level.iconallies = newHudElem();
	level.iconallies.alignX = "right";
	level.iconallies.alignY = "middle";
	level.iconallies.x = 320 - barsize - 3;
	level.iconallies.y = y;
	level.iconallies.color = (1,1,1);
	level.iconallies.alpha = 1;
	level.iconallies setShader(game["headicon_allies"], 18, 18);

	level.timeallies = newHudElem();
	level.timeallies.alignX = "right";
	level.timeallies.alignY = "middle";
	level.timeallies.x = 320;
	level.timeallies.y = y;
	level.timeallies.color = (1,0,0);
	level.timeallies.alpha = 0.5;
	level.timeallies setShader("white", 1, 11);

	level.timeback = newHudElem();
	level.timeback.alignX = "center";
	level.timeback.alignY = "middle";
	level.timeback.x = 320;
	level.timeback.y = y;
	level.timeback.alpha = 0.3;
	level.timeback.color = (0.2,0.2,0.2);
	level.timeback setShader("white", barsize*2+4, 13);

	level.timeaxis = newHudElem();
	level.timeaxis.alignX = "left";
	level.timeaxis.alignY = "middle";
	level.timeaxis.x = 320;
	level.timeaxis.y = y;
	level.timeaxis.color = (0,0,1);
	level.timeaxis.alpha = 0.5;
	level.timeaxis setShader("white", 1, 11);

	level.iconaxis = newHudElem();
	level.iconaxis.alignX = "left";
	level.iconaxis.alignY = "middle";
	level.iconaxis.x = 320 + barsize + 3;
	level.iconaxis.y = y;
	level.iconaxis.color = (1,1,1);
	level.iconaxis.alpha = 1;
	level.iconaxis setShader(game["headicon_axis"], 18, 18);

	level.inzoneaxis = newHudElem();
	level.inzoneaxis.alignX = "left";
	level.inzoneaxis.alignY = "middle";
	level.inzoneaxis.x = 320 + barsize + 25;
	level.inzoneaxis.y = y;
	level.inzoneaxis.color = (1,1,1);
	level.inzoneaxis.alpha = 1;
	level.inzoneaxis.fontscale = 1.6;
	level.inzoneaxis setValue(0);

	psp_A = getent("psp_a", "targetname");

	if(isdefined(psp_A))
	{
		level.pspastatus = newHudElem();
		level.pspastatus.archived = false;
		level.pspastatus.alignX = "center";
		level.pspastatus.alignY = "middle";
		level.pspastatus.x = 320;
		level.pspastatus.y = 25;
		level.pspastatus.alpha = 0;
		level.pspastatus setShader("objectiveA", 12, 12);
	}

	psp_B = getent("psp_b", "targetname");

	if(isdefined(psp_B))
	{
		level.pspbstatus = newHudElem();
		level.pspbstatus.archived = false;
		level.pspbstatus.alignX = "center";
		level.pspbstatus.alignY = "middle";
		level.pspbstatus.x = 320;
		level.pspbstatus.y = 25;
		level.pspbstatus.alpha = 0;
		level.pspbstatus setShader("objectiveB", 12, 12);
	}
}

updateHUD()
{
	barsize = 200;
	axis = int(level.axistimepassed * barsize / (level.zonetimelimit * 60 - 1) + 1);
	allies = int(level.alliestimepassed * barsize / (level.zonetimelimit * 60 - 1) + 1);

	if(level.alliestimepassed != level.oldalliestimepassed)
		if(isDefined(level.timeallies)) level.timeallies scaleOverTime(1, allies, 11);
	if(level.axistimepassed != level.oldaxistimepassed)
		if(isDefined(level.timeaxis)) level.timeaxis scaleOverTime(1, axis, 11);

	level.oldalliestimepassed = level.alliestimepassed;
	level.oldaxistimepassed = level.axistimepassed;
}

updateStatusA(team)
{
	barsize = 200;

	if(isdefined(level.pspastatus))
	{
		if(team == "allies")
		{
			level.pspastatus.alignX = "right";
			level.pspastatus.x = 320 - barsize - 3;
		}
		else
		{
			level.pspastatus.alignX = "left";
			level.pspastatus.x = 320 + barsize + 3;
		}
		level.pspastatus.alpha = 0.8;
	}
}

updateStatusB(team)
{
	barsize = 200;

	if(isdefined(level.pspbstatus))
	{
		if(team == "allies")
		{
			level.pspbstatus.alignX = "right";
			level.pspbstatus.x = 320 - barsize - 20;
		}
		else
		{
			level.pspbstatus.alignX = "left";
			level.pspbstatus.x = 320 + barsize + 20;
		}
		level.pspbstatus.alpha = 0.8;
	}
}

removeHUD()
{
	if(isDefined(level.inzoneallies)) level.inzoneallies destroy();
	if(isDefined(level.iconallies)) level.iconallies destroy();
	if(isDefined(level.timeallies)) level.timeallies destroy();
	if(isDefined(level.timeback)) level.timeback destroy();
	if(isDefined(level.timeaxis)) level.timeaxis destroy();
	if(isDefined(level.iconaxis)) level.iconaxis destroy();
	if(isDefined(level.inzoneaxis)) level.inzoneaxis destroy();
	if(isdefined(level.pspastatus)) level.pspastatus destroy();
	if(isdefined(level.pspbstatus)) level.pspbstatus destroy();
	if(isDefined(level.pspatimerbar)) level.pspatimerbar destroy();
	if(isDefined(level.pspatimer)) level.pspatimer destroy();
	if(isDefined(level.pspbtimerbar)) level.pspbtimerbar destroy();
	if(isDefined(level.pspbtimer)) level.pspbtimer destroy();
}
