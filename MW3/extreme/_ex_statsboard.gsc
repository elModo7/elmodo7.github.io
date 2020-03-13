main()
{
	if(prepareStats())
	{
		// play music if there is no end music playing
		if(level.ex_statsmusic)
		{
			statsmusic = randomInt(10);
			musicplay("gom_music_" + statsmusic);
		}
		runStats();
	}
}

prepareStats()
{
	// Create the statsboard data structure
	level.stats = spawnstruct();
	if(level.ex_stbd_icons) level.stats.maxplayers = 5;
		else level.stats.maxplayers = 6;
	level.stats.players = 0;
	level.stats.maxcategories = 0;
	level.stats.categories = 0;
	level.stats.maxtime = level.ex_stbd_time;
	level.stats.time = level.stats.maxtime;
	level.stats.hasdata = false;
	level.stats.cat = [];

	thread [[level.ex_bclear]]("all",5);
	game["menu_team"] = "";

	// Valid players available?
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		// Only get stats from real players
		player.stats_player = false;
		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionteam != "spectator")
			player.stats_player = true;

		if(player.stats_player) level.stats.players++;
	}

	if(level.stats.players == 0) return false;
	if(level.stats.players > level.stats.maxplayers) level.stats.players = level.stats.maxplayers;

	// Make all players spectators with limited permissions
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		player setClientCvar("g_scriptMainMenu", "");
		player closeMenu();
		player extreme\_ex_spawn::spawnSpectator();
		player allowSpectateTeam("allies", false);
		player allowSpectateTeam("axis", false);
		player allowSpectateTeam("freelook", false);
		player allowSpectateTeam("none", true);

		if(!isPlayer(player) || !player.stats_player) continue;

		player.statsicon = player thread getStatsIcon();

		if(level.ex_stbd_se)
		{
			// set player score and efficiency
			if(isDefined(player.score)) player.pers["score"] = player.score;
				else player.pers["score"] = 0;

			if(!isDefined(player.pers["kill"])) player.pers["kill"] = 0;
			if(!isDefined(player.pers["death"])) player.pers["death"] = 0;

			if(player.pers["kill"] == 0 || (player.pers["kill"] - player.pers["death"]) <= 0) player.pers["efficiency"] = 0;
				else player.pers["efficiency"] = int( (100 / player.pers["kill"]) * (player.pers["kill"] - player.pers["death"]) );
			if(player.pers["efficiency"] > 100) player.pers["efficiency"] = 0;
		}
	}

	category = 0;
	for(;;)
	{
		category_str = GetCategoryStr(category);
		if(category_str == "") break;
		level.stats.maxcategories++;

		level.stats.cat[category_str] = [];
		level.stats.categories++;

		category_kill_str = GetCategoryKillStr(category);
		category_death_str = GetCategoryDeathStr(category);

		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player) || !player.stats_player) continue;

			if(category_kill_str != "-") kills = player.pers[category_kill_str];
				else kills = 0;
			if(category_death_str != "-") deaths = player.pers[category_death_str];
				else deaths = 0;

			// For whatever reason, kills or deaths is undefined sometimes. Make sure they exist
			if(!isDefined(kills)) kills = 0;
			if(!isDefined(deaths)) deaths = 0;

			if(level.stats.cat[category_str].size < level.stats.maxplayers)
			{
				// Add array element with players's stats
				level.stats.cat[category_str][level.stats.cat[category_str].size] = spawnstruct();
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].player = player;
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].statsicon = player.statsicon;
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].kills = kills;
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].deaths = deaths;

				if(kills || deaths) level.stats.hasdata = true;
			}
			else
			{
				// Array full: check if players's stats are better than stats in array
				for(j = 0; j < level.stats.cat[category_str].size; j++)
				{
					if(category_kill_str != "-")
					{
						// If category manages kills, use those
						if(kills > level.stats.cat[category_str][j].kills)
						{
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].player = player;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].statsicon = player.statsicon;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].kills = kills;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].deaths = deaths;
						}
					}
					else
					{
						// Category does not manage kills, so use deaths instead
						if(deaths > level.stats.cat[category_str][j].deaths)
						{
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].player = player;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].statsicon = player.statsicon;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].kills = kills;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].deaths = deaths;
						}
					}
				}
			}
			// Sort the scores in this category
			// Do not check on maxplayers, because it will not sort if stats.players < stats.maxplayers
			if(level.stats.cat[category_str].size >= level.stats.players)
				sortScores(category_str, 0, level.stats.cat[category_str].size - 1);
		}

		category++;
	}

	// Dump stats to log
	if(level.ex_stbd_log)
	{
		logprint("STATSBOARD [categories][" + level.stats.categories + "]\n");
		for(i = 0; i < level.stats.maxcategories; i++)
		{
			category_str = GetCategoryStr(i);
			if(isDefined(level.stats.cat[category_str]))
			{
				logprint("STATSBOARD [" + category_str + "][" + level.stats.cat[category_str].size + "]\n");
				for(j = 0; j < level.stats.cat[category_str].size; j++)
				{
					logprint("  [" + category_str + "][" + j + "][" + level.stats.cat[category_str][j].player.name + "][" +
						level.stats.cat[category_str][j].kills + ":" + level.stats.cat[category_str][j].deaths + "]\n");
				}
			}
		}
	}

	// No data - no stats
	if(!level.stats.hasdata) return false;
	return true;
}

