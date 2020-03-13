#include maps\mp\gametypes\_weapons;

exPlayerConnect()
{
	// if roundbased, no need to display the connecting information if they've already been playing
	if(level.ex_roundbased && isDefined(self.pers) && isDefined(self.pers["score"])) return;

	// if using the ready-up system, no need to display the connecting information if they've already been playing
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
	{
		if(level.ex_plcdmsg) iprintln(&"CLIENTCONTROL_CONNECTING", [[level.ex_pname]](self));

		if(level.ex_plcdsound)
		{
			players = level.players;
			for(i = 0; i < players.size; i++) players[i] playLocalSound("gomplayersjoined");
		}
	}
}

exPlayerJoinedServer()
{	
	// add player to players array
	level.players[level.players.size] = self;

	// set one-off vars
	self.usedweapons = false;
	self.ex_sinbin = false;
	self.ex_glplay = undefined;
	self.pers["spec_on"] = false;
	self.pers["dth_on"] = false;
	self.pers["intro_on"] = false;
	if(!isDefined(self.pers["kill"])) self.pers["kill"] = 0;
	if(!isDefined(self.pers["death"])) self.pers["death"] = 0;
	if(!isDefined(self.pers["teamkill"])) self.pers["teamkill"] = 0;
	if(!isDefined(self.pers["suicide"])) self.pers["suicide"] = 0;
	if(!isDefined(self.pers["special"])) self.pers["special"] = 0;
	if(!isDefined(self.pers["bonus"])) self.pers["bonus"] = 0;
	if(!isDefined(self.pers["specials_cash"])) self.pers["specials_cash"] = 0;

	// check security status
	self extreme\_ex_security::checkInit();

	// restore points, kills, deaths and bonus if rejoining during grace period
	if(level.ex_scorememory && level extreme\_ex_memory::getScoreMemory(self.name))
	{
		memory = self extreme\_ex_memory::getMemory("score", "points");
		if(!memory.error)
		{
			self.score = memory.value;
			self.pers["score"] = memory.value;
		}
		memory = self extreme\_ex_memory::getMemory("score", "kills");
		if(!memory.error) self.pers["kill"] = memory.value;
		memory = self extreme\_ex_memory::getMemory("score", "deaths");
		if(!memory.error)
		{
			self.deaths = memory.value;
			self.pers["death"] = memory.value;
		}
		memory = self extreme\_ex_memory::getMemory("score", "bonus");
		if(!memory.error) self.pers["bonus"] = memory.value;
		memory = self extreme\_ex_memory::getMemory("score", "special");
		if(!memory.error) self.pers["special"] = memory.value;
	}

	// check if this player is excluded from the inactivity monitor
	self extreme\_ex_security::checkIgnoreInactivity();

	// initialize eXtreme+ rcon
	self extreme\_ex_rcon::rconInitPlayer();

	// Prepare in-game menu for adding this server to the favorites
	if(level.ex_addtofavorites)
	{
		self setClientCvar("ui_favoriteExtreme", "1");
		self setClientCvar("ui_favoriteName", getCvar("sv_hostname"));
		if(isDefined(level.ex_addtofavorites_ip) && level.ex_addtofavorites_ip != "")
			self setClientCvar("ui_favoriteAddress", level.ex_addtofavorites_ip + ":" + getCvar("net_port"));
		else
			self setClientCvar("ui_favoriteAddress", getCvar("net_ip") + ":" + getCvar("net_port"));
	}
	else self setClientCvar("ui_favoriteExtreme", "0");

	// remove existing ready-up spawn ticket
	if(!level.ex_readyup || (level.ex_readyup && !isDefined(game["readyup_done"])) )
		self.pers["readyup_spawnticket"] = undefined;

	// sync snaps cvar
	self setClientCvar("snaps", level.ex_snaps);

	// update specialty store cvars
	self thread extreme\_ex_specials::playerSpecialtyCvars();

	// update weapon cvars
	//self thread updateAllAllowedSingleClient();

	// check if player prefers a female model
	self extreme\_ex_diana::checkDiana();

	// make sure to update the ui_zoom variable
	self extreme\_ex_zoom::checkZoom();

	// detect forced auto-assign (0 = off, 1 = all, 2 = non-clan only)
	self.ex_autoassign = 0;
	if(level.ex_autoassign == 1) self.ex_autoassign = 1;
		else if(level.ex_autoassign == 2 && (!isDefined(self.ex_name) || self.ex_clid != 1)) self.ex_autoassign = 1;

	//if(self.ex_autoassign) logprint("TEAM DEBUG (C): " + self.name + " self.ex_autoassign switched on\n");
	//	else logprint("TEAM DEBUG (C): " + self.name + " self.ex_autoassign switched off\n");

	if(self.ex_autoassign) self setClientCvar("ui_allow_select_team", "0");
		else self setClientCvar("ui_allow_select_team", "1");

	// bots need to reselect weapon on round based games with swapteams enabled
	if(isDefined(self.pers["isbot"]))
	{
		if(level.ex_roundbased && level.ex_swapteams && game["roundsplayed"] > 0 && !isDefined(self.pers["weapon"]))
		{
			if(level.ex_testclients_diag) logprint(self.name + " reselecting new weapons...\n");
			self thread extreme\_ex_bots::dbotLoadout();
		}
	}

	// if roundbased, no need to hear any intro sounds again if they've already been playing
	if(level.ex_roundbased && isDefined(self.pers) && isDefined(self.pers["score"])) return;

	// if using the ready-up system, no need to hear any intro sounds again if they've already been playing
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	// start menu music
	if(level.ex_gameover && (level.ex_endmusic || level.ex_mvmusic || level.ex_statsmusic)) skip_intromusic = true;
	  else skip_intromusic = false;

	thread extreme\_ex_maps::getmapstring(getCvar("mapname"));

	if(!skip_intromusic && level.ex_intromusic > 0)
	{
		if(level.ex_intromusic == 1 && level.msc)
		{
			self.pers["intro_on"] = true;
			self playlocalsound(getCvar("mapname"));
		}
		else
		{
			if(level.ex_intromusic == 2 && level.msc)
			{
				self.pers["intro_on"] = true;
				self playlocalsound("mus_" + getCvar("mapname"));
			}
			else
			{
				if(level.ex_intromusic == 3 || !level.msc)
				{
					intro = randomInt(10) + 1;
					self.pers["intro_on"] = true;
					self playlocalsound("intromusic_" + intro);
				}
			}
		}
	}

	if(level.ex_plcdmsg)
	{
		if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
			iprintln(&"CLIENTCONTROL_HASJOINED", [[level.ex_pname]](self));
	}
}

