/*QUAKED mp_dm_spawn (1.0 0.5 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies at one of these positions.*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_clientcontrol::menuAutoAssignDM;
	level.allies = extreme\_ex_clientcontrol::menuAllies;
	level.axis = extreme\_ex_clientcontrol::menuAxis;
	level.spectator = extreme\_ex_clientcontrol::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.spawnplayer = ::spawnplayer;
	level.updatetimer = ::blank;
	level.endgameconfirmed = ::endMap;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();
}

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
{
	wait(0);
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
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
		}
		precacheShader("hud_status_dead");
		precacheShader("objpoint_A");
		precacheShader("objpoint_B");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		precacheString(&"Join-O-Meter");
		precacheString(&"Kill-O-Meter");
		precacheString(&"Die-O-Meter");
		precacheString(&"Duel-O-Meter");
		precacheString(&"Alive players: ");
		precacheString(&"Opponent Info");
		precacheString(&"Player ^3A");
		precacheString(&"Player ^3B");
		precacheString(&"Distance(m)");
		precacheString(&"Health");
		precacheString(&"Weapon");
		precacheString(&"Ammo");
		precacheString(&"Sniper");
		precacheString(&"Rifle");
		precacheString(&"Shotgun");
		precacheString(&"Machinegun");
		precacheString(&"Pistol");
		precacheString(&"Knife");
		precacheString(&"Sprinting");
		precacheString(&"Turret");
		precacheString(&"Bazooka");
		precacheString(&"Grenade");
		precacheString(&"Smoke");
		precacheString(&"Flamethrower");
		precacheString(&"None");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_playerscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.jointimeleft = level.joinperiodtime;
	level.dueltimeleft = level.duelperiodtime;

	level.matchstarted = false;
	level.joinperiod = false;
	level.endingmatch = false;
	level.duel = false;
	level.oldbarsize = 0;
	level.QuickMessageToAll = true;
	level.mapended = false;

	if(!isdefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	thread startGame();
	thread updateGametypeCvars();

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
		self.sessionteam = "none";

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
	self extreme\_ex_clientcontrol::explayerdisconnect();

	if(isdefined(self.clientid))
		setplayerteamrank(self, self.clientid, 0);

	checkAlivePlayers();
	self removeKillOMeter();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;

	// Don't do knockback if the damage direction was not specified
	if(!isdefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1) iDamage = 1;

		// Apply the damage to the player
		self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
		self playrumble("damage_heavy");

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

		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator") return;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self removeKillOMeter();
	self thread removeDuelHud();

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";

	if(!isdefined(self.switching_teams))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfteam = "";
	lpselfguid = self getGuid();
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			//if(!isdefined(self.switching_teams))
			//attacker.score--;
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			//attacker.score++;
			//attacker checkScoreLimit();
			attacker.killometer = level.killometer;
			attacker updateKillOMeter();
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;

		attacker notify("update_playerscore_hud");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		//self.score--;

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";

		self notify("update_playerscore_hud");
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
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"]);

	if(!isdefined(self.nowinner))
		checkAlivePlayers();
	else
		self.nowinner = undefined;

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait( [[level.ex_fpstime]](delay) );	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);

	self thread spawnPlayer();
}

spawnPlayer()
{
	self endon("disconnect");

	// Avoid duplicates
	self notify("lms_respawn");
	self endon("lms_respawn");

	// Wait for spawn if we are not in the first joinperiod or if we have already spawned once.
	if(!level.joinperiod || isdefined(self.spawned))
	{
		self thread extreme\_ex_spawn::spawnSpectator(self.origin + (0, 0, 60), self.angles);
		if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";

		if(!level.matchstarted) thread countPlayers();
			else self iprintlnbold(&"MP_LMS_NEXT_CYCLE");

		level waittill("lms_spawn_players");
	}
	
	// Flag player as one that has spawned at least once
	self.spawned = true;

	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;

	self extreme\_ex_main::exprespawn();
	
	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_DM(spawnpoints);

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

	if(level.scorelimit > 0) self setClientCvar("cg_objectiveText", &"MP_LMS_OBJ_TEXT", level.scorelimit);
		else self setClientCvar("cg_objectiveText", &"MP_LMS_OBJ_TEXT_NOSCORE");

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");

	checkAlivePlayers(true);
	self thread killOMeter();
}

respawn()
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

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

	updateAlivePlayersHud(0);

	for(;;)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	players = level.players;
	highscore = undefined;
	tied = undefined;
	playername = undefined;
	name = undefined;
	guid = undefined;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] == "spectator")
			continue;

		if(!isdefined(highscore))
		{
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
			continue;
		}

		if(player.score == highscore)
			tied = true;
		else if(player.score > highscore)
		{
			tied = false;
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
		}
	}

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();

		if(isdefined(tied) && tied == true)
			player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
		else if(isdefined(playername))
			player setClientCvar("cg_objectiveText", &"MP_WINS", playername);

		player extreme\_ex_spawn::spawnIntermission();

		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	if(isdefined(name))
		logPrint("W;;" + guid + ";" + name + "\n");

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

	if(self.score < level.scorelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_lms_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_lms_timelimit", "1440");
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

		scorelimit = getcvarint("scr_lms_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			players = level.players;
			for(i = 0; i < players.size; i++)
				players[i] checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateAlivePlayersHud(n)
{
	if(!isdefined(level.aphud))
	{
		level.aphud = newHudElem();
		level.aphud.alignX = "center";
		level.aphud.alignY = "middle";
		level.aphud.x = 320;
		level.aphud.y = 20;
		level.aphud.alpha = 0.8;
		level.aphud.color = (1,1,1);
		level.aphud.label = &"Alive players: ";
	}
	level.aphud setValue(n);			
}

checkAlivePlayers(spawn)
{
	// Count the number of players who is still alive
	n=0;
	lastOnesAlive = undefined;
	lastOnesAlive2 = undefined;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player) && isAlive(player))
		{
			n++;

			// Save the two last players
			if(isdefined(lastOnesAlive)) lastOnesAlive2 = lastOnesAlive;
			lastOnesAlive = player;
		}
	}

	updateAlivePlayersHud(n);

	// Do not check for winners when players spawn
	if(isdefined(spawn)) return;

	// Do we have a winner?
	if(n<2)
		level thread endMatch(lastOnesAlive);
	else if(n==2)
		level thread duel(lastOnesAlive, lastOnesAlive2);
}

countPlayers()
{
	// Count the number of players who has chosen their team
	n=0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isdefined(player.pers["team"])) n++;
	}

	// Do we have enough players to start?
	if(n>=level.minplayers)
	{
		// Start join period
		level thread watchJoinPeriod();
	}
	else
	{
		iprintlnbold(&"MP_LMS_WAITING",(level.minplayers - n), &"MP_LMS_PLAYERS");
	}
}

watchJoinPeriod()
{
	level notify("end_watchJoinPeriod");
	level endon("end_watchJoinPeriod");

	// Make sure we have only one thread
	if(level.joinperiod) return;
	level.joinperiod = true;
	level.jointimeleft = level.joinperiodtime;

	// Officially start the game
	level.matchstarted = true;
	
	// Spawn all waiting players
	iprintlnbold(&"MP_LMS_SPAWNING");
	level notify("lms_spawn_players");
	wait( [[level.ex_fpstime]](0.05) );
	level notify("lms_spawn_players");

	iprintlnbold(&"MP_LMS_OPEN_FOR_JOIN", level.joinperiodtime, &"MP_LMS_SECONDS");
	// Allow new players to join for the specified amount of time
	for(i=0;i<level.joinperiodtime;i++)
	{
		level.jointimeleft = level.joinperiodtime - i;
		wait( [[level.ex_fpstime]](1) );
	}
	iprintlnbold(&"MP_LMS_NO_JOIN");

	// Join period is officially over
	level.joinperiod = false;
}

endMatch(winner)
{
	// Avoid dups
	if(level.endingmatch) return;
	level.endingmatch = true;

	// Reset flags
	level.joinperiod = false;
	level.duel = false;

	// Kill threads
	level notify("end_killometers");
	level notify("end_duel");

	removeDuelOMeter();
	removeSpectatorHuds();

	// Announce winner
	if(isdefined(winner))
	{
		iprintlnbold(&"MP_LMS_WINNER", [[level.ex_pname]](winner));

		winner.score++;
		winner notify("update_playerhud_score");
		winner thread removeDuelHud();
		wait( [[level.ex_fpstime]](1) );

		if(level.killwinner && isAlive(winner))
		{
			winner.ex_forcedsuicide = true;
			winner suicide();
		}
	}
	else iprintlnbold(&"MP_LMS_NO_SURVIVE");

	wait( [[level.ex_fpstime]](4) );
	if(isdefined(winner))
		winner checkScoreLimit();

	// Did the map end?
	if(level.mapended)	return;

	// Reset player flags for dead players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isAlive(player))
			player.spawned = undefined;

		player.killometer = level.killometer;
		player updateKillOMeter();
	}

	// Restart the kill-o-meter for the winner if still alive
	if(isDefined(winner) && isAlive(winner))
		winner thread killometer();

	// Start a new join period
	level notify("end_watchJoinPeriod");
	wait( [[level.ex_fpstime]](0.05) );
	level.joinperiod = false;
	level thread watchJoinPeriod();

	level.endingmatch = false;
}

killOMeter()
{
	self endon("disconnect");
	self endon("spawned");
	self endon("killed_player");
	level endon("end_killometers");

	// Avoid duplicate threads, happens sometimes, reason unknown
	self notify("end_killometer");
	wait( [[level.ex_fpstime]](0.05) );
	self endon("end_killometer");

	self.killometer = level.killometer;
	self setupKillOMeter();

	while(isAlive(self) && self.sessionstate == "playing")
	{
		updateKillOMeter();
		wait( [[level.ex_fpstime]](1) );
		if(self.killometer && !level.joinperiod)
			self.killometer--;
		else if(!self.killometer)
		{
			self.ex_forcedsuicide = true;
			self suicide();
		}
	}
	self removeKillOMeter();
}

removeKillOMeter()
{
	if(isdefined(self.komback)) self.komback destroy();
	if(isdefined(self.komfront)) self.komfront destroy();
	if(isdefined(self.komtext)) self.komtext destroy();
}

setupKillOMeter()
{
	y = 10;
	barsize = 300;

	self.oldbarsize = barsize;

	self removeKillOMeter();

	self.komback = newClientHudElem(self);
	self.komback.archived = false;
	self.komback.sort = 1;
	self.komback.horzAlign = "fullscreen";
	self.komback.vertAlign = "fullscreen";
	self.komback.alignX = "center";
	self.komback.alignY = "middle";
	self.komback.x = 320;
	self.komback.y = y;
	self.komback.alpha = 0.3;
	self.komback.color = (0.2,0.2,0.2);
	self.komback setShader("white", barsize+4, 13);

	self.komfront = newClientHudElem(self);
	self.komfront.archived = false;
	self.komfront.sort = 2;
	self.komfront.horzAlign = "fullscreen";
	self.komfront.vertAlign = "fullscreen";
	self.komfront.alignX = "center";
	self.komfront.alignY = "middle";
	self.komfront.x = 320;
	self.komfront.y = y;
	self.komfront.color = (0,1,0);
	self.komfront.alpha = 0.5;
	self.komfront setShader("white", barsize, 11);

	self.komtext = newClientHudElem(self);
	self.komtext.archived = false;
	self.komtext.sort = 3;
	self.komtext.horzAlign = "fullscreen";
	self.komtext.vertAlign = "fullscreen";
	self.komtext.alignX = "center";
	self.komtext.alignY = "middle";
	self.komtext.x = 320;
	self.komtext.y = y;
	self.komtext.alpha = 0.8;
	self.komtext.color = (1,1,1);
	self.komtext setText(&"Kill-O-Meter");
}

updateKillOMeter()
{
	y = 10;
	barsize = 300;

	if(isdefined(self.komfront))
	{
		if(level.joinperiod)
		{
			pc = level.jointimeleft/level.joinperiodtime;
			self.komtext setText(&"Join-O-Meter");
			self.komfront.color = (0,0,1);
		}
		else
		{
			pc = self.killometer/level.killometer;
			if(pc>=0.55)
			{
				c = 1 - (pc - 0.55)/0.45;
				self.komfront.color = (1*c,1,0);
				self.komtext setText(&"Kill-O-Meter");
			}
			else if(pc>=0.1)
			{
				c = (pc-0.1)/0.45;
				self.komfront.color = (1,1*c,0);
				self.komtext setText(&"Kill-O-Meter");
			}
			else
			{
				self.komtext setText(&"Die-O-Meter");
				self.komfront.color = (1,0,0);
			}
		}

		size = int(barsize * pc + 0.5);
		if(size < 1) size = 1;
		if(self.oldbarsize != size)
		{
			self.komfront scaleOverTime(1, size, 11);
			self.oldbarsize = size;
		}
	}
}

duel(p1, p2)
{
	level notify("end_duel");
	level endon("end_duel");
	if(level.duel) return;
	level.duel = true;
	level.dueltimeleft = level.duelperiodtime;

	// End join period
	level notify("end_watchJoinPeriod");
	level.joinperiod = false;

	iprintlnbold(&"MP_LMS_DUEL", level.duelperiodtime, &"MP_LMS_SECONDS");

	if(isDefined(p1) && isAlive(p1) && isDefined(p2) && isAlive(p2))
	{
		p1 notify("end_killometer");
		p2 notify("end_killometer");
		p1 removeKillOMeter();
		p2 removeKillOMeter();
		p1 thread duelHud(p2);
		p2 thread duelHud(p1);
	}

	setupDuelOMeter();

	setupSpectatorHuds(p1,p2);

	for(i=0;i<level.duelperiodtime;i++)
	{
		level.dueltimeleft = level.duelperiodtime - i;
		updateDuelOMeter();
		wait( [[level.ex_fpstime]](1) );
	}

	// If we get here then there is no winners, kill the loosers...
	iprintlnbold(&"MP_LMS_SUCKS");
	p1.nowinner = true;
	p1.ex_forcedsuicide = true;
	p1 suicide();
	p2.ex_forcedsuicide = true;
	p2 suicide();

	// End match without winner
	endMatch(undefined);
}

duelHud(other)
{
	self endon("end_duelhud");

	size = 70;
	x = 6;
	y = 60;

	other.dh_weapon = &"None";
	other.dh_ammo = 0;

	titlecolor = (1,1,1);
	subtitlecolor = (0.8,0.8,0.8);
	valuecolor = (1,1,0);

	self.duelback = newClientHudElem(self);
	self.duelback.horzAlign = "left";
	self.duelback.vertAlign = "top";
	self.duelback.alignX = "left";
	self.duelback.alignY = "top";
	self.duelback.x = x;
	self.duelback.y = y;
	self.duelback.alpha = 0.3;
	self.duelback.color = (0,0,0.2);
	self.duelback setShader("white", 1, 135);			
	self.duelback scaleOverTime(1, size , 135);

	wait( [[level.ex_fpstime]](1) );

	if(!isdefined(self) || !isdefined(other) || !isAlive(self) || !isAlive(other)) return;

	dist = int(distance(self.origin, other.origin) * 0.0254 + 0.5);
	cw = other getCurrentWeapon();
	weapon = weaponType(cw);
	ammo = other getammocount(cw);

	other.dh_weapon = weapon;
	other.dh_ammo = ammo;

	self.dueltitle = newClientHudElem(self);
	self.dueltitle.horzAlign = "left";
	self.dueltitle.vertAlign = "top";
	self.dueltitle.alignX = "center";
	self.dueltitle.alignY = "top";
	self.dueltitle.x = x+(size/2);
	self.dueltitle.y = y+2;
	self.dueltitle.alpha = 0;
	self.dueltitle.color = titlecolor;
	self.dueltitle setText(&"Opponent Info");			
	self.dueltitle fadeOverTime(1);
	self.dueltitle.alpha = 1;

	self.dueldist = newClientHudElem(self);
	self.dueldist.horzAlign = "left";
	self.dueldist.vertAlign = "top";
	self.dueldist.alignX = "center";
	self.dueldist.alignY = "top";
	self.dueldist.x = x+(size/2);
	self.dueldist.y = y+17;
	self.dueldist.alpha = 0;
	self.dueldist.color = subtitlecolor;
	self.dueldist setText(&"Distance(m)");			
	self.dueldist fadeOverTime(2);
	self.dueldist.alpha = 1;

	self.dueldist2 = newClientHudElem(self);
	self.dueldist2.horzAlign = "left";
	self.dueldist2.vertAlign = "top";
	self.dueldist2.alignX = "center";
	self.dueldist2.alignY = "top";
	self.dueldist2.x = x+(size/2);
	self.dueldist2.y = y+30;
	self.dueldist2.alpha = 0;
	self.dueldist2.color = valuecolor;
	self.dueldist2 setValue(dist);			
	self.dueldist2 fadeOverTime(2);
	self.dueldist2.alpha = 0.8;
	
	self.duelhealth = newClientHudElem(self);
	self.duelhealth.horzAlign = "left";
	self.duelhealth.vertAlign = "top";
	self.duelhealth.alignX = "center";
	self.duelhealth.alignY = "top";
	self.duelhealth.x = x+(size/2);
	self.duelhealth.y = y + 47;
	self.duelhealth.alpha = 0;
	self.duelhealth.color = subtitlecolor;
	self.duelhealth setText(&"Health");			
	self.duelhealth fadeOverTime(2);
	self.duelhealth.alpha = 0.8;

	self.duelhealth2 = newClientHudElem(self);
	self.duelhealth2.horzAlign = "left";
	self.duelhealth2.vertAlign = "top";
	self.duelhealth2.alignX = "center";
	self.duelhealth2.alignY = "top";
	self.duelhealth2.x = x+(size/2);
	self.duelhealth2.y = y + 60;
	self.duelhealth2.alpha = 0;
	self.duelhealth2.color = valuecolor;
	self.duelhealth2 setValue(other.health);			
	self.duelhealth2 fadeOverTime(2);
	self.duelhealth2.alpha = 0.8;

	self.duelweapon = newClientHudElem(self);
	self.duelweapon.horzAlign = "left";
	self.duelweapon.vertAlign = "top";
	self.duelweapon.alignX = "center";
	self.duelweapon.alignY = "top";
	self.duelweapon.x = x+(size/2);
	self.duelweapon.y = y + 77;
	self.duelweapon.alpha = 0;
	self.duelweapon.color = subtitlecolor;
	self.duelweapon setText(&"Weapon");			
	self.duelweapon fadeOverTime(2);
	self.duelweapon.alpha = 0.8;

	self.duelweapon2 = newClientHudElem(self);
	self.duelweapon2.horzAlign = "left";
	self.duelweapon2.vertAlign = "top";
	self.duelweapon2.alignX = "center";
	self.duelweapon2.alignY = "top";
	self.duelweapon2.x = x+(size/2);
	self.duelweapon2.y = y + 90;
	self.duelweapon2.alpha = 0;
	self.duelweapon2.color = valuecolor;
	self.duelweapon2 setText(weapon);			
	self.duelweapon2 fadeOverTime(2);
	self.duelweapon2.alpha = 0.8;

	self.duelammo = newClientHudElem(self);
	self.duelammo.horzAlign = "left";
	self.duelammo.vertAlign = "top";
	self.duelammo.alignX = "center";
	self.duelammo.alignY = "top";
	self.duelammo.x = x+(size/2);
	self.duelammo.y = y + 107;
	self.duelammo.alpha = 0;
	self.duelammo.color = subtitlecolor;
	self.duelammo setText(&"Ammo");			
	self.duelammo fadeOverTime(2);
	self.duelammo.alpha = 0.8;

	self.duelammo2 = newClientHudElem(self);
	self.duelammo2.horzAlign = "left";
	self.duelammo2.vertAlign = "top";
	self.duelammo2.alignX = "center";
	self.duelammo2.alignY = "top";
	self.duelammo2.x = x+(size/2);
	self.duelammo2.y = y + 120;
	self.duelammo2.alpha = 0;
	self.duelammo2.color = valuecolor;
	self.duelammo2 setValue(ammo);			
	self.duelammo2 fadeOverTime(2);
	self.duelammo2.alpha = 0.8;

	while(isdefined(self) && isAlive(self) && self.sessionstate == "playing" && isdefined(other) && isAlive(other) && other.sessionstate == "playing")
	{
		dist = int(distance(self.origin, other.origin) * 0.0254 + 0.5);
		self.dueldist2 setValue(dist);			
		self.duelhealth2 setValue(other.health);			

		cw = other getCurrentWeapon();
		weapon = weaponType(cw);
		ammo = other getammocount(cw);
		self.duelweapon2 setText(weapon);			
		self.duelammo2 setValue(ammo);			

		other.dh_weapon = weapon;
		other.dh_ammo = ammo;

		wait( [[level.ex_fpstime]](0.05) );
	}
}

removeDuelHud()
{
	// End thread
	self notify("end_duelhud");

	// Fade away text
	if(isdefined(self.dueltitle))
	{
		self.dueltitle fadeOverTime(1);
		self.dueltitle.alpha = 0;
	}
	if(isdefined(self.dueldist))
	{
		self.dueldist fadeOverTime(1);
		self.dueldist.alpha = 0;
	}
	if(isdefined(self.dueldist2))
	{
		self.dueldist2 fadeOverTime(1);
		self.dueldist2.alpha = 0;
	}
	if(isdefined(self.duelhealth))
	{
		self.duelhealth fadeOverTime(1);
		self.duelhealth.alpha = 0;
	}
	if(isdefined(self.duelhealth2))
	{
		self.duelhealth2 fadeOverTime(1);
		self.duelhealth2.alpha = 0;
	}
	if(isdefined(self.duelweapon))
	{
		self.duelweapon fadeOverTime(1);
		self.duelweapon.alpha = 0;
	}
	if(isdefined(self.duelweapon2))
	{
		self.duelweapon2 fadeOverTime(1);
		self.duelweapon2.alpha = 0;
	}
	if(isdefined(self.duelammo))
	{
		self.duelammo fadeOverTime(1);
		self.duelammo.alpha = 0;
	}
	if(isdefined(self.duelammo2))
	{
		self.duelammo2 fadeOverTime(1);
		self.duelammo2.alpha = 0;
	}
	wait( [[level.ex_fpstime]](1) );

	if(isdefined(self.duelback))
		self.duelback scaleOverTime(1, 1 , 135);

	wait( [[level.ex_fpstime]](1) );

	// Remove HUD elements
	if(isdefined(self.duelback)) self.duelback destroy();
	if(isdefined(self.dueldist)) self.dueldist destroy();
	if(isdefined(self.dueldist2)) self.dueldist2 destroy();
	if(isdefined(self.duelhealth)) self.duelhealth destroy();
	if(isdefined(self.duelhealth2)) self.duelhealth2 destroy();
	if(isdefined(self.duelweapon)) self.duelweapon destroy();
	if(isdefined(self.duelweapon2)) self.duelweapon2 destroy();
	if(isdefined(self.duelammo)) self.duelammo destroy();
	if(isdefined(self.duelammo2)) self.duelammo2 destroy();
	if(isdefined(self.dueltitle)) self.dueltitle destroy();
}

weaponType(cw)
{
	if(extreme\_ex_weapons::isWeaponType(cw, "rifle")) weapon = &"Rifle";
	else if(extreme\_ex_weapons::isWeaponType(cw, "mg") || extreme\_ex_weapons::isWeaponType(cw, "smg")) weapon = &"Machinegun";
	else if(extreme\_ex_weapons::isWeaponType(cw, "sniper")) weapon = &"Sniper";
	else if(extreme\_ex_weapons::isWeaponType(cw, "shotgun")) weapon = &"Shotgun";
	else if(extreme\_ex_weapons::isWeaponType(cw, "pistol")) weapon = &"Pistol";
	else if(extreme\_ex_weapons::isWeaponType(cw, "knife")) weapon = &"Knife";
	else if(extreme\_ex_weapons::isWeaponType(cw, "turret")) weapon = &"Turret";
	else if(extreme\_ex_weapons::isWeaponType(cw, "flamethrower")) weapon = &"Flamethrower";
	else if(extreme\_ex_weapons::isWeaponType(cw, "fraggrenade") ||
		extreme\_ex_weapons::isWeaponType(cw, "firegrenade") ||
		extreme\_ex_weapons::isWeaponType(cw, "gasgrenade") ||
		extreme\_ex_weapons::isWeaponType(cw, "satchelcharge")) weapon = &"Grenade";
	else if(extreme\_ex_weapons::isWeaponType(cw, "smokegrenade")) weapon = &"Smoke";
	else if(extreme\_ex_weapons::isWeaponType(cw, "rocket")) weapon = &"Bazooka";
	else if(cw == game["sprint"]) weapon = &"Sprinting";
	else weapon = &"None";

	return weapon;
}

removeDuelOMeter()
{
	if(isdefined(level.duelback)) level.duelback destroy();
	if(isdefined(level.duelfront)) level.duelfront destroy();
	if(isdefined(level.dueltext)) level.dueltext destroy();
}

setupDuelOMeter()
{
	y = 10;
	barsize = 300;

	level.oldbarsize = barsize;

	level removeDuelOMeter();

	level.duelback = newHudElem();
	level.duelback.archived = false;
	level.duelback.sort = 1;
	level.duelback.horzAlign = "fullscreen";
	level.duelback.vertAlign = "fullscreen";
	level.duelback.alignX = "center";
	level.duelback.alignY = "middle";
	level.duelback.x = 320;
	level.duelback.y = y;
	level.duelback.alpha = 0.3;
	level.duelback.color = (0.2,0.2,0.2);
	level.duelback setShader("white", barsize+4, 13);

	level.duelfront = newHudElem();
	level.duelfront.archived = false;
	level.duelfront.sort = 2;
	level.duelfront.horzAlign = "fullscreen";
	level.duelfront.vertAlign = "fullscreen";
	level.duelfront.alignX = "center";
	level.duelfront.alignY = "middle";
	level.duelfront.x = 320;
	level.duelfront.y = y;
	level.duelfront.color = (1,1,0);
	level.duelfront.alpha = 0.5;
	level.duelfront setShader("white", barsize, 11);

	level.dueltext = newHudElem();
	level.dueltext.archived = false;
	level.dueltext.sort = 3;
	level.dueltext.horzAlign = "fullscreen";
	level.dueltext.vertAlign = "fullscreen";
	level.dueltext.alignX = "center";
	level.dueltext.alignY = "middle";
	level.dueltext.x = 320;
	level.dueltext.y = y;
	level.dueltext.alpha = 0.8;
	level.dueltext.color = (1,1,1);
	level.dueltext setText(&"Duel-O-Meter");
}

updateDuelOMeter()
{
	y = 10;
	barsize = 300;

	if(isdefined(level.duelfront))
	{
		pc = level.dueltimeleft/level.duelperiodtime;
		level.duelfront.color = (1,1*pc,0);

		size = int(barsize * pc + 0.5);
		if(size < 1) size = 1;
		if(level.oldbarsize != size)
		{
			level.duelfront scaleOverTime(1, size, 11);
			level.oldbarsize = size;
		}
	}
}

setupSpectatorHuds(a,b)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && !isAlive(player))
		{
			player thread spectatorHud(a,b);
		}
	}
}

spectatorHud(a,b)
{
	self endon("disconnect");
	self endon("end_spectatorhud");

	self.spectatorhud = true;

	size = 70;
	x = 6;
	y = 60;
	x2 = x + y + 20;

	titlecolor = (1,1,1);
	subtitlecolor = (0.8,0.8,0.8);
	valuecolor = (0,0.8,0);
	valuecolor2 = (0.8,0,0);

	self.spectatorback = newClientHudElem(self);
	self.spectatorback.horzAlign = "left";
	self.spectatorback.vertAlign = "top";
	self.spectatorback.alignX = "left";
	self.spectatorback.alignY = "top";
	self.spectatorback.x = x;
	self.spectatorback.y = y;
	self.spectatorback.alpha = 0.3;
	self.spectatorback.color = (0,0.2,0);
	self.spectatorback setShader("white", 1, 135);			
	self.spectatorback scaleOverTime(1, size , 135);

	self.spectator2back = newClientHudElem(self);
	self.spectator2back.horzAlign = "left";
	self.spectator2back.vertAlign = "top";
	self.spectator2back.alignX = "left";
	self.spectator2back.alignY = "top";
	self.spectator2back.x = x2;
	self.spectator2back.y = y;
	self.spectator2back.alpha = 0.3;
	self.spectator2back.color = (0.2,0,0);
	self.spectator2back setShader("white", 1, 135);			
	self.spectator2back scaleOverTime(1, size , 135);

	wait( [[level.ex_fpstime]](1) );

	if(!isdefined(a) || !isdefined(b) || !isAlive(a) || !isAlive(b)) return;

	self.spectatortitle = newClientHudElem(self);
	self.spectatortitle.horzAlign = "left";
	self.spectatortitle.vertAlign = "top";
	self.spectatortitle.alignX = "center";
	self.spectatortitle.alignY = "top";
	self.spectatortitle.x = x+(size/2);
	self.spectatortitle.y = y+2;
	self.spectatortitle.alpha = 0;
	self.spectatortitle.color = titlecolor;
	self.spectatortitle setText(&"Player ^3A");			
	self.spectatortitle fadeOverTime(1);
	self.spectatortitle.alpha = 1;

	self.spectatordist = newClientHudElem(self);
	self.spectatordist.horzAlign = "left";
	self.spectatordist.vertAlign = "top";
	self.spectatordist.alignX = "center";
	self.spectatordist.alignY = "top";
	self.spectatordist.x = x+(size/2);
	self.spectatordist.y = y+17;
	self.spectatordist.alpha = 0;
	self.spectatordist.color = subtitlecolor;
	self.spectatordist setText(&"Distance(m)");			
	self.spectatordist fadeOverTime(2);
	self.spectatordist.alpha = 1;

	self.spectatordist2 = newClientHudElem(self);
	self.spectatordist2.horzAlign = "left";
	self.spectatordist2.vertAlign = "top";
	self.spectatordist2.alignX = "center";
	self.spectatordist2.alignY = "top";
	self.spectatordist2.x = x+(size/2);
	self.spectatordist2.y = y+30;
	self.spectatordist2.alpha = 0;
	self.spectatordist2.color = valuecolor;
	self.spectatordist2 setValue(0);
	self.spectatordist2 fadeOverTime(2);
	self.spectatordist2.alpha = 0.8;
	
	self.spectatorhealth = newClientHudElem(self);
	self.spectatorhealth.horzAlign = "left";
	self.spectatorhealth.vertAlign = "top";
	self.spectatorhealth.alignX = "center";
	self.spectatorhealth.alignY = "top";
	self.spectatorhealth.x = x+(size/2);
	self.spectatorhealth.y = y + 47;
	self.spectatorhealth.alpha = 0;
	self.spectatorhealth.color = subtitlecolor;
	self.spectatorhealth setText(&"Health");			
	self.spectatorhealth fadeOverTime(2);
	self.spectatorhealth.alpha = 0.8;

	self.spectatorhealth2 = newClientHudElem(self);
	self.spectatorhealth2.horzAlign = "left";
	self.spectatorhealth2.vertAlign = "top";
	self.spectatorhealth2.alignX = "center";
	self.spectatorhealth2.alignY = "top";
	self.spectatorhealth2.x = x+(size/2);
	self.spectatorhealth2.y = y + 60;
	self.spectatorhealth2.alpha = 0;
	self.spectatorhealth2.color = valuecolor;
	self.spectatorhealth2 setValue(a.health);			
	self.spectatorhealth2 fadeOverTime(2);
	self.spectatorhealth2.alpha = 0.8;

	self.spectatorweapon = newClientHudElem(self);
	self.spectatorweapon.horzAlign = "left";
	self.spectatorweapon.vertAlign = "top";
	self.spectatorweapon.alignX = "center";
	self.spectatorweapon.alignY = "top";
	self.spectatorweapon.x = x+(size/2);
	self.spectatorweapon.y = y + 77;
	self.spectatorweapon.alpha = 0;
	self.spectatorweapon.color = subtitlecolor;
	self.spectatorweapon setText(&"Weapon");			
	self.spectatorweapon fadeOverTime(2);
	self.spectatorweapon.alpha = 0.8;

	self.spectatorweapon2 = newClientHudElem(self);
	self.spectatorweapon2.horzAlign = "left";
	self.spectatorweapon2.vertAlign = "top";
	self.spectatorweapon2.alignX = "center";
	self.spectatorweapon2.alignY = "top";
	self.spectatorweapon2.x = x+(size/2);
	self.spectatorweapon2.y = y + 90;
	self.spectatorweapon2.alpha = 0;
	self.spectatorweapon2.color = valuecolor;
	self.spectatorweapon2 setText(a.dh_weapon);
	self.spectatorweapon2 fadeOverTime(2);
	self.spectatorweapon2.alpha = 0.8;

	self.spectatorammo = newClientHudElem(self);
	self.spectatorammo.horzAlign = "left";
	self.spectatorammo.vertAlign = "top";
	self.spectatorammo.alignX = "center";
	self.spectatorammo.alignY = "top";
	self.spectatorammo.x = x+(size/2);
	self.spectatorammo.y = y + 107;
	self.spectatorammo.alpha = 0;
	self.spectatorammo.color = subtitlecolor;
	self.spectatorammo setText(&"Ammo");			
	self.spectatorammo fadeOverTime(2);
	self.spectatorammo.alpha = 0.8;

	self.spectatorammo2 = newClientHudElem(self);
	self.spectatorammo2.horzAlign = "left";
	self.spectatorammo2.vertAlign = "top";
	self.spectatorammo2.alignX = "center";
	self.spectatorammo2.alignY = "top";
	self.spectatorammo2.x = x+(size/2);
	self.spectatorammo2.y = y + 120;
	self.spectatorammo2.alpha = 0;
	self.spectatorammo2.color = valuecolor;
	self.spectatorammo2 setValue(a.dh_ammo);
	self.spectatorammo2 fadeOverTime(2);
	self.spectatorammo2.alpha = 0.8;

	self.spectator2title = newClientHudElem(self);
	self.spectator2title.horzAlign = "left";
	self.spectator2title.vertAlign = "top";
	self.spectator2title.alignX = "center";
	self.spectator2title.alignY = "top";
	self.spectator2title.x = x2+(size/2);
	self.spectator2title.y = y+2;
	self.spectator2title.alpha = 0;
	self.spectator2title.color = titlecolor;
	self.spectator2title setText(&"Player ^3B");			
	self.spectator2title fadeOverTime(1);
	self.spectator2title.alpha = 1;

	self.spectator2dist = newClientHudElem(self);
	self.spectator2dist.horzAlign = "left";
	self.spectator2dist.vertAlign = "top";
	self.spectator2dist.alignX = "center";
	self.spectator2dist.alignY = "top";
	self.spectator2dist.x = x2+(size/2);
	self.spectator2dist.y = y+17;
	self.spectator2dist.alpha = 0;
	self.spectator2dist.color = subtitlecolor;
	self.spectator2dist setText(&"Distance(m)");			
	self.spectator2dist fadeOverTime(2);
	self.spectator2dist.alpha = 1;

	self.spectator2dist2 = newClientHudElem(self);
	self.spectator2dist2.horzAlign = "left";
	self.spectator2dist2.vertAlign = "top";
	self.spectator2dist2.alignX = "center";
	self.spectator2dist2.alignY = "top";
	self.spectator2dist2.x = x2+(size/2);
	self.spectator2dist2.y = y+30;
	self.spectator2dist2.alpha = 0;
	self.spectator2dist2.color = valuecolor2;
	self.spectator2dist2 setValue(0);
	self.spectator2dist2 fadeOverTime(2);
	self.spectator2dist2.alpha = 0.8;
	
	self.spectator2health = newClientHudElem(self);
	self.spectator2health.horzAlign = "left";
	self.spectator2health.vertAlign = "top";
	self.spectator2health.alignX = "center";
	self.spectator2health.alignY = "top";
	self.spectator2health.x = x2+(size/2);
	self.spectator2health.y = y + 47;
	self.spectator2health.alpha = 0;
	self.spectator2health.color = subtitlecolor;
	self.spectator2health setText(&"Health");			
	self.spectator2health fadeOverTime(2);
	self.spectator2health.alpha = 0.8;

	self.spectator2health2 = newClientHudElem(self);
	self.spectator2health2.horzAlign = "left";
	self.spectator2health2.vertAlign = "top";
	self.spectator2health2.alignX = "center";
	self.spectator2health2.alignY = "top";
	self.spectator2health2.x = x2+(size/2);
	self.spectator2health2.y = y + 60;
	self.spectator2health2.alpha = 0;
	self.spectator2health2.color = valuecolor2;
	self.spectator2health2 setValue(b.health);			
	self.spectator2health2 fadeOverTime(2);
	self.spectator2health2.alpha = 0.8;

	self.spectator2weapon = newClientHudElem(self);
	self.spectator2weapon.horzAlign = "left";
	self.spectator2weapon.vertAlign = "top";
	self.spectator2weapon.alignX = "center";
	self.spectator2weapon.alignY = "top";
	self.spectator2weapon.x = x2+(size/2);
	self.spectator2weapon.y = y + 77;
	self.spectator2weapon.alpha = 0;
	self.spectator2weapon.color = subtitlecolor;
	self.spectator2weapon setText(&"Weapon");			
	self.spectator2weapon fadeOverTime(2);
	self.spectator2weapon.alpha = 0.8;

	self.spectator2weapon2 = newClientHudElem(self);
	self.spectator2weapon2.horzAlign = "left";
	self.spectator2weapon2.vertAlign = "top";
	self.spectator2weapon2.alignX = "center";
	self.spectator2weapon2.alignY = "top";
	self.spectator2weapon2.x = x2+(size/2);
	self.spectator2weapon2.y = y + 90;
	self.spectator2weapon2.alpha = 0;
	self.spectator2weapon2.color = valuecolor2;
	self.spectator2weapon2 setText(b.dh_weapon);
	self.spectator2weapon2 fadeOverTime(2);
	self.spectator2weapon2.alpha = 0.8;

	self.spectator2ammo = newClientHudElem(self);
	self.spectator2ammo.horzAlign = "left";
	self.spectator2ammo.vertAlign = "top";
	self.spectator2ammo.alignX = "center";
	self.spectator2ammo.alignY = "top";
	self.spectator2ammo.x = x2+(size/2);
	self.spectator2ammo.y = y + 107;
	self.spectator2ammo.alpha = 0;
	self.spectator2ammo.color = subtitlecolor;
	self.spectator2ammo setText(&"Ammo");			
	self.spectator2ammo fadeOverTime(2);
	self.spectator2ammo.alpha = 0.8;

	self.spectator2ammo2 = newClientHudElem(self);
	self.spectator2ammo2.horzAlign = "left";
	self.spectator2ammo2.vertAlign = "top";
	self.spectator2ammo2.alignX = "center";
	self.spectator2ammo2.alignY = "top";
	self.spectator2ammo2.x = x2+(size/2);
	self.spectator2ammo2.y = y + 120;
	self.spectator2ammo2.alpha = 0;
	self.spectator2ammo2.color = valuecolor2;
	self.spectator2ammo2 setValue(b.dh_ammo);
	self.spectator2ammo2 fadeOverTime(2);
	self.spectator2ammo2.alpha = 0.8;

	// Add objective points
	self.objpointa = newClientHudElem(self);
	self.objpointa.name = "PlayerA";
	self.objpointa.x = a.origin[0];
	self.objpointa.y = a.origin[1];
	self.objpointa.z = a.origin[2] + 70;
	self.objpointa.alpha = .61;
	self.objpointa.archived = false;
	self.objpointa setShader("objpoint_A", 14, 14);
	self.objpointa setwaypoint(true);

	self.objpointb = newClientHudElem(self);
	self.objpointb.name = "PlayerB";
	self.objpointb.x = b.origin[0];
	self.objpointb.y = b.origin[1];
	self.objpointb.z = b.origin[2] + 70;
	self.objpointb.alpha = .61;
	self.objpointb.archived = false;
	self.objpointb setShader("objpoint_B", 14, 14);
	self.objpointb setwaypoint(true);

	while(isdefined(a) && isAlive(a) && a.sessionstate == "playing" && isdefined(b) && isAlive(b) && b.sessionstate == "playing")
	{
		dist = int(distance(a.origin, b.origin) * 0.0254 + 0.5);

		self.spectatordist2 setValue(dist);			
		self.spectatorhealth2 setValue(a.health);			
		self.spectatorweapon2 setText(a.dh_weapon);
		self.spectatorammo2 setValue(a.dh_ammo);

		self.objpointa.x = a.origin[0];
		self.objpointa.y = a.origin[1];
		self.objpointa.z = a.origin[2] + 70;

		self.spectator2dist2 setValue(dist);			
		self.spectator2health2 setValue(b.health);			
		self.spectator2weapon2 setText(b.dh_weapon);
		self.spectator2ammo2 setValue(b.dh_ammo);

		self.objpointb.x = b.origin[0];
		self.objpointb.y = b.origin[1];
		self.objpointb.z = b.origin[2] + 70;

		wait( [[level.ex_fpstime]](0.05) );
	}
}

removeSpectatorHuds()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && isdefined(player.spectatorhud))
		{
			player thread removeSpectatorHud();
		}
	}
}

removeSpectatorHud()
{
	// End thread
	self notify("end_spectatorhud");

	self.spectatorhud = undefined;

	// Remove objective points
	if(isdefined(self.objpointa)) self.objpointa destroy();
	if(isdefined(self.objpointb)) self.objpointb destroy();

	// Fade away text
	if(isdefined(self.spectatortitle))
	{
		self.spectatortitle fadeOverTime(1);
		self.spectatortitle.alpha = 0;
	}
	if(isdefined(self.spectatordist))
	{
		self.spectatordist fadeOverTime(1);
		self.spectatordist.alpha = 0;
	}
	if(isdefined(self.spectatordist2))
	{
		self.spectatordist2 fadeOverTime(1);
		self.spectatordist2.alpha = 0;
	}
	if(isdefined(self.spectatorhealth))
	{
		self.spectatorhealth fadeOverTime(1);
		self.spectatorhealth.alpha = 0;
	}
	if(isdefined(self.spectatorhealth2))
	{
		self.spectatorhealth2 fadeOverTime(1);
		self.spectatorhealth2.alpha = 0;
	}
	if(isdefined(self.spectatorweapon))
	{
		self.spectatorweapon fadeOverTime(1);
		self.spectatorweapon.alpha = 0;
	}
	if(isdefined(self.spectatorweapon2))
	{
		self.spectatorweapon2 fadeOverTime(1);
		self.spectatorweapon2.alpha = 0;
	}
	if(isdefined(self.spectatorammo))
	{
		self.spectatorammo fadeOverTime(1);
		self.spectatorammo.alpha = 0;
	}
	if(isdefined(self.spectatorammo2))
	{
		self.spectatorammo2 fadeOverTime(1);
		self.spectatorammo2.alpha = 0;
	}

	if(isdefined(self.spectator2title))
	{
		self.spectator2title fadeOverTime(1);
		self.spectator2title.alpha = 0;
	}
	if(isdefined(self.spectator2dist))
	{
		self.spectator2dist fadeOverTime(1);
		self.spectator2dist.alpha = 0;
	}
	if(isdefined(self.spectator2dist2))
	{
		self.spectator2dist2 fadeOverTime(1);
		self.spectator2dist2.alpha = 0;
	}
	if(isdefined(self.spectator2health))
	{
		self.spectator2health fadeOverTime(1);
		self.spectator2health.alpha = 0;
	}
	if(isdefined(self.spectator2health2))
	{
		self.spectator2health2 fadeOverTime(1);
		self.spectator2health2.alpha = 0;
	}
	if(isdefined(self.spectator2weapon))
	{
		self.spectator2weapon fadeOverTime(1);
		self.spectator2weapon.alpha = 0;
	}
	if(isdefined(self.spectator2weapon2))
	{
		self.spectator2weapon2 fadeOverTime(1);
		self.spectator2weapon2.alpha = 0;
	}
	if(isdefined(self.spectator2ammo))
	{
		self.spectator2ammo fadeOverTime(1);
		self.spectator2ammo.alpha = 0;
	}
	if(isdefined(self.spectator2ammo2))
	{
		self.spectator2ammo2 fadeOverTime(1);
		self.spectator2ammo2.alpha = 0;
	}
	wait( [[level.ex_fpstime]](1) );

	if(isdefined(self.spectatorback))
		self.spectatorback scaleOverTime(1, 1 , 135);

	if(isdefined(self.spectator2back))
		self.spectator2back scaleOverTime(1, 1 , 135);

	wait( [[level.ex_fpstime]](1) );

	// Remove HUD elements
	if(isdefined(self.spectatorback)) self.spectatorback destroy();
	if(isdefined(self.spectatordist)) self.spectatordist destroy();
	if(isdefined(self.spectatordist2)) self.spectatordist2 destroy();
	if(isdefined(self.spectatorhealth)) self.spectatorhealth destroy();
	if(isdefined(self.spectatorhealth2)) self.spectatorhealth2 destroy();
	if(isdefined(self.spectatorweapon)) self.spectatorweapon destroy();
	if(isdefined(self.spectatorweapon2)) self.spectatorweapon2 destroy();
	if(isdefined(self.spectatorammo)) self.spectatorammo destroy();
	if(isdefined(self.spectatorammo2)) self.spectatorammo2 destroy();
	if(isdefined(self.spectatortitle)) self.spectatortitle destroy();

	if(isdefined(self.spectator2back)) self.spectator2back destroy();
	if(isdefined(self.spectator2dist)) self.spectator2dist destroy();
	if(isdefined(self.spectator2dist2)) self.spectator2dist2 destroy();
	if(isdefined(self.spectator2health)) self.spectator2health destroy();
	if(isdefined(self.spectator2health2)) self.spectator2health2 destroy();
	if(isdefined(self.spectator2weapon)) self.spectator2weapon destroy();
	if(isdefined(self.spectator2weapon2)) self.spectator2weapon2 destroy();
	if(isdefined(self.spectator2ammo)) self.spectator2ammo destroy();
	if(isdefined(self.spectator2ammo2)) self.spectator2ammo2 destroy();
	if(isdefined(self.spectator2title)) self.spectator2title destroy();
}
