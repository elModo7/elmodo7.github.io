/*------------------------------------------------------------------------------
Individual Hold the Flag - eXtreme+ mod compatible version 1.2
Author : La Truffe
Based on HTF (Hold the Flag)
Credits : Bell (HTF), Ravir (cvardef function), Astoroth (eXtreme+ mod)
------------------------------------------------------------------------------*/

main()
{
	// Trick SET: pretend we're on HQ gametype to benefit from the level.radio definitions in the map script
	setcvar("g_gametype", "hq");

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
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;
	
	// Over-override Callback_StartGameType
	level.ihtf_callbackStartGameType = level.callbackStartGameType;
	level.callbackStartGameType = ::IHTF_Callback_StartGameType;

	// set eXtreme+ variables and precache (phase 1 only)
	extreme\_ex_varcache::main(1);
}

IHTF_Callback_StartGameType()
{
	// Trick UNSET: restore IHTF gametype
	setcvar("g_gametype", "ihtf");

	// set eXtreme+ variables and precache (phase 2 only)
	extreme\_ex_varcache::main(2);

	// disable tripwires (Pat: in here since day one. I wonder why)
	level.ex_tweapons = 0;
	
	[[level.ihtf_callbackStartGameType]]();
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
	level.compassflag_none	= "objective";
	level.objpointflag_allies = "objpoint_flag_" + game["allies"];
	level.objpointflag_axis = "objpoint_flag_" + game["axis"];
	level.objpointflag_none = "objpoint_star";
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	
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
		precacheShader(level.compassflag_none);
		precacheShader(level.objpointflag_allies);
		precacheShader(level.objpointflag_axis);
		precacheShader(level.objpointflag_none);
		precacheShader(level.hudflag_allies);
		precacheShader(level.hudflag_axis);
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
	thread maps\mp\gametypes\_hud_playerscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	SaveSDBombzonesPos();
	SaveCTFFlagsPos();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.playerspawnpoints = SpawnPointsArray(level.playerspawnpointsmode, "ihtf_player_spawn");
	level.flagspawnpoints = SpawnPointsArray(level.flagspawnpointsmode, "ihtf_flag_spawn");

	if(!level.playerspawnpoints.size)
	{
		maps\mp\_utility::error("NO PLAYER SPAWNPOINTS IN MAP");
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	if(!level.flagspawnpoints.size)
	{
		maps\mp\_utility::error("NO FLAG SPAWNPOINTS IN MAP");
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	//logprint(level.playerspawnpoints.size + " player spawn points\n");
	//logprint(level.flagspawnpoints.size + " flag positions\n");

	RemoveHQRadioPoints();

	level.holdtime = 0;
	level.totalholdtime = 0;
	level.holdtime_old = level.holdtime;
	level.totalholdtime_old = level.totalholdtime;
	level.startflagtime = 0;

	level.QuickMessageToAll = true;
	level.mapended = false; 
	level.hasspawned["flag"] = false;

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
		thread InitFlag();
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
		self.sessionteam = "none";
		
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
	self extreme\_ex_clientcontrol::explayerdisconnect();

	lpselfnum = self getEntityNumber();
	lpselfGuid = self getGuid();
	logPrint("Q;" + lpselfGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1) iDamage = 1;

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

	if(isdefined(self.flag))
		flagcarrier = true;
	else
		flagcarrier = undefined;

	if(self.sessionteam == "spectator") return;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self dropFlag();

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";

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
			doKillcam = false;
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// Was the flagcarrier killed?
			if(isdefined(flagcarrier))
			{
				attacker AnnounceSelf(&"MP_IHTF_YOU_KILLED_FLAG_CARRIER", undefined);
				attacker AnnounceOthers(&"MP_IHTF_KILLED_FLAG_CARRIER", attacker);
				points = level.PointsForKillingFlagCarrier;
			}
			else
				points = level.PointsForKillingPlayers;
			
			// Check if extra points should be given for bash or headshot
			reward_points = 0;
			if(isDefined(sMeansOfDeath))
			{
				if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
					else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
			}

			if(level.PointsForKillingPlayers) points += reward_points;
			attacker.score += points;
			attacker.pers["bonus"] += reward_points;
			attacker checkScoreLimit();
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
		
		attacker notify("update_playerhud_score");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
		
		self notify("update_playerhud_score");
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isdefined(self.switching_teams))
		self.ex_team_changed = true;

	self.joining_team = undefined;
	self.leaving_team = undefined;
	self.switching_teams = undefined;

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

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;

	self extreme\_ex_main::exprespawn();
	
	spawnpoints = level.playerspawnpoints;
	
	// Find a spawn point away from the flag
	spawnpoint = undefined;
	for(i = 0; i < 5; i ++)
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
		if(spawnpoint isAwayFromFlag()) break;
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
		else maps\mp\_utility::error("NO PLAYER SPAWNPOINTS IN MAP");

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(level.scorelimit > 0) self setClientCvar("cg_objectiveText", &"MP_IHTF_OBJ_TEXT", level.scorelimit);
		else self setClientCvar("cg_objectiveText", &"MP_IHTF_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");

	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
		thread CheckForFlag();
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

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
	players = level.players;
	highscore = undefined;
	tied = undefined;
	playername = undefined;
	playerteam = undefined;
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
			playerteam = player.pers["team"];
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
	flagtimepassed = (getTime () - level.startflagtime) / 1000;
	if((level.flag.atbase || (!level.flag.stolen)) && (flagtimepassed >= level.flagtimeout))
	{
		iprintln(&"MP_IHTF_FLAG_TIMEOUT", level.flagtimeout);

		// Hide the flag
		level.flag.basemodel hide();
		level.flag.flagmodel hide();
		level.flag.compassflag = level.compassflag_none;
		level.flag.objpointflag = level.objpointflag_none;

		// Prevent players from stealing it until it respawns
		level.flag.stolen = true;

		// Respawn the flag		
		level.flag returnFlag(false);
	}

	if(level.timelimit <= 0)
		return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < level.timelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	waittillframeend;

	if(level.scorelimit <= 0)
		return;

	if(self.score < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_ihtf_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ihtf_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock))
				extreme\_ex_gtcommon::createClock();
				level.clock setTimer(level.timelimit * 60);
			}
			else if(isDefined(level.clock)) level.clock destroy();

			checkTimeLimit();
		}

		scorelimit = getcvarint("scr_ihtf_scorelimit");
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