exPlayerPreServerInfo()
{
	if(level.ex_cinematic)
	{
		cinematic_play = true;
		if(level.ex_cinematic == 1 || level.ex_cinematic == 2)
		{
			memory = self extreme\_ex_memory::getMemory("cinematic", "status");
			if(!memory.error) cinematic_play = memory.value;
			if(cinematic_play) self thread extreme\_ex_memory::setMemory("cinematic", "status", 0);
		}

		waittillframeend;
		if(cinematic_play) self extreme\_ex_utils::execClientCommand("unskippablecinematic poweredby");
		wait( [[level.ex_fpstime]](0.05) );
	}
}

exPrintJoinedTeam(team)
{
	if( isDefined(self.ex_autoassign_team) && ((isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name)) )
	{
		if(team == "allies")
		{
			switch(game["allies"])
			{
				case "american":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_AMERICAN", [[level.ex_pname]](self));
					break;
				case "british":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_BRITISH", [[level.ex_pname]](self));
					break;
				default:
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_RUSSIAN", [[level.ex_pname]](self));
					break;
			}
		}
		else if(team == "axis")
		{
			switch(game["axis"])
			{
				case "german":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_GERMAN", [[level.ex_pname]](self));
					break;
			}
		}
	}
	else if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
	{
		if(team == "allies")
		{
			switch(game["allies"])
			{
				case "american":
					iprintln(&"CLIENTCONTROL_RECRUIT_AMERICAN", [[level.ex_pname]](self));
					break;
				case "british":
					iprintln(&"CLIENTCONTROL_RECRUIT_BRITISH", [[level.ex_pname]](self));
					break;
				default:
					iprintln(&"CLIENTCONTROL_RECRUIT_RUSSIAN", [[level.ex_pname]](self));
					break;
			}
		}
		else if(team == "axis")
		{
			switch(game["axis"])
			{
				case "german":
					iprintln(&"CLIENTCONTROL_RECRUIT_GERMAN", [[level.ex_pname]](self));
					break;
			}
		}
	}
}

