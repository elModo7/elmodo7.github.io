
main()
{
	// Trick SET: pretend we're on HQ gametype to get the level.radio definitions in the map script
	setcvar("g_gametype", "hq");

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

	// Over-override Callback_StartGameType
	level.chq_callbackStartGameType = level.callbackStartGameType;
	level.callbackStartGameType = ::CHQ_Callback_StartGameType;

	// set eXtreme+ variables and precache (phase 1 only)
	extreme\_ex_varcache::main(1);
}

CHQ_Callback_StartGameType()
{
	// Trick UNSET: restore CHQ gametype
	setcvar("g_gametype", "chq");

	// set eXtreme+ variables and precache (phase 2 only)
	extreme\_ex_varcache::main(2);

	[[level.chq_callbackStartGameType]]();
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	game["radio_prespawn"][0] = "objectiveA";
	game["radio_prespawn"][1] = "objectiveB";
	game["radio_prespawn"][2] = "objective";
	game["radio_prespawn_objpoint"][0] = "objpoint_A";
	game["radio_prespawn_objpoint"][1] = "objpoint_B";
	game["radio_prespawn_objpoint"][2] = "objpoint_star";
	game["radio_none"] = "objective";
	game["radio_axis"] = "objective_" + game["axis"];
	game["radio_allies"] = "objective_" + game["allies"];

	//custom radio colors for different nationalities
	if(game["allies"] == "american") game["radio_model"] = "xmodel/military_german_fieldradio_green_nonsolid";
	else if(game["allies"] == "british") game["radio_model"] = "xmodel/military_german_fieldradio_tan_nonsolid";
	else if(game["allies"] == "russian") game["radio_model"] = "xmodel/military_german_fieldradio_grey_nonsolid";
	assert(isdefined(game["radio_model"]));

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
		}
		precacheShader("objective");
		precacheShader("objectiveA");
		precacheShader("objectiveB");
		precacheShader("objective");
		precacheShader("objpoint_A");
		precacheShader("objpoint_B");
		precacheShader("objpoint_radio");
		precacheShader("field_radio");
		precacheShader(game["radio_allies"]);
		precacheShader(game["radio_axis"]);
		precacheModel(game["radio_model"]);
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		precacheString(&"MP_ESTABLISHING_HQ");
		precacheString(&"MP_DESTROYING_HQ");
		precacheString(&"MP_LOSING_HQ");
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

	level._effect["radioexplosion"] = loadfx("fx/explosions/grenadeExp_blacktop.efx");

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.roundStarted = false;
	level.progressBarHeight = 12;
	level.progressBarWidth = 192;
	level.timesCaptured = 0;
	level.nextradio = 0;
	level.DefendingRadioTeam = "none";
	level.MultipleCaptureBias = 1;
	level.NeutralizingPoints = level.ex_chqpoints_teamneut;
	level.RadioSpawnDelay = level.ex_chq_radio_spawntime;
	level.RadioMaxHoldSeconds = level.ex_chq_radio_holdtime;
	level.radioradius = 120;
	level.zradioradius = level.ex_chq_radio_zradius;
	level.captured_radios["allies"] = 0;
	level.captured_radios["axis"] = 0;

	if(!isdefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		hq_setup();
		thread hq_points();
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

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

		// Fix for spectate problem
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

		if(isdefined(self.pers["weapon"]))
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
	if(!isdefined(vDir)) iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

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

		if(isdefined(eAttacker) && eAttacker != self) eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
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
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams)) self.deaths++;

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

					if((players[self.joining_team] - players[self.leaving_team]) > 1) attacker.score--;
				}
			}

			if(isdefined(attacker.friendlydamage)) attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
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

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isdefined(self.switching_teams))
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	level hq_removeall_hudelems(self);

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	//check if it was the last person to die on the defending team
	level updateTeamStatus();
	if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]) && (level.exist[self.pers["team"]] <= 0))
	{
		for(i = 0; i < level.radio.size; i++)
		{
			if(level.radio[i].hidden == true) continue;
			level hq_radio_capture(level.radio[i], "none");
			break;
		}
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
	self.isscorer = undefined;
	self.esthq = undefined;
	self.desthq = undefined;

	self extreme\_ex_main::exprespawn();
	
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = undefined;

	if(level.ex_readyup)
	{
		if(isDefined(game["readyup_done"]) && game["readyup_done"]) spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_AwayfromRadios(spawnpoints);
			else spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
	}
	else spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_AwayfromRadios(spawnpoints);

	if(level.ex_specials && level.ex_insertion)
	{
		insertion_info = extreme\_ex_specials_insertion::insertionGetFrom(self);
		if(insertion_info["exists"])
		{
			spawnpoint.origin = insertion_info["origin"];
			spawnpoint.angles = insertion_info["angles"];
		}
	}

	if(isdefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
		else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isdefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(level.scorelimit > 0) self setClientCvar("cg_objectiveText", &"MP_OBJ_TEXT", level.scorelimit);
		else self setClientCvar("cg_objectiveText", &"MP_OBJ_TEXT_NOSCORE");

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

	if(isdefined(self.respawntext))
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

	if(winningteam == "allies") level.ex_resultsound = "MP_announcer_allies_win";
	else if(winningteam == "axis") level.ex_resultsound = "MP_announcer_axis_win";
	else level.ex_resultsound = "MP_announcer_round_draw";

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
			if((isdefined(player.pers["team"])) && (player.pers["team"] == winningteam))
					winners = (winners + ";" + lpselfguid + ";" + player.name);
			else if((isdefined(player.pers["team"])) && (player.pers["team"] == losingteam))
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
		timelimit = getCvarfloat("scr_chq_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setcvar("scr_chq_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isdefined(level.clock)) extreme\_ex_gtcommon::createClock();
				level.clock setTimer(level.timelimit * 60);
			}
			else if(isdefined(level.clock)) level.clock destroy();

			checkTimeLimit();
		}

		scorelimit = getCvarint("scr_chq_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);
		}

		checkScoreLimit();

		wait( [[level.ex_fpstime]](1) );
	}
}