pickupFlag(flag)
{
	flag notify("end_autoreturn");

	// What is my team?
	myteam = self.pers["team"];
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	flag.flagmodel setmodel("xmodel/prop_flag_" + game[myteam]);
	self.flag = flag;

	flag.team = myteam;
	flag.atbase = false;

	if(myteam == "allies")
	{
		flag.compassflag = level.compassflag_allies;
		flag.objpointflag = level.objpointflag_allies;
	}
	else
	{
		flag.compassflag = level.compassflag_axis;
		flag.objpointflag = level.objpointflag_axis;
	}

	flag deleteFlagWaypoint();

	objective_icon(self.flag.objective, flag.compassflag);
	objective_team(self.flag.objective, "none");

	self playsound("ctf_touchenemy");
	self attachFlag();
}

dropFlag(dropspot)
{
	if(isdefined(self.flag))
	{
		level.holdtime = 0;
		level.totalholdtime = 0;

		UpdateHud();

		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
		  else start = self.origin + (0, 0, 10);

		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		self.flag.stolen = false;

		// set compass flag position on player
		objective_position(self.flag.objective, self.flag.origin);
		objective_state(self.flag.objective, "current");

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag.compassflag = level.compassflag_none;
				self.flag.objpointflag = level.objpointflag_none;
				self.flag thread returnFlag(false);
				break;
			}
		}

		self.flag = undefined;
		
		level.startflagtime = getTime();
	}
}