exPlayerDisconnect()
{
	self notify("kill_thread");

	// remove player from players array
	self removePlayerOnDisconnect();

	entity = self getEntityNumber();
	if(level.ex_specials) level thread extreme\_ex_specials::onPlayerDisconnected(entity);

	// update persistent memory and save
	if(level.ex_cinematic == 2) self extreme\_ex_memory::setMemory("cinematic", "status", 1, true);
	if(level.ex_rcon && (level.ex_rcon_mode == 1 || (level.ex_rcon_mode == 0 && !level.ex_rcon_autopass)) && level.ex_rcon_cachepin)
		self extreme\_ex_memory::setMemory("rcon", "pin", "xxxx", true);
	if(level.ex_clanlogin && isDefined(self.ex_name))
		self extreme\_ex_memory::setMemory("clan", "pin", "xxxx", true);
	if(level.ex_scorememory)
	{
		level thread extreme\_ex_memory::setScoreMemory(self.name);
		if(isDefined(self.score)) self extreme\_ex_memory::setMemory("score", "points", self.score, true);
			else self extreme\_ex_memory::setMemory("score", "points", 0, true);
		if(isDefined(self.pers["kill"])) self extreme\_ex_memory::setMemory("score", "kills", self.pers["kill"], true);
			else self extreme\_ex_memory::setMemory("score", "kills", 0, true);
		if(isDefined(self.deaths)) self extreme\_ex_memory::setMemory("score", "deaths", self.deaths, true);
			else self extreme\_ex_memory::setMemory("score", "deaths", 0, true);
		if(isDefined(self.pers["bonus"])) self extreme\_ex_memory::setMemory("score", "bonus", self.pers["bonus"], true);
			else self extreme\_ex_memory::setMemory("score", "bonus", 0, true);
		if(isDefined(self.pers["special"])) self extreme\_ex_memory::setMemory("score", "special", self.pers["special"], true);
			else self extreme\_ex_memory::setMemory("score", "special", 0, true);
	}

	self thread extreme\_ex_memory::saveMemory();

	// disconnect message and sound
	if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
	{
		if(level.ex_plcdmsg) iprintln(&"CLIENTCONTROL_DISCONNECTED", [[level.ex_pname]](self));

		if(level.ex_plcdsound)
		{
			players = level.players;
			for(i = 0; i < players.size; i++) players[i] playLocalSound("gomplayersleft");
		}
	}
}

removePlayerOnDisconnect()
{
	for(entry = 0; entry < level.players.size; entry++ )
	{
		if(level.players[entry] == self)
		{
			while(entry < level.players.size-1)
			{
				level.players[entry] = level.players[entry + 1];
				entry++;
			}
			level.players[entry] = undefined;
			break;
		}
	}
}

getSessionState(ss)
{
	switch(ss)
	{
		case "spectator":
		case "intermission":
		case "dead":
		return true;
		
		default:
		return false;
	}
}