runStats()
{
	createLevelHUD();

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].stats_player))
			players[i] thread playerStatsLogic();
	}

	thread levelStatsLogic();
	level waittill("stats_finished");

	if(level.ex_stbd_fade) fadeAllHUD(1);
	deleteAllHUD();
	wait( [[level.ex_fpstime]](2) );
}

newplayerStatsLogic()
{
	self endon("disconnect");
	level endon("stats_done");

	if(!isPlayer(self)) return;
	if(isDefined(self.stats_player)) return;
	self.stats_player = false;

	//logprint("STATSBOARD: launching newplayerStatsLogic for player " + self.name + "\n");

	self setClientCvar("g_scriptMainMenu", "");
	self closeMenu();
	self extreme\_ex_spawn::spawnSpectator();
	self allowSpectateTeam("allies", false);
	self allowSpectateTeam("axis", false);
	self allowSpectateTeam("freelook", false);
	self allowSpectateTeam("none", true);

	self thread playerStatsLogic();
}

playerStatsLogic()
{
	self endon("disconnect");
	level endon("stats_done");

	//logprint("STATSBOARD: launching playerStatsLogic for player " + self.name + "\n");

	if(!createPlayerHUD())
	{
		logprint("STATSBOARD: error creating HUD elements for player " + self.name + "\n");
		logprint("STATSBOARD: cleaning HUD for second try...\n");
		extreme\_ex_hud::cleanplayerend();
		deletePlayerHUD();
		if(!createPlayerHUD())
		{
			logprint("STATSBOARD: still errors. aborting playerStatsLogic\n");
			return;
		}
	}

	// Initialize player vars
	self.stats_category = 99;
	self nextCategory();

	// Now loop until the thread is signaled to end
	for (;;)
	{
		wait( [[level.ex_fpstime]](0.01) );

		// Attack (FIRE) button for next category
		if(isplayer(self) && self attackButtonPressed() == true)
		{
			self nextCategory();
			while(isPlayer(self) && self attackButtonPressed() == true)
				wait( [[level.ex_fpstime]](0.01) );
		}

		// Melee button for previous category
		if(isplayer(self) && self meleeButtonPressed() == true)
		{
			self previousCategory();
			while(isPlayer(self) && self meleeButtonPressed() == true)
				wait( [[level.ex_fpstime]](0.01) );
		}

		if(isPlayer(self))
		{
			self.sessionstate = "spectator";
			self.spectatorclient = -1;
		}
	}
}

levelStatsLogic()
{
	if(level.ex_stbd_tps)
	{
		level.stats.maxtime = level.stats.categories * level.ex_stbd_tps;
		level.stats.time = level.stats.maxtime;
	}

	for(i = 0; i < level.stats.maxtime; i++)
	{
		wait( [[level.ex_fpstime]](1) );
		players = level.players;
		for(j = 0; j < players.size; j++)
		{
			player = players[j];
			if(!isDefined(player.stats_player))
				player thread newplayerStatsLogic();
		}
		level.stats.time--;
		level.statshud[6] setValue(level.stats.time);
	}
	level notify("stats_done");

	// If things are needed between the "done" and "finished" signals, first clean HUD
	//if(level.ex_stbd_fade) fadeAllHUD(1);
	//deleteAllHUD();
	wait( [[level.ex_fpstime]](1) );

	level notify("stats_finished");
}