returnFlag(delay)
{
	self notify("end_autoreturn");
	self deleteFlagWaypoint();
	objective_delete(self.objective);

	// Wait delay before spawning flag
	if(delay)
	{
		self.flagmodel hide();
		self.origin = (self.home_origin[0], self.home_origin[0], self.home_origin[2] - 5000);
		wait( [[level.ex_fpstime]](level.flagspawndelay + 0.05) );
	}

	if(!level.hasspawned["flag"])
	{
		self.origin = self.home_origin;
 		self.flagmodel.origin = self.home_origin;
	 	self.flagmodel.angles = self.home_angles;
		if(level.randomflagspawns) level.hasspawned["flag"] = true;
	}
	else
	{
		spawnpoints = level.flagspawnpoints;

		// Find a new spawn point for the flag
		spawnpoint = undefined;
		for(i = 0; i < 50; i ++)
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
			if(spawnpoint.origin != self.origin)
				break;
		}

		self.origin = spawnpoint.origin;
 		self.flagmodel.origin = spawnpoint.origin;
	 	self.flagmodel.angles = spawnpoint.angles;
		self.basemodel.origin = spawnpoint.origin;
	 	self.basemodel.angles = spawnpoint.angles;
	}

	self.flagmodel show();
	self.basemodel show();
	self.atbase = true;
	self.stolen = false;

	// set compass flag position on player
	objective_add(self.objective, "current", self.origin, self.compassflag);
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");

	self createFlagWaypoint();
	
	level.holdtime = 0;
	level.totalholdtime = 0;

	UpdateHud();

	level.startflagtime = getTime();
}

autoReturn()
{
	level endon("ex_gameover");
	self endon("end_autoreturn");

	if(!level.flagrecovertime) return;

	wait( [[level.ex_fpstime]](level.flagrecovertime) );

	self thread returnFlag(false);
}

attachFlag()
{
	if(isdefined(self.flagAttached))
		return;

	//put icon on screen
	self.flagAttached = newClientHudElem(self);
	self.flagAttached.horzAlign = "left";
	self.flagAttached.vertAlign = "top";
	self.flagAttached.alignX = "center";
	self.flagAttached.alignY = "middle";
	self.flagAttached.x = 30;
	self.flagAttached.y = 95;

	iconSize = 40;

	if(self.pers["team"] == "allies")
	{
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		self.flagAttached setShader(level.hudflag_allies, iconSize, iconSize);
		if(!level.ex_rank_statusicons) self.statusicon = level.hudflag_allies;
	}
	else
	{
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		self.flagAttached setShader(level.hudflag_axis, iconSize, iconSize);
		if(!level.ex_rank_statusicons) self.statusicon = level.hudflag_axis;
	}
	self attach(flagModel, "J_Spine4", true);
}

detachFlag(flag)
{
	if(!isdefined(self.flagAttached))
		return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	self detach(flagModel, "J_Spine4");

	self.statusicon = "";

	self.flagAttached destroy();
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
	self.waypoint = waypoint;
}

deleteFlagWaypoint()
{
	if(!level.ex_objindicator)
		return;

	if(isdefined(self.waypoint))
		self.waypoint destroy();
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

AnnounceSelf(locstring, var)
{
	if(isdefined(var))
		self iprintlnbold(locstring, var);
	else
		self iprintlnbold(locstring);
}

AnnounceOthers(locstring, var)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(players[i] == self)
			continue;

		if(isdefined(var))
			players[i] iprintln(locstring, var);
		else
			players[i] iprintln(locstring);
	}
}

AnnounceAll(locstring, var)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(var))
			players[i] iprintln(locstring, var);
		else
			players[i] iprintln(locstring);
	}
}