menuAutoAssign()
{
	if(isdefined(self.spawned)) return;

	numonteam["allies"] = 0;
	numonteam["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(player == self || !isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || !isDefined(player.pers["teamTime"])) continue;
		numonteam[player.pers["team"]]++;
	}

	// if teams are equal return the team with the lowest score
	if(numonteam["allies"] == numonteam["axis"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			teams[0] = "allies";
			teams[1] = "axis";
			assignment = teams[randomInt(2)];
		}
		else if(getTeamScore("allies") < getTeamScore("axis")) assignment = "allies";
			else assignment = "axis";
	}
	else if(numonteam["allies"] < numonteam["axis"]) assignment = "allies";
		else assignment = "axis";

	if(assignment == self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		if(!isDefined(self.pers["weapon"]))
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
				else self openMenu(game["menu_weapon_axis"]);
		}

		return;
	}

	if(assignment != self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self.pers["team"] = assignment;
	self.pers["savedmodel"] = undefined;

	// create the eXtreme+ weapon array
	self extreme\_ex_weapons::setWeaponArray();

	// clear game weapon arrarys
	self clearWeapons();
	
	self setClientCvar("ui_allow_weaponchange", "1");
	
	self updateAllAllowedSingleClient();

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				if(isdefined(self.respawntimer)) self.respawntimer destroy();
				[[level.spawnplayer]]();
				self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
			}
		}
		else if(self.pers["team"] == "allies")
		{
			self openMenu(game["menu_weapon_allies"]);
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		}
		else
		{
			self openMenu(game["menu_weapon_axis"]);
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		}
	}

	self notify("joined_team");
	if(!level.ex_roundbased) self notify("end_respawn");
}

menuAutoAssignDM()
{
	if(self.pers["team"] != "allies" && self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self suicide();
		}

		teams[0] = "allies";
		teams[1] = "axis";
		self.pers["team"] = teams[randomInt(2)];
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon arrarys
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");

		self updateAllAllowedSingleClient();

		if(self.pers["team"] == "allies") self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		else self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				if(isdefined(self.respawntimer)) self.respawntimer destroy();
				[[level.spawnplayer]]();
				self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
			}
		}
		else if(!isDefined(self.pers["weapon"]))
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
				else self openMenu(game["menu_weapon_axis"]);
		}
	}
}

menuAllies()
{
	if(isdefined(self.spawned)) return;
	
	if(self.pers["team"] != "allies")
	{
		if(self.sessionstate == "playing")
		{
			if(level.ex_currentgt != "dm" || level.ex_currentgt != "lms" || level.ex_currentgt != "hm")
			{
				self.joining_team = "allies";
				self.leaving_team = self.pers["team"];
			}

			self.switching_teams = true;
			self suicide();
		}

		self.pers["team"] = "allies";
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon arrarys
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");

		self updateAllAllowedSingleClient();

		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		// allow team change option on weapons menu if not deathmatch
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "lms" || level.ex_autoassign) self setClientCvar("ui_allow_teamchange", 0);
		else self setClientCvar("ui_allow_teamchange", 1);

		self notify("joined_team");
		if(!level.ex_roundbased) self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				if(isdefined(self.respawntimer)) self.respawntimer destroy();
				[[level.spawnplayer]]();
				self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
			}
		}
		else if(!isDefined(self.pers["weapon"])) self openMenu(game["menu_weapon_allies"]);
	}
}

menuAxis()
{
	if(isdefined(self.spawned)) return;

	if(self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			if(level.ex_currentgt != "dm" || level.ex_currentgt != "lms" || level.ex_currentgt != "hm")
			{
				self.joining_team = "axis";
				self.leaving_team = self.pers["team"];
			}

			self.switching_teams = true;
			self suicide();
		}

		self.pers["team"] = "axis";
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon arrarys
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");

		self updateAllAllowedSingleClient();

		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		// allow team change option on weapons menu if not deathmatch
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "lms" || level.ex_autoassign) self setClientCvar("ui_allow_teamchange", 0);
		else self setClientCvar("ui_allow_teamchange", 1);

		self notify("joined_team");
		if(!level.ex_roundbased) self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				if(isdefined(self.respawntimer)) self.respawntimer destroy();
				[[level.spawnplayer]]();
				self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
			}
		}
		else if(!isDefined(self.pers["weapon"])) self openMenu(game["menu_weapon_axis"]);
	}
}