hq_setup()
{
	wait( [[level.ex_fpstime]](0.05) );

	maperrors = [];

	if(!isdefined(level.radio))
		level.radio = getentarray("hqradio", "targetname");

	if(level.custom_radios) maps\mp\gametypes\_mapsetup_chq_hq::init();

	if(level.radio.size < 3) maperrors[maperrors.size] = "^1Less than 3 entities found with \"targetname\" \"hqradio\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	setTeamScore("allies", 0);
	setTeamScore("axis", 0);

	for(i = 0; i < level.radio.size; i++)
	{
		level.radio[i] setmodel(game["radio_model"]);
		level.radio[i].team = "none";
		level.radio[i].holdtime_allies = 0;
		level.radio[i].holdtime_axis = 0;
		level.radio[i].hidden = true;
		level.radio[i] hide();

		if((!isdefined(level.radio[i].script_radius)) || (level.radio[i].script_radius <= 0)) level.radio[i].radius = level.radioradius;
		else level.radio[i].radius = level.radio[i].script_radius;

		level thread hq_radio_think(level.radio[i]);
	}

	hq_randomize_radioarray();

	level thread hq_obj_think();
}

hq_randomize_radioarray()
{
	for(i = 0; i < level.radio.size; i++)
	{
		rand = randomint(level.radio.size);
		temp = level.radio[i];
		level.radio[i] = level.radio[rand];
		level.radio[rand] = temp;
	}
}

hq_obj_think(radio)
{
	NeutralRadios = 0;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true) continue;
		NeutralRadios++;
	}

	if(NeutralRadios <= 0)
	{
		if(level.nextradio > level.radio.size - 1)
		{
			hq_randomize_radioarray();
			level.nextradio = 0;

			if(isdefined(radio))
			{
				// same radio twice in a row so go to the next radio
				if(radio == level.radio[level.nextradio]) level.nextradio++;
			}
		}

		//find a fake radio position that isn't the last position or the next position
		randAorB = undefined;
		if(level.radio.size >= 4)
		{
			fakeposition = level.radio[randomint(level.radio.size)];
			if(isdefined(level.radio[(level.nextradio - 1)]))
			{
				while((fakeposition == level.radio[level.nextradio]) || (fakeposition == level.radio[level.nextradio - 1]))
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			else
			{
				while(fakeposition == level.radio[level.nextradio])
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			randAorB = randomint(2);
			//objective_add(1, "current", fakeposition.origin, game["radio_prespawn"][randAorB]);
			//thread maps\mp\gametypes\_objpoints::addObjpoint(fakeposition.origin, "1", game["radio_prespawn_objpoint"][randAorB]);
		}

		if(!isdefined(randAorB))
			otherAorB = 2; //use original icon since there is only one objective that will show
		else if(randAorB == 1)
			otherAorB = 0;
		else
			otherAorB = 1;

		//objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][otherAorB]);
		//thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin, "0", game["radio_prespawn_objpoint"][otherAorB]);

		wait( [[level.ex_fpstime]](10) );

		level hq_check_teams_exist();
		restartRound = false;

		while((!level.alliesexist) || (!level.axisexist))
		{
			restartRound = true;
			wait( [[level.ex_fpstime]](2) );
			level hq_check_teams_exist();
		}

		if(level.mapended) return;

		if(restartRound) restartRound();
		level.roundStarted = true;

		iprintln(&"MP_RADIOS_SPAWN_IN_SECONDS", level.RadioSpawnDelay);
		wait( [[level.ex_fpstime]](level.RadioSpawnDelay) );

		level.radio[level.nextradio] show();
		level.radio[level.nextradio].hidden = false;

		level thread playSoundOnPlayers("explo_plant_no_tick");
		objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][2]);
		//objective_icon(0, game["radio_none"]);
		//objective_delete(1);
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin, "0", "objpoint_radio");

		if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0)) objective_team(0, "allies");		// AXIS HAVE A RADIO AND ALLIES DONT
		else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0)) objective_team(0, "axis");	// ALLIES HAVE A RADIO AND AXIS DONT
		else objective_team(0, "none");	// NO TEAMS HAVE A RADIO

		level.nextradio++;
	}
}