InitFlag()
{
	flagpoint = GetFlagPoint();
	origin = flagpoint.origin;
	angles = flagpoint.angles;

	// Spawn a script origin
	level.flag = spawn("script_origin",origin);
	level.flag.targetname = "ihtf_flaghome";
	level.flag.origin = origin;
	level.flag.angles = angles;
	level.flag.home_origin = origin;
	level.flag.home_angles = angles;

	// Spawn the flag base model
	level.flag.basemodel = spawn("script_model", level.flag.home_origin);
	level.flag.basemodel.angles = level.flag.home_angles;
	level.flag.basemodel setmodel("xmodel/prop_flag_base");
	
	// Spawn the flag
	level.flag.flagmodel = spawn("script_model", level.flag.home_origin);
	level.flag.flagmodel.angles = level.flag.home_angles;
	level.flag.flagmodel setmodel("xmodel/prop_flag_german");
	level.flag.flagmodel hide();

	// Set flag properties
	level.flag.team = "none";
	level.flag.atbase = false;
	level.flag.stolen = true;
	level.flag.objective = 0;
	level.flag.compassflag = level.compassflag_none;
	level.flag.objpointflag = level.objpointflag_none;

	wait( [[level.ex_fpstime]](0.05) );

	SetupHud();

	level.flag returnFlag(true);
}

GetFlagPoint()
{
	// Get nearest spawn

	spawnpoints = level.flagspawnpoints;
	flagpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	return flagpoint;
}

CheckForFlag()
{
	level endon("intermission");

	// check if flag exists. It could be missing due the ready-up
	if(!isDefined(level.flag)) return;

	self.flag = undefined;
	count=0;

	// What is my team?
	myteam = self.pers["team"];
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";
	
	while(isAlive(self) && self.sessionstate=="playing" && myteam == self.pers["team"])
	{
		// Does the flag exist and is not currently being stolen?
		if(isDefined(level.flag) && !level.flag.stolen)
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag() && !level.flag.stolen)
			{
				level.flag.stolen = true;
		
				// Steal flag
				self pickupFlag(level.flag);
				
				self AnnounceSelf(&"MP_IHTF_YOU_STOLE_FLAG", undefined);
				self AnnounceOthers(&"MP_IHTF_STOLE_FLAG", self);

				// Get personal score
				self.score += level.PointsForStealingFlag;

				lpselfnum = self getEntityNumber();
				lpselfguid = self getGuid();
				logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_stole" + "\n");

				self notify("update_playerscore_hud");

				self checkScoreLimit();
				
				count = 0;
			}
		}

		// Update objective on compass
		if(isdefined(self.flag))
		{
			// Update the objective
			objective_position(self.flag.objective, self.origin);

			wait( [[level.ex_fpstime]](0.05) );

			// Make sure flag still exist
			if(isdefined(self.flag))
			{
				// Check hold time every second
				count++;
				if(count>=20)
				{
					count = 0;
				
					level.holdtime ++;
					level.totalholdtime ++;
					
					if(level.totalholdtime >= level.flagmaxholdtime)
					{
						AnnounceAll(&"MP_IHTF_FLAG_MAXTIME", level.flagmaxholdtime);

						level.holdtime = 0;
						level.totalholdtime = 0;

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_maxheld" + "\n");
						
						self detachFlag(self.flag);
						self.flag.compassflag = level.compassflag_none;
						self.flag.objpointflag = level.objpointflag_none;

						self.flag thread ReturnFlag(true);
						self.flag = undefined;	
					}

					if(level.holdtime >= level.flagholdtime)
					{
						iprintln(&"MP_IHTF_FLAG_CARRIER_SCORES", level.PointsForHoldingFlag);
						self.score += level.PointsForHoldingFlag;

						self.pers["flagcap"]++;
						if(level.ex_statshud) self thread extreme\_ex_statshud::showStatsHUD();

						level.holdtime = 0;

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_scored" + "\n");

						self notify("update_playerscore_hud");

						self checkScoreLimit();
					}

					UpdateHud();
				}
			}
		}
		else wait( [[level.ex_fpstime]](0.2) );
	}

	//player died or went spectator
	self dropFlag();
}

isTouchingFlag()
{
	if(!isDefined(level.flag)) return true;

	if(distance(self.origin, level.flag.origin) < 50)
		return true;
	else
		return false;
}

