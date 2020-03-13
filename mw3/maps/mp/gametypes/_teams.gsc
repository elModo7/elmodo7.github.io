#include extreme\_ex_weapons;

init()
{
	level endon("ex_gameover");

	if(getCvar("scr_teambalance") == "") setCvar("scr_teambalance", "0");
	level.teambalance = getCvarInt("scr_teambalance");

	setPlayerModels();

	level.ex_autobalancing = false;
	if(level.ex_teamplay)
	{
		[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
		[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
		level thread updateTeamBalanceCvar();

		wait( [[level.ex_fpstime]](0.15) );

		if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts")
		{
			if(level.teambalance)
			{
				if(level.ex_teambalance_delay)
				{
					wait( [[level.ex_fpstime]](level.ex_teambalance_delay) );
					level.ex_teambalance_delay = 0;
				}

				if(level.teambalance && !getTeamBalance())
				{
					iprintlnbold(&"MP_AUTOBALANCE_NEXT_ROUND");
					level waittill("restarting");

					if(level.teambalance && !getTeamBalance()) level balanceTeams();
				}
			}
		}
		else
		{
			for(;;)
			{
				if(level.teambalance)
				{
					if(level.ex_teambalance_delay)
					{
						wait( [[level.ex_fpstime]](level.ex_teambalance_delay) );
						level.ex_teambalance_delay = 0;
					}

					if(level.teambalance && !getTeamBalance())
					{
						iprintlnbold(&"MP_AUTOBALANCE_SECONDS", 15);
						wait( [[level.ex_fpstime]](15) );

						if(level.teambalance && !getTeamBalance()) level balanceTeams();
					}

					wait( [[level.ex_fpstime]](59) );
				}

				wait( [[level.ex_fpstime]](1) );
			}
		}
	}
}

onJoinedTeam()
{
	self updateTeamTime();
}

onJoinedSpectators()
{
	self.pers["teamTime"] = undefined;
}

updateTeamTime()
{
	if(level.ex_currentgt == "sd" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd") self.pers["teamTime"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
		else self.pers["teamTime"] = (gettime() / 1000);
}

updateTeamBalanceCvar()
{
	for(;;)
	{
		teambalance = getCvarInt("scr_teambalance");
		if(level.teambalance != teambalance)
			level.teambalance = teambalance;

		wait( [[level.ex_fpstime]](5) );
	}
}

getTeamBalance()
{
	level endon("ex_gameover");

	if(level.ex_autobalancing) return true;

	AlliedPlayers = 0;
	AxisPlayers = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isPlayer(player) && isDefined(player.pers["team"]))
		{
			if(player.pers["team"] != "spectator" && player.sessionteam != "spectator")
			{
				switch(player.pers["team"])
				{
					case "allies":
						AlliedPlayers++;
						//logprint("TB DEBUG: " + player.name + " counted as allies\n");
						break;
					case "axis":
						AxisPlayers++;
						//logprint("TB DEBUG: " + player.name + " counted as axis\n");
						break;
				}
			}
			//else logprint("TB DEBUG: " + player.name + " not counted. (session)team set to \"spectator\"\n");
		}
	}

	if(AlliedPlayers > (AxisPlayers + 1))
	{
		//logprint("TB DEBUG: initiating team balancing. More allies (" + AlliedPlayers + ") than axis (" + AxisPlayers + ")\n");
		return false;
	}
	else if(AxisPlayers > (AlliedPlayers + 1))
	{
		//logprint("TB DEBUG: initiating team balancing. More axis (" + AxisPlayers + ") than allies (" + AlliedPlayers + ")\n");
		return false;
	}

	return true;
}

balanceTeams()
{
	level endon("ex_gameover");

	if(level.ex_autobalancing) return;
	level.ex_autobalancing = true;

	AlliedPlayers = [];
	AlliedClanPlayers = 0;
	AxisPlayers = [];
	AxisClanPlayers = 0;
	MostRecent = undefined;

	// Populate the team arrays
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		wait( [[level.ex_fpstime]](0.05) );
		if(isPlayer(players[i]) && isDefined(players[i].pers["teamTime"]))
		{
		  if(isDefined(players[i].pers["team"]))
		  {
				if(players[i].pers["team"] == "allies")
				{
					AlliedPlayers[AlliedPlayers.size] = players[i];
					if(isDefined(players[i].ex_name) && players[i].ex_clid == 1) AlliedClanPlayers++;
				}
				else if(players[i].pers["team"] == "axis")
				{
					AxisPlayers[AxisPlayers.size] = players[i];
					if(isDefined(players[i].ex_name) && players[i].ex_clid == 1) AxisClanPlayers++;
				}
			}
		}
	}

	// If level.ex_clantag1_nobalance is enabled, clan1 members will not be
	// auto-balanced, unless all players on that team are clan members
	clan_nobalance = level.ex_clantag1_nobalance;
	if(clan_nobalance && (AlliedPlayers.size == AlliedClanPlayers || AxisPlayers.size == AxisClanPlayers)) clan_nobalance = false;

	iprintlnbold(&"MP_AUTOBALANCE_NOW");

	while((AlliedPlayers.size > (AxisPlayers.size + 1)) || (AxisPlayers.size > (AlliedPlayers.size + 1)))
	{
		if(AlliedPlayers.size > (AxisPlayers.size + 1))
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			for(j = 0; j < AlliedPlayers.size; j++)
			{
				wait( [[level.ex_fpstime]](0.05) );
				if(isPlayer(AlliedPlayers[j]) && (isDefined(AlliedPlayers[j].dont_auto_balance) || !isDefined(AlliedPlayers[j].pers) || !isDefined(AlliedPlayers[j].pers["teamTime"]))) continue;
				if(clan_nobalance && isDefined(AlliedPlayers[j].ex_name) && AlliedPlayers[j].ex_clid == 1) continue;

				if(isPlayer(AlliedPlayers[j]))
				{
					if(!isDefined(MostRecent)) MostRecent = AlliedPlayers[j];
						else if(isPlayer(AlliedPlayers[j]) && isDefined(AlliedPlayers[j].pers["teamTime"]) && AlliedPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"]) MostRecent = AlliedPlayers[j];
				}
			}

			if(isDefined(MostRecent))
			{
				if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent changeTeam_RoundBased("axis");
					else MostRecent changeTeam("axis");
			}
		}
		else if(AxisPlayers.size > (AlliedPlayers.size + 1))
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			for(j = 0; j < AxisPlayers.size; j++)
			{
				if(isPlayer(AxisPlayers[j]) && (isDefined(AxisPlayers[j].dont_auto_balance) || !isDefined(AxisPlayers[j].pers) || !isDefined(AxisPlayers[j].pers["teamTime"]))) continue;
				if(clan_nobalance && isDefined(AxisPlayers[j].ex_name) && AxisPlayers[j].ex_clid == 1) continue;

				if(isPlayer(AxisPlayers[j]))
				{
					if(!isDefined(MostRecent)) MostRecent = AxisPlayers[j];
						else if(isPlayer(AxisPlayers[j]) && isDefined(AxisPlayers[j].pers["teamTime"]) && AxisPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"]) MostRecent = AxisPlayers[j];
				}
			}

			if(isDefined(MostRecent))
			{
				if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent changeTeam_RoundBased("allies");
					else MostRecent changeTeam("allies");
			}
		}

		AlliedPlayers = [];
		AlliedClanPlayers = 0;
		AxisPlayers = [];
		AxisClanPlayers = 0;
		MostRecent = undefined;

		// Populate the team arrays to check again
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			wait( [[level.ex_fpstime]](0.05) );
			if(isPlayer(players[i]) && isDefined(players[i].pers["teamTime"]))
			{
			  if(isDefined(players[i].pers["team"]))
			  {
					if(players[i].pers["team"] == "allies")
					{
						AlliedPlayers[AlliedPlayers.size] = players[i];
						if(isDefined(players[i].ex_name) && players[i].ex_clid == 1) AlliedClanPlayers++;
					}
					else if(players[i].pers["team"] == "axis")
					{
						AxisPlayers[AxisPlayers.size] = players[i];
						if(isDefined(players[i].ex_name) && players[i].ex_clid == 1) AxisClanPlayers++;
					}
				}
			}
		}

		clan_nobalance = level.ex_clantag1_nobalance;
		if(clan_nobalance && (AlliedPlayers.size == AlliedClanPlayers || AxisPlayers.size == AxisClanPlayers)) clan_nobalance = false;
	}

	level.ex_autobalancing = false;
}