hq_radio_think(radio)
{
	level endon("intermission");
	while(!level.mapended)
	{
		wait( [[level.ex_fpstime]](0.05) );
		if(!radio.hidden)
		{
			players = level.players;
			radio.allies = 0;
			radio.axis = 0;
			for(i = 0; i < players.size; i++)
			{
				if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
				{
					if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
					{
						if(players[i].pers["team"] == radio.team)
							continue;

						if((level.captured_radios[players[i].pers["team"]] > 0) && (radio.team == "none"))
							continue;

						if((!isdefined(players[i].radioicon)) || (!isdefined(players[i].radioicon[0])))
						{
							players[i].radioicon[0] = newClientHudElem(players[i]);
							players[i].radioicon[0].x = 30;
							players[i].radioicon[0].y = 95;
							players[i].radioicon[0].alignX = "center";
							players[i].radioicon[0].alignY = "middle";
							players[i].radioicon[0].horzAlign = "left";
							players[i].radioicon[0].vertAlign = "top";
							players[i].radioicon[0] setShader("field_radio", 40, 32);
						}

						if((level.captured_radios[players[i].pers["team"]] <= 0) && (radio.team == "none"))
						{
							if(!isdefined(players[i].progressbar_capture))
							{
								players[i].progressbar_capture = newClientHudElem(players[i]);
								players[i].progressbar_capture.x = 0;
								players[i].progressbar_capture.y = 104;
								players[i].progressbar_capture.alignX = "center";
								players[i].progressbar_capture.alignY = "middle";
								players[i].progressbar_capture.horzAlign = "center_safearea";
								players[i].progressbar_capture.vertAlign = "center_safearea";
								players[i].progressbar_capture.alpha = 0.5;
							}

							players[i].progressbar_capture setShader("black", level.progressBarWidth, level.progressBarHeight);

							if(!isdefined(players[i].progressbar_capture2))
							{
								players[i].progressbar_capture2 = newClientHudElem(players[i]);
								players[i].progressbar_capture2.x = ((level.progressBarWidth / (-2)) + 2);
								players[i].progressbar_capture2.y = 104;
								players[i].progressbar_capture2.alignX = "left";
								players[i].progressbar_capture2.alignY = "middle";
								players[i].progressbar_capture2.horzAlign = "center_safearea";
								players[i].progressbar_capture2.vertAlign = "center_safearea";
							}

							if(players[i].pers["team"] == "allies") players[i].progressbar_capture2 setShader("white", radio.holdtime_allies, level.progressBarHeight - 4);
							else players[i].progressbar_capture2 setShader("white", radio.holdtime_axis, level.progressBarHeight - 4);

							if(!isdefined(players[i].progressbar_capture3))
							{
								players[i].progressbar_capture3 = newClientHudElem(players[i]);
								players[i].progressbar_capture3.x = 0;
								players[i].progressbar_capture3.y = 50;
								players[i].progressbar_capture3.alignX = "center";
								players[i].progressbar_capture3.alignY = "middle";
								players[i].progressbar_capture3.horzAlign = "center_safearea";
								players[i].progressbar_capture3.vertAlign = "center_safearea";
								players[i].progressbar_capture3.archived = false;
								players[i].progressbar_capture3.font = "default";
								players[i].progressbar_capture3.fontscale = 2;
								players[i].progressbar_capture3 settext(&"MP_ESTABLISHING_HQ");
							}

							if(!isdefined(players[i].esthq)) players[i].esthq = true;
						}
						else if(radio.team != "none")
						{
							if(!isdefined(players[i].progressbar_capture))
							{
								players[i].progressbar_capture = newClientHudElem(players[i]);
								players[i].progressbar_capture.x = 0;
								players[i].progressbar_capture.y = 104;
								players[i].progressbar_capture.alignX = "center";
								players[i].progressbar_capture.alignY = "middle";
								players[i].progressbar_capture.horzAlign = "center_safearea";
								players[i].progressbar_capture.vertAlign = "center_safearea";
								players[i].progressbar_capture.alpha = 0.5;
							}
							players[i].progressbar_capture setShader("black", level.progressBarWidth, level.progressBarHeight);

							if(!isdefined(players[i].progressbar_capture2))
							{
								players[i].progressbar_capture2 = newClientHudElem(players[i]);
								players[i].progressbar_capture2.x = ((level.progressBarWidth / (-2)) + 2);
								players[i].progressbar_capture2.y = 104;
								players[i].progressbar_capture2.alignX = "left";
								players[i].progressbar_capture2.alignY = "middle";
								players[i].progressbar_capture2.horzAlign = "center_safearea";
								players[i].progressbar_capture2.vertAlign = "center_safearea";
							}

							if(players[i].pers["team"] == "allies") players[i].progressbar_capture2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
							else players[i].progressbar_capture2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

							if(!isdefined(players[i].progressbar_capture3))
							{
								players[i].progressbar_capture3 = newClientHudElem(players[i]);
								players[i].progressbar_capture3.x = 0;
								players[i].progressbar_capture3.y = 50;
								players[i].progressbar_capture3.alignX = "center";
								players[i].progressbar_capture3.alignY = "middle";
								players[i].progressbar_capture3.horzAlign = "center_safearea";
								players[i].progressbar_capture3.vertAlign = "center_safearea";
								players[i].progressbar_capture3.archived = false;
								players[i].progressbar_capture3.font = "default";
								players[i].progressbar_capture3.fontscale = 2;
								players[i].progressbar_capture3 settext(&"MP_DESTROYING_HQ");
							}

							if(!isdefined(players[i].desthq)) players[i].desthq = true;

							if(radio.team == "allies")
							{
								if(!isdefined(level.progressbar_axis_neutralize))
								{
									level.progressbar_axis_neutralize = newTeamHudElem("allies");
									level.progressbar_axis_neutralize.x = 0;
									level.progressbar_axis_neutralize.y = 104;
									level.progressbar_axis_neutralize.alignX = "center";
									level.progressbar_axis_neutralize.alignY = "middle";
									level.progressbar_axis_neutralize.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize.alpha = 0.5;
								}
								level.progressbar_axis_neutralize setShader("black", level.progressBarWidth, level.progressBarHeight);

								if(!isdefined(level.progressbar_axis_neutralize2))
								{
									level.progressbar_axis_neutralize2 = newTeamHudElem("allies");
									level.progressbar_axis_neutralize2.x = ((level.progressBarWidth / (-2)) + 2);
									level.progressbar_axis_neutralize2.y = 104;
									level.progressbar_axis_neutralize2.alignX = "left";
									level.progressbar_axis_neutralize2.alignY = "middle";
									level.progressbar_axis_neutralize2.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize2.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize2.color = (.8,0,0);
								}

								if(players[i].pers["team"] == "allies") level.progressbar_axis_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
								else level.progressbar_axis_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

								if(!isdefined(level.progressbar_axis_neutralize3))
								{
									level.progressbar_axis_neutralize3 = newTeamHudElem("allies");
									level.progressbar_axis_neutralize3.x = 0;
									level.progressbar_axis_neutralize3.y = 50;
									level.progressbar_axis_neutralize3.alignX = "center";
									level.progressbar_axis_neutralize3.alignY = "middle";
									level.progressbar_axis_neutralize3.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize3.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize3.archived = false;
									level.progressbar_axis_neutralize3.font = "default";
									level.progressbar_axis_neutralize3.fontscale = 2;
									level.progressbar_axis_neutralize3 settext(&"MP_LOSING_HQ");
								}
							}
							else
							if(radio.team == "axis")
							{
								if(!isdefined(level.progressbar_allies_neutralize))
								{
									level.progressbar_allies_neutralize = newTeamHudElem("axis");
									level.progressbar_allies_neutralize.x = 0;
									level.progressbar_allies_neutralize.y = 104;
									level.progressbar_allies_neutralize.alignX = "center";
									level.progressbar_allies_neutralize.alignY = "middle";
									level.progressbar_allies_neutralize.horzAlign = "center_safearea";
									level.progressbar_allies_neutralize.vertAlign = "center_safearea";
									level.progressbar_allies_neutralize.alpha = 0.5;
								}
								level.progressbar_allies_neutralize setShader("black", level.progressBarWidth, level.progressBarHeight);

								if(!isdefined(level.progressbar_allies_neutralize2))
								{
									level.progressbar_allies_neutralize2 = newTeamHudElem("axis");
									level.progressbar_allies_neutralize2.x = ((level.progressBarWidth / (-2)) + 2);
									level.progressbar_allies_neutralize2.y = 104;
									level.progressbar_allies_neutralize2.alignX = "left";
									level.progressbar_allies_neutralize2.alignY = "middle";
									level.progressbar_allies_neutralize2.horzAlign = "center_safearea";
									level.progressbar_allies_neutralize2.vertAlign = "center_safearea";
									level.progressbar_allies_neutralize2.color = (.8,0,0);
								}

								if(players[i].pers["team"] == "allies") level.progressbar_allies_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
								else level.progressbar_allies_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

								if(!isdefined(level.progressbar_allies_neutralize3))
								{
									level.progressbar_allies_neutralize3 = newTeamHudElem("axis");
									level.progressbar_allies_neutralize3.x = 0;
									level.progressbar_allies_neutralize3.y = 50;
									level.progressbar_allies_neutralize3.alignX = "center";
									level.progressbar_allies_neutralize3.alignY = "middle";
									level.progressbar_allies_neutralize3.horzAlign = "center_safearea";
									level.progressbar_allies_neutralize3.vertAlign = "center_safearea";
									level.progressbar_allies_neutralize3.archived = false;
									level.progressbar_allies_neutralize3.font = "default";
									level.progressbar_allies_neutralize3.fontscale = 2;
									level.progressbar_allies_neutralize3 settext(&"MP_LOSING_HQ");
								}
							}
						}

						if(players[i].pers["team"] == "allies") radio.allies++;
						else radio.axis++;

						players[i].inrange = true;
						players[i].isscorer = true;
					}
					else if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
					{
						if((isdefined(players[i].radioicon)) || (isdefined(players[i].radioicon[0]))) players[i].radioicon[0] destroy();
						if(isdefined(players[i].progressbar_capture)) players[i].progressbar_capture destroy();
						if(isdefined(players[i].progressbar_capture2)) players[i].progressbar_capture2 destroy();
						if(isdefined(players[i].progressbar_capture3)) players[i].progressbar_capture3 destroy();

						players[i].inrange = undefined;
					}
				}
			}

			if(radio.team == "none") // Radio is captured if no enemies around
			{
				if((radio.allies > 0) && (radio.axis <= 0) && (radio.team != "allies"))
				{
					radio.holdtime_allies = int(.667 + (radio.holdtime_allies + (radio.allies * level.MultipleCaptureBias)));

					if(radio.holdtime_allies >= (level.progressBarWidth - 4))
					{
						if((level.captured_radios["allies"] > 0) && (radio.team != "none")) level hq_radio_capture(radio, "none");
						else if(level.captured_radios["allies"] <= 0) level hq_radio_capture(radio, "allies");
					}
				}
				else if((radio.axis > 0) && (radio.allies <= 0) && (radio.team != "axis"))
				{
					radio.holdtime_axis = int(.667 + (radio.holdtime_axis + (radio.axis * level.MultipleCaptureBias)));

					if(radio.holdtime_axis >= (level.progressBarWidth - 4))
					{
						if((level.captured_radios["axis"] > 0) && (radio.team != "none")) level hq_radio_capture(radio, "none");
						else if(level.captured_radios["axis"] <= 0) level hq_radio_capture(radio, "axis");
					}
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;

					players = level.players;
					for(i = 0; i < players.size; i++)
					{
						if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
						{
							if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
							{
								if(isdefined(players[i].progressbar_capture)) players[i].progressbar_capture destroy();
								if(isdefined(players[i].progressbar_capture2)) players[i].progressbar_capture2 destroy();
								if(isdefined(players[i].progressbar_capture3)) players[i].progressbar_capture3 destroy();
							}
						}
					}
				}
			}
			else // Radio should go to neutral first
			{
				if((radio.team == "allies") && (radio.axis <= 0))
				{
					if(isdefined(level.progressbar_axis_neutralize)) level.progressbar_axis_neutralize destroy();
					if(isdefined(level.progressbar_axis_neutralize2)) level.progressbar_axis_neutralize2 destroy();
					if(isdefined(level.progressbar_axis_neutralize3)) level.progressbar_axis_neutralize3 destroy();
				}
				else if((radio.team == "axis") && (radio.allies <= 0))
				{
					if(isdefined(level.progressbar_allies_neutralize)) level.progressbar_allies_neutralize destroy();
					if(isdefined(level.progressbar_allies_neutralize2)) level.progressbar_allies_neutralize2 destroy();
					if(isdefined(level.progressbar_allies_neutralize3)) level.progressbar_allies_neutralize3 destroy();
				}

				if((radio.allies > 0) && (radio.team == "axis"))
				{
					radio.holdtime_allies = int(.667 + (radio.holdtime_allies + (radio.allies * level.MultipleCaptureBias)));
					if(radio.holdtime_allies >= (level.progressBarWidth - 4))
						level hq_radio_capture(radio, "none");
				}
				else if((radio.axis > 0) && (radio.team == "allies"))
				{
					radio.holdtime_axis = int(.667 + (radio.holdtime_axis + (radio.axis * level.MultipleCaptureBias)));
					if(radio.holdtime_axis >= (level.progressBarWidth - 4))
						level hq_radio_capture(radio, "none");
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;
				}
			}
		}
	}
}