nextCategory()
{
	self endon("disconnect");
	level endon("stats_done");

	oldcategory = self.stats_category;
	self.stats_category++;
	while(true)
	{
		if(self.stats_category >= level.stats.maxcategories) self.stats_category = 0;
		category_str = getCategoryStr(self.stats_category);
		if(isActivatedCategory(self.stats_category) && isDefined(level.stats.cat[category_str]) && hasData(category_str)) break;
		self.stats_category++;
		if(self.stats_category == oldcategory) break; // Complete cycle, so end
	}

	if(self.stats_category != oldcategory)
	{
		self playLocalSound("flagchange");
		if(level.ex_stbd_fade)
		{
			self fadePlayerHUD(0.5);
			wait( [[level.ex_fpstime]](0.5) );
		}
		self showCategory(self.stats_category);
	}
}

previousCategory()
{
	self endon("disconnect");
	level endon("stats_done");

	oldcategory = self.stats_category;
	self.stats_category--;
	while(true)
	{
		if(self.stats_category < 0) self.stats_category = level.stats.maxcategories-1;
		category_str = getCategoryStr(self.stats_category);
		if(isActivatedCategory(self.stats_category) && isDefined(level.stats.cat[category_str]) && hasData(category_str)) break;
		self.stats_category--;
		if(self.stats_category == oldcategory) break; // Complete cycle, so end
	}

	if(self.stats_category != oldcategory)
	{
		self playLocalSound("flagchange");
		if(level.ex_stbd_fade)
		{
			self fadePlayerHUD(0.5);
			wait( [[level.ex_fpstime]](0.5) );
		}
		self showCategory(self.stats_category);
	}
}

showCategory(newcategory)
{
	self endon("disconnect");
	level endon("stats_done");

	category_str = GetCategoryStr(newcategory);
	if(!isDefined(level.stats.cat[category_str]) || category_str == "") return;

	category_locstr = getCategoryLocStr(newcategory);
	self.pstatshud_head[0].label = category_locstr;
	self.pstatshud_head[0].alpha = 1;

	category_header = getCategoryHeader(newcategory);
	self.pstatshud_head[1].label = category_header;
	self.pstatshud_head[1].alpha = 1;

	if(level.ex_stbd_icons)
	{
		for(i = 0; i < level.stats.players; i++)
		{
			self.pstatshud_col1[i] setShader(level.stats.cat[category_str][i].statsicon, 14,14);
			self.pstatshud_col1[i].alpha = 1;
		}
	}

	for(i = 0; i < level.stats.players; i++)
	{
		if(isPlayer(level.stats.cat[category_str][i].player) &&
			isDefined(level.stats.cat[category_str][i].player.stats_player) &&
			level.stats.cat[category_str][i].player.stats_player &&
			!isDefined(level.stats.cat[category_str][i].playerleft))
		{
			self.pstatshud_col2[i] setPlayerNameString(level.stats.cat[category_str][i].player);
			self.pstatshud_col2[i].alpha = 1;
		}
		else
		{
			level.stats.cat[category_str][i].playerleft = true;
			self.pstatshud_col2[i] setText(&"STATSBOARD_PLAYERLEFT");
			self.pstatshud_col2[i].alpha = 1;
		}
	}

	category_kill_str = GetCategoryKillStr(newcategory);
	for(i = 0; i < level.stats.players; i++)
	{
		if(category_kill_str != "-")
		{
			self.pstatshud_col3[i] setValue(level.stats.cat[category_str][i].kills);
			self.pstatshud_col3[i].alpha = 1;
		}
		else self.pstatshud_col3[i].alpha = 0;
	}

	category_death_str = GetCategoryDeathStr(newcategory);
	for(i = 0; i < level.stats.players; i++)
	{
		if(category_death_str != "-")
		{
			self.pstatshud_col4[i] setValue(level.stats.cat[category_str][i].deaths);
			self.pstatshud_col4[i].alpha = 1;
		}
		else self.pstatshud_col4[i].alpha = 0;
	}
}

hasData(category_str)
{
	self endon("disconnect");
	level endon("stats_done");

	for(i = 0; i < level.stats.cat[category_str].size; i++)
		if(level.stats.cat[category_str][i].kills != 0 || level.stats.cat[category_str][i].deaths != 0)
		  return true;

	return false;
}