changeTeam(team, special)
{
	if(!isDefined(special)) special = false;

	if(level.ex_mbot && isdefined(self.pers["isbot"]))
	{
		leavingteam = self.pers["team"];

		self thread extreme\_ex_bots::botJoin("spectator");
		wait( [[level.ex_fpstime]](0.75) );

		if(leavingteam == "allies")
		{
			level.bots_al--;
			self thread extreme\_ex_bots::addBot("axis");
		}
		else
		{
			level.bots_ax--;
			self thread extreme\_ex_bots::addBot("allies");
		}
	}
	else
	{
		if(self.sessionstate != "dead")
		{
			// Set a flag on the player to they aren't robbed points for dying - the callback will remove the flag
			if(!special)
			{
				self.switching_teams = true;
				self.joining_team = team;
				self.leaving_team = self.pers["team"];
			}
		
			// Suicide the player so they can't hit escape and fail the team balance
			self suicide();
		}

		self.pers["team"] = team;
		self.pers["savedmodel"] = undefined;
		self.sessionteam = self.pers["team"];

		if(isDefined(self.pers["isbot"]))
		{
			self thread extreme\_ex_bots::dbotLoadout();
			return;
		}

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon arrarys
		self extreme\_ex_clientcontrol::clearWeapons();
	
		// update spectator permissions immediately on change of team
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

		// update allowed weapons
		self maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		// allow weapon change, do not allow team change!
		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("ui_allow_teamchange", 0);

		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
			[[level.spawnplayer]]();
			self extreme\_ex_clientcontrol::exPrintJoinedTeam(self.pers["team"]);
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
				self openMenu(game["menu_weapon_allies"]);
			}
			else
			{
				self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
				self openMenu(game["menu_weapon_axis"]);
			}
		}

		self updateTeamTime();

		self notify("end_respawn");
	}
}

