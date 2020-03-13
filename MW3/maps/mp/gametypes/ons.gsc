/*------------------------------------------------------------------------------
On Slaught
AdmiralMOD by Matthias Lorenz, http://www.cod2mod.com
Additions and Standalone Version: La Tuffe (nedgerblansky), Tally, & Oddball
credits: some script in here was originally coded by Pointy
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
	level.compassflag_empty = "gfx/custom/objective_empty.tga";
	
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflag_empty = "gfx/custom/objpoint_empty.tga";

	level.hudicon_empty = "gfx/custom/headicon_empty.tga";

	//Setup the hud icons and team specific stuff
	switch(game["allies"])
	{
		case "american":
			game["allies_area_secured"] = "US_area_secured";
			game["allies_ground_taken"] = "US_ground_taken";
			game["allies_losing_ground"] = "US_losing_ground";
			break;
		case "british":
			game["allies_area_secured"] = "UK_area_secured";
			game["allies_ground_taken"] = "UK_ground_taken";
			game["allies_losing_ground"] = "UK_losing_ground";
			break;
		case "russian":
			game["allies_area_secured"] = "RU_area_secured";
			game["allies_ground_taken"] = "RU_ground_taken";
			game["allies_losing_ground"] = "RU_losing_ground";
			break;
	}

	switch(game["axis"])
	{
		case "german":
			game["german_area_secured"] = "GE_area_secured";
			game["german_ground_taken"] = "GE_ground_taken";
			game["german_losing_ground"] = "GE_losing_ground";
			break;
	}

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
		}
		precacheShader(level.compassflag_empty);
		precacheShader(level.compassflag_allies);
		precacheShader(level.compassflag_axis);
		precacheShader(level.objpointflag_allies);
		precacheShader(level.objpointflag_axis);
		precacheShader(level.objpointflag_empty);
		precacheShader(level.hudicon_empty);
		precacheShader("gfx/custom/flagge_german.tga");
		precacheShader("gfx/custom/flagge_" + game["allies"] + ".tga");
		precacheModel("xmodel/prop_flag_" + game["allies"]);
		precacheModel("xmodel/prop_flag_" + game["axis"]);
		precacheModel("xmodel/fahne");
		precacheModel("xmodel/prop_flag_base");
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

	// if Spawn Type defined
	if(!isdefined(level.spawntype) || !(isSpawnTypeCorrect(level.spawntype)))
		level.spawntype = "dm";

	level.spawn_allies = getSpawnTypeAllies(level.spawntype);
	level.spawn_axis = getSpawnTypeAxis(level.spawntype);

	setSpawnPoints(level.spawn_allies);
	if(level.spawn_allies != level.spawn_axis) //For "sd" or "ctf"
		setSpawnPoints(level.spawn_axis);

	allowed[0] = "ctf"; // KEEP IT THIS WAY
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.roundstarted = false;
	level.roundended = false;
	level.winning_team = "draw";

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	if(!isDefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	if(!isDefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["state"])) game["state"] = "waiting";

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

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams) && !level.roundended && level.roundstarted)
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
			
			// Only handle points if game has started and has not ended
			if(!level.roundended && level.roundstarted)
			{
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
						attacker.pers["score"]--;
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

	if(level.roundended) return;

	if(isDefined(self.switching_teams))
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

	// Handle ready-up spawn tickets
	if(level.ex_readyup == 2 && isDefined(game["readyup_done"]))
	{
		if(!isDefined(self.pers["readyup_spawnticket"]))
		{
			if(level.ex_readyup_status == 2 && level.ex_readyup_ticketing == 1)
				self.pers["readyup_spawnticket"] = 1;
			else if(level.ex_readyup_status == 3)
				self.pers["readyup_spawnticket"] = 1;
			else
			{
				self extreme\_ex_readyup::moveToSpectators();
				if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
				self extreme\_ex_readyup::waitForNextRound();
				return;
			}
		}
	}

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

	if(self.pers["team"] == "allies") spawnpointname = level.spawn_allies;
		else spawnpointname = level.spawn_axis;
		
	spawnpoints = getentarray(spawnpointname, "classname");

	// Find a spawn point away from the flags
	spawnpoint = undefined;
	for(i = 0; i < 5; i ++)
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
		if(spawnpoint IsAwayFromFlags(level.spawndistance)) break;
	}

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

	if(!isDefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isDefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"MP_DOM_OBJ_TEXT_NOSCORE");

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
		level.clock setTimer(level.roundlength * 60);
	}

	thread startRound();

	for(;;)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

startRound()
{
	game["roundnumber"]++;
	level.roundstarted = true;
	game["state"] = "playing";

	wait( [[level.ex_fpstime]](level.roundlength * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");
	level thread endRound();
}

endRound()
{
	level.roundended = true;
	game["roundsplayed"]++;

	if(level.winning_team == "allies")
	{
		text = &"MP_ALLIES_WIN_ROUND";
		winner = "allies";
		loser = "axis";
	}
	else if(level.winning_team == "axis")
	{
		text = &"MP_AXIS_WIN_ROUND";
		winner = "axis";
		loser = "allies";
	}
	else
	{
		text = &"MP_THE_ROUND_IS_A_TIE";
		winner = "draw";
		loser = "draw";
	}

	iprintlnbold(text);
	announceWinner(winner, true);

	if(game["roundsplayed"] < level.roundlimit)
	{
		// do endround delay
		wait( [[level.ex_fpstime]](level.cooldowntime) );

		// announce next round
		iprintlnbold(&"MP_DOM_START_NEXT_ROUND");
		wait( [[level.ex_fpstime]](2) );

		// reset player vars
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			player.pers["rank"] = 1;
			if(level.ex_readyup == 2) player.pers["readyup_spawnticket"] = 1;
		}

		// restart the map
		level notify("restarting");
		map_restart(true);
	}
	else
	{
		// end the map
		level thread endMap();
	}
}

endMap()
{
	level.mapended = true;
	level notify("end_map");

	if(isDefined(level.clock))
		level.clock destroy();

	if(game["alliedscore"] > game["axisscore"])
	{
		text = &"MP_ALLIES_WIN";
		winner = "allies";
		loser = "axis";
	}
	else if(game["axisscore"] > game["alliedscore"])
	{
		text = &"MP_AXIS_WIN";
		winner = "axis";
		loser = "allies";
	}
	else
	{
		text = &"MP_THE_GAME_IS_A_TIE";
		winner = "draw";
		loser = "draw";
	}

	iprintlnbold(text);
	announceWinner(winner, false);

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	winners = "";
	losers = "";
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if((winner == "allies") || (winner == "axis"))
		{
			lpselfguid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winner))
				winners = (winners + ";" + lpselfguid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == loser))
				losers = (losers + ";" + lpselfguid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();
		player setClientCvar("cg_objectiveText", text);
		player extreme\_ex_spawn::spawnIntermission();

		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	if((winner == "allies") || (winner == "axis"))
	{
		logPrint("W;" + winner + winners + "\n");
		logPrint("L;" + loser + losers + "\n");
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

announceWinner(winner, doscore)
{
	if(winner == "allies")
	{
		if(doscore)
		{
			game["alliedscore"]++;
			setTeamScore("allies", game["alliedscore"]);
			level notify("update_teamscore_hud");
		}

		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_" + game["allies"] + ".tga",128,128,1,0.9,1,1,1);
	}

	if(winner == "axis")
	{
		if(doscore)
		{
			game["axisscore"]++;
			setTeamScore("axis", game["axisscore"]);
			level notify("update_teamscore_hud");
		}

		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_german.tga",128,128,1,0.9,1,1,1);
	}

	if(winner == "allies") level thread playSoundOnPlayers("MP_announcer_allies_win");
		else if(winner == "axis") level thread playSoundOnPlayers("MP_announcer_axis_win");
			else level thread playSoundOnPlayers("MP_announcer_round_draw");

	wait( [[level.ex_fpstime]](4) );
	level deleteLevelHudElementByName("flag_winner");
}

checkTimeLimit()
{
	if(level.timelimit <= 0) return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < level.timelimit) return;

	if(level.mapended) return;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkRoundLimit()
{
	if(level.roundlimit <= 0) return;

	if(game["roundsplayed"] < level.roundlimit) return;

	if(level.mapended) return;

	iprintln(&"MP_ROUND_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getCvarFloat("scr_ons_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ons_timelimit", "1440");
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

		roundlimit = getCvarInt("scr_ons_roundlimit");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
			setCvar("ui_roundlimit", level.roundlimit);

			checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

initFlags()
{
	level.hud_ons_pos_y = 30;
	level.flag_radius 	= 80;
	
	if(isdefined(level.flags))
	{
		flags = level.flags;
	}
	else
	{
		flags = [];

		spawnpoints = getentarray("mp_dm_spawn", "classname");

		j = randomInt(spawnpoints.size);

		flags[0] = spawnpoints[j];	
		//logprint("Flag "+flags.size+ " : " + spawnpoints[j].origin + "\n");

		if(level.flagsnumber > 0)
			// Fixed number of flags
			flagsnumber = level.flagsnumber;
		else
		{
			// Variable number of flags, depending on the number of players
			players = level.players;
			flagsnumber = players.size / 2 + 1;
			if(flagsnumber < 2)
				flagsnumber = 2;
			if(flagsnumber > 7)
				flagsnumber = 7;
		}

		trys = 0;

		while(flags.size < flagsnumber) 
		{
			trys++;
			if(trys > 100) break;

			j = randomInt(spawnpoints.size);

			near = false;

			for(i=0;i<flags.size;i++) 
			{
				if(distance(spawnpoints[j].origin,flags[i].origin) < 1000) 
				{
					near = true;
					break;
				}
			}

			if(near == true) continue;

			flags[flags.size] = spawnpoints[j];
		}

		level.flags = flags;
	}

	for(i = 0; i < flags.size; i++)
	{
		team = "none";
		flags[i] placeSpawnpoint();

		flags[i].flagmodel = spawn("script_model", flags[i].origin);
		flags[i].flagmodel.angles = flags[i].angles;
		flags[i].flagmodel setmodel("xmodel/fahne");

		flags[i].basemodel = spawn("script_model", flags[i].origin);
		flags[i].basemodel.angles = flags[i].angles;
		flags[i].basemodel setmodel("xmodel/prop_flag_base");

		flags[i].team 	= team;
		flags[i].objective = i;
		flags[i].compassflag = level.compassflag_empty;
		flags[i].objpointflag = level.objpointflag_empty;

		flags[i] thread flag();

		level createLevelHudElement("flag_" + flags[i].objective, 325 + 36 * i - 18 * (flags.size - 1), level.hud_ons_pos_y, "center", "middle", "fullscreen", "fullscreen", false, level.hudicon_empty, 32, 32, 1, 0.8, 1, 1, 1);
	}	
	
	level.flagscaptured["allies"] = 0;
	level.flagscaptured["axis"] = 0;

	level.indexFlagAllies = 0;
	level.indexFlagAxis = flags.size - 1;
	onslaughtObjectivesShow();

	level thread checkWin(level.flags);
}

FlagTimeOut()
{
	if(!level.flagtimeout) return;

	if(!level.roundstarted) return;

	// No multiple occurrences allowed otherwise new flag point selection will yield unpredictable results
	while(isdefined(level.FlagTimeOut_running) && level.FlagTimeOut_running)
		wait( [[level.ex_fpstime]](randomint(10) / 10) );

	iprintln(&"MP_DOM_CAPTURE_TIMEOUT", level.flagtimeout);
	iprintln(&"MP_DOM_NEW_FLAG", 5);

	level.FlagTimeOut_running = true;
	self.flagmodel hide();
	self.basemodel hide();
	self deleteFlagWaypoint();
	objective_state(self.objective, "invisible");
	level changeLevelHudElementByName("flag_" + self.objective, 0);

	spawnpoints = getentarray("mp_dm_spawn", "classname");

	new_point = undefined;
	for(i = 0; i < 100 ; i ++)
	{
		new_point = spawnpoints[randomint(spawnpoints.size)];
		if(new_point IsAwayFromFlags(1000))
			break;
	}

	wait( [[level.ex_fpstime]](5) );

	self.origin = new_point.origin;
	self.flagmodel.origin = self.origin;
	self.flagmodel.angles = self.angles;
	self.basemodel.origin = self.origin;
	self.basemodel.angles = self.angles;
	level changeLevelHudElementByName("flag_" + self.objective, 0.8);
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");
	self createFlagWaypoint();
	self.flagmodel show();
	self.basemodel show();

	level.FlagTimeOut_running = false;
}

flag()
{
	level endon("end_map");

	objective_add(self.objective, "invisible", self.origin, self.compassflag);
	self createFlagWaypoint();

	for(;;)
	{
		other = WaitForRadius(self.origin, level.flag_radius, 50);

		// no return value for WaitForRadius : time out for the flag
		if(!isdefined(other)) self FlagTimeOut();
		else if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator") && level.roundstarted && !level.roundended)
		{
			// Touched by enemy
			if(other.pers["team"] != self.team)
			{
				if(other canCapture(self))
					self startCaptureProgress(other.clientid, other.pers["team"]);
				else 
				{
					other iprintlnbold(&"MP_ONS_CANT_CAPTURE");
					wait( [[level.ex_fpstime]](3) );
				}
			}
			
			// Flag is reachable
			self.reachable = true;
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
}

startCaptureProgress(clientid, team)
{
	helper = spawn("script_model",self.origin);
	helper playloopsound("dom_start_flag_capture");

	origin = self.origin;
	time = 0;
	swatch = 0;

	other = getPlayerPlaying(clientid,team);

	// Neutralize flag
	if(self.team != "none") 
	{
		time_neutral = int(level.flagcapturetime/2);

		self.blink = true;

		while(isDefined(self) && time < time_neutral) 
		{
			// If player near flag
			origin = getPlayerOrigin(clientid);

			// Abort
			if(!isDefined(origin) || (isDefined(origin) && distance(origin, self.origin) > level.flag_radius) || checkOtherPlayerInRange(clientid, origin, EnemyTeam(team), level.flag_radius) > -1 || !(other canCapture(self)) )
			{
				level changeLevelHudElementByName("flag_" + self.objective,0.8);

				if(isDefined(helper)) 
				{
					helper stoploopsound();
					helper delete();
				}

				self.blink = undefined;

				return;
			}

			alpha = 0.8 - ((0.8/time_neutral) * time);

			if(swatch == 0) level changeLevelHudElementByName("flag_" + self.objective,0);
			if(swatch == 1) level changeLevelHudElementByName("flag_" + self.objective,alpha);

			swatch++;
			if(swatch > 1) swatch = 0;

			time++;
			wait( [[level.ex_fpstime]](0.5) );
		}

		level.flagscaptured[EnemyTeam(team)] --;
		self onslaughtObjectivesManage(team, true);
	}

	// Show neutral
	self.flagmodel setmodel("xmodel/fahne");
	self.team = "none";
	self.compassflag = level.compassflag_empty;
	self.objpointflag = level.objpointflag_empty;
	objective_icon(self.objective, self.compassflag);

	level deleteLevelHudElementByName("flag_" + self.objective);
	level createLevelHudElement("flag_" + self.objective, 325 + 36 * self.objective - 18 * (level.flags.size - 1), level.hud_ons_pos_y, "center", "middle", "fullscreen", "fullscreen", false, level.hudicon_empty, 32, 32, 1, 0.8, 1, 1, 1);

	self createFlagWaypoint();
	
	// Announce flag take-over to other team
	if(self.team == "allies")
		level thread playSoundOnPlayers(game["allies_losing_ground"], "allies");
	else if(self.team == "axis")
		level thread playSoundOnPlayers(game["german_losing_ground"], "axis");

	self.blink = true;

	// Capture flag
	while(isDefined(self) && time < level.flagcapturetime) 
	{
		// Check if player is still there
		origin = getPlayerOrigin(clientid);
	
		// Abort
		if(!isDefined(origin) || (isDefined(origin) && distance(origin, self.origin) > level.flag_radius) || checkOtherPlayerInRange(clientid, origin, EnemyTeam(team), level.flag_radius) > -1 || !(other canCapture(self)) )
		{
			level changeLevelHudElementByName("flag_" + self.objective,0.8);
			
			if(isDefined(helper)) 
			{
				helper stoploopsound();
				helper delete();
			}
			
			self.blink = undefined;
			
			return;
		}
		
		alpha = 0.8 - ((0.8/level.flagcapturetime) * time);
	
		if(swatch == 0) level changeLevelHudElementByName("flag_" + self.objective,0);
		if(swatch == 1) level changeLevelHudElementByName("flag_" + self.objective,alpha);
		
		swatch++;
		if(swatch > 1) swatch = 0;
		
		time++;
		wait( [[level.ex_fpstime]](0.5) );
	}
	
	if(isDefined(helper)) helper delete();

	if(isDefined(other)) other GetFlag(self); // Getting flag
	
	self.blink = undefined;
}

GetFlag(flag) 
{
	self endon("disconnect");

	// Give points
	if(level.pointscaptureflag > 0) 
	{
		self.pers["score"] += level.pointscaptureflag;
		self.score = self.pers["score"];

		if(level.ex_ranksystem) self.pers["special"] += level.pointscaptureflag;
		// added for arcade style HUD points
		self notify("update_playerscore_hud");
	}

	level.flagscaptured[self.pers["team"]] ++;
	
	if(self.pers["team"] == "allies") 
	{
		flag.team = "allies";
		
		// Only if not last flag
		if(!checkAllFlagsCaptured()) 
		{
			if(randomInt(2)) level thread playSoundOnPlayers(game["allies_area_secured"], "allies");
				else level thread playSoundOnPlayers(game["allies_ground_taken"], "allies");

			level thread playSoundOnPlayers(game["german_losing_ground"], "axis");
		}
	
		flagModel = "xmodel/prop_flag_" + game["allies"];
		flag.flagmodel setmodel(flagModel);
		
		flag.compassflag = level.compassflag_allies;
		objective_icon(flag.objective, flag.compassflag);

		if(level.showflagwaypoints) flag.objpointflag = level.objpointflag_allies;

		level deleteLevelHudElementByName("flag_" + flag.objective);
		level createLevelHudElement("flag_" + flag.objective, 325 + 36 * flag.objective - 18 * (level.flags.size - 1), level.hud_ons_pos_y, "center", "middle", "fullscreen", "fullscreen", false, game["hudicon_allies"], 32, 32, 1, 0.8, 1, 1, 1);
	}
	else 
	{
		flag.team = "axis";

		// Only if not last flag
		if(!checkAllFlagsCaptured()) 
		{
			if(randomInt(2)) level thread playSoundOnPlayers(game["german_area_secured"], "axis");
				else level thread playSoundOnPlayers(game["german_ground_taken"], "axis");

			level thread playSoundOnPlayers(game["allies_losing_ground"], "allies");
		}

		flagModel = "xmodel/prop_flag_" + game["axis"];
		flag.flagmodel setmodel(flagModel);
		
		flag.compassflag = level.compassflag_axis;
		objective_icon(flag.objective, flag.compassflag);

		if(level.showflagwaypoints) flag.objpointflag = level.objpointflag_axis;

		level deleteLevelHudElementByName("flag_" + flag.objective);
		level createLevelHudElement("flag_" + flag.objective, 325 + 36 * flag.objective - 18 * (level.flags.size - 1), level.hud_ons_pos_y, "center", "middle", "fullscreen", "fullscreen", false, game["hudicon_axis"], 32, 32, 1, 0.8, 1, 1, 1);
	}

	self.dont_auto_balance = true;
	flag createFlagWaypoint();
	flag onslaughtObjectivesManage(self.pers["team"], false);
}

createFlagWaypoint()
{
	self deleteFlagWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.origin[0];
	waypoint.y = self.origin[1];
	waypoint.z = self.origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;

	if(level.showflagwaypoints) waypoint setShader(self.objpointflag, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint_flag = waypoint;
}

deleteFlagWaypoint()
{
	if(isdefined(self.waypoint_flag))
		self.waypoint_flag destroy();
}

checkWin(flags) 
{
	level notify("checkWin");
	level endon("checkWin");
	
	while(isDefined(flags)) 
	{
		if(checkAllFlagsCaptured()) 
		{
			if(flags[0].team == "allies")	
				level.winning_team = "allies";
			else							
				level.winning_team = "axis";
	
			level thread endRound();
			break;
		}		
		
		wait( [[level.ex_fpstime]](0.5) );
	}
}

checkAllFlagsCaptured() 
{
	flags = level.flags;
	
	team = flags[0].team;

	if(!isDefined(team)) return false;
	if(team != "axis" && team != "allies") return false;

	if(level.flagscaptured[team] == flags.size)
		return true;
	
	return false;
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

printOnTeam(text, team, playername)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text,playername);
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

createLevelHudElement(hud_element_name, x,y,xAlign,yAlign,horzAlign,vertAlign,foreground,shader,shader_width,shader_height,sort,alpha,color_r,color_g,color_b) 
{
	if(!isDefined(level.hud)) level.hud = [];

	count = level.hud.size;

	level.hud[count] = newHudElem();
	level.hud[count].x = x;
	level.hud[count].y = y;
	level.hud[count].alignX = xAlign;
	level.hud[count].alignY = yAlign;
	level.hud[count].horzAlign = horzAlign;
	level.hud[count].vertAlign = vertAlign;
	level.hud[count].foreground = foreground;
	level.hud[count] setShader(shader, shader_width, shader_height);
	level.hud[count].sort = sort;
	level.hud[count].alpha = alpha;
	level.hud[count].color = (color_r,color_g,color_b);

	level.hud[count].name = hud_element_name;
	level.hud[count].shader_name = shader;
	level.hud[count].shader_width = shader_width;
	level.hud[count].shader_height = shader_height;
}

changeLevelHudElementByName(hud_element_name,alpha) 
{
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
		for(i=0;i<level.hud.size;i++)
		{
			if(isDefined(level.hud[i].name) && level.hud[i].name == hud_element_name) 
			{
				if(isDefined(level.hud[i])) level.hud[i].alpha = alpha;
				break;
			}
		}	
	}
}

deleteLevelHudElementByName(hud_element_name) 
{
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
		for(i=0;i<level.hud.size;i++)
		{
			if(isDefined(level.hud[i].name) && level.hud[i].name == hud_element_name) 
			{
				level.hud[i] destroy();
				level.hud[i].name = undefined;
			}
		}

		new_ar = [];

		for(i=0;i<level.hud.size;i++) 
			if(isDefined(level.hud[i].name)) new_ar[new_ar.size] = level.hud[i];

		level.hud = new_ar;
	}
}

WaitFlagTimeOut(timeout)
{
	// No more time out for this flag
	if(isdefined(self.reachable)) return;

	wait( [[level.ex_fpstime]](timeout) );

	// If still not reachable, time out !
	if(!isdefined(self.reachable))
		self notify("flag_timeout");
}

WaitForRadius(origin, radius, height) 
{
	self endon("flag_timeout");

	self thread WaitFlagTimeOut(level.flagtimeout);

	if(!isDefined(origin) || !isDefined(radius) || !isDefined(height)) return;

	trigger = spawn("trigger_radius", origin, 0, radius, height);

	while(1) 
	{
		trigger waittill("trigger", other);

		if(isPlayer(other) && other.sessionstate == "playing") 
		{
			if(isDefined(trigger)) trigger delete();
			return other;
		}
		
		wait( [[level.ex_fpstime]](0.1) );
	}

	if(isDefined(trigger)) trigger delete();
}

getPlayerPlaying(client_id,team) 
{
	self endon("disconnect");

	players = level.players;

	for(i=0;i<players.size;i++) 
	{
		if(players[i].sessionstate == "playing" && players[i].clientid == client_id && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team) 
		{
			return players[i];
		}
	}

	return undefined;
}

getPlayerOrigin(client_id) 
{
	self endon("disconnect");

	players = level.players;

	for(i=0;i<players.size;i++) 
	{
		if(players[i].sessionstate == "playing" && players[i].clientid == client_id) 
		{
			return players[i].origin;
		}
	}

	return undefined;
}

checkOtherPlayerInRange(client_id, origin, team, radius)
{
	wait( [[level.ex_fpstime]](0.05) );

	players = level.players;

	for(i = 0; i < players.size; i++) 
	{
		if(players[i].sessionstate == "playing" && isDefined(players[i].pers["team"]) && (players[i].pers["team"] == team || team == "all") && distance(players[i].origin,origin) < radius && players[i].clientid != client_id)
		{
			return players[i].clientid;
		}
	}

	return -1;
}

IsAwayFromFlags(mindist)
{
	if(!isdefined(level.flags)) return true;

	for(i = 0; i < level.flags.size; i ++)
		if(distance(self.origin, level.flags[i].origin) < mindist) return false;

	return true;
}

EnemyTeam(team)
{
	if(team == "allies") return ("axis");
	return ("allies");
}

//Added by 0ddball.

getSpawnTypeAllies(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
			spawntype_allies = "mp_dm_spawn";
			break;
		case "tdm" : 
			spawntype_allies = "mp_tdm_spawn";
			break;
		case "sd" :
			spawntype_allies = "mp_sd_spawn_attacker";
			break;
		case "ctf":
			spawntype_allies = "mp_ctf_spawn_allied";
			break;
		default:
			spawntype_allies = "mp_dm_spawn";
		break;
	}
	return spawntype_allies;
}

getSpawnTypeAxis(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
			spawntype_axis = "mp_dm_spawn";
			break;
		case "tdm" :
			spawntype_axis = "mp_tdm_spawn";
			break;
		case "sd" :
			spawntype_axis = "mp_sd_spawn_defender";
			break;
		case "ctf":
			spawntype_axis = "mp_ctf_spawn_axis";
			break;
		default:
			spawntype_axis = "mp_dm_spawn";
		break;
	}
	return spawntype_axis;
}

isSpawnTypeCorrect(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
		case "tdm" : 
		case "sd" :
		case "ctf":
			res = true;
			break;
		default:
			res=false;;
		break;
	}
	return res;
}

setSpawnPoints(spawntype)
{
	spawnpoints = getentarray(spawntype, "classname");
	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	return spawnpoints;
}

// Player method: Tell if a player has the right to capture a Flag in Onslaught Mode.
canCapture(flag)
{
	return (((self.pers["team"] == "allies") && (flag.objective <= level.indexFlagAllies)) || ((self.pers["team"] == "axis") && (flag.objective >= level.indexFlagAxis)));
}

// Function: Add the next Flag objective on compass for Onslaught Mode.
onslaughtObjectivesShow()
{		
	//Hide all.
	for(i=0; i<level.flags.size; i++)
		objective_state(i, "invisible");
	
	maxIndex = level.flags.size - 1;
	
	// End of round conditions
	if((level.indexFlagAllies < 0)	|| (level.indexFlagAllies > maxIndex) || (level.indexFlagAxis < 0)	|| (level.indexFlagAxis > maxIndex))
			return;
			
	if(level.indexFlagAllies == level.indexFlagAxis)
	{
		team = "none";
		objective_team(level.indexFlagAllies, team);
		objective_state(level.indexFlagAllies, "current");
	}
	else
	{
		objective_team(level.indexFlagAllies, "allies");
		objective_state(level.indexFlagAllies, "current");
		objective_team(level.indexFlagAxis, "axis");
		objective_state(level.indexFlagAxis, "current");
	}
}

// Flag method: self has its state changed by a "team" player. If changed to neutral, then neutral = true.
onslaughtObjectivesManage(team, neutral)
{
	i = self.objective;
	
	if(team == "allies")
	{
		if(level.indexFlagAxis < i) level.indexFlagAxis = i;
		if(!neutral) level.indexFlagAllies ++;
		//iprintlnbold("Flag i = " + i + " IndexAxis = " + level.indexFlagAxis + ",IndexAllies = " + level.indexFlagAllies);
	}
	else if(team == "axis")
	{
		if(level.indexFlagAllies > i) level.indexFlagAllies = i;
		if(!neutral) level.indexFlagAxis --;
		//iprintlnbold("Flag i = " + i + " IndexAxis = " + level.indexFlagAxis + ",IndexAllies = " + level.indexFlagAllies);
	}
	else return;

	onslaughtObjectivesShow();
}

