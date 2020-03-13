/*QUAKED mp_ctf_spawn_allied (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

/*QUAKED mp_ctf_spawn_axis (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

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

	if(!isDefined(game["precachedone"]))
	{
		// just to get sound working at start round?
		if(!isdefined(game["attackers"])) game["attackers"] = "allies";
		if(!isdefined(game["defenders"])) game["defenders"] = "axis";

		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
			precacheStatusIcon("lib_statusicon");
		}
		precacheShader("objective");
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		precacheString(&"MP_SLASH");
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
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_lib_spawn_alliesnonjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_lib_spawn_axisnonjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	spawnpointname = "mp_lib_spawn_alliesinjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_lib_spawn_axisinjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	allowed[0] = "lib";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.roundended = false;
	level.spawn_in_jail = false;

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	doordamageaxis = [];
	doordamageaxis = getentarray("doordamageaxis", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	if(!isdefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	if(!isdefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["state"])) game["state"] = "waiting";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread lib_jails();
		thread Jail_Init();
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
	self.killed_once = false;

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
	if(self.sessionteam == "spectator" || self.in_jail || self.ex_invulnerable) return;

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

	if(self.sessionteam == "spectator") return;

	self.in_jail = true;	
	self.status = "injail";
	self.killed_once = true;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
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
					{
						attacker.pers["score"]--;
						attacker.score = attacker.pers["score"];
					}
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
				if(level.ex_reward_teamkill)
				{
					attacker.pers["score"] -= points;
					attacker.score = attacker.pers["score"];
				}
				else
				{
					attacker.pers["score"] -= level.ex_points_kill;
					attacker.score = attacker.pers["score"];
				}
			}
			else
			{
				attacker.pers["score"] += points;
				attacker.pers["bonus"] += reward_points;
				attacker.score = attacker.pers["score"];
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

		self.pers["score"]--;
		self.score = self.pers["score"];

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isDefined(self.switching_teams))
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	team_dead = self getTeamStatus();

	if(team_dead) // If the last player on a team was just killed, don't do killcam
	{
		self.skip_setspectatepermissions = true;
		wait( [[level.ex_fpstime]](2) );
		self thread spawnPlayer();
		return;
	}

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

	// Set jail status before setting sessionstate
	self.in_jail = false;
	self.status = "free";

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
	
	if(level.spawn_in_jail || self.killed_once)
	{
		if(self.pers["team"] == "allies") spawnpointname = "mp_lib_spawn_alliesinjail";
			else spawnpointname = "mp_lib_spawn_axisinjail";
	}
	else
	{
		if(self.pers["team"] == "allies") spawnpointname = "mp_lib_spawn_alliesnonjail";
			else spawnpointname = "mp_lib_spawn_axisnonjail";
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

	if(!isdefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isdefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(level.roundlength <= 0) self setClientCvar("cg_objectiveText", "Capture all enemies in your jail. Capture the enemy's jail control switch (marked on your compass) to release any of your teammates in jail.");
		else self setClientCvar("cg_objectiveText", "Capture all enemies in your jail before the round ends. Capture the enemy's jail control switch (marked on your compass) to release any of your teammates in jail. If the round ends due to roundlength, the team with the most kills wins the round.");

	self thread updateTimer();

	self maps\mp\gametypes\_spectating::setSpectatePermissions();

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

	if(!level.forcerespawn)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

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
		self.respawntext setText(&"PLATFORM_PRESS_TO_SPAWN");
	}

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true) wait( [[level.ex_fpstime]](0.05) );

	self notify("remove_respawntext");
	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

startGame()
{
	thread startRound();
}

startRound()
{
	level endon("round_ended");
	game["state"] = "playing";
	game["roundnumber"]++;

	extreme\_ex_gtcommon::createClock();
	level.clock setTimer(level.roundlength * 60);

	thread Monitor_Teams();
	wait( [[level.ex_fpstime]](0.2) );
	thread Players_Free_Hud();

	thread sayObjective();

	level notify("round_started");

	wait( [[level.ex_fpstime]](level.roundlength * 60) );

	if(level.roundended) return;

	thread Check_Win_by_Teams();
}

endRound(roundwinner)
{
	level endon("intermission");
	level endon("kill_endround");

	if(level.roundended) return;
	level.roundended = true;
	level notify("round_ended");

	level thread announceWinner(roundwinner, 0.6);

	winners = "";
	losers = "";

	if(roundwinner == "allies")
	{
		game["alliedscore"]++;
		setTeamScore("allies", game["alliedscore"]);
		iprintlnbold(&"LIB_ALLIES_WIN");
	}
	else if(roundwinner == "axis")
	{
		game["axisscore"]++;
		setTeamScore("axis", game["axisscore"]);
		iprintlnbold(&"LIB_AXIS_WIN");
	}
	else iprintlnbold(&"MP_THE_ROUND_IS_A_TIE");

	wait( [[level.ex_fpstime]](5) );

	checkScoreLimit();

	if(level.mapended) return;
	level.mapended = true;

	level notify("restarting");

	map_restart(true);
}

endMap()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MP_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MP_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MP_AXIS_WIN";
	}

	if(winningteam == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winningteam == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else
		level thread playSoundOnPlayers("MP_announcer_round_draw");

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	winners = "";
	losers = "";
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
	if(level.scorelimit <= 0) return;

	if(game["alliedscore"] < level.scorelimit && game["axisscore"] < level.scorelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		scorelimit = getCvarInt("scr_lib_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
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
}

printOnTeam(text, team)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
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

Jail_Init()
{
	// Set up Objective Icons
	door_switches = getentarray("door_switch","targetname");
	for(i = 0; i < door_switches.size; i++)
	{
		door_switch = door_switches[i];

		if(door_switch.script_noteworthy == "alliesdoor")
		{
			door_switch.objective = i;
			door_switch.team = "allies";
			objective_add(i, "current", door_switch.origin, "objective");
			objective_team(i, "allies");
		}

		if(door_switch.script_noteworthy == "axisdoor")
		{
			door_switch.objective = i;
			door_switch.team = "axis";
			objective_add(i, "current", door_switch.origin, "objective");
			objective_team(i, "axis");
		}
	}

	// Setup Jailcell Zones
	axisjailfields = getentarray("axisinjail", "targetname");
	for(i = 0; i < axisjailfields.size; i++)
		axisjailfields[i] thread jail_think("axis");

	alliesjailfields = getentarray("alliesinjail", "targetname");
	for(i = 0; i < alliesjailfields.size; i++)
		alliesjailfields[i] thread jail_think("allies");

	// SETUP DOOR DAMAGE TRIGGERS

	axisjaildoordamage = getentarray("doordamageaxis", "targetname");
	for(i = 0; i < axisjaildoordamage.size; i++)
		axisjaildoordamage[i] thread jail_damagethink("axis");

	alliesjaildoordamage = getentarray("doordamageallies", "targetname");
	for(i = 0; i < alliesjaildoordamage.size; i++)
		alliesjaildoordamage[i] thread jail_damagethink("allies");
}

jail_think(team)
{
	//objective_add(self.objective, "current", self.origin, "objective");
	//objective_team(self.objective, team);

	while(1)
	{
		self waittill("trigger",other);
		
		if( level.door_closed[team] && isPlayer(other) && other.pers["team"] == team && isDefined(other.in_jail) && !other.in_jail && isAlive(other) )
			other thread goto_jail(self,team);
	}
}

goto_jail(jail,team)
{
	self endon("disconnect");

	self.in_jail = true;
	if(!level.ex_rank_statusicons) self.statusicon = "lib_statusicon";
	self.status = "injail";

	self [[level.ex_dWeapon]]();
	while(self istouching(jail) && level.door_closed[team]) wait( [[level.ex_fpstime]](0.1) );
	self [[level.ex_eWeapon]]();

	self.in_jail = false;
	self.statusicon = "";
	self.status = "free";
}

jail_damagethink(team)
{
	while(1)
	{
		self waittill("trigger",other);
		
		if( isPlayer(other) && isAlive(other) )
			other thread goto_jaildamage(self,team);
	}
}

goto_jaildamage(hurt,team)
{
	self endon("disconnect");
		
	if(self istouching(hurt) && level.door_damage[team])
	{
		self.ex_forcedsuicide = true;
		self suicide();
		wait( [[level.ex_fpstime]](0.5) );
	}
}

Monitor_Teams()
{
	spawn_in_jail_delay = 120;
	level.old_allies = 0;
	level.old_axis = 0;
	old_allies_free = 0;
	old_axis_free = 0;
	teams_free = true;

	while(teams_free)
	{
		wait( [[level.ex_fpstime]](0.5) );

		if(spawn_in_jail_delay)
		{
			spawn_in_jail_delay--;
			if(!spawn_in_jail_delay) level.spawn_in_jail = true;
		}

		allies = 0;
		axis = 0;
		level.exist["allies"] = 0;
		level.exist["axis"] = 0;
		level.free["allies"] = 0;
		level.free["axis"] = 0;

		// checking players on both sides
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator")
			{
				level.exist[player.pers["team"]]++;

				if(player.sessionstate == "spectator")
					continue;

				if(player.pers["team"] == "axis")
					axis++;
				else
					allies++;

				if(!player.in_jail)
					level.free[player.pers["team"]]++;
			}
		}

		// We have seen allies and axis before, but one team completely left
		if( (!allies && level.old_allies) || (!axis && level.old_axis) )
		{
			thread endRound("draw");
			return;
		}

		//logprint("DEBUG: allies:" + allies + ", level.old_allies:" + level.old_allies + ", axis:" + axis + ", level.old_axis:" + level.old_axis + "\n");
		//logprint("DEBUG: old_allies_free:" + old_allies_free + ", level.free_allies:" + level.free["allies"] + ", old_axis_free:" + old_axis_free + ", level.free_axis:" + level.free["axis"] + "\n");
		if(old_axis_free != level.free["axis"] || old_allies_free != level.free["allies"] || level.old_allies != allies || level.old_axis != axis)
		{
			old_axis_free = level.free["axis"];
			old_allies_free = level.free["allies"];
			level.old_allies = allies;
			level.old_axis = axis;
			
			level.free_hud["axis"] = level.free["axis"];
			level.free_hud["allies"] = level.free["allies"];
			level notify("Update_Free_HUD");
		}

		// No allies or axis ever spawned, so we have to wait for more players to join
		if(!level.old_allies || !level.old_axis) continue;

		// If all players on a team died (in jail), end checking
		if( (!level.free["allies"] && level.door_closed["allies"]) || (!level.free["axis"] && level.door_closed["axis"]) )
			teams_free = false;
	}

	// At least one team is not free, end the round
	allies_down = false;
	if(!level.free["allies"] && level.door_closed["allies"])
		allies_down = true;

	axis_down = false;
	if(!level.free["axis"] && level.door_closed["axis"])
		axis_down = true;

	if(allies_down && axis_down)
		thread endRound("draw");
	else if(allies_down && !axis_down)
		thread endRound("axis");
	else if(!allies_down && axis_down)
		thread endRound("allies");
}

getTeamStatus()
{
	//Checks to see if this was the last person on the team to die
	//With ALL other teammates either dead or in jail
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] != self.pers["team"])
			continue;
		
		if(player.sessionstate == "dead" || (isDefined(player.in_jail) && player.in_jail))
			continue;

		if(player.sessionstate == "playing")
			return false;
	}

	return true;
}

Check_Win_by_Teams()
{
	iprintln(&"MP_TIMEHASEXPIRED");

	if(level.free_hud["axis"] > level.free_hud["allies"])
		thread endRound("axis");
	else if(level.free_hud["axis"] < level.free_hud["allies"])
		thread endRound("allies");
	else
		thread endRound("draw");
}

announceWinner(winner, delay)
{
	wait( [[level.ex_fpstime]](delay) );

	// Announce winner
	if(winner == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winner == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else if(winner == "draw")
		level thread playSoundOnPlayers("MP_announcer_round_draw");
}

sayObjective()
{
	wait( [[level.ex_fpstime]](2) );

	attacksounds["american"] = "US_mp_cmd_movein";
	attacksounds["british"] = "UK_mp_cmd_movein";
	attacksounds["russian"] = "RU_mp_cmd_movein";
	attacksounds["german"] = "GE_mp_cmd_movein";
	defendsounds["american"] = "US_mp_cmd_movein";
	defendsounds["british"] = "UK_mp_cmd_movein";
	defendsounds["russian"] = "RU_mp_cmd_movein";
	defendsounds["german"] = "GE_mp_cmd_movein";

	level playSoundOnPlayers(attacksounds[game[game["attackers"]]], game["attackers"]);
	level playSoundOnPlayers(defendsounds[game[game["defenders"]]], game["defenders"]);
}

Players_Free_Hud()
{
	level.old_axis = 0;
	level.old_allies = 0;
	level.free_hud["axis"] = 0;
	level.free_hud["allies"] = 0;

	level.libhud_axisicon = newHudElem();
	level.libhud_axisicon.horzAlign = "right";
	level.libhud_axisicon.vertAlign = "top";
	level.libhud_axisicon.x = -20;
	level.libhud_axisicon.y = 28;
	level.libhud_axisicon.archived = false;
	level.libhud_axisicon setShader(game["hudicon_allies"], 16, 16);

	level.libhud_alliesicon = newHudElem();
	level.libhud_alliesicon.horzAlign = "right";
	level.libhud_alliesicon.vertAlign = "top";
	level.libhud_alliesicon.x = -20;
	level.libhud_alliesicon.y = 50;
	level.libhud_alliesicon.archived = false;
	level.libhud_alliesicon setShader(game["hudicon_axis"], 16, 16);

	level.libhud_axisfree = newHudElem();
	level.libhud_axisfree.horzAlign = "right";
	level.libhud_axisfree.vertAlign = "top";
	level.libhud_axisfree.alignX = "right";
	level.libhud_axisfree.x = -40;
	level.libhud_axisfree.y = 52;
	level.libhud_axisfree.font = "default";
	level.libhud_axisfree.fontscale = 1;
	level.libhud_axisfree.archived = false;
	level.libhud_axisfree setValue(level.free_hud["axis"]);

	level.libhud_alliesfree = newHudElem();
	level.libhud_alliesfree.horzAlign = "right";
	level.libhud_alliesfree.vertAlign = "top";
	level.libhud_alliesfree.alignX = "right";
	level.libhud_alliesfree.x = -40;
	level.libhud_alliesfree.y = 30;
	level.libhud_alliesfree.font = "default";
	level.libhud_alliesfree.fontscale = 1;
	level.libhud_alliesfree.archived = false;
	level.libhud_alliesfree setValue(level.free_hud["allies"]);

	level.libhud_axis = newHudElem();
	level.libhud_axis.horzAlign = "right";
	level.libhud_axis.vertAlign = "top";
	level.libhud_axis.alignX = "right";
	level.libhud_axis.x = -20;
	level.libhud_axis.y = 52;
	level.libhud_axis.font = "default";
	level.libhud_axis.fontscale = 1;
	level.libhud_axis.archived = false;
	level.libhud_axis.label = (&"MP_SLASH");
	level.libhud_axis setValue(level.old_axis);

	level.libhud_allies = newHudElem();
	level.libhud_allies.horzAlign = "right";
	level.libhud_allies.vertAlign = "top";
	level.libhud_allies.alignX = "right";
	level.libhud_allies.x = -20;
	level.libhud_allies.y = 30;
	level.libhud_allies.font = "default";
	level.libhud_allies.fontscale = 1;
	level.libhud_allies.archived = false;
	level.libhud_allies.label = (&"MP_SLASH");
	level.libhud_allies setValue(level.old_allies);

	level thread Maintain_Free_HUD();
}

Maintain_Free_HUD()
{
	level endon("ex_gameover");

	while(1)
	{
		level waittill("Update_Free_HUD");
		wait( [[level.ex_fpstime]](0.05) );

		thread Update_Free_HUD();
	}
}

Update_Free_HUD()
{
	if(isDefined(level.libhud_axis))
	{
		level.libhud_axis.x = getPosition(level.free_hud["axis"]);
		level.libhud_axis setValue(level.old_axis);
	}

	if(isDefined(level.libhud_allies))
	{
		level.libhud_allies.x = getPosition(level.free_hud["allies"]);
		level.libhud_allies setValue(level.old_allies);
	}

	if(isDefined(level.libhud_axisfree))
		level.libhud_axisfree setValue(level.free_hud["axis"]);

	if(isDefined(level.libhud_alliesfree))
		level.libhud_alliesfree setValue(level.free_hud["allies"]);
}

getPosition(free)
{
	offset = 0;
	if(free >= 10)
		offset += 11;

	return -20 + offset;
}

///door crap

lib_jails()
{
	//thread test();
	level.door_closed["axis"] = true;
	level.door_closed["allies"] = true;
	level.door_damage["axis"] = false;
	level.door_damage["allies"] = false;

	door_trigs = getentarray("door_trig","targetname");

	for(i = 0; i < door_trigs.size; i++)
	{
		if(!isdefined(door_trigs[i].script_noteworthy))
			door_trigs[i].script_noteworthy = "rot";

		switch(door_trigs[i].script_noteworthy)
		{
			case "alliesdoor":
				 door_trigs[i] thread allies_door_think();break;
				
			case "axisdoor":
				 door_trigs[i] thread axis_door_think();break;
		}
	}
}

addalliedplayerscore(trigger)
{
	if(level.door_closed["allies"]) iprintln(&"LIB_ALLIESFREED", [[level.ex_pname]](self));
}

addaxisplayerscore(trigger)
{
	if(level.door_closed["axis"]) iprintln(&"LIB_AXISFREED", [[level.ex_pname]](self));
}

allies_door_think()
{
	self.team = "allies";
	self setteamfortrigger("allies");

	while(1)
	{
		self waittill("trigger",other);

		if(level.door_closed["allies"])
		{					
			if(isPlayer(other))
				other thread addalliedplayerscore(self);
		}		

		door = getentarray(self.target,"targetname");

		for(i=0;i<door.size;i++)
		{
			if(!isdefined(door[i].script_start) || door[i].script_start == false)
			{
				if(self.script_noteworthy == "slide_nouse")
					self thread open_slide_door(door[i], "allies");
				else
				{
					if(other useButtonPressed())
						self thread open_slide_door(door[i], "allies");
				}
			}
		}
	}
}

axis_door_think()
{
	self.team = "axis";
	self setteamfortrigger("axis");

	while(1)
	{
		self waittill("trigger",other);

		if(level.door_closed["axis"])
		{					
			if(isPlayer(other))
				other thread addaxisplayerscore(self);
		}		

		door = getentarray(self.target,"targetname");

		for(i=0;i<door.size;i++)
		{
			if(!isdefined(door[i].script_start) || door[i].script_start == false)
			{
				if(self.script_noteworthy == "slide_nouse")
					self thread open_slide_door(door[i], "axis");
				else
				{
					if(other useButtonPressed())
						self thread open_slide_doors(door[i], "axis");
				}
			}
		}
	}
}

test()
{
	while(1)
	{
		wait( [[level.ex_fpstime]](0.5) );
		if(getCvar("test_open") != "")
		{
			door_switches = getentarray("door_switch","targetname");
			n=0;
			for(i = 0; i < door_switches.size; i++)
			{
				door_switch = door_switches[i];
				n++;

				if(door_switch.script_noteworthy == "alliesdoor")
					iprintln("Allies Switch Found");
				else if(door_switch.script_noteworthy == "axisdoor")
					iprintln("Axis Switch Found");
			}

			if(n==0)
				iprintln("No Door Switches");

			door_trigs = getentarray("door_trig","targetname");
			for(i = 0; i < door_trigs.size; i++)
			{
				if(door_trigs[i].script_noteworthy == "alliesdoor")
					door_trigs[i] thread test_door("allies");
				else if(door_trigs[i].script_noteworthy == "axisdoor")
					door_trigs[i] thread test_door("axis");
			}
			iprintln("^3Test script: Doors Opening");
			setcvar("test_open", "");
		}
	}
}

test_door(team)
{
	door = getentarray(self.target,"targetname");

	for(i=0;i<door.size;i++)
	{
		if(!isdefined(door[i].script_start) || door[i].script_start == false)
			self thread open_slide_door(door[i], team);

		//self thread detect_slide_touch(door[i],other);
	}
}

open_slide_door(door, team)
{
	door.script_start = true;
	open_sound1 = undefined;
	stop_sound = undefined;
	close_sound = undefined;
	alarm_sound = undefined;

	if(isdefined(door.script_noteworthy2) && (door.script_noteworthy2 == "locked"))
	{
		
		if(!isdefined(door.script_noteworthy))
			door.script_noteworthy = "wood";

		if(door.script_noteworthy == "wood")
			door playsound("wood_door_locked");
		else
			door playsound("metal_door_locked");

		door.script_start = false;
	}
	else
	{
		if(!isdefined(door.script_noteworthy))
			door.script_noteworthy = "wood";

		switch(door.script_noteworthy)
		{
			case "wood":
				open_sound1 = "wood_sliding_door";
				stop_sound = "wood_door_open_stop";
				close_sound = "wood_door_close_stop";
				break;
			case "metal":
				open_sound1 = "metal_door_sliding_openlib";
				stop_sound = "metal_door_sliding_close";
				close_sound = "metal_door_sliding_closelib";
				alarm_sound = "jail_alarmlib";
				break;
		}

		if(!isdefined(door.script_delay))
			door.script_delay = 10;

		open_move_timer = door.script_delay;

		script_org1 = getent(door.target,"targetname");

		script_org2 = getent(script_org1.target,"targetname");

		vec = (script_org1.origin - script_org2.origin);

		pos1 = door.origin;

		pos2 = (door.origin + vec);

		move_timer = 1.4;

		while(1)
		{
			start_time = gettime();

			if(move_timer < .01)
				move_timer = .01;

			level.door_closed[team] = false;

			if(door.script_noteworthy == "metal")
			{	
				door playsound(open_sound1);
				door playsound(alarm_sound);
			}

			door moveto(pos2, move_timer, 0, 0);

			door waittill("movedone");

			door moveto(door.origin,.01,0,0);

			end_time = gettime();

			time = ((end_time - start_time)/ 1000);

			move_timer -= time;

			if(move_timer < .01)
				move_timer = .01;

			if(door.origin == pos2)
				break;
			else
				door waittill("notouch"); // rotatedone sent by touch thread so wait
		}

		//door playsound (stop_sound);

		wait( [[level.ex_fpstime]](open_move_timer) );

		thread alliesdead();

		move_timer = 1.4;

		while(1)
		{
			start_time = gettime();

			if(move_timer < .01)
				move_timer = .01;

			if(move_timer < .2)
				level.door_damage["team"] = true;			

			if(door.script_noteworthy == "metal")
				door playsound(close_sound);

			door moveto(pos1, move_timer, 0, 0);

			door waittill("movedone");

			door moveto(door.origin,.01,0,0);

			end_time = gettime();

			time = ((end_time - start_time)/ 1000);

			move_timer -= time;

			if(move_timer < .01)
				move_timer = .01;

			if(door.origin == pos1)
				break;
			else
				door waittill("notouch"); // rotatedone sent by touch thread so wait
		}

		door notify("closed");

		level.door_closed[team] = true;
		level.door_damage["team"] = false;
		door.script_start = false;
	}
}

open_slide_doors(door, team)
{
	door.script_start = true;
	open_sound1 = undefined;
	stop_sound = undefined;
	close_sound = undefined;
	alarm_sound = undefined;

	if(isdefined(door.script_noteworthy2) && (door.script_noteworthy2 == "locked"))
	{
		if(!isdefined(door.script_noteworthy))
			door.script_noteworthy = "wood";

		if(door.script_noteworthy == "wood")
			door playsound("wood_door_locked");
		else
			door playsound("metal_door_locked");

		door.script_start = false;
	}
	else
	{
		if(!isdefined(door.script_noteworthy))
			door.script_noteworthy = "wood";

		switch(door.script_noteworthy)
		{
			case "wood":
				open_sound1 = "wood_sliding_door";
				stop_sound = "wood_door_open_stop";
				close_sound = "wood_door_close_stop";
				break;
			case "metal":
				open_sound1 = "metal_door_sliding_openlib";
				stop_sound = "metal_door_sliding_close";
				close_sound = "metal_door_sliding_closelib";
				alarm_sound = "jail_alarmlib";
				break;
		}

		if(!isdefined(door.script_delay))
			door.script_delay = 10;

		open_move_timer = door.script_delay;

		script_org1 = getent(door.target,"targetname");

		script_org2 = getent(script_org1.target,"targetname");

		vec = (script_org1.origin - script_org2.origin);

		pos1 = door.origin;

		pos2 = (door.origin + vec);

		move_timer = 1.4;

		while(1)
		{
			start_time = gettime();

			if(move_timer < .01)
				move_timer = .01;

			level.door_closed[team] = false;

			if(door.script_noteworthy == "metal")
			{	
				door playsound(open_sound1);
				door playsound(alarm_sound);
			}

			door moveto(pos2, move_timer, 0, 0);

			door waittill("movedone");

			door moveto(door.origin,.01,0,0);

			end_time = gettime();

			time = ((end_time - start_time)/ 1000);

			move_timer -= time;

			if(move_timer < .01)
				move_timer = .01;

			if(door.origin == pos2)
				break;
			else
				door waittill("notouch"); // rotatedone sent by touch thread so wait
		}

		//door playsound (stop_sound);

		wait( [[level.ex_fpstime]](open_move_timer) );
		
		//level.door_damage["axis"] = true;
		thread axisdead();
		move_timer = 1.4;

		while(1)
		{
			start_time = gettime();

			if(move_timer < .01)
				move_timer = .01;
		
			if(door.script_noteworthy == "metal")
				door playsound(close_sound);

			door moveto(pos1, move_timer, 0, 0);

			door waittill("movedone");

			//thread doaxisdamage(other);

			door moveto(door.origin,.01,0,0);

			end_time = gettime();

			time = ((end_time - start_time)/ 1000);

			move_timer -= time;

			if(move_timer < .01)
				move_timer = .01;
					
			if(door.origin == pos1)
				break;
			else
				door waittill("notouch"); // rotatedone sent by touch thread so wait
		}

		door notify("closed");

		level.door_closed[team] = true;
		//level.door_damage["axis"] = false;

		door.script_start = false;
	}
}

axisdead()
{
	wait( [[level.ex_fpstime]](1.2) );
	level.door_damage["axis"] = true;
	wait( [[level.ex_fpstime]](0.5) );
	level.door_damage["axis"] = false;
}

alliesdead()
{
	wait( [[level.ex_fpstime]](1.2) );
	level.door_damage["allies"] = true;
	wait( [[level.ex_fpstime]](0.5) );
	level.door_damage["allies"] = false;
}