changeTeam_RoundBased(team)
{
	self.pers["team"] = team;
	self.pers["savedmodel"] = undefined;

	// create the eXtreme+ weapon array
	self extreme\_ex_weapons::setWeaponArray();

	// clear game weapon arrarys
	self extreme\_ex_clientcontrol::clearWeapons();

	// update allowed weapons
	//self maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

	// do not allow team change!
	self setClientCvar("ui_allow_teamchange", 0);

	self updateTeamTime();
}

setPlayerModels()
{
	// Make sure the level script has the soldier types defined correctly
	switch(game["allies"])
	{
		case "british":
			if(isDefined(game["british_soldiertype"]))
			{
				if(game["british_soldiertype"] != "africa" && game["british_soldiertype"] != "normandy")
					game["british_soldiertype"] = "normandy";
			}
			else game["british_soldiertype"] = "normandy";
			break;
		case "russian":
			if(isDefined(game["russian_soldiertype"]))
			{
				if(game["russian_soldiertype"] != "coats" && game["russian_soldiertype"] != "padded")
					game["russian_soldiertype"] = "coats";
			}
			else game["russian_soldiertype"] = "coats";
			break;
		case "american":
			game["american_soldiertype"] = "normandy";
			break;
	}

	if(isDefined(game["german_soldiertype"]))
	{
		if(game["german_soldiertype"] != "africa" && game["german_soldiertype"] != "normandy" &&
		   game["german_soldiertype"] != "winterdark" && game["german_soldiertype"] != "winterlight")
			game["german_soldiertype"] = "normandy";
	}
	else game["german_soldiertype"] = "normandy";

	// Workaround for the 127 bones error with mobile turrets
	if(level.override_soldiertype)
	{
		if(isDefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "coats")
			game["russian_soldiertype"] = "padded";
		if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
			game["german_soldiertype"] = "winterlight";
	}

	// Stock processing
	switch(game["allies"])
	{
		case "british":
			if(isDefined(game["british_soldiertype"]) && game["british_soldiertype"] == "africa")
			{
				mptype\british_africa::precache();
				game["allies_model"] = mptype\british_africa::main;
			}
			else
			{
				mptype\british_normandy::precache();
				game["allies_model"] = mptype\british_normandy::main;
			}
			break;
	
		case "russian":
			if(isDefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "padded")
			{
				mptype\russian_padded::precache();
				game["allies_model"] = mptype\russian_padded::main;
			}
			else
			{
				mptype\russian_coat::precache();
				game["allies_model"] = mptype\russian_coat::main;
			}
			break;
	
		case "american":
		default:
			mptype\american_normandy::precache();
			game["allies_model"] = mptype\american_normandy::main;
	}

	if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
	{
		mptype\german_winterdark::precache();
		game["axis_model"] = mptype\german_winterdark::main;
	}
	else if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterlight")
	{
		mptype\german_winterlight::precache();
		game["axis_model"] = mptype\german_winterlight::main;
	}
	else if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "africa")
	{
		mptype\german_africa::precache();
		game["axis_model"] = mptype\german_africa::main;
	}
	else
	{
		mptype\german_normandy::precache();
		game["axis_model"] = mptype\german_normandy::main;	
	}
}