hq_radio_capture(radio, team)
{
	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			{
				players[i].radioicon[0] destroy();
				if(isdefined(players[i].progressbar_capture)) players[i].progressbar_capture destroy();
				if(isdefined(players[i].progressbar_capture2)) players[i].progressbar_capture2 destroy();
				if(isdefined(players[i].progressbar_capture3)) players[i].progressbar_capture3 destroy();
			}

			// dish out some player scores
			if(isdefined(players[i].isscorer))
			{
				if(!level.ex_chqpoints_radius || (distance(players[i].origin, radio.origin) <= level.ex_chqpoints_radius))
				{
					if(isdefined(players[i].esthq))
					{
						players[i].score += level.ex_chqpoints_playercap;
						if(level.ex_ranksystem) players[i].pers["special"]+= level.ex_chqpoints_playercap;
						// added for arcade style HUD points
						players[i] notify("update_playerscore_hud");

						lpselfnum = players[i] getEntityNumber();
						lpselfguid = players[i] getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + players[i].pers["team"] + ";" + players[i].name + ";" + "hq_establish" + "\n");
					}
					else if(isdefined(players[i].desthq))
					{
						players[i].score += level.ex_chqpoints_playerneut;
						if(level.ex_ranksystem) players[i].pers["special"]+= level.ex_chqpoints_playerneut;
						// added for arcade style HUD points
						players[i] notify("update_playerscore_hud");

						lpselfnum = players[i] getEntityNumber();
						lpselfguid = players[i] getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + players[i].pers["team"] + ";" + players[i].name + ";" + "hq_destroy" + "\n");
					}
				}

				players[i].esthq = undefined;
				players[i].desthq = undefined;
				players[i].isscorer = undefined;
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;
		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;
		// Print some text
		if(radio.team == "allies")
		{
			if(getTeamCount("axis")) iprintln(&"MP_SHUTDOWN_ALLIED_HQ");

			if(isdefined(level.progressbar_axis_neutralize)) level.progressbar_axis_neutralize destroy();
			if(isdefined(level.progressbar_axis_neutralize2)) level.progressbar_axis_neutralize2 destroy();
			if(isdefined(level.progressbar_axis_neutralize3)) level.progressbar_axis_neutralize3 destroy();
		}
		else if(radio.team == "axis")
		{
			if(getTeamCount("allies")) iprintln(&"MP_SHUTDOWN_AXIS_HQ");

			if(isdefined(level.progressbar_allies_neutralize)) level.progressbar_allies_neutralize destroy();
			if(isdefined(level.progressbar_allies_neutralize2)) level.progressbar_allies_neutralize2 destroy();
			if(isdefined(level.progressbar_allies_neutralize3)) level.progressbar_allies_neutralize3 destroy();
		}
	}

	if(radio.team == "none") radio playsound("explo_plant_no_tick");

	NeutralizingTeam = undefined;
	if(radio.team == "allies") NeutralizingTeam = "axis";
	else if(radio.team == "axis") NeutralizingTeam = "allies";

	radio.team = team;

	level notify("Radio State Changed");

	if(team == "none")
	{
		// RADIO GOES NEUTRAL
		radio setmodel(game["radio_model"]);
		radio hide();
		radio.hidden = true;

		radio playsound("explo_radio");
		if(isdefined(NeutralizingTeam))
		{
			if(NeutralizingTeam == "allies") level thread playSoundOnPlayers("mp_announcer_axishqdest");
			else if(NeutralizingTeam == "axis") level thread playSoundOnPlayers("mp_announcer_alliedhqdest");
		}

		objective_delete(0);
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		level.DefendingRadioTeam = "none";
		level notify("Radio Neutralized");

		//give some points to the neutralizing team
		if(isdefined(NeutralizingTeam))
		{
			if((NeutralizingTeam == "allies") || (NeutralizingTeam == "axis"))
			{
				if(getTeamCount(NeutralizingTeam))
				{
					setTeamScore(NeutralizingTeam, getTeamScore(NeutralizingTeam) + level.NeutralizingPoints);
					level notify("update_teamscore_hud");

					if(NeutralizingTeam == "allies") iprintln(&"MP_SCORED_ALLIES", level.NeutralizingPoints);
					else iprintln(&"MP_SCORED_AXIS", level.NeutralizingPoints);
				}
			}
		}

		//give all the players that are alive full health
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].sessionstate == "playing")
			{
				players[i].maxhealth = 100;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread hq_removhudelem_allplayers(radio);
	}
	else
	{
		// RADIO CAPTURED BY A TEAM
		level.captured_radios[team] = 1;
		level.DefendingRadioTeam = team;

		if(team == "allies")
		{
			iprintln(&"MP_SETUP_HQ_ALLIED");

			if(game["allies"] == "british") alliedsound = "UK_mp_hqsetup";
			else if(game["allies"] == "russian") alliedsound = "RU_mp_hqsetup";
			else alliedsound = "US_mp_hqsetup";

			level thread playSoundOnPlayers(alliedsound, "allies");
			level thread playSoundOnPlayers("GE_mp_enemyhqsetup", "axis");
		}
		else
		{
			iprintln(&"MP_SETUP_HQ_AXIS");

			if(game["allies"] == "british") alliedsound = "UK_mp_enemyhqsetup";
			else if(game["allies"] == "russian") alliedsound = "RU_mp_enemyhqsetup";
			else alliedsound = "US_mp_enemyhqsetup";

			level thread playSoundOnPlayers("GE_mp_hqsetup", "axis");
			level thread playSoundOnPlayers(alliedsound, "allies");
		}

		//give some points to the capturing team
		if(isdefined(level.DefendingRadioTeam))
		{
			if((level.DefendingRadioTeam == "allies") || (level.DefendingRadioTeam == "axis"))
			{
				if(getTeamCount(level.DefendingRadioTeam))
				{
					setTeamScore(level.DefendingRadioTeam, getTeamScore(level.DefendingRadioTeam) + level.ex_chqpoints_teamcap);
					level notify("update_teamscore_hud");
				}
			}
		}

		//give all the alive players that are now defending the radio full health
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == level.DefendingRadioTeam && players[i].sessionstate == "playing")
			{
				players[i].maxhealth = 100;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread hq_maxholdtime_think();
	}

	objective_icon(0, (game["radio_" + team ]));
	objective_team(0, "none");

	objteam = "none";
	if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0)) objteam = "allies";
	else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0)) objteam = "axis";

	// Make all neutral radio objectives go to the right team
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true) continue;
		if(level.radio[i].team == "none") objective_team(0, objteam);
	}

	level thread hq_obj_think(radio);
}