isAwayFromFlag()
{
	if(!isDefined(level.flag)) return true;

	if(distance(self.origin, level.flag.origin) >= level.spawndistance) return true;
		else return false;
}

SetupHud()
{
	y = 10;
	barsize = 200;

	level.cursorleft = newHudElem();
	level.cursorleft.x = 320;
	level.cursorleft.y = y;
	level.cursorleft.alignX = "right";
	level.cursorleft.alignY = "middle";
	level.cursorleft.color = (1,0,0);
	level.cursorleft.alpha = 0.4;
	level.cursorleft setShader("white", 1, 11);

	level.scoreback = newHudElem();
	level.scoreback.alignX = "center";
	level.scoreback.alignY = "middle";
	level.scoreback.x = 320;
	level.scoreback.y = y;
	level.scoreback.alpha = 0.3;
	level.scoreback.color = (0.2,0.2,0.2);
	level.scoreback setShader("white", barsize*2+4, 13);

	level.cursorright = newHudElem();
	level.cursorright.x = 320;
	level.cursorright.y = y;
	level.cursorright.alignX = "left";
	level.cursorright.alignY = "middle";
	level.cursorright.color = (0,0,1);
	level.cursorright.alpha = 0.4;
	level.cursorright setShader("white", 1, 11);
}

UpdateHud()
{
	barsize = 200;
	left = int(level.holdtime * barsize / (level.flagholdtime - 1) + 1);
	right = int(level.totalholdtime * barsize / (level.flagmaxholdtime - 1) + 1);

	if(isDefined(level.cursorleft) && level.holdtime != level.holdtime_old)
		if(isDefined(level.cursorleft)) level.cursorleft scaleOverTime(1, left, 11);
	if(isDefined(level.cursorright) && level.totalholdtime != level.totalholdtime_old)
		if(isDefined(level.cursorright)) level.cursorright scaleOverTime(1, right, 11);
		
	level.holdtime_old = level.holdtime;
	level.totalholdtime_old = level.totalholdtime;
}

AddToSpawnArray(array, spawntype, customclassname)
{
	spawnpoints = getentarray(spawntype, "classname");
	for(i = 0; i < spawnpoints.size; i ++)
	{
		s = array.size;
		origin = FixSpawnPoint(spawnpoints[i].origin);
		array[s] = spawn("script_origin", origin);
		array[s].origin = origin;
		array[s].angles = spawnpoints[i].angles;
		array[s].targetname = customclassname;
		array[s] placeSpawnpoint();
	}
	
	return (array);
}

AddToSpawnArrayCTFFlags(array, customclassname)
{
	if((!isdefined(level.ctfflagspos[0])) || (!isdefined(level.ctfflagspos[1])))
		return (array);
		
	s = array.size;
	origin = FixSpawnPoint(level.ctfflagspos[0].origin);
	array[s] = spawn("script_origin", origin);
	array[s].origin = origin;
	array[s].angles = level.ctfflagspos[0].angles;
	array[s].targetname = customclassname;
	array[s] placeSpawnpoint();
	
	origin = FixSpawnPoint(level.ctfflagspos[1].origin);
	array[s + 1] = spawn("script_origin", origin);
	array[s + 1].origin = origin;
	array[s + 1].angles = level.ctfflagspos[1].angles;
	array[s + 1].targetname = customclassname;
	array[s + 1] placeSpawnpoint();

	return (array);
}

SaveCTFFlagsPos()
{
	allied_flags = getentarray("allied_flag", "targetname");
	axis_flags = getentarray("axis_flag", "targetname");
	
	if((allied_flags.size != 1) || (axis_flags.size != 1))
		return;

	allied_flag = getent("allied_flag", "targetname");
	axis_flag = getent("axis_flag", "targetname");
	
	level.ctfflagspos[0] = spawnstruct();
	level.ctfflagspos[0].origin = allied_flag.origin;
	level.ctfflagspos[0].angles = allied_flag.angles;
	level.ctfflagspos[1] = spawnstruct();
	level.ctfflagspos[1].origin = axis_flag.origin;
	level.ctfflagspos[1].angles = axis_flag.angles;
}