sortScores(category_str, start, max)
{
	temp = spawnstruct();

	i = start;
	while(i < max)
	{
		j = start;
		while(j < (max - i))
		{
			r = compareScores(category_str, j, j + 1);
			if(r == 2)
			{
				temp = level.stats.cat[category_str][j];
				level.stats.cat[category_str][j] = level.stats.cat[category_str][j + 1];
				level.stats.cat[category_str][j + 1] = temp;
			}
			j++;
		}
		i++;
	}

	temp = undefined;
}

compareScores(category_str, s1, s2)
{
	if(category_str == "score" || category_str == "bonus") special = true;
		else special = false;

	k = level.stats.cat[category_str][s1].kills - level.stats.cat[category_str][s2].kills;
	d = level.stats.cat[category_str][s1].deaths - level.stats.cat[category_str][s2].deaths;

	if(k == 0)
	{
		if(d == 0) return 0;
		if(!special)
		{
			if(d > 0) return 2;
				else return 1;
		}
		else
		{
			if(d > 0) return 1;
				else return 2;
		}
	}
	else
	{
		if(k > 0) return 1;
			else return 2;
	}
}

createLevelHUD()
{
	// Create all level HUD elements
	maxLines = level.stats.players + 2;
	//maxLines = level.stats.maxplayers + 2;

	level.statshud = [];

	// Background
	level.statshud[0] = newHudElem();
	level.statshud[0].archived = false;
	level.statshud[0].horzAlign = "subleft";
	level.statshud[0].vertAlign = "subtop";
	level.statshud[0].alignX = "left";
	level.statshud[0].alignY = "top";
	level.statshud[0].x = 190 + level.ex_stbd_movex;
	level.statshud[0].y = 45;
	level.statshud[0].alpha = .7;
	level.statshud[0].sort = 100;
	level.statshud[0].color = (0,0,0);
	level.statshud[0] setShader("white", 260, 75 + (maxLines * 16));

	// Title bar
	level.statshud[1] = newHudElem();
	level.statshud[1].archived = false;
	level.statshud[1].horzAlign = "subleft";
	level.statshud[1].vertAlign = "subtop";
	level.statshud[1].alignX = "left";
	level.statshud[1].alignY = "top";
	level.statshud[1].x = 193 + level.ex_stbd_movex;
	level.statshud[1].y = 47;
	level.statshud[1].alpha = .3;
	level.statshud[1].sort = 101;
	level.statshud[1] setShader("white", 255, 21);

	// Separator (top)
	level.statshud[2] = newHudElem();
	level.statshud[2].archived = false;
	level.statshud[2].horzAlign = "subleft";
	level.statshud[2].vertAlign = "subtop";
	level.statshud[2].alignX = "left";
	level.statshud[2].alignY = "top";
	level.statshud[2].x = 193 + level.ex_stbd_movex;
	level.statshud[2].y = 100;
	level.statshud[2].alpha = .3;
	level.statshud[2].sort = 101;
	level.statshud[2] setShader("white", 255, 1);

	// Separator (bottom)
	level.statshud[3] = newHudElem();
	level.statshud[3].archived = false;
	level.statshud[3].horzAlign = "subleft";
	level.statshud[3].vertAlign = "subtop";
	level.statshud[3].alignX = "left";
	level.statshud[3].alignY = "top";
	level.statshud[3].x = 193 + level.ex_stbd_movex;
	level.statshud[3].y = 100 + (maxLines * 16);
	level.statshud[3].alpha = .3;
	level.statshud[3].sort = 101;
	level.statshud[3] setShader("white", 255, 1);

	// Title
	level.statshud[4] = newHudElem();
	level.statshud[4].archived = false;
	level.statshud[4].horzAlign = "subleft";
	level.statshud[4].vertAlign = "subtop";
	level.statshud[4].alignX = "left";
	level.statshud[4].alignY = "top";
	level.statshud[4].x = 195 + level.ex_stbd_movex;
	level.statshud[4].y = 50;
	level.statshud[4].sort = 102;
	level.statshud[4].fontscale = 1.4;
	level.statshud[4].label = &"STATSBOARD_TITLE";

	// How-to instructions
	level.statshud[5] = newHudElem();
	level.statshud[5].archived = false;
	level.statshud[5].horzAlign = "subleft";
	level.statshud[5].vertAlign = "subtop";
	level.statshud[5].alignX = "center";
	level.statshud[5].alignY = "top";
	level.statshud[5].x = 320 + level.ex_stbd_movex;
	level.statshud[5].y = 83 + (maxLines * 16);
	level.statshud[5].sort = 102;
	level.statshud[5].fontscale = 1;
	level.statshud[5].alignX = "center";
	level.statshud[5].label = &"STATSBOARD_HOWTO";

	// Time left
	level.statshud[6] = newHudElem();
	level.statshud[6].archived = false;
	level.statshud[6].horzAlign = "subleft";
	level.statshud[6].vertAlign = "subtop";
	level.statshud[6].alignX = "left";
	level.statshud[6].alignY = "top";
	level.statshud[6].x = 195 + level.ex_stbd_movex;
	level.statshud[6].y = 105 + (maxLines * 16);
	level.statshud[6].sort = 102;
	level.statshud[6].fontscale = 1;
	level.statshud[6].label = &"STATSBOARD_TIMELEFT";
	level.statshud[6] setValue(level.ex_stbd_time);
}