hq_maxholdtime_think()
{
	level endon("Radio State Changed");
	assert(level.RadioMaxHoldSeconds > 2);
	if(level.RadioMaxHoldSeconds > 0) wait( [[level.ex_fpstime]](level.RadioMaxHoldSeconds - 0.05) );
	level thread hq_radio_resetall();
}

hq_points()
{
	while(!level.mapended)
	{
		if(level.DefendingRadioTeam != "none")
		{
			if(getTeamCount(level.DefendingRadioTeam))
			{
				setTeamScore(level.DefendingRadioTeam, getTeamScore(level.DefendingRadioTeam) + level.ex_chqpoints_defpps);
				level notify("update_teamscore_hud");
				checkScoreLimit();
			}
		}
		wait( [[level.ex_fpstime]](1) );
	}
}

hq_radio_resetall()
{
	// Find the radio that is in play
	radio = undefined;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == false)
			radio = level.radio[i];
	}

	if(!isdefined(radio))
		return;

	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			{
				players[i].radioicon[0] destroy();
				if(isdefined(players[i].progressbar_capture)) players[i].progressbar_capture destroy();
				if(isdefined(players[i].progressbar_capture2)) players[i].progressbar_capture2 destroy();
				if(isdefined(players[i].progressbar_capture3)) players[i].progressbar_capture3 destroy();
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;

		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;

		localizedTeam = undefined;
		if(radio.team == "allies")
		{
			localizedTeam = (&"MP_UPTEAM");
			if(isdefined(level.progressbar_axis_neutralize)) level.progressbar_axis_neutralize destroy();
			if(isdefined(level.progressbar_axis_neutralize2)) level.progressbar_axis_neutralize2 destroy();
			if(isdefined(level.progressbar_axis_neutralize3)) level.progressbar_axis_neutralize3 destroy();
		}
		else if(radio.team == "axis")
		{
			localizedTeam = (&"MP_DOWNTEAM");
			if(isdefined(level.progressbar_allies_neutralize)) level.progressbar_allies_neutralize destroy();
			if(isdefined(level.progressbar_allies_neutralize2)) level.progressbar_allies_neutralize2 destroy();
			if(isdefined(level.progressbar_allies_neutralize3)) level.progressbar_allies_neutralize3 destroy();
		}

		minutes = 0;
		maxTime = level.RadioMaxHoldSeconds;
		while(maxTime >= 60)
		{
			minutes++;
			maxTime -= 60;
		}
		seconds = maxTime;
		if((minutes > 0) && (seconds > 0)) iprintlnbold(&"MP_MAXHOLDTIME_MINUTESANDSECONDS", localizedTeam, minutes, seconds);
		else if((minutes > 0) && (seconds <= 0)) iprintlnbold(&"MP_MAXHOLDTIME_MINUTES", localizedTeam);
		else if((minutes <= 0) && (seconds > 0)) iprintlnbold(&"MP_MAXHOLDTIME_SECONDS", localizedTeam, seconds);
	}

	radio.team = "none";
	level.DefendingRadioTeam = "none";
	objective_team(0, "none");

	radio setmodel(game["radio_model"]);
	radio hide();

	if(!level.mapended)
	{
		radio playsound("explo_radio");
		level thread playSoundOnPlayers("mp_announcer_hqdefended");
	}

	radio.hidden = true;
	objective_delete(0);
	thread maps\mp\gametypes\_objpoints::removeObjpoints();

	level thread hq_obj_think(radio);
	level thread hq_removhudelem_allplayers(radio);
}