model()
{
	self detachAll();
	
	if(self.pers["team"] == "allies") [[game["allies_model"] ]]();
		else if(self.pers["team"] == "axis") [[game["axis_model"] ]]();

	self.pers["savedmodel"] = maps\mp\_utility::saveModel();
}

CountPlayers()
{
	//chad
	allies = 0;
	axis = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies")) allies++;
			else if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis")) axis++;
	}
	players["allies"] = allies;
	players["axis"] = axis;
	return players;
}

switchClanVersusNonclan(mode)
{
	level endon("ex_gameover");

	if(mode == level.ex_clanvsnonclan) return;

	if(mode == 0)
	{
		level.ex_clanvsnonclan = 0;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHOFF_NOW");

		level.ex_autoassign = level.ex_autoassign_org;
		if(level.ex_autoassign == 2)
		{
			level.teambalance = 0;
			setCvar("scr_teambalance", level.teambalance);
		}
		else
		{
			level.teambalance = [[level.ex_drm]]("scr_teambalance", 1, 0, 1,"int");
			setCvar("scr_teambalance", level.teambalance);
			if(level.teambalance && !getTeamBalance()) level balanceTeams();
		}
	}

	if(mode == 1)
	{
		level.ex_clanvsnonclan = 1;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHON_NOW");

		wait [[level.ex_fpstime]]((3) );
		players = level.players;
		for(i = 0; i < players.size; i++) players[i] freezecontrols(true);

		level.ex_autoassign = 2;
		level.teambalance = 0;
		setCvar("scr_teambalance", level.teambalance);

		wait( [[level.ex_fpstime]](3) );
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			players[i] extreme\_ex_main::resetPlayerVariables();
			players[i] freezecontrols(false);
		}

		thread balanceClanVersusNonclan();
		wait( [[level.ex_fpstime]](5) );
		iprintlnBold(&"MISC_CLANVSNONCLAN_RESTART");
		wait( [[level.ex_fpstime]](3) );
		map_restart(true);
	}

	if(mode == 2)
	{
		level.ex_clanvsnonclan = 2;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHON_NEXTMAP");
	}

	if(mode == 3)
	{
		level.ex_clanvsnonclan = 3;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHOFF_NEXTMAP");
	}
}

balanceClanVersusNonclan()
{
	level endon("ex_gameover");

	iprintlnbold(&"MP_AUTOBALANCE_NOW");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isPlayer(player))
		{
			if(isDefined(player.ex_name) && player.ex_clid == 1)
			{
				if(isDefined(player.pers["team"]) && player.pers["team"] != level.ex_autoassign_clanteam)
					if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || level.ex_currentgt == "ihtf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd") player changeTeam_RoundBased(level.ex_autoassign_clanteam);
						else player changeTeam(level.ex_autoassign_clanteam, true);
			}
			else
			{
				if(isDefined(player.pers["team"]) && player.pers["team"] != level.ex_autoassign_nonclanteam)
					if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || level.ex_currentgt == "ihtf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd") player changeTeam_RoundBased(level.ex_autoassign_nonclanteam);
						else player changeTeam(level.ex_autoassign_nonclanteam, true);
			}
		}
	}
}

monitorClanVersusNonclan()
{
	level endon("ex_gameover");

	check_interval = 60; // seconds between each check
	noplayers_checks_max = 3; // terminate clan vs. non-clan if still no players after x checks
	nomembers_checks_max = 3; // terminate clan vs. non-clan if still no members after x checks
	members_min = 2; // minimum numbers of clan members needed to keep clan vs. non-clan alive

	noplayers_checks = 0;
	nomembers_checks = 0;

	monitoring = true;
	while(monitoring)
	{
		wait( [[level.ex_fpstime]](check_interval) );

		//logprint("CLANVSNONCLAN: checking for players\n");
		members = 0;

		players = level.players;
		if(players.size)
		{
			noplayers_checks = 0;
			//logprint("CLANVSNONCLAN: checking for members\n");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player.ex_name) && player.ex_clid == 1)
				{
					members++;
					//logprint("CLANVSNONCLAN: member " + player.name + " is online\n");
				}
			}
			if(members < members_min) nomembers_checks++;
			  else nomembers_checks = 0;
			if(nomembers_checks == nomembers_checks_max) monitoring = false;
		}
		else
		{
			noplayers_checks++;
			if(noplayers_checks == noplayers_checks_max) monitoring = false;
		}
	}

	//logprint("CLANVSNONCLAN: switching to any to any mode\n");
	setCvar("ex_clanvsnonclan", 0);
	switchClanVersusNonclan(0);
}