createPlayerHUD()
{
	self endon("disconnect");
	level endon("stats_done");

	// Category
	if(!isDefined(self.pstatshud_head))
	{
		self.pstatshud_head = [];

		if(!isDefined(self.pstatshud_head[0])) self.pstatshud_head[0] = newClientHudElem(self);
		if(isDefined(self.pstatshud_head[0]))
		{
			self.pstatshud_head[0].archived = false;
			self.pstatshud_head[0].horzAlign = "subleft";
			self.pstatshud_head[0].vertAlign = "subtop";
			self.pstatshud_head[0].alignX = "left";
			self.pstatshud_head[0].alignY = "top";
			self.pstatshud_head[0].x = 195 + level.ex_stbd_movex;
			self.pstatshud_head[0].y = 80;
			self.pstatshud_head[0].sort = 103;
			self.pstatshud_head[0].fontscale = 1.2;
		}
		else return(false);

		// Column header
		if(!isDefined(self.pstatshud_head[1])) self.pstatshud_head[1] = newClientHudElem(self);
		if(isDefined(self.pstatshud_head[1]))
		{
			self.pstatshud_head[1].archived = false;
			self.pstatshud_head[1].horzAlign = "subleft";
			self.pstatshud_head[1].vertAlign = "subtop";
			self.pstatshud_head[1].alignX = "right";
			self.pstatshud_head[1].alignY = "middle";
			self.pstatshud_head[1].x = 445 + level.ex_stbd_movex;
			self.pstatshud_head[1].y = 80;
			self.pstatshud_head[1].sort = 103;
			self.pstatshud_head[1].fontscale = 1.1;
			self.pstatshud_head[1].alignX = "right";
		}
		else return(false);
	}

	if(level.ex_stbd_icons && !isDefined(self.pstatshud_col1))
	{
		self.pstatshud_col1 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			if(!isDefined(self.pstatshud_col1[i])) self.pstatshud_col1[i] = newClientHudElem(self);
			if(isDefined(self.pstatshud_col1[i]))
			{
				self.pstatshud_col1[i].archived = false;
				self.pstatshud_col1[i].horzAlign = "subleft";
				self.pstatshud_col1[i].vertAlign = "subtop";
				self.pstatshud_col1[i].alignX = "left";
				self.pstatshud_col1[i].alignY = "top";
				self.pstatshud_col1[i].x = 195 + level.ex_stbd_movex;
				self.pstatshud_col1[i].y = 105 + i * 16;
				self.pstatshud_col1[i].sort = 103;
			}
			else return(false);
		}
		namex = 215;
	}
	else namex = 195;

	if(!isDefined(self.pstatshud_col2))
	{
		self.pstatshud_col2 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			if(!isDefined(self.pstatshud_col2[i])) self.pstatshud_col2[i] = newClientHudElem(self);
			if(isDefined(self.pstatshud_col2[i]))
			{
				self.pstatshud_col2[i].archived = false;
				self.pstatshud_col2[i].horzAlign = "subleft";
				self.pstatshud_col2[i].vertAlign = "subtop";
				self.pstatshud_col2[i].alignX = "left";
				self.pstatshud_col2[i].alignY = "top";
				self.pstatshud_col2[i].x = namex + level.ex_stbd_movex; //195;
				self.pstatshud_col2[i].y = 105 + i * 16;
				self.pstatshud_col2[i].sort = 103;
				self.pstatshud_col2[i].fontscale = 1.2;
				self.pstatshud_col2[i].color = (1,1,1);
			}
			else return(false);
		}
	}

	if(!isDefined(self.pstatshud_col3))
	{
		self.pstatshud_col3 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			if(!isDefined(self.pstatshud_col3[i])) self.pstatshud_col3[i] = newClientHudElem(self);
			if(isDefined(self.pstatshud_col3[i]))
			{
				self.pstatshud_col3[i].archived = false;
				self.pstatshud_col3[i].horzAlign = "subleft";
				self.pstatshud_col3[i].vertAlign = "subtop";
				self.pstatshud_col3[i].alignX = "left";
				self.pstatshud_col3[i].alignY = "top";
				self.pstatshud_col3[i].x = 375 + level.ex_stbd_movex;
				self.pstatshud_col3[i].y = 105 + i * 16;
				self.pstatshud_col3[i].sort = 103;
				self.pstatshud_col3[i].fontscale = 1.3;
				self.pstatshud_col3[i].color = (1,1,1);
			}
			else return(false);
		}
	}

	if(!isDefined(self.pstatshud_col4))
	{
		self.pstatshud_col4 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			if(!isDefined(self.pstatshud_col4[i])) self.pstatshud_col4[i] = newClientHudElem(self);
			if(isDefined(self.pstatshud_col4[i]))
			{
				self.pstatshud_col4[i].archived = false;
				self.pstatshud_col4[i].horzAlign = "subleft";
				self.pstatshud_col4[i].vertAlign = "subtop";
				self.pstatshud_col4[i].alignX = "left";
				self.pstatshud_col4[i].alignY = "top";
				self.pstatshud_col4[i].x = 415 + level.ex_stbd_movex;
				self.pstatshud_col4[i].y = 105 + i * 16;
				self.pstatshud_col4[i].sort = 103;
				self.pstatshud_col4[i].fontscale = 1.3;
				self.pstatshud_col4[i].color = (1,1,1);
			}
			else return(false);
		}
	}

	return(true);
}