hq_removeall_hudelems(player)
{
	if(isPlayer(player) && isDefined(level.radio))
	{
		for(i = 0; i < level.radio.size; i++)
		{
			if(isdefined(player.radioicon) && isdefined(player.radioicon[0])) player.radioicon[0] destroy();
			if(isdefined(player.progressbar_capture)) player.progressbar_capture destroy();
			if(isdefined(player.progressbar_capture2)) player.progressbar_capture2 destroy();
			if(isdefined(player.progressbar_capture3)) player.progressbar_capture3 destroy();
		}
	}
}

hq_removhudelem_allplayers(radio)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].radioicon) && isdefined(players[i].radioicon[0])) players[i].radioicon[0] destroy();
		if(isdefined(players[i].progressbar_capture)) players[i].progressbar_capture destroy();
		if(isdefined(players[i].progressbar_capture2)) players[i].progressbar_capture2 destroy();
		if(isdefined(players[i].progressbar_capture3)) players[i].progressbar_capture3 destroy();
	}
}

hq_check_teams_exist()
{
	players = level.players;
	level.alliesexist = false;
	level.axisexist = false;
	for(i = 0; i < players.size; i++)
	{
		if(!isdefined(players[i].sessionteam) || players[i].sessionteam == "spectator") continue;
		if(players[i].pers["team"] == "allies") level.alliesexist = true;
		else if(players[i].pers["team"] == "axis") level.axisexist = true;

		if(level.alliesexist && level.axisexist) return;
	}
}

