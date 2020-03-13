/*------------------------------------------------------------------------------
Capture the Flag Back - eXtreme+ mod compatible version
Version : 1.1
Author : La Truffe
Credits : Matthias (original CTFB in Admiral mod), Astoroth (eXtreme+ mod),
Ravir (cvardef function)
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

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflagmissing_allies = "objpoint_flagmissing_" + game["allies"];
	level.objpointflagmissing_axis = "objpoint_flagmissing_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	level.hudflagflash_allies = "hud_flagflash_" + game["allies"];
	level.hudflagflash_axis = "hud_flagflash_" + game["axis"];

	switch(game["allies"])
	{
		case "american":
			game["flag_taken"] = "US_mp_flagtaken";
			break;
		case "british":
			game["flag_taken"] = "UK_mp_flagtaken";
			break;
		case "russian":
			game["flag_taken"] = "RU_mp_flagtaken";
			break;
	}

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
			precacheStatusIcon(level.hudflag_allies);
			precacheStatusIcon(level.hudflag_axis);
		}
		precacheShader(level.compassflag_allies);
		precacheShader(level.compassflag_axis);
		precacheShader(level.objpointflag_allies);
		precacheShader(level.objpointflag_axis);
		precacheShader(level.hudflag_allies);
		precacheShader(level.hudflag_axis);
		precacheShader(level.hudflagflash_allies);
		precacheShader(level.hudflagflash_axis);
		precacheShader(level.objpointflag_allies);
		precacheShader(level.objpointflag_axis);
		precacheShader(level.objpointflagmissing_allies);
		precacheShader(level.objpointflagmissing_axis);
		precacheModel("xmodel/prop_flag_" + game["allies"]);
		precacheModel("xmodel/prop_flag_" + game["axis"]);
		precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
		precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
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

	if(level.random_flag_position)
	{
		spawnpointname = "mp_dm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();
	}

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];

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

		if(!isdefined(self.pers["skipserverinfo"]))
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
	self dropFlag();
	self dropOwnFlag();

	self extreme\_ex_clientcontrol::explayerdisconnect();

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies")
			setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis")
			setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator")
			setplayerteamrank(self, 2, 0);
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

	if(self.sessionteam == "spectator") return;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill

	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	flagrunner_enemy = false;
	if(isdefined(self.flag))
	{
		flagrunner_enemy = true;
		self dropFlag();
	}

	flagrunner_own = false;
	if(isdefined(self.ownflag))
	{
		flagrunner_own = true;
		self dropOwnFlag();
	}

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

			if(flagrunner_enemy) reward_points += level.ex_ctfbpoints_playerkfe;
			if(flagrunner_own) reward_points += level.ex_ctfbpoints_playerkfo;

			points = level.ex_points_kill + reward_points;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker.score -= points;
					else attacker.score -= level.ex_points_kill;
			}
			else
			{
				if(level.flagprotectiondistance) points += attacker checkProtectedOwnFlag(self.origin);
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

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

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
	
	if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
		else spawnpointname = "mp_ctf_spawn_axis";

	if(level.random_flag_position) spawnpointname = "mp_dm_spawn";

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

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(level.scorelimit > 0) self setClientCvar("cg_objectiveText", &"MP_CTFB_OBJ_TEXT", level.scorelimit);
		else self setClientCvar("cg_objectiveText", &"MP_CTFB_OBJ_TEXT_NOSCORE");

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
	if(level.timelimit > 0)
	{
		extreme\_ex_gtcommon::createClock();
		level.clock setTimer(level.timelimit * 60);
	}

	for(;;)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = &"MP_THE_GAME_IS_A_TIE";
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
		timelimit = getCvarFloat("scr_ctfb_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ctfb_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_ctfb_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

initFlags()
{
	maperrors = [];

	allied_flags = getentarray("allied_flag", "targetname");
	if(allied_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"allied_flag\"";
	else if(allied_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"allied_flag\"";

	axis_flags = getentarray("axis_flag", "targetname");
	if(axis_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"axis_flag\"";
	else if(axis_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"axis_flag\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	allied_flag = getent("allied_flag", "targetname");
	axis_flag = getent("axis_flag", "targetname");

	if(level.random_flag_position)
	{
		spawnpoints = getentarray("mp_dm_spawn", "classname");
		
		allied_flag.origin = (0,0,0);
		axis_flag.origin = (0,0,0);
		
		trys = 0;
		while((distance(allied_flag.origin, axis_flag.origin) < 2200) || (allied_flag.origin == axis_flag.origin))
		{
			j = randomInt(spawnpoints.size);
			allied_flag = spawnpoints[j];
		
			j = randomInt(spawnpoints.size);
			axis_flag = spawnpoints[j];
	
			trys ++;

			if(trys > 50)
				break;
		}
	}
	
	if((distance(axis_flag.origin, allied_flag.origin) < 2000) || (allied_flag.origin == axis_flag.origin))
	{
		allied_flag = getent("allied_flag", "targetname");
		axis_flag = getent("axis_flag", "targetname");
	}

	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
	allied_flag.basemodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.basemodel.angles = allied_flag.home_angles;
	allied_flag.basemodel setmodel("xmodel/prop_flag_base");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;
	allied_flag.objpointflag = level.objpointflag_allies;
	allied_flag.objpointflagmissing = level.objpointflagmissing_allies;

	allied_flag thread flag();

	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
	axis_flag.basemodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.basemodel.angles = axis_flag.home_angles;
	axis_flag.basemodel setmodel("xmodel/prop_flag_base");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;
	axis_flag.objpointflag = level.objpointflag_axis;
	axis_flag.objpointflagmissing = level.objpointflagmissing_axis;

	axis_flag thread flag();

	level.flags	= [];
	level.flags["allies"] = allied_flag;
	level.flags["axis"] = axis_flag;
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self createFlagWaypoint();

	for(;;)
	{
		if(level.random_flag_position)
		{
			other = undefined;
			other = self checkFlag();
		}
		else
		{
			self waittill("trigger", other);
		}

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if(isdefined(other.flag) && (other.pers["team"] != other.flag.team)) // Captured flag
					{
						friendlyAlias = "ctf_touchcapture";
						enemyAlias = "ctf_enemy_touchcapture";

						if(self.team == "axis")
						{
							enemy = "allies";
							if((level.ex_flag_voiceover & 2) == 2) level thread playSoundOnPlayers("GE_mp_flagcap");
						}
						else
						{
							enemy = "axis";
							if((level.ex_flag_voiceover & 2) == 2) level thread playSoundOnPlayers("mp_announcer_axisflagcap");
						}

						level thread playSoundOnPlayers(friendlyAlias, self.team);
						level thread playSoundOnPlayers(enemyAlias, enemy);

						thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_CAPTURED", self.team, other);
						thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_CAPTURED", enemy, other);

						other.flag returnFlag();
						other detachFlag(other.flag);
						other.flag = undefined;
						other.statusicon = "";

						other.score += level.ex_ctfbpoints_playercf;
						if(level.ex_ranksystem) other.pers["special"] += level.ex_ctfbpoints_playercf;
						// added for arcade style HUD points
						other notify("update_playerscore_hud");

						other.pers["flagcap"]++;
						if(level.ex_statshud) other thread extreme\_ex_statshud::showStatsHUD();

						teamscore = getTeamScore(other.pers["team"]);
						teamscore += level.ex_ctfbpoints_teamcf;
						setTeamScore(other.pers["team"], teamscore);
						level notify("update_teamscore_hud");

						lpselfnum = other getEntityNumber();
						lpselfguid = other getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_captured" + "\n");

						checkScoreLimit();
					}
				}
				else // Picked up own flag
				{
					level thread playSoundOnPlayers("ctf_touchown", self.team);
					thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_PICKED_UP", self.team, other);

					if(self.team == "axis")
						enemy = "allies";
					else
						enemy = "axis";

					other pickupOwnFlag(self);
					other thread checkBaseHomeOwnFlag(self);
					if(level.ex_flag_drop) level thread dropflagUntagEnemy(enemy);

					if(!isDefined(other.ownflagDropped))
					{
						other.score += level.ex_ctfbpoints_playerpf;
						if(level.ex_ranksystem) other.pers["special"] += level.ex_ctfbpoints_playerpf;
						other notify("update_playerscore_hud");
					}

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_pickup_own" + "\n");
				}
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				friendlyAlias = "ctf_touchenemy";
				enemyAlias = "ctf_enemy_touchenemy";

				if(self.team == "axis")
					enemy = "allies";
				else
					enemy = "axis";

				level thread playSoundOnPlayers(friendlyAlias, self.team);
				level thread playSoundOnPlayers(enemyAlias, enemy);
				if(level.ex_flag_drop) level thread dropflagUntagOwn(self.team);

				thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_TAKEN", self.team, other);
				thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_TAKEN", enemy, other);

				if(self.atbase) // Stolen flag
				{
					if((level.ex_flag_voiceover & 1) == 1)
					{
						if(self.team == "axis")
							level thread playSoundOnPlayers(game["flag_taken"]);
						else
							level thread playSoundOnPlayers("GE_mp_flagtaken");
					}

					other.score += level.ex_ctfbpoints_playersf;
					if(level.ex_ranksystem) other.pers["special"] += level.ex_ctfbpoints_playersf;
					other notify("update_playerscore_hud");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_take" + "\n");
				}
				else // Picked up flag
				{
					if(!isDefined(other.enemyflagDropped))
					{
						other.score += level.ex_ctfbpoints_playertf;
						if(level.ex_ranksystem) other.pers["special"] += level.ex_ctfbpoints_playertf;
						other notify("update_playerscore_hud");
					}

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_pickup" + "\n");
				}

				other pickupFlag(self);
			}
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

checkFlag()
{
	self notify("checkFlag");
	self endon("checkFlag");

	other = undefined;

	while(isDefined(self) && !isDefined(other))
	{
		wait( [[level.ex_fpstime]](0.2) );

		players = level.players;

		for(i = 0; i < players.size; i++)
		{
			if(isDefined(self) && players[i].sessionstate == "playing" && distance(self.origin,players[i].origin) < 65)
				return players[i];				
		}		
	}	
}

checkBaseHomeOwnFlag(flag)
{
	self endon("disconnect");
	self endon("killed_player");

	self notify("checkBase");
	self endon("checkBase");

	while(isDefined(flag))
	{
		wait( [[level.ex_fpstime]](0.3) );

		if(isDefined(flag) && (self.sessionstate == "playing") && (distance(flag.basemodel.origin, self.origin) < 50))
		{
			// Returned flag
			if((level.ex_flag_voiceover & 4) == 4)
			{
				if(flag.team == "axis")
					level thread playSoundOnPlayers("mp_announcer_axisflagret");
				else
					level thread playSoundOnPlayers("mp_announcer_alliedflagret");
			}

			level thread playSoundOnPlayers("ctf_touchown", flag.team);
			thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_RETURNED", flag.team, self);

			flag returnFlag();
			self detachOwnFlag(flag);
			self.ownflag = undefined; 
			self.statusicon = "";			
			
			self.pers["flagret"]++;
			self.score += level.ex_ctfbpoints_playerrf;
			if(level.ex_ranksystem) self.pers["special"] += level.ex_ctfbpoints_playerrf;
			// added for arcade style HUD points
			self notify("update_playerscore_hud");
			level notify("update_teamscore_hud");

			lpselfnum = self getEntityNumber();
			lpselfguid = self getGuid();
			logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.pers["team"] + ";" + self.name + ";" + "ctfb_returned" + "\n");

			break;
		}
	}	
}

pickupFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;

	flag.carrier = self;

	if(!isdefined(self.ownflag))
	{
		if(self.pers["team"] == "allies" && !level.ex_rank_statusicons)
			self.statusicon = level.hudflag_axis;
		else if(self.pers["team"] == "axis" && !level.ex_rank_statusicons)
			self.statusicon = level.hudflag_allies;
	}
	else self thread BlinkFlags();

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();
	flag createFlagMissingWaypoint();

	objective_onEntity(flag.objective, self);
	objective_team(flag.objective, self.pers["team"]);

	self attachFlag();

	self thread showFlag_afterTime(flag);
}

pickupOwnFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.ownflag = flag;
	
	flag.carrier = self;

	if(!isdefined(self.flag))
	{
		if(self.pers["team"] == "allies" && !level.ex_rank_statusicons)
			self.statusicon = level.hudflag_allies;
		else if(self.pers["team"] == "axis" && !level.ex_rank_statusicons)
			self.statusicon = level.hudflag_axis;
	}
	else self thread BlinkFlags();

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();

	//flag createFlagMissingWaypoint();

	objective_onEntity(flag.objective, self);
	objective_team(flag.objective, self.pers["team"]);

	self attachOwnFlag();
	
	self thread showFlag_afterTime(flag);
}

dropFlag(dropspot)
{
	if(isdefined(self.flag))
	{
		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
		  else start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"] + (randomint(20), randomint(20), 0);
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;

		self.flag.carrier = undefined;

		objective_position(self.flag.objective, self.flag.origin);
		objective_team(self.flag.objective, "none");

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag returnFlag();
				break;
			}
		}

		if((level.ex_flag_voiceover & 8) == 8)
		{
			if(self.flag.team == "axis")
				level thread playSoundOnPlayers("mp_announcer_axisflagdrop");
			else
				level thread playSoundOnPlayers("mp_announcer_alliedflagdrop");
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

dropOwnFlag(dropspot)
{
	if(isdefined(self.ownflag))
	{
		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
		  else start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.ownflag.origin = trace["position"] + (randomint(20),randomint(20),0);
		self.ownflag.flagmodel.origin = self.ownflag.origin;
		self.ownflag.flagmodel show();
		self.ownflag.atbase = false;

		self.ownflag.carrier = undefined;

		objective_position(self.ownflag.objective, self.ownflag.origin);
		objective_team(self.ownflag.objective, "none");

		self.ownflag createFlagWaypoint();

		self.ownflag thread autoReturn();
		self detachOwnFlag(self.ownflag);

		// check if it's in a flag returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.ownflag.flagmodel istouching(level.flag_returners[i]))
			{
				self.ownflag returnFlag();
				break;
			}
		}

		self.ownflag = undefined;
		self.dont_auto_balance = undefined;
	}
}

showFlag_afterTime(flag)
{
	if(!level.show_enemy_own_flag) return;

	self endon("disconnect");
	self endon("killed_player");
	
	flag endon("end_autoreturn");

	flag_after_sec = level.show_enemy_own_flag_after_sec;
	flag_time = level.show_enemy_own_flag_time;

	for(;;)
	{
		wait( [[level.ex_fpstime]](flag_after_sec) );
	
		objective_onEntity(flag.objective, self);
		objective_team(flag.objective, "none");
		
		wait( [[level.ex_fpstime]](flag_time) );
		
		objective_onEntity(flag.objective, self);
		objective_team(flag.objective, self.pers["team"]);
	}
}

returnFlag()
{
	self notify("end_autoreturn");

	if(level.ex_flag_drop)
	{
		if(self.team == "axis") enemy = "allies";
			else enemy = "axis";
		level thread dropflagUntag(enemy);
	}

	self.origin = self.home_origin;
	self.flagmodel.origin = self.home_origin;
	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	self.carrier = undefined;

	objective_position(self.objective, self.origin);
	objective_team(self.objective, "none");

	self createFlagWaypoint();
	self deleteFlagMissingWaypoint();
}

autoReturn()
{
	level endon("ex_gameover");
	self endon("end_autoreturn");

	wait( [[level.ex_fpstime]](level.flagautoreturndelay) );

	if(level.ex_gameover) announce_return = false;
		else announce_return = true;

	if(announce_return)
	{
		if(self.team == "axis")
		{
			level thread playSoundOnPlayers("mp_announcer_axisflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_DOWNTEAM");
		}
		else
		{
			level thread playSoundOnPlayers("mp_announcer_alliedflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_UPTEAM");
		}
	}

	self thread returnFlag();
}

attachFlag()
{
	self endon("disconnect");

	if(isdefined(self.enemyflagAttached))
		return;

	if(self.pers["team"] == "allies")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach(flagModel, "J_Spine4", true);
	self.enemyflagAttached = true;
	self.flagAttached = true;
	
	self thread createHudIcon();
	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

attachOwnFlag()
{
	self endon("disconnect");

	if(isdefined(self.ownflagAttached))
		return;

	if(self.pers["team"] == "axis")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach( flagModel, "J_Spine2", true);
	self.ownflagAttached = true;
	self.flagAttached = true;
	
	self thread createOwnHudIconOwn();
	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

detachFlag(flag)
{
	self endon("disconnect");

	if(!isdefined(self.enemyflagAttached))
		return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		
	self detach(flagModel, "J_Spine4");
	self.enemyflagAttached = undefined;

	if(!isdefined(self.ownflagAttached))
		self.flagAttached = undefined;
	
	self thread deleteHudIcon();
}

detachOwnFlag(flag)
{
	self endon("disconnect");

	if(!isdefined(self.ownflagAttached))
		return;

	if(self.pers["team"] == "axis")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		
	self detach(flagModel, "J_Spine2");
	self.ownflagAttached = undefined;

	if(!isdefined(self.enemyflagAttached))
		self.flagAttached = undefined;

	self thread deleteOwnHudIcon();
}

dropFlagMonitor()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.dropmonRunning)) return;
	self.dropmonRunning = true;

	while(isAlive(self) && (isDefined(self.ownflagAttached) || isDefined(self.enemyflagAttached)) )
	{
		if(self useButtonPressed() && self meleeButtonPressed())
		{
			dropspot = self getDropSpot(100);
			if(isDefined(dropspot))
			{
				if(isDefined(self.enemyflagAttached))
				{
					self.enemyflagDropped = true;
					self dropFlag(dropspot);
					if(!isDefined(self.ownflagAttached)) break;
						else while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
				}
				else if(isDefined(self.ownflagAttached))
				{
					self.ownflagDropped = true;
					self dropOwnFlag(dropspot);
					break;
				}
			}
		}
		wait( [[level.ex_fpstime]](0.05) );
	}

	self.dropmonRunning = undefined;
}

dropflagUntag(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			{
				players[i].ownflagDropped = undefined;
				players[i].enemyflagDropped = undefined;
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
		{
			players[i].ownflagDropped = undefined;
			players[i].enemyflagDropped = undefined;
		}
	}
}

dropflagUntagEnemy(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i].enemyflagDropped = undefined;
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i].enemyflagDropped = undefined;
	}
}

dropflagUntagOwn(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i].ownflagDropped = undefined;
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i].ownflagDropped = undefined;
	}
}

getDropSpot(radius)
{
	origin = self.origin + (0, 0, 20);
	dropspot = undefined;

	// scan 360 degrees in 20 degree increments for good spot to drop flag
	for(i = 0; i < 360; i += 20)
	{
		// locate candidate spot in circle
		spot0 = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), radius);
		trace = bulletTrace(origin, spot0, false, undefined);
		spot1 = trace["position"];
		dist1 = int(distance(origin, spot1) + 0.5);
		if(dist1 != radius) continue;

		// check if this spot is in minefield (unfortunately needs entity to check)
		badspot = false;
		model1 = spawn("script_model", spot1);
		model1 setmodel("xmodel/tag_origin");
		for(j = 0; j < level.flag_returners.size; j++)
		{
			if(model1 istouching(level.flag_returners[j]))
			{
				badspot = true;
				break;
			}
		}
		model1 delete();
		if(badspot) continue;

		// find ground level
		trace = bulletTrace(spot1, spot1 + (0, 0, -2000), false, undefined);
		spot2 = trace["position"];
		dist2 = int(distance(spot1, spot2) + 0.5);

		// make sure path is clear 50 units up
		trace = bulletTrace(spot2, spot2 + (0, 0, 50), false, undefined);
		spot3 = trace["position"];
		dist3 = int(distance(spot2, spot3) + 0.5);
		if(dist3 != 50) continue;

		dropspot = spot2;
		break;
	}

	return dropspot;
}

createHudIcon()
{
	iconSize = 40;

	self.hud_flag = newClientHudElem(self);
	self.hud_flag.x = 30;
	self.hud_flag.y = 95;
	self.hud_flag.alignX = "center";
	self.hud_flag.alignY = "middle";
	self.hud_flag.horzAlign = "left";
	self.hud_flag.vertAlign = "top";
	self.hud_flag.alpha = 0;

	self.hud_flagflash = newClientHudElem(self);
	self.hud_flagflash.x = 30;
	self.hud_flagflash.y = 95;
	self.hud_flagflash.alignX = "center";
	self.hud_flagflash.alignY = "middle";
	self.hud_flagflash.horzAlign = "left";
	self.hud_flagflash.vertAlign = "top";
	self.hud_flagflash.alpha = 0;
	self.hud_flagflash.sort = 1;

	if(self.pers["team"] == "allies")
	{
		self.hud_flag setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "axis");
		self.hud_flag setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagflash fadeOverTime(.2);
	self.hud_flagflash.alpha = 1;

	self.hud_flag fadeOverTime(.2);
	self.hud_flag.alpha = 1;

	wait( [[level.ex_fpstime]](0.2) );
	
	if(isdefined(self.hud_flagflash))
	{
		self.hud_flagflash fadeOverTime(1);
		self.hud_flagflash.alpha = 0;
	}
}

createHudIconOwn()
{
	iconSize = 40;

	self.hud_flag = newClientHudElem(self);
	self.hud_flag.x = 30;
	self.hud_flag.y = 95;
	self.hud_flag.alignX = "center";
	self.hud_flag.alignY = "middle";
	self.hud_flag.horzAlign = "left";
	self.hud_flag.vertAlign = "top";
	self.hud_flag.alpha = 0;

	self.hud_flagflash = newClientHudElem(self);
	self.hud_flagflash.x = 30;
	self.hud_flagflash.y = 95;
	self.hud_flagflash.alignX = "center";
	self.hud_flagflash.alignY = "middle";
	self.hud_flagflash.horzAlign = "left";
	self.hud_flagflash.vertAlign = "top";
	self.hud_flagflash.alpha = 0;
	self.hud_flagflash.sort = 1;

	if(self.pers["team"] == "axis")
	{
		self.hud_flag setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "allies");
		self.hud_flag setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagflash fadeOverTime(.2);
	self.hud_flagflash.alpha = 1;

	self.hud_flag fadeOverTime(.2);
	self.hud_flag.alpha = 1;

	wait( [[level.ex_fpstime]](0.2) );
	
	if(isdefined(self.hud_flagflash))
	{
		self.hud_flagflash fadeOverTime(1);
		self.hud_flagflash.alpha = 0;
	}
}

createOwnHudIconOwn()
{
	iconSize = 40;

	self.hud_flagown = newClientHudElem(self);
	self.hud_flagown.x = 30;
	self.hud_flagown.y = 135;
	self.hud_flagown.alignX = "center";
	self.hud_flagown.alignY = "middle";
	self.hud_flagown.horzAlign = "left";
	self.hud_flagown.vertAlign = "top";
	self.hud_flagown.alpha = 0;

	self.hud_flagownflash = newClientHudElem(self);
	self.hud_flagownflash.x = 30;
	self.hud_flagownflash.y = 135;
	self.hud_flagownflash.alignX = "center";
	self.hud_flagownflash.alignY = "middle";
	self.hud_flagownflash.horzAlign = "left";
	self.hud_flagownflash.vertAlign = "top";
	self.hud_flagownflash.alpha = 0;
	self.hud_flagownflash.sort = 1;

	if(self.pers["team"] == "axis")
	{
		self.hud_flagown setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagownflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "allies");
		self.hud_flagown setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagownflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagownflash fadeOverTime(.2);
	self.hud_flagownflash.alpha = 1;

	self.hud_flagown fadeOverTime(.2);
	self.hud_flagown.alpha = 1;

	wait( [[level.ex_fpstime]](0.2) );
	
	if(isdefined(self.hud_flagownflash))
	{
		self.hud_flagownflash fadeOverTime(1);
		self.hud_flagownflash.alpha = 0;
	}
}

deleteHudIcon()
{
	if(isdefined(self.hud_flagflash))
		self.hud_flagflash destroy();
		
	if(isdefined(self.hud_flag))
		self.hud_flag destroy();
}

deleteOwnHudIcon()
{
	if(isdefined(self.hud_flagownflash))
		self.hud_flagownflash destroy();
		
	if(isdefined(self.hud_flagown))
		self.hud_flagown destroy();
}

createFlagWaypoint()
{
	if(!level.ex_objindicator)
		return;

	self deleteFlagWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.origin[0];
	waypoint.y = self.origin[1];
	waypoint.z = self.origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;
	waypoint setShader(self.objpointflag, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint_flag = waypoint;
}

deleteFlagWaypoint()
{
	if(isdefined(self.waypoint_flag))
		self.waypoint_flag destroy();
}

createFlagMissingWaypoint()
{
	if(!level.ex_objindicator)
		return;

	self deleteFlagMissingWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.home_origin[0];
	waypoint.y = self.home_origin[1];
	waypoint.z = self.home_origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;
	waypoint setShader(self.objpointflagmissing, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint_base = waypoint;
}

deleteFlagMissingWaypoint()
{
	if(isdefined(self.waypoint_base))
		self.waypoint_base destroy();
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

BlinkFlags()
{
	self endon("disconnect");
	
	while(isdefined(self.flag) && isdefined(self.ownflag) && !level.ex_rank_statusicons)
	{
		if(self.statusicon == level.hudflag_allies)
			self.statusicon = level.hudflag_axis;
		else
			self.statusicon = level.hudflag_allies;

		wait( [[level.ex_fpstime]](2) );
	}
}

checkProtectedOwnFlag(victim_origin)
{
	// called from Callback_PlayerKilled(). "self" is attacker!

	// check if attacker is still playing
	if(self.pers["team"] == "spectator") return(0);

	flag = level.flags[self.pers["team"]];
	if(!isdefined(flag)) return(0);

	// is flag being carried?
	if(isdefined(flag.carrier))
	{
		// no "self-assistance"
		if(flag.carrier == self) return(0);
			
		// no assistance for enemy carrier
		if(flag.carrier.pers["team"] != self.pers["team"]) return(0);

		dist = distance(victim_origin, flag.carrier.origin);
		if(dist <= level.flagprotectiondistance)
		{
			lpselfnum = self getEntityNumber();
			lpselfguid = self getGuid();
			logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.pers["team"] + ";" + self.name + ";" + "ctfb_assist" + "\n");
			iprintln(&"MP_CTFB_ASSIST", [[level.ex_pname]](self));
			return(level.ex_ctfbpoints_assist);
		}
	}
	// flag is at base, or was dropped
	else
	{
		if(flag.atbase) dist = distance(victim_origin, flag.home_origin);
			else dist = distance(victim_origin, flag.origin);

		if(dist <= level.flagprotectiondistance)
		{
			lpselfnum = self getEntityNumber();
			lpselfguid = self getGuid();
			logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.pers["team"] + ";" + self.name + ";" + "ctfb_defend" + "\n");
			iprintln(&"MP_CTFB_DEFEND", [[level.ex_pname]](self));
			return(level.ex_ctfbpoints_defend);
		}
	}

	return(0);
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

printOnTeam(text, team, player)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text, [[level.ex_pname]](player));
	}
}