fadeAllHUD(fadetime)
{
	// Fade all HUD elements
	thread fadeAllPlayerHUD(fadetime);
	thread fadeLevelHUD(fadetime);
	wait( [[level.ex_fpstime]](fadetime) );
}

fadeLevelHUD(fadetime)
{
	// Fade all level based HUD elements
	for(i = 0; i < level.statshud.size; i++)
	{
		if(isDefined(level.statshud[i]))
		{
			level.statshud[i] fadeOverTime(fadetime);
			level.statshud[i].alpha = 0;
		}
	}
}

fadeAllPlayerHUD(fadetime)
{
	// Fade all player based HUD elements for all players
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isPlayer(players[i])) players[i] thread fadePlayerHUD(fadetime);
}

fadePlayerHUD(fadetime)
{
	self endon("disconnect");
	level endon("stats_done");

	// Fade all player based HUD elements for single player (self)
	// We take the paranoid approach to check player existence

	if(isPlayer(self) && isDefined(self.pstatshud_head)) elements = self.pstatshud_head.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
	{
		if(isPlayer(self) && isDefined(self.pstatshud_head[i]))
		{
			self.pstatshud_head[i] fadeOverTime(fadetime);
			self.pstatshud_head[i].alpha = 0;
		}
	}

	if(isPlayer(self) && isDefined(self.pstatshud_col1)) elements = self.pstatshud_col1.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
	{
		if(isPlayer(self) && isDefined(self.pstatshud_col1[i]))
		{
			self.pstatshud_col1[i] fadeOverTime(fadetime);
			self.pstatshud_col1[i].alpha = 0;
		}
	}

	if(isPlayer(self) && isDefined(self.pstatshud_col2)) elements = self.pstatshud_col2.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
	{
		if(isPlayer(self) && isDefined(self.pstatshud_col2[i]))
		{
			self.pstatshud_col2[i] fadeOverTime(fadetime);
			self.pstatshud_col2[i].alpha = 0;
		}
	}

	if(isPlayer(self) && isDefined(self.pstatshud_col3)) elements = self.pstatshud_col3.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
	{
		if(isPlayer(self) && isDefined(self.pstatshud_col3[i]))
		{
			self.pstatshud_col3[i] fadeOverTime(fadetime);
			self.pstatshud_col3[i].alpha = 0;
		}
	}

	if(isPlayer(self) && isDefined(self.pstatshud_col4)) elements = self.pstatshud_col4.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
	{
		if(isPlayer(self) && isDefined(self.pstatshud_col4[i]))
		{
			self.pstatshud_col4[i] fadeOverTime(fadetime);
			self.pstatshud_col4[i].alpha = 0;
		}
	}
}