waittill_any(string1, string2)
{
	self endon("death");
	ent = spawnstruct();

	if(isdefined(string1)) self thread waittill_string(string1, ent);

	if(isdefined(string2)) self thread waittill_string(string2, ent);

	ent waittill("returned");
	ent notify("die");
}

waittill_string(msg, ent)
{
	self endon("death");
	ent endon("die");
	self waittill(msg);
	ent notify("returned");
}

updateTeamStatus()
{
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
			level.exist[players[i].pers["team"]]++;
	}
}

restartRound()
{
	if(level.mapended) return;

	if(level.roundStarted)
	{
		iprintlnbold(&"MP_MATCHRESUMING");
		return;
	}
	else if(!level.ex_readyup)
	{
		iprintlnbold(&"MP_MATCHSTARTING");
		wait( [[level.ex_fpstime]](5) );
	}

	if(level.ex_readyup) return;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isdefined(player.sessionteam) || player.sessionteam == "spectator") continue;

		if(isdefined(player.pers["team"]) && (player.pers["team"] == "allies" || player.pers["team"] == "axis"))
		{
			player.score = 0;
			player.deaths = 0;

			// kill running player threads and respawn
			player notify("kill_thread");
			wait(0);
			player spawnPlayer();
		}
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
		if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"])) self.respawntimer.alpha = 1;
		else self.respawntimer.alpha = 0;
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

getTeamCount(team)
{
	count = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && (player.pers["team"] == team))
			count++;
	}

	return count;
}