AddToSpawnArraySDbombzones(array, customclassname)
{
	if((!isdefined(level.sdbombzonepos[0])) || (!isdefined(level.sdbombzonepos[1])))
		return (array);

	s = array.size;
	for(i = 0; i <= 1; i ++)
	{
		origin = FixSpawnPoint(level.sdbombzonepos[i].origin);
		array[s + i] = spawn("script_origin", origin);
		array[s + i].origin = origin;
		array[s + i].angles = level.sdbombzonepos[i].angles;
		array[s + i].targetname = customclassname;
		array[s + i] placeSpawnpoint();
	}

	return (array);
}

SaveSDBombzonesPos()
{
	bombzones = getentarray("bombzone", "targetname");
	if(isdefined(bombzones[0]))
	{
		level.sdbombzonepos[0] = spawnstruct();
		level.sdbombzonepos[0].origin = bombzones[0].origin;
		level.sdbombzonepos[0].angles = bombzones[0].angles;
	}
	if(isdefined(bombzones[1]))
	{
		level.sdbombzonepos[1] = spawnstruct();
		level.sdbombzonepos[1].origin = bombzones[1].origin;
		level.sdbombzonepos[1].angles = bombzones[1].angles;
	}
}

AddToSpawnArrayHQRadios(array, customclassname)
{
	if(!isdefined(level.radio))
		return (array);

	for(i = 0; i < level.radio.size; i ++)
	{
		s = array.size;
		origin = FixSpawnPoint(level.radio[i].origin);
		array[s] = spawn("script_origin", origin);
		array[s].origin = origin;
		array[s].angles = level.radio[i].angles;
		array[s].targetname = customclassname;
		array[s] placeSpawnpoint();
	}
	
	return (array);
}

RemoveHQRadioPoints()
{
	if(!isdefined(level.radio))
		return;

	for(i = 0; i < level.radio.size; i ++)
		level.radio[i] delete();

	level.radio = undefined;
}

SpawnPointsArray(modestring, customclassname)
{
	modearray = strtok(modestring, " ");
	activespawntype = [];
	for(i = 0; i < modearray.size; i ++)
	{
		switch(modearray[i])
		{
			case "dm" :
			case "tdm" :
			case "ctfp" :
			case "ctff" :
			case "sdp" :
			case "sdb" :
			case "hq" :
				activespawntype[modearray[i]] = true;
				break;
			default :
				break;
		}
	}

	array = [];

	if(isdefined(activespawntype["dm"]))
		array = AddToSpawnArray(array, "mp_dm_spawn", customclassname);

	if(isdefined(activespawntype["tdm"]))
		array = AddToSpawnArray(array, "mp_tdm_spawn", customclassname);
	
	if(isdefined(activespawntype["ctfp"]))
	{
		array = AddToSpawnArray(array, "mp_ctf_spawn_allied", customclassname);
		array = AddToSpawnArray(array, "mp_ctf_spawn_axis", customclassname);
	}
	
	if(isdefined(activespawntype["sdp"]))
	{
		array = AddToSpawnArray(array, "mp_sd_spawn_attacker", customclassname);
		array = AddToSpawnArray(array, "mp_sd_spawn_defender", customclassname);
	}
	
	if(isdefined(activespawntype["ctff"]))
		array = AddToSpawnArrayCTFFlags(array, customclassname);
	
	if(isdefined(activespawntype["sdb"]))
		array = AddToSpawnArraySDBombzones(array, customclassname);
	
	if(isdefined(activespawntype["hq"]))
		array = AddToSpawnArrayHQRadios(array, customclassname);

	return (array);
}

FixSpawnPoint(position)
{
	return (physicstrace(position + (0, 0, 20), position + (0, 0, -20)));
}