deleteAllHUD()
{
	// Destroy all player based HUD elements for all players
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isPlayer(players[i])) players[i] thread deletePlayerHUD();

	// Destroy all level HUD elements
	for(i = 0; i < level.statshud.size; i++)
		if(isDefined(level.statshud[i])) level.statshud[i] destroy();
}

deletePlayerHUD()
{
	self endon("disconnect");
	level endon("stats_done");

	// Destroy all player based HUD elements for a single player
	// We take the paranoid approach to check player existence

	if(isPlayer(self) && isDefined(self.pstatshud_head)) elements = self.pstatshud_head.size;
		else elements = 0;
	for(j = 0; j < elements; j++)
		if(isPlayer(self) && isDefined(self.pstatshud_head[j])) self.pstatshud_head[j] destroy();

	self.pstatshud_head = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col1)) elements = self.pstatshud_col1.size;
		else elements = 0;
	for(j = 0; j < elements; j++)
		if(isPlayer(self) && isDefined(self.pstatshud_col1[j])) self.pstatshud_col1[j] destroy();

	self.pstatshud_col1 = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col2)) elements = self.pstatshud_col2.size;
		else elements = 0;
	for(j = 0; j < elements; j++)
		if(isPlayer(self) && isDefined(self.pstatshud_col2[j])) self.pstatshud_col2[j] destroy();

	self.pstatshud_col2 = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col3)) elements = self.pstatshud_col3.size;
		else elements = 0;
	for(j = 0; j < elements; j++)
		if(isPlayer(self) && isDefined(self.pstatshud_col3[j])) self.pstatshud_col3[j] destroy();

	self.pstatshud_col3 = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col4)) elements = self.pstatshud_col4.size;
		else elements = 0;
	for(j = 0; j < elements; j++)
		if(isPlayer(self) && isDefined(self.pstatshud_col4[j])) self.pstatshud_col4[j] destroy();

	self.pstatshud_col4 = undefined;
}

getStatsIcon()
{
	self endon("disconnect");
	level endon("stats_done");

	statsicon = "objective_spectator";

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		if(level.ex_ranksystem && isDefined(self.pers["rank"]))
		{
			switch(self.pers["rank"])
			{
				case 0:
					statsicon = game["statusicon_rank0"];
					break;
				case 1:
					statsicon = game["statusicon_rank1"];
					break;
				case 2:
					statsicon = game["statusicon_rank2"];
					break;
				case 3:
					statsicon = game["statusicon_rank3"];
					break;
				case 4:
					statsicon = game["statusicon_rank4"];
					break;
				case 5:
					statsicon = game["statusicon_rank5"];
					break;
				case 6:
					statsicon = game["statusicon_rank6"];
					break;
				case 7:
					statsicon = game["statusicon_rank7"];
					break;
			}
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				switch(game["allies"])
				{
					case "american":
						statsicon = "objective_american";
						break;
					case "british":
						statsicon = "objective_british";
						break;
					default:
						statsicon = "objective_russian";
						break;
				}
			}
			else if(self.pers["team"] == "axis")
			{
				switch(game["axis"])
				{
					case "german":
						statsicon = "objective_german";
						break;
				}
			}
		}
	}

	return statsicon;
}

isActivatedCategory(category)
{
	// score, efficiency and bonus points belong to ex_stbd_se; others to ex_stbd_kd
	activated = false;
	if( (level.ex_stbd_kd && category < 25) || (level.ex_stbd_se && category >= 25) ) activated = true;

	return activated;
}

getCategoryStr(category)
{
	// Categories
	switch(category)
	{
		case  0: return "killsdeaths";
		case  1: return "grenades";
		case  2: return "tripwires";
		case  3: return "headshots";
		case  4: return "bashes";
		case  5: return "snipers";
		case  6: return "knives";
		case  7: return "mortars";
		case  8: return "artillery";
		case  9: return "airstrikes";
		case 10: return "napalm";
		case 11: return "panzers";
		case 12: return "spawn";
		case 13: return "landmines";
		case 14: return "firenades";
		case 15: return "gasnades";
		case 16: return "flamethrowers";
		case 17: return "satchelcharges";
		case 18: return "gunship";
		case 19: return "spam";
		case 20: return "team";
		case 21: return "plane";
		case 22: return "falling";
		case 23: return "minefield";
		case 24: return "suicide";
		case 25: return "flag";
		case 26: return "bonus";
		case 27: return "score";
		default: return "";
	}
}