menuSpectator()
{
	// do not allow anyone to go to spectators
	//if(isdefined(self.spawned)) return;

	// only allow clan 1 members (as set up in clancontrol.cfg) to go to spectators
	//if(isdefined(self.spawned) && (!isDefined(self.ex_name) || (isDefined(self.ex_name) && self.ex_clid != 1))) return;

	// allow only clan members (clan 1 - 4 as set up in clancontrol.cfg) to go to spectators
	//if(isdefined(self.spawned) && !isDefined(self.ex_name)) return;

	if(self.pers["team"] != "spectator")
	{
		if(isAlive(self))
		{
			if(level.ex_currentgt != "dm" || level.ex_currentgt != "lms" || level.ex_currentgt != "hm")
			{
				self.joining_team = "spectator";
				self.leaving_team = self.pers["team"];
			}

			self.switching_teams = true;
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.pers["savedmodel"] = undefined;
		self.sessionteam = "spectator";

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon arrarys
		self clearWeapons();

		self updateAllAllowedSingleClient();

		self setClientCvar("ui_allow_weaponchange", "0");

		extreme\_ex_spawn::spawnspectator();
		
		self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
	}

	self notify("joined_spectators");
}

menuWeapon(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis")) return;

	weapon = self restrictWeaponByServerCvars(response);

	if(weapon == "restricted")
	{
		if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);

		return;
	}

	self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(level.ex_wepo_secondary)
	{
		if(isDefined(self.pers["weapon2"]) && self.pers["weapon2"] == response)
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
			else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);
	
			return;
		}
	}
	else if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon) return;

	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		if(level.ex_wepo_secondary) self.pers["weapon1"] = weapon;
		self updateDisabledSingleClient(weapon);

		if(!level.ex_wepo_secondary)
		{
			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				if(isdefined(self.respawntimer)) self.respawntimer destroy();
				[[level.spawnplayer]]();
				self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
			}
		}
		else
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
			else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);

			return;
		}
	}
	else
	{
		self.pers["weapon"] = weapon;
		if(level.ex_wepo_secondary) self.pers["weapon1"] = weapon;
		self updateDisabledSingleClient(weapon);

		weaponname = getWeaponName(weapon);
		if(level.ex_roundbased && (level.ex_currentgt == "sd" || level.ex_currentgt == "lts"))
		{
			if(useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_SPAWN_WITH_AN_NEXT_ROUND", weaponname);
				else self iprintln(&"MP_YOU_WILL_SPAWN_WITH_A_NEXT_ROUND", weaponname);
		}
		else
		{
			if(useAn(self.pers["weapon"])) self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
				else self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
		}
	}

	level thread maps\mp\gametypes\_weapons::updateAllowed();

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

menuSecWeapon(response)
{
	self endon("disconnect");

	weapon = self restrictWeaponByServerCvars(response);

	if(weapon == "restricted" || (isDefined(self.pers["weapon1"]) && self.pers["weapon1"] == response))
	{
		if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
		else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);

		return;
	}

	self updateDisabledSingleClient(weapon);

	if(!isDefined(self.pers["weapon2"]))
	{
		self.pers["weapon2"] = weapon;

		if(!isDefined(self.ex_team_changed) && (isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize))) )
		{
			self [[level.respawnplayer]](true);
		}
		else
		{
			if(isdefined(self.respawntimer)) self.respawntimer destroy();
			[[level.spawnplayer]]();
			self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
		}
	}
	else
	{
		self.pers["weapon2"] = weapon;

		weaponname = getWeaponName(weapon);
		if(level.ex_roundbased && (level.ex_currentgt == "sd" || level.ex_currentgt == "lts"))
		{
			if(useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_SPAWN_WITH_AN_NEXT_ROUND_SECONDARY", weaponname);
				else self iprintln(&"MP_YOU_WILL_SPAWN_WITH_A_NEXT_ROUND_SECONDARY", weaponname);
		}
		else
		{
			if(useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN_SECONDARY", weaponname);
				else self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A_SECONDARY", weaponname);
		}
	}		

	level thread maps\mp\gametypes\_weapons::updateAllowed();

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

clearWeapons()
{
	self endon("disconnect");

	// clear weapon selection
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
}