getCategoryKillStr(category)
{
	// Kills
	switch(category)
	{
		case  0: return "kill";
		case  1: return "grenadekill";
		case  2: return "tripwirekill";
		case  3: return "headshotkill";
		case  4: return "bashkill";
		case  5: return "sniperkill";
		case  6: return "knifekill";
		case  7: return "mortarkill";
		case  8: return "artillerykill";
		case  9: return "airstrikekill";
		case 10: return "napalmkill";
		case 11: return "panzerkill";
		case 12: return "spawnkill";
		case 13: return "landminekill";
		case 14: return "firenadekill";
		case 15: return "gasnadekill";
		case 16: return "flamethrowerkill";
		case 17: return "satchelchargekill";
		case 18: return "gunshipkill";
		case 19: return "spamkill";
		case 20: return "teamkill";
		case 21: return "-";
		case 22: return "-";
		case 23: return "-";
		case 24: return "-";
		case 25: return "flagcap";
		case 26: return "-";
		case 27: return "score";
		default: return "";
	}
}

getCategoryDeathStr(category)
{
	// Deaths
	switch(category)
	{
		case  0: return "death";
		case  1: return "grenadedeath";
		case  2: return "tripwiredeath";
		case  3: return "headshotdeath";
		case  4: return "bashdeath";
		case  5: return "sniperdeath";
		case  6: return "knifedeath";
		case  7: return "mortardeath";
		case  8: return "artillerydeath";
		case  9: return "airstrikedeath";
		case 10: return "napalmdeath";
		case 11: return "panzerdeath";
		case 12: return "spawndeath";
		case 13: return "landminedeath";
		case 14: return "firenadedeath";
		case 15: return "gasnadedeath";
		case 16: return "flamethrowerdeath";
		case 17: return "satchelchargedeath";
		case 18: return "gunshipdeath";
		case 19: return "-";
		case 20: return "-";
		case 21: return "planedeath";
		case 22: return "fallingdeath";
		case 23: return "minefielddeath";
		case 24: return "suicide";
		case 25: return "flagret";
		case 26: return "bonus";
		case 27: return "efficiency";
		default: return "";
	}
}

getCategoryLocStr(category)
{
	// Localized strings for categories
	switch(category)
	{
		case  0: return &"STATSBOARD_KILLS_DEATHS";
		case  1: return &"STATSBOARD_GRENADES";
		case  2: return &"STATSBOARD_TRIPWIRES";
		case  3: return &"STATSBOARD_HEADSHOTS";
		case  4: return &"STATSBOARD_BASHES";
		case  5: return &"STATSBOARD_SNIPERS";
		case  6: return &"STATSBOARD_KNIVES";
		case  7: return &"STATSBOARD_MORTARS";
		case  8: return &"STATSBOARD_ARTILLERY";
		case  9: return &"STATSBOARD_AIRSTRIKES";
		case 10: return &"STATSBOARD_NAPALM";
		case 11: return &"STATSBOARD_PANZERS";
		case 12: return &"STATSBOARD_SPAWN";
		case 13: return &"STATSBOARD_LANDMINES";
		case 14: return &"STATSBOARD_FIRENADES";
		case 15: return &"STATSBOARD_GASNADES";
		case 16: return &"STATSBOARD_FLAMETHROWERS";
		case 17: return &"STATSBOARD_SATCHELCHARGES";
		case 18: return &"STATSBOARD_GUNSHIP";
		case 19: return &"STATSBOARD_SPAM_KILLS";
		case 20: return &"STATSBOARD_TEAM_KILLS";
		case 21: return &"STATSBOARD_PLANE_DEATHS";
		case 22: return &"STATSBOARD_FALLING_DEATHS";
		case 23: return &"STATSBOARD_MINEFIELD_DEATHS";
		case 24: return &"STATSBOARD_SUICIDE_DEATHS";
		case 25: return &"STATSBOARD_FLAGS";
		case 26: return &"STATSBOARD_BONUS";
		case 27: return &"STATSBOARD_SCORE_EFFICIENCY";
		default: return "";
	}
}

getCategoryHeader(category)
{
	// localized strings for column headers
	switch(category)
	{
		case 25: return &"STATSBOARD_HEADER_FL";
		case 26: return &"STATSBOARD_HEADER_BP";
		case 27: return &"STATSBOARD_HEADER_SE";
		default: return &"STATSBOARD_HEADER_KD";
	}
}
