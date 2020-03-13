init()
{
	// Either set it to true or false. DO NOT DISABLE!
	level.ex_maps_log = false;

	// ***** END-GAME VOTING *****
	level.ex_maps = [];

	// Catch-all map. KEEP THIS INDEX 0!
	level.ex_maps[0] = spawnstruct();
	level.ex_maps[0].mapname = "";
	level.ex_maps[0].longname = "Non-localized map name";
	level.ex_maps[0].loclname = &"Non-localized map name";
	level.ex_maps[0].gametype = "dm tdm";

	// Add stock and custom maps
	scriptdata\_ex_votemaps::init();

	// Sort the array using QuickSort
	//dumpArray();
	quickSort(1, level.ex_maps.size - 1);
	//dumpArray();

	// ***** END-GAME VOTING THUMBNAILS *****
	if(level.ex_mapvote && level.ex_mapvote_thumbnails)
	{
		thumbnail = "s000";
		level.ex_maps[0].thumbnail = thumbnail;
		[[level.ex_PrecacheShader]](thumbnail);
		for(i = 1; i < level.ex_maps.size; i++)
		{
			lcmapname = tolower(level.ex_maps[i].mapname);
			thumbnail = scriptdata\_ex_votethumb::getThumbnail(lcmapname);
			level.ex_maps[i].thumbnail = thumbnail;
			if(thumbnail != "s000") [[level.ex_PrecacheShader]](thumbnail);
		}

		if(level.ex_maps.size > 60)
		{
			level.ex_statshud = 0;
			level.ex_compass_changer = 0;
			level.ex_arcade_shaders = 0;
		}
	}

	// ***** IN-GAME VOTING *****
	if(level.ex_mbot) return;

	level.ex_votecvars = [];
	level.ex_gtcvars = [];
	level.ex_mapcvars = [];

	index = level.ex_votecvars.size;
	level.ex_votecvars[index] = spawnstruct();
	level.ex_votecvars[index].cvar = "ui_ingame_vote_allow_old";
	level.ex_votecvars[index].status = [[level.ex_drm]]("ex_ingame_vote_allow_old", 0, 0, 1, "int");

	index = level.ex_votecvars.size;
	level.ex_votecvars[index] = spawnstruct();
	level.ex_votecvars[index].cvar = "ui_ingame_vote_allow_gametype";
	level.ex_votecvars[index].status = [[level.ex_drm]]("ex_ingame_vote_allow_gametype", 1, 0, 1, "int");
	level.ex_ingame_vote_allow_gametype = level.ex_votecvars[index].status;

	index = level.ex_votecvars.size;
	level.ex_votecvars[index] = spawnstruct();
	level.ex_votecvars[index].cvar = "ui_ingame_vote_allow_map";
	level.ex_votecvars[index].status = [[level.ex_drm]]("ex_ingame_vote_allow_map", 1, 0, 1, "int");
	level.ex_ingame_vote_allow_map = level.ex_votecvars[index].status;

	if(level.ex_ingame_vote_allow_gametype)
	{
		gt_str = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lib lms lts ons rbcnq rbctf sd tdm tkoth vip";
		gt_array = strtok(gt_str, " ");

		for(i = 0; i < gt_array.size; i++)
		{
			gt = gt_array[i];

			index = level.ex_gtcvars.size;
			level.ex_gtcvars[index] = spawnstruct();
			level.ex_gtcvars[index].cvar = "ui_ingame_vote_allow_" + gt;
			level.ex_gtcvars[index].status = [[level.ex_drm]]("ex_ingame_vote_allow_" + gt, 1, 0, 1, "int");
		}
	}

	if(level.ex_rcon || level.ex_ingame_vote_allow_map)
	{
		number = level.ex_maps.size - 1;
		if(number > 160) number = 160; // 2*80

		for(i = 1; i <= number; i++)
		{
			index = level.ex_mapcvars.size;
			level.ex_mapcvars[index] = spawnstruct();
			level.ex_mapcvars[index].cvar = "ui_ingame_vote_map_name_" + i;
			level.ex_mapcvars[index].status = level.ex_maps[i].longname;

			index = level.ex_mapcvars.size;
			level.ex_mapcvars[index] = spawnstruct();
			level.ex_mapcvars[index].cvar = "ui_ingame_vote_map_cmd_" + i;
			level.ex_mapcvars[index].status = "callvote map " + level.ex_maps[i].mapname;
		}

		index = level.ex_mapcvars.size;
		level.ex_mapcvars[index] = spawnstruct();
		level.ex_mapcvars[index].cvar = "ui_ingame_vote_map_2pages";
		level.ex_mapcvars[index].status = (number > 80);
	}

	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
}

onJoinedTeam()
{
	self thread SetInGameVoteDvars();
}

onJoinedSpectators()
{
	self thread SetInGameVoteDvars();
}

quickSort(lo0, hi0)
{
	temp = spawnstruct();
	pivot = spawnstruct();

	lo = lo0;
	hi = hi0;
	if( lo >= hi ) return;
	if( lo == hi - 1 )
	{
		if( strCompare( level.ex_maps[lo], level.ex_maps[hi] ) == 2 )
		{
			temp = level.ex_maps[lo];
			level.ex_maps[lo] = level.ex_maps[hi];
			level.ex_maps[hi] = temp;
		}
		return;
	}

	ipivot = int( (lo + hi) / 2 );
	pivot = level.ex_maps[ipivot];
	level.ex_maps[ipivot] = level.ex_maps[hi];
	level.ex_maps[hi] = pivot;

	while( lo < hi )
	{
		while( (strCompare(level.ex_maps[lo], pivot) <= 1) && (lo < hi) ) lo++;
		while( (strCompare(pivot, level.ex_maps[hi]) <= 1) && (lo < hi) ) hi--;

		if( lo < hi )
		{
			temp = level.ex_maps[lo];
			level.ex_maps[lo] = level.ex_maps[hi];
			level.ex_maps[hi] = temp;
		}
	}

	level.ex_maps[hi0] = level.ex_maps[hi];
	level.ex_maps[hi] = pivot;

	quickSort( lo0, lo - 1 );
	quickSort( hi + 1, hi0 );

	pivot = undefined;
	temp = undefined;
}

strCompare(str1, str2)
{
	// return values
	// 0 : string1 and string 2 are the same
	// 1 : string1 < string2
	// 2 : string1 > string2

	ascii = " !#$%&'()*+,-.0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[]^_`{}~";

	monostr1 = tolower( extreme\_ex_utils::monotone(str1.longname) );
	monostr2 = tolower( extreme\_ex_utils::monotone(str2.longname) );

	if(monostr1.size <= monostr2.size)
	{
		mode = 1;
		str1 = monostr1;
		str2 = monostr2;
	}
	else
	{
		mode = 2;
		str1 = monostr2;
		str2 = monostr1;
	}

	size1 = str1.size;
	size2 = str2.size;

	for(i = 0; i < size1; i++)
	{
		chr1 = str1[i];
		pos1 = -1;
		for(j = 0; j < ascii.size; j++)
		{
			if(chr1 == ascii[j])
			{
				pos1 = j;
				break;
			}
		}

		chr2 = str2[i];
		pos2 = -1;
		for(j = 0; j < ascii.size; j++)
		{
			if(chr2 == ascii[j])
			{
				pos2 = j;
				break;
			}
		}

		if(mode == 1)
		{
			if(pos1 < pos2) return 1;
			if(pos1 > pos2) return 2;
		}
		else
		{
			if(pos1 < pos2) return 2;
			if(pos1 > pos2) return 1;
		}
	}

	if(size1 == size2) return 0;
	if(mode == 1) return 1;
		else return 2;
}

dumpArray()
{
	for(i = 1; i < level.ex_maps.size; i++)
		logprint("map " + i + ": " + extreme\_ex_utils::monotone(level.ex_maps[i].longname) + " (" + level.ex_maps[i].mapname + ")\n");
}

SetInGameVoteDvars()
{
	self endon("disconnect");

	// if already sent, don't send again
	if(isDefined(self.pers["ingame_vote_sent"])) return;
	self.pers["ingame_vote_sent"] = true;

	// figure out if this player has access rights to rcon map control
	rcon_allowed = false;
	if(level.ex_rcon && isDefined(self.ex_rcon) && isDefined(self.ex_rcon_access) && (self.ex_rcon_access &  1) ==  1) rcon_allowed = true;

	for(i = 0; i < level.ex_votecvars.size; i++)
	{
		self setClientCvar(level.ex_votecvars[i].cvar, level.ex_votecvars[i].status);
		if(i % 3 == 0) wait( [[level.ex_fpstime]](1) );
	}

	// send game type vars if extreme callvote for game types is enabled, but only
	// if g_allowvote was enabled when map started
	if(level.ex_allowvote && level.ex_ingame_vote_allow_gametype)
	{
		for(i = 0; i < level.ex_gtcvars.size; i++)
		{
			self setClientCvar(level.ex_gtcvars[i].cvar, level.ex_gtcvars[i].status);
			if(i % 3 == 0) wait( [[level.ex_fpstime]](1) );
		}
	}

	// send map vars if this is a player with access rights to rcon map control *OR*
	// when extreme callvote for maps is enabled, but only if g_allowvote was enabled
	// when map started
	if(rcon_allowed || (level.ex_allowvote && level.ex_ingame_vote_allow_map))
	{
		for(i = 0; i < level.ex_mapcvars.size; i++)
		{
			self setClientCvar(level.ex_mapcvars[i].cvar, level.ex_mapcvars[i].status);
			if(i % 3 == 0) wait( [[level.ex_fpstime]](1) );
		}
	}
}

main()
{
	if(PrepareMapVote())
	{
		if(level.ex_mvmusic)
		{
			mv_music = randomInt(10);
			musicplay("gom_music_" + mv_music);
		}
		RunMapVote();
	}
}

PrepareMapVote()
{
	game["menu_team"] = "";

	// Prepare players for vote
	votingplayers = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		resetTimeout();

		players[i] setClientCvar("g_scriptMainMenu", "");
		players[i] closeMenu();
		players[i] extreme\_ex_spawn::spawnSpectator();
		players[i] allowSpectateTeam("allies", false);
		players[i] allowSpectateTeam("axis", false);
		players[i] allowSpectateTeam("freelook", false);
		players[i] allowSpectateTeam("none", true);

		players[i].mv_allowvote = true;

		// No voting for spectators
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator")
			if(!isDefined(players[i].ex_name) || !isDefined(players[i].ex_clid))
				players[i].mv_allowvote = false;

		// No voting for testclients (bots)
		if(isDefined(players[i].pers["isbot"]) && players[i].pers["isbot"])
			players[i].mv_allowvote = false;

		// No voting for non-clan players if clan voting enabled, unless it should be ignored
		if(level.ex_clanvoting && !level.ex_mapvoteignclan)
			if(!isDefined(players[i].ex_name) || !isDefined(players[i].ex_clid) || !level.ex_clvote[players[i].ex_clid])
				players[i].mv_allowvote = false;

		// No voting for this player
		//if(players[i].name == "PatmanSan")
		//	players[i].mv_allowvote = false;

		if(players[i].mv_allowvote) votingplayers++;
	}

	// Any players?
	if(votingplayers == 0) return false;

	// Use map rotation (mode 0 - 3) or map list (mode 4 - 7)?
	if(level.ex_mapvotemode < 4)
	{
		// Rotation: get the map rotation queue
		switch(level.ex_mapvotemode)
		{
			case 1: { mv_maprot = extreme\_ex_maprotation::GetRandomMapRotation(); break; }
			case 2: { mv_maprot = extreme\_ex_maprotation::GetPlayerBasedMapRotation(); break; }
			case 3: { mv_maprot = extreme\_ex_maprotation::GetRandomPlayerBasedMapRotation(); break; }
			default: { mv_maprot = extreme\_ex_maprotation::GetPlainMapRotation(); break; }
		}

		// Any maps to begin with?
		if(!isDefined(mv_maprot) || !mv_maprot.size) return false;

		// Prepare final array
		if(level.ex_mapvotemax > mv_maprot.size)
		{
			mv_mapvotemax = mv_maprot.size;
			if(level.ex_mapvotereplay) mv_mapvotemax++;
		}
		else mv_mapvotemax = level.ex_mapvotemax;

		// If map vote memory enabled, load the memory and add the map we just played
		if(level.ex_mapvote_memory) mapvoteMemory(level.ex_currentmap, mv_mapvotemax);

		level.mv_items = [];
		lastgametype = level.ex_currentgt;

		// Do we need the first slot for current map (replay)?
		if(level.ex_mapvotereplay == 2)
		{
			level.mv_items[0]["map"] = level.ex_currentmap;
			level.mv_items[0]["mapname"] = &"MAPVOTE_REPLAY";
			level.mv_items[0]["gametype"] = level.ex_currentgt;
			level.mv_items[0]["gametypename"] = extreme\_ex_maps::getgtstringshort(level.ex_currentgt);
			level.mv_items[0]["votes"] = 0;
		}

		i = level.mv_items.size;

		// Get candidates
		for(j = 0; j < mv_maprot.size; j++)
		{
			// Make sure we know the game type
			if(!isDefined(mv_maprot[j]["gametype"])) mv_maprot[j]["gametype"] = lastgametype;
				else lastgametype = mv_maprot[j]["gametype"];

			// Skip current map and gametype combination
			if(mv_maprot[j]["map"] == level.ex_currentmap && mv_maprot[j]["gametype"] == level.ex_currentgt)
			{
				if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maprot[j]["map"] + ". Map has just been played.\n");
				continue;
			}

			// If map vote memory enabled, skip map if it is in memory
			if(level.ex_mapvote_memory && mapvoteInMemory(mv_maprot[j]["map"]))
			{
				if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maprot[j]["map"] + ". Map has been played recently (memory).\n");
				continue;
			}

			// Fill the candidate entry
			level.mv_items[i]["map"] = mv_maprot[j]["map"];
			level.mv_items[i]["mapname"] = extreme\_ex_maps::getmapstring(mv_maprot[j]["map"]);
			level.mv_items[i]["gametype"] = mv_maprot[j]["gametype"];
			level.mv_items[i]["gametypename"] = extreme\_ex_maps::getgtstringshort(mv_maprot[j]["gametype"]);
			level.mv_items[i]["exec"] = mv_maprot[j]["exec"];
			level.mv_items[i]["votes"] = 0;

			i++;
			if(i == mv_mapvotemax) break;
		}

		// Do we need the last slot for current map (replay)?
		if(level.ex_mapvotereplay == 1)
		{
			if(level.mv_items.size)
			{
				if(level.mv_items.size == level.ex_mapvotemax) replayentry = level.mv_items.size - 1;
					else replayentry = level.mv_items.size;
			}
			else replayentry = 0;

			level.mv_items[replayentry]["map"] = level.ex_currentmap;
			level.mv_items[replayentry]["mapname"] = &"MAPVOTE_REPLAY";
			level.mv_items[replayentry]["gametype"] = level.ex_currentgt;
			level.mv_items[replayentry]["gametypename"] = extreme\_ex_maps::getgtstringshort(level.ex_currentgt);
			level.mv_items[replayentry]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;
	}
	else
	{
		// Map List: copy maps from list
		mv_maplist = [];
		mv_reverse = 0;

		if(level.ex_mapvotemode == 6)
		{
			mv_reverse = getCvar("ex_mapvotereverse");
			if(mv_reverse != "")
			{
				mv_reverse = getCvarInt("ex_mapvotereverse");
				mv_reverse = !mv_reverse;
			}
			else mv_reverse = 0;
			setCvar("ex_mapvotereverse", mv_reverse);
		}

		if(!mv_reverse) // top-down
		{
			i = 0;
			for(j = 1; j < level.ex_maps.size; j++)
			{
				if(!isDefined(level.ex_maps[j].playsize)) level.ex_maps[j].playsize = "all";

				mv_maplist[i]["map"] = level.ex_maps[j].mapname;
				mv_maplist[i]["mapname"] = level.ex_maps[j].loclname;
				mv_maplist[i]["gametype"] = tolower(level.ex_maps[j].gametype);
				mv_maplist[i]["thumbnail"] = level.ex_maps[j].thumbnail;
				mv_maplist[i]["playsize"] = 0;
				if(level.ex_maps[j].playsize == "large") mv_maplist[i]["playsize"] = level.ex_mapsizing_large;
					else if(level.ex_maps[j].playsize == "medium") mv_maplist[i]["playsize"] = level.ex_mapsizing_medium;
				i++;
			}
		}
		else
		{
			i = 0;
			for(j = level.ex_maps.size - 1; j > 0; j--) // bottom-up (reverse list)
			{
				if(!isDefined(level.ex_maps[j].playsize)) level.ex_maps[j].playsize = "all";

				mv_maplist[i]["map"] = level.ex_maps[j].mapname;
				mv_maplist[i]["mapname"] = level.ex_maps[j].loclname;
				mv_maplist[i]["gametype"] = tolower(level.ex_maps[j].gametype);
				mv_maplist[i]["thumbnail"] = level.ex_maps[j].thumbnail;
				mv_maplist[i]["playsize"] = 0;
				if(level.ex_maps[j].playsize == "large") mv_maplist[i]["playsize"] = level.ex_mapsizing_large;
					else if(level.ex_maps[j].playsize == "medium") mv_maplist[i]["playsize"] = level.ex_mapsizing_medium;
				i++;
			}
		}

		// Any maps to begin with?
		if(!isDefined(mv_maplist)) return false;

		// Randomize list if requested (mode 5 and 7)
		if(level.ex_mapvotemode == 5 || level.ex_mapvotemode == 7)
		{
			for(i = 0; i < 20; i++)
			{
				for(j = 0; j < mv_maplist.size; j++)
				{
					r = randomInt(mv_maplist.size);
					element = mv_maplist[j];
					mv_maplist[j] = mv_maplist[r];
					mv_maplist[r] = element;
				}
			}
		}

		// Prepare final array
		if(level.ex_mapvotemax > mv_maplist.size)
		{
			mv_mapvotemax = mv_maplist.size;
			if(level.ex_mapvotereplay) mv_mapvotemax++;
		}
		else mv_mapvotemax = level.ex_mapvotemax;

		// If map vote memory enabled, load the memory and add the map we just played
		if(level.ex_mapvote_memory) mapvoteMemory(level.ex_currentmap, mv_mapvotemax);

		// Get the number of players for player based map filter
		players = level.players;
		mv_numplayers = players.size;
		if(level.ex_maps_log) logprint("MAPVOTE DEBUG: number of players for mapvote = " + mv_numplayers + "\n");
		mv_skipmemcheck = false;
		mv_currentmapix = 0;

		for(run = 1; run <= 3; run++)
		{
			if(level.ex_maps_log) logprint("MAPVOTE DEBUG: map selection run " + run + "\n");
			level.mv_items = [];

			// Do we need the first slot for current map (replay)?
			if(level.ex_mapvotereplay == 2)
			{
				level.mv_items[0]["map"] = level.ex_currentmap;
				level.mv_items[0]["mapname"] = &"MAPVOTE_REPLAY";
				level.mv_items[0]["gametype"] = level.ex_currentgt;
				level.mv_items[0]["gametypename"] = "";
				level.mv_items[0]["thumbnail"] = level.ex_maps[0].thumbnail;
				level.mv_items[0]["votes"] = 0;
			}

			i = level.mv_items.size;

			// Get candidates
			for(j = 0; j < mv_maplist.size; j++)
			{
				// Skip current map
				if(mv_maplist[j]["map"] == level.ex_currentmap)
				{
					if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maplist[j]["map"] + ". Map has just been played.\n");
					mv_currentmapix = j;
					if(level.ex_mapvotereplay == 2) level.mv_items[0]["thumbnail"] = mv_maplist[j]["thumbnail"];
					continue;
				}

				// If map vote memory enabled, skip map if it is in memory
				if(!mv_skipmemcheck && level.ex_mapvote_memory && mapvoteInMemory(mv_maplist[j]["map"]))
				{
					if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maplist[j]["map"] + ". Map has been played recently (memory).\n");
					continue;
				}

				// If map filter enabled, only allow map if minimum number of players available
				if(level.ex_mapvote_filter)
				{
					if(level.ex_mapvote_filter == 2)
					{
						if(mv_maplist[j]["playsize"] == level.ex_mapsizing_large) // Large map
						{
							if(mv_numplayers < mv_maplist[j]["playsize"])
							{
								if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting large map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires " + mv_maplist[j]["playsize"] + " players.\n");
								continue;
							}
						}
						else if(mv_maplist[j]["playsize"] == level.ex_mapsizing_medium) // Medium map
						{
							if((mv_numplayers < mv_maplist[j]["playsize"]) || (mv_numplayers >= level.ex_mapsizing_large))
							{
								if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting medium map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires " + mv_maplist[j]["playsize"] + " players.\n");
								continue;
							}
						}
						else if((mv_maplist[j]["playsize"] != 0) && (mv_numplayers >= level.ex_mapsizing_medium)) // Small map
						{
							if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting small map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires " + mv_maplist[j]["playsize"] + " players.\n");
							continue;
						}
					}
					else if(mv_numplayers < mv_maplist[j]["playsize"])
					{
						if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires " + mv_maplist[j]["playsize"] + " players.\n");
						continue;
					}
				}

				// Make sure we have a game type to vote for
				if(mv_maplist[j]["gametype"] == "") mv_maplist[j]["gametype"] = "dm tdm";

				level.mv_items[i]["map"] = mv_maplist[j]["map"];
				level.mv_items[i]["mapname"] = mv_maplist[j]["mapname"];
				level.mv_items[i]["gametype"] = mv_maplist[j]["gametype"];
				level.mv_items[i]["gametypename"] = "";
				level.mv_items[i]["thumbnail"] = mv_maplist[j]["thumbnail"];
				level.mv_items[i]["votes"] = 0;

				i++;
				if(i == mv_mapvotemax) break;
			}

			// If we have at least two maps we don't need another run
			if(level.mv_items.size > 1) break;

			// No maps after run: (1) size from small to medium, (2) size from medium to large, (3) skip memory check
			if(mv_numplayers < level.ex_mapsizing_medium) mv_numplayers = level.ex_mapsizing_medium;
				else if(mv_numplayers < level.ex_mapsizing_large) mv_numplayers = level.ex_mapsizing_large;
					else mv_skipmemcheck = true;
		}

		// Do we need the last slot for current map (replay)?
		if(level.ex_mapvotereplay == 1)
		{
			if(level.mv_items.size)
			{
				if(level.mv_items.size == level.ex_mapvotemax) replayentry = level.mv_items.size - 1;
					else replayentry = level.mv_items.size;
			}
			else replayentry = 0;

			level.mv_items[replayentry]["map"] = level.ex_currentmap;
			level.mv_items[replayentry]["mapname"] = &"MAPVOTE_REPLAY";
			level.mv_items[replayentry]["gametype"] = level.ex_currentgt;
			level.mv_items[replayentry]["gametypename"] = "";
			level.mv_items[replayentry]["thumbnail"] = mv_maplist[mv_currentmapix]["thumbnail"];
			level.mv_items[replayentry]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;
	}

	// Any maps left?
	if(level.mv_itemsmax == 0) return false;
	return true;
}

RunMapVote()
{
	level.mv_perpage = 5; // default: 5. max: 5
	level.mv_width = 200; // default: 200. max: 600
	level.mv_originx1 = int((600 - level.mv_width) / 2) + level.ex_mapvote_movex;
	level.mv_originx2 = level.mv_originx1 + level.mv_width; // int( 320 + (level.mv_width / 2));
	level.mv_originxc = int(level.mv_originx1 + (level.mv_width / 2));
	level.mv_heightadj = 0;

	if(level.ex_mapvote_thumbnails)
	{
		level.mv_perpage = 9;
		level.mv_heightadj = 105;
	}

	if(level.ex_mapvotemode < 4) thread VoteLogicRotation();
		else thread VoteLogicList();

	level waittill("VotingComplete");
}

VoteLogicRotation()
{
	// Big brother is watching votes (rotation based)

	// Make sure the vote window has the enough lines for the weapon modes, if
	// weapon mode selection is enabled
	ItemsOnPage = maxItemsOnPage(1);
	if(level.ex_mapvoteweaponmode && level.weaponmodenames.size > ItemsOnPage)
	{
		if(level.weaponmodenames.size > level.mv_perpage) ItemsOnPage = level.mv_perpage;
			else ItemsOnPage = level.weaponmodenames.size;
	}
	// Make sure the vote window is at least 5 lines high for the message
	// for players not allowed to vote to display correctly
	if(ItemsOnPage < 5) ItemsOnPage = 5;
	CreateHud(ItemsOnPage);

	// Start voting threads for players
	level.mv_stage = 1;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i].mv_allowvote) && players[i].mv_allowvote) players[i] thread PlayerVote();
			else players[i] thread PlayerNoVote();
	}

	mv_musicstop = undefined;

	for(; level.ex_mapvotetime >= 0; level.ex_mapvotetime--)
	{
		for(t = 0; t < 10; t++)
		{
			// Reset votes
			for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

			// Get current players
			players = level.players;

			// Spawn no-vote thread for new players (joined during vote)
			for(i = 0; i < players.size; i++)
			{
				if(isPlayer(players[i]) && !isDefined(players[i].mv_allowvote))
				{
					players[i].mv_allowvote = false;
					players[i] thread PlayerNoVote();
				}
			}

			// Recount votes
			for(i = 0; i < players.size; i++)
				if(players[i].mv_allowvote && players[i].mv_choice != 0)
					level.mv_items[players[i].mv_choice - 1]["votes"]++;

			// Update votes on player's HUD, depending on page displayed (scary stuff)
			for(i = 0; i < players.size; i++)
			{
				if(players[i].mv_allowvote)
				{
					if(players[i].mv_flipchoice != 0) isonpage = onPage(players[i].mv_flipchoice);
						else isonpage = onPage(players[i].mv_choice);
					for(j = 0; j < maxItemsOnPage(isonpage); j++)
						players[i].mv_votes[j] setValue(level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
				}
			}

			if(level.ex_mvmusic && !isDefined(mv_musicstop) && !level.ex_mapvoteweaponmode && level.ex_mapvotetime <= 5)
			{
				musicstop(level.ex_mapvotetime);
				mv_musicstop = true;
			}

			wait( [[level.ex_fpstime]](0.1) );
		}
		// Update time left HUD
		level.mv_timeleft setValue(level.ex_mapvotetime);
	}

	// Signal voting threads to end, and wait for threads to die
	level notify("VotingStageDone");
	wait( [[level.ex_fpstime]](0.2) );

	// Count the votes
	mv_newitemnum = 0;
	mv_topvotes = 0;
	for(i = 0; i < level.mv_itemsmax; i++)
	{
		if(level.mv_items[i]["votes"] > mv_topvotes)
		{
			mv_newitemnum = i;
			mv_topvotes = level.mv_items[i]["votes"];
		}
	}

	// Select the winning map and game type
	map = level.mv_items[mv_newitemnum]["map"];
	mapname = level.mv_items[mv_newitemnum]["mapname"];
	gametype = level.mv_items[mv_newitemnum]["gametype"];
	gametypename = extreme\_ex_maps::getgtstringshort(gametype); // only short strings are precached!
	exec = level.mv_items[mv_newitemnum]["exec"];

	if(level.ex_mapvoteweaponmode)
	{
		// Fade HUD elements
		FadePlayerHUDStage();

		// Destroy the HUD elements which will be recreated for stage 2
		DeletePlayerHudStage();

		level.mv_items = [];
		for(j = 0; j < level.weaponmodenames.size; j++)
		{
			wm_index = level.mv_items.size;
			level.mv_items[wm_index]["weaponmode"] = level.weaponmodenames[j];
			level.mv_items[wm_index]["weaponmodename"] = level.weaponmodes[level.weaponmodenames[j]].loc;
			level.mv_items[wm_index]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;

		// Do we have enough weapon modes to vote for?
		if(level.mv_itemsmax > 1)
		{
			// Change title to show map voted for
			level.mv_title.label = mapname;
			level.mv_title setText(gametypename);

			level.mv_stage = 3;
			players = level.players;
			for(i = 0; i < players.size; i++)
				if(isDefined(players[i].mv_allowvote) && players[i].mv_allowvote) players[i] thread PlayerVote();
					else if(!isDefined(players[i].mv_allowvote)) players[i] thread PlayerNoVote();

			// Weapon mode voting in progress
			for(; level.ex_mapvotetimewm >= 0; level.ex_mapvotetimewm--)
			{
				for(t = 0; t < 10; t++)
				{
					// Reset votes
					for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

					// Get current players
					players = level.players;

					// Spawn no-vote thread for new players (joined during vote)
					for(i = 0; i < players.size; i++)
					{
						if(isPlayer(players[i]) && !isDefined(players[i].mv_allowvote))
						{
							players[i].mv_allowvote = false;
							players[i] thread PlayerNoVote();
						}
					}

					// Recount votes
					for(i = 0; i < players.size; i++)
						if(players[i].mv_allowvote && players[i].mv_choice != 0)
							level.mv_items[players[i].mv_choice - 1]["votes"]++;

					// Update votes on player's HUD, depending on page displayed (scary stuff)
					for(i = 0; i < players.size; i++)
					{
						if(players[i].mv_allowvote)
						{
							if(players[i].mv_flipchoice != 0) isonpage = onPage(players[i].mv_flipchoice);
								else isonpage = onPage(players[i].mv_choice);
							for(j = 0; j < maxItemsOnPage(isonpage); j++)
								players[i].mv_votes[j] setValue(level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
						}
					}

					if(level.ex_mvmusic && !isDefined(mv_musicstop) && level.ex_mapvotetimewm <= 10)
					{
						musicstop(level.ex_mapvotetimewm);
						mv_musicstop = true;
					}

					wait( [[level.ex_fpstime]](0.1) );
				}
				// Update time left HUD
				level.mv_timeleft setValue(level.ex_mapvotetimewm);
			}

			// Signal voting threads to end, and wait for threads to die
			level notify("VotingStageDone");
			wait( [[level.ex_fpstime]](0.2) );
		}
		else if(level.ex_mvmusic) musicstop(5);

		// Count the votes
		mv_newitemnum = 0;
		mv_topvotes = 0;
		for(i = 0; i < level.mv_itemsmax; i++)
		{
			if(level.mv_items[i]["votes"] > mv_topvotes)
			{
				mv_newitemnum = i;
				mv_topvotes = level.mv_items[i]["votes"];
			}
		}

		// Select the winning weapon mode
		weaponmode = level.mv_items[mv_newitemnum]["weaponmode"];
		weaponmodename = level.mv_items[mv_newitemnum]["weaponmodename"];

		// Write to cvar
		setCvar("ex_weaponmode", level.weaponmodes[weaponmode].id);
	}
	else weaponmodename = undefined;

	// Signal voting threads to end, and wait for threads to die
	level notify("VotingDone");
	wait( [[level.ex_fpstime]](0.2) );

	// Fade HUD elements
	FadeHud();

	// Destroy all HUD elements
	DeleteHud();

	// Write to cvars
	if(!isDefined(exec)) exec = "";
		else exec = "exec " + exec;
	setCvar("sv_maprotationcurrent", exec + " gametype " + gametype + " map " + map);

	// Announce winner
	WinnerIs(mapname, gametypename, weaponmodename);

	// Signal the end of map vote
	level notify("VotingComplete");
}

VoteLogicList()
{
	// Big brother is watching votes (list based)

	// Make sure the vote window has the max number of lines, because in list mode
	// we do not know how many lines we need for game type selection
	CreateHud(level.mv_perpage);

	mv_musicstop = undefined;

	if(level.ex_mapvotemode != 7)
	{
		// Start voting threads for players
		level.mv_stage = 1;
		players = level.players;
		for(i = 0; i < players.size; i++)
			if(isDefined(players[i].mv_allowvote) && players[i].mv_allowvote) players[i] thread PlayerVote();
				else players[i] thread PlayerNoVote();

		for(; level.ex_mapvotetime >= 0; level.ex_mapvotetime--)
		{
			for(t = 0; t < 10; t++)
			{
				// Reset votes
				for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

				// Get current players
				players = level.players;

				// Spawn no-vote thread for new players (joined during vote)
				for(i = 0; i < players.size; i++)
				{
					if(isPlayer(players[i]) && !isDefined(players[i].mv_allowvote))
					{
						players[i].mv_allowvote = false;
						players[i] thread PlayerNoVote();
					}
				}

				// Recount votes
				for(i = 0; i < players.size; i++)
					if(players[i].mv_allowvote && players[i].mv_choice != 0)
						level.mv_items[players[i].mv_choice - 1]["votes"]++;

				// Update votes on player's HUD, depending on page displayed (scary stuff)
				for(i = 0; i < players.size; i++)
				{
					if(players[i].mv_allowvote)
					{
						if(players[i].mv_flipchoice != 0) isonpage = onPage(players[i].mv_flipchoice);
							else isonpage = onPage(players[i].mv_choice);
						for(j = 0; j < maxItemsOnPage(isonpage); j++)
							players[i].mv_votes[j] setValue(level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
					}
				}

				wait( [[level.ex_fpstime]](0.1) );
			}
			// Update time left HUD
			level.mv_timeleft setValue(level.ex_mapvotetime);
		}

		// Signal voting threads to end, and wait for threads to die
		level notify("VotingStageDone");
		wait( [[level.ex_fpstime]](0.2) );

		// Fade HUD elements
		FadePlayerHUDStage();

		// Destroy the HUD elements which will be recreated for stage 2
		DeletePlayerHudStage();
	}

	// Count the votes
	mv_newitemnum = 0;
	mv_topvotes = 0;
	for(i = 0; i < level.mv_itemsmax; i++)
	{
		if(level.mv_items[i]["votes"] > mv_topvotes)
		{
			mv_newitemnum = i;
			mv_topvotes = level.mv_items[i]["votes"];
		}
	}

	// Select the winning map
	map = level.mv_items[mv_newitemnum]["map"];
	mapname = level.mv_items[mv_newitemnum]["mapname"];
	if(level.ex_mapvote_thumbnails) showWinningMapThumbnail(mv_newitemnum);

	// Prepare for game type voting
	gt_array = strtok(level.mv_items[mv_newitemnum]["gametype"], " ");
	if(!isDefined(gt_array) || gt_array.size == 0) gt_array[0] = "tdm";

	level.mv_items = undefined;
	gt_index = 0;
	for(j = 0; j < gt_array.size; j++)
	{
		gt_allowed = [[level.ex_drm]]("ex_endgame_vote_allow_" + gt_array[j], 1, 0, 1, "int");

		if(gt_allowed)
		{
			level.mv_items[gt_index]["gametype"] = gt_array[j];
			level.mv_items[gt_index]["gametypename"] = extreme\_ex_maps::getgtstring(gt_array[j]);
			level.mv_items[gt_index]["votes"] = 0;
			gt_index++;
		}
		else if(level.ex_maps_log) logprint("MAPVOTE: Ignoring game type " + gt_array[j] + ". Disabled in mapcontrol.cfg (see ex_endgame_vote_allow_" + gt_array[j] + ").\n");
	}

	// Safety net in case none of the game types were allowed
	if(!isDefined(level.mv_items))
	{
		level.mv_items[gt_index]["gametype"] = "tdm";
		level.mv_items[gt_index]["gametypename"] = extreme\_ex_maps::getgtstring("tdm");
		level.mv_items[gt_index]["votes"] = 0;
	}

	level.mv_itemsmax = level.mv_items.size;

	// Do we have enough game types to vote for?
	if(level.mv_itemsmax > 1)
	{
		// Change title to show map voted for
		level.mv_title.label = mapname;

		level.mv_stage = 2;
		players = level.players;
		for(i = 0; i < players.size; i++)
			if(isDefined(players[i].mv_allowvote) && players[i].mv_allowvote) players[i] thread PlayerVote();
				else if(!isDefined(players[i].mv_allowvote)) players[i] thread PlayerNoVote();

		// Game type voting in progress
		for(; level.ex_mapvotetimegt >= 0; level.ex_mapvotetimegt--)
		{
			for(t = 0; t < 10; t++)
			{
				// Reset votes
				for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

				// Get current players
				players = level.players;

				// Spawn no-vote thread for new players (joined during vote)
				for(i = 0; i < players.size; i++)
				{
					if(isPlayer(players[i]) && !isDefined(players[i].mv_allowvote))
					{
						players[i].mv_allowvote = false;
						players[i] thread PlayerNoVote();
					}
				}

				// Recount votes
				for(i = 0; i < players.size; i++)
					if(players[i].mv_allowvote && players[i].mv_choice != 0)
						level.mv_items[players[i].mv_choice - 1]["votes"]++;

				// Update votes on player's HUD, depending on page displayed (scary stuff)
				for(i = 0; i < players.size; i++)
				{
					if(players[i].mv_allowvote)
					{
						if(players[i].mv_flipchoice != 0) isonpage = onPage(players[i].mv_flipchoice);
							else isonpage = onPage(players[i].mv_choice);
						for(j = 0; j < maxItemsOnPage(isonpage); j++)
							players[i].mv_votes[j] setValue(level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
					}
				}

				if(level.ex_mvmusic && !isDefined(mv_musicstop) && !level.ex_mapvoteweaponmode && level.ex_mapvotetimegt <= 10)
				{
					musicstop(level.ex_mapvotetimegt);
					mv_musicstop = true;
				}

				wait( [[level.ex_fpstime]](0.1) );
			}
			// Update time left HUD
			level.mv_timeleft setValue(level.ex_mapvotetimegt);
		}

		// Signal voting threads to end, and wait for threads to die
		level notify("VotingStageDone");
		wait( [[level.ex_fpstime]](0.2) );
	}
	else if(level.ex_mvmusic && !level.ex_mapvoteweaponmode) musicstop(5);

	// Count the votes
	mv_newitemnum = 0;
	mv_topvotes = 0;
	for(i = 0; i < level.mv_itemsmax; i++)
	{
		if(level.mv_items[i]["votes"] > mv_topvotes)
		{
			mv_newitemnum = i;
			mv_topvotes = level.mv_items[i]["votes"];
		}
	}

	// Select the winning game type
	gametype = level.mv_items[mv_newitemnum]["gametype"];
	gametypename = level.mv_items[mv_newitemnum]["gametypename"];

	// Prepare for weapon mode voting
	if(level.ex_mapvoteweaponmode)
	{
		// Fade HUD elements
		FadePlayerHUDStage();

		// Destroy the HUD elements which will be recreated for stage 3
		DeletePlayerHudStage();

		level.mv_items = [];
		for(j = 0; j < level.weaponmodenames.size; j++)
		{
			wm_index = level.mv_items.size;
			level.mv_items[wm_index]["weaponmode"] = level.weaponmodenames[j];
			level.mv_items[wm_index]["weaponmodename"] = level.weaponmodes[level.weaponmodenames[j]].loc;
			level.mv_items[wm_index]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;

		// Do we have enough weapon modes to vote for?
		if(level.mv_itemsmax > 1)
		{
			// title already shows map voted for
			// can't show short GT string, because they are not precached for modes > 4
			//level.mv_title setText(extreme\_ex_maps::getgtstringshort(gametype));

			level.mv_stage = 3;
			players = level.players;
			for(i = 0; i < players.size; i++)
				if(isDefined(players[i].mv_allowvote) && players[i].mv_allowvote) players[i] thread PlayerVote();
					else if(!isDefined(players[i].mv_allowvote)) players[i] thread PlayerNoVote();

			// Weapon mode voting in progress
			for(; level.ex_mapvotetimewm >= 0; level.ex_mapvotetimewm--)
			{
				for(t = 0; t < 10; t++)
				{
					// Reset votes
					for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

					// Get current players
					players = level.players;

					// Spawn no-vote thread for new players (joined during vote)
					for(i = 0; i < players.size; i++)
					{
						if(isPlayer(players[i]) && !isDefined(players[i].mv_allowvote))
						{
							players[i].mv_allowvote = false;
							players[i] thread PlayerNoVote();
						}
					}

					// Recount votes
					for(i = 0; i < players.size; i++)
						if(players[i].mv_allowvote && players[i].mv_choice != 0)
							level.mv_items[players[i].mv_choice - 1]["votes"]++;

					// Update votes on player's HUD, depending on page displayed (scary stuff)
					for(i = 0; i < players.size; i++)
					{
						if(players[i].mv_allowvote)
						{
							if(players[i].mv_flipchoice != 0) isonpage = onPage(players[i].mv_flipchoice);
								else isonpage = onPage(players[i].mv_choice);
							for(j = 0; j < maxItemsOnPage(isonpage); j++)
								players[i].mv_votes[j] setValue(level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
						}
					}

					if(level.ex_mvmusic && !isDefined(mv_musicstop) && level.ex_mapvotetimewm <= 10)
					{
						musicstop(level.ex_mapvotetimewm);
						mv_musicstop = true;
					}

					wait( [[level.ex_fpstime]](0.1) );
				}
				// Update time left HUD
				level.mv_timeleft setValue(level.ex_mapvotetimewm);
			}

			// Signal voting threads to end, and wait for threads to die
			level notify("VotingStageDone");
			wait( [[level.ex_fpstime]](0.2) );
		}
		else if(level.ex_mvmusic) musicstop(5);

		// Count the votes
		mv_newitemnum = 0;
		mv_topvotes = 0;
		for(i = 0; i < level.mv_itemsmax; i++)
		{
			if(level.mv_items[i]["votes"] > mv_topvotes)
			{
				mv_newitemnum = i;
				mv_topvotes = level.mv_items[i]["votes"];
			}
		}

		// Select the winning weapon mode
		weaponmode = level.mv_items[mv_newitemnum]["weaponmode"];
		weaponmodename = level.mv_items[mv_newitemnum]["weaponmodename"];

		// Write to cvar
		setCvar("ex_weaponmode", level.weaponmodes[weaponmode].id);
	}
	else weaponmodename = undefined;

	// Signal voting threads to end, and wait for threads to die
	level notify("VotingDone");
	wait( [[level.ex_fpstime]](0.2) );

	// Fade HUD elements
	FadeHud();

	// Destroy all HUD elements
	DeleteHud();

	// Write to cvars
	setCvar("sv_maprotationcurrent", "gametype " + gametype + " map " + map);

	// Announce winner
	WinnerIs(mapname, gametypename, weaponmodename);

	// Signal the end of map vote
	level notify("VotingComplete");
}

PlayerNoVote()
{
	// Thread for players not allowed to vote (all modes)
	// For players joining the vote during VoteLogic(), create HUD elements in this thread
	// not in CreateHUD()
	level endon("VotingDone");

	// Tag player as a non-voting player
	self.mv_allowvote = false;

	// To vertically center HUD elements, find out how many map lines are displayed
	// If less than 5 maps, make sure we have enough space for HUD elements
	minMapLinesOnPage = maxItemsOnPage(1);
	if(minMapLinesOnPage < 5) minMapLinesOnPage = 5;

	// Map vote in progress
	self.mv_inprogress = newClientHudElem(self);
	self.mv_inprogress.archived = false;
	self.mv_inprogress.horzAlign = "subleft";
	self.mv_inprogress.vertAlign = "subtop";
	self.mv_inprogress.alignX = "center";
	self.mv_inprogress.alignY = "middle";
	self.mv_inprogress.x = level.mv_originxc;
	self.mv_inprogress.y = 70 + int(minMapLinesOnPage / 2) * 16;
	self.mv_inprogress.sort = 103;
	self.mv_inprogress.fontscale = 1.5;
	self.mv_inprogress.color = (0, 1, 0);
	self.mv_inprogress.label = &"MAPVOTE_INPROGRESS";

	// You are not allowed to vote
	self.mv_notallowed = newClientHudElem(self);
	self.mv_notallowed.archived = false;
	self.mv_notallowed.horzAlign = "subleft";
	self.mv_notallowed.vertAlign = "subtop";
	self.mv_notallowed.alignX = "center";
	self.mv_notallowed.alignY = "middle";
	self.mv_notallowed.x = level.mv_originxc;
	self.mv_notallowed.y = 95 + int(minMapLinesOnPage / 2) * 16;
	self.mv_notallowed.sort = 103;
	self.mv_notallowed.fontscale = 1.3;
	self.mv_notallowed.color = (1, 0, 0);
	self.mv_notallowed.label = &"MAPVOTE_NOTALLOWED";

	// Please wait...
	self.mv_wait = newClientHudElem(self);
	self.mv_wait.archived = false;
	self.mv_wait.horzAlign = "subleft";
	self.mv_wait.vertAlign = "subtop";
	self.mv_wait.alignX = "center";
	self.mv_wait.alignY = "middle";
	self.mv_wait.x = level.mv_originxc;
	self.mv_wait.y = 111 + int(minMapLinesOnPage / 2) * 16;
	self.mv_wait.sort = 103;
	self.mv_wait.fontscale = 1.3;
	self.mv_wait.color = (1, 0, 0);
	self.mv_wait.label = &"MAPVOTE_PLEASEWAIT";

	// Now loop until the thread is signaled to end
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.1) );
		if(isPlayer(self))
		{
			self.sessionstate = "spectator";
			self.spectatorclient = -1;
		}
	}
}

PlayerVote()
{
	// Thread for players allowed to vote (map: modes 0 - 6, game type: modes 4 - 7, weapon mode: ex_mapvote_mode_weapons "1")
	level endon("VotingDone");
	level endon("VotingStageDone");

	// Players start without a vote
	self.mv_choice = 0;
	self.mv_flipchoice = 0;

	// Create HUD elements for maps (max 10)
	for(i = 0; i <= maxItemsOnPage(onPage(self.mv_choice))-1; i++)
	{
		self.mv_items[i] = newClientHudElem(self);
		self.mv_items[i].archived = false;
		self.mv_items[i].horzAlign = "subleft";
		self.mv_items[i].vertAlign = "subtop";
		self.mv_items[i].alignX = "left";
		self.mv_items[i].alignY = "middle";
		self.mv_items[i].x = level.mv_originx1 + 5; //195;
		self.mv_items[i].y = 105 + i * 16;
		self.mv_items[i].sort = 104;
		self.mv_items[i].fontscale = 1.3;

		switch(level.mv_stage)
		{
			case 1:
				self.mv_items[i].label = level.mv_items[i]["mapname"];
				if(level.ex_mapvotemode < 4) self.mv_items[i] setText(level.mv_items[i]["gametypename"]);
				break;
			case 2:
				self.mv_items[i].label = level.mv_items[i]["gametypename"];
				break;
			case 3:
				self.mv_items[i].label = level.mv_items[i]["weaponmodename"];
				break;
		}
	}

	// Create HUD elements for voting slots (max 10)
	for(i = 0; i <= maxItemsOnPage(onPage(self.mv_choice))-1; i++)
	{
		self.mv_votes[i] = newClientHudElem(self);
		self.mv_votes[i].archived = false;
		self.mv_votes[i].horzAlign = "subleft";
		self.mv_votes[i].vertAlign = "subtop";
		self.mv_votes[i].alignX = "center";
		self.mv_votes[i].alignY = "middle";
		self.mv_votes[i].x = level.mv_originx2 - 20; //430;
		self.mv_votes[i].y = 105 + i * 16;
		self.mv_votes[i].sort = 104;
		self.mv_votes[i] setValue(level.mv_items[i]["votes"]);
	}

	// Update page info
	self.mv_page setValue(onPage(self.mv_choice));

	// Create HUD element for selection bar. It starts invisible.
	// Keep sort number less than maps and votes, so it appears behind them
	self.mv_indicator = newClientHudElem(self);
	self.mv_indicator.archived = false;
	self.mv_indicator.horzAlign = "subleft";
	self.mv_indicator.vertAlign = "subtop";
	self.mv_indicator.alignX = "left";
	self.mv_indicator.alignY = "middle";
	self.mv_indicator.x = level.mv_originx1 + 3; //193;
	self.mv_indicator.y = 104;
	self.mv_indicator.sort = 103;
	self.mv_indicator.alpha = 0;
	self.mv_indicator.color = (0, 0, 1);
	self.mv_indicator setShader("white", level.mv_width - 6, 17); //254;

	// Now loop until the thread is signaled to end
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.01) );

		// Attack (FIRE) button to vote
		if(isplayer(self) && self attackButtonPressed() == true)
		{
			nextMap(self);
			while(isPlayer(self) && self attackButtonPressed() == true)
				wait( [[level.ex_fpstime]](0.01) );
		}

		// Melee button to flip pages
		if(isplayer(self) && self meleeButtonPressed() == true)
		{
			if(maxPages() > 1) flipPage(self);
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

nextMap(player)
{
	// Show indicator if first vote
	if(player.mv_choice == 0)
		player.mv_indicator.alpha = .8;

	// Is this first click after page flipping?
	if(player.mv_flipchoice != 0)
	{
		if(onPage(player.mv_choice) == onPage(player.mv_flipchoice)) player.mv_choice++;
			else player.mv_choice = player.mv_flipchoice;
		player.mv_indicator.alpha = .8;
		player.mv_flipchoice = 0;

	}
	else player.mv_choice++;

	if(player.mv_choice > level.mv_itemsmax)
		player.mv_choice = 1;

	showChoice(player, player.mv_choice);
}

flipPage(player)
{
	// IMPORTANT: do not change player's choice during page flipping!
	// Hide the indicator
	player.mv_indicator.alpha = 0;

	// Init temporary choice on first flip
	if(player.mv_flipchoice == 0) player.mv_flipchoice = player.mv_choice;

	// Set next page. Rotate if on last page already
	page = onPage(player.mv_flipchoice);
	page++;
	if(page > maxPages()) page = 1;

	// Calculate temporary choice based on new page.
	player.mv_flipchoice = (page * level.mv_perpage)-(level.mv_perpage-1);

	showChoice(player, player.mv_flipchoice);

	// Show indicator if this is the page with the player's choice on it
	if(player.mv_choice != 0 && (onPage(player.mv_choice) == onPage(player.mv_flipchoice)))
		player.mv_indicator.alpha = .8;
}

showChoice(player, choice)
{
	// Show players's choice, and auto-flip page if needed
	if(choice == 1) oldpage = maxPages();
		else oldpage = onPage(choice-1);
	newpage = onPage(choice);

	// Is a page flip needed?
	if(newpage != oldpage)
	{
		// Remove old maps and votes
		for(i = 0; i <= maxItemsOnPage(oldpage)-1; i++)
		{
			player.mv_items[i].alpha = 0;
			player.mv_votes[i].alpha = 0;
		}
		// Show new maps and votes
		for(i = 0; i <= maxItemsOnPage(newpage)-1; i++)
		{
			switch(level.mv_stage)
			{
				case 1:
					player.mv_items[i].label = level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["mapname"];
					if(level.ex_mapvotemode < 4) player.mv_items[i] setText(level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["gametypename"]);
					break;
				case 2:
					player.mv_items[i].label = level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["gametypename"];
					break;
				case 3:
					player.mv_items[i].label = level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["weaponmodename"];
					break;
			}

			player.mv_votes[i] setValue(level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["votes"]);
			player.mv_items[i].alpha = 1;
			player.mv_votes[i].alpha = 1;
		}
		// Update page info
		player.mv_page setValue(newpage);
	}
	// Update indicator, and show selected map if not in page flipping mode
	if(player.mv_flipchoice == 0)
	{
		indpos = (level.mv_perpage - 1) - ((newpage * level.mv_perpage) - choice);
		self.mv_indicator.y = 104 + (indpos * 16);
		self playLocalSound("flagchange");
		if(level.ex_mapvote_thumbnails && level.mv_stage == 1) self showPlayerMapThumbnail(choice);
	}
}

showPlayerMapThumbnail(choice)
{
	thumbnail_width = 256;
	thumbnail_height = 96;

	if(!isDefined(self.mv_thumbnail))
	{
		self.mv_thumbnail = newClientHudElem(self);
		self.mv_thumbnail.archived = false;
		self.mv_thumbnail.horzAlign = "subleft";
		self.mv_thumbnail.vertAlign = "subtop";
		self.mv_thumbnail.alignX = "center";
		self.mv_thumbnail.alignY = "top";
		self.mv_thumbnail.x = level.mv_originxc;
		self.mv_thumbnail.y = 255;
		self.mv_thumbnail.sort = 200;
		self.mv_thumbnail.alpha = 1;
	}

	self.mv_thumbnail setShader(level.mv_items[choice - 1]["thumbnail"], thumbnail_width, thumbnail_height);
}

showWinningMapThumbnail(choice)
{
	thumbnail_width = 256;
	thumbnail_height = 96;

	level.mv_thumbnail = newHudElem();
	level.mv_thumbnail.archived = false;
	level.mv_thumbnail.horzAlign = "subleft";
	level.mv_thumbnail.vertAlign = "subtop";
	level.mv_thumbnail.alignX = "center";
	level.mv_thumbnail.alignY = "top";
	level.mv_thumbnail.x = level.mv_originxc;
	level.mv_thumbnail.y = 255;
	level.mv_thumbnail.sort = 200;
	level.mv_thumbnail.alpha = 1;
	level.mv_thumbnail setShader(level.mv_items[choice]["thumbnail"], thumbnail_width, thumbnail_height);
}

moveWinningMapThumbnail(movetime)
{
	if(isDefined(level.mv_thumbnail))
	{
		level.mv_thumbnail moveOverTime(movetime);
		level.mv_thumbnail.x = 320;
		level.mv_thumbnail.y = 170;
		wait( [[level.ex_fpstime]](movetime) );
	}
}

WinnerIs(mapname, gametypename, weaponmodename)
{
	// Announce the winning map
	if(level.ex_mapvote_thumbnails) moveWinningMapThumbnail(1);

	// And the winner is...
	level.mv_winner = newHudElem();
	level.mv_winner.archived = false;
	level.mv_winner.horzAlign = "subleft";
	level.mv_winner.vertAlign = "subtop";
	level.mv_winner.alignX = "center";
	level.mv_winner.alignY = "middle";
	level.mv_winner.x = 320;
	level.mv_winner.y = 90;
	level.mv_winner.fontscale = 1.3;
	level.mv_winner.label = &"MAPVOTE_WINNER";

	// Winning map name
	level.mv_winner_map = newHudElem();
	level.mv_winner_map.archived = false;
	level.mv_winner_map.horzAlign = "subleft";
	level.mv_winner_map.vertAlign = "subtop";
	level.mv_winner_map.alignX = "center";
	level.mv_winner_map.alignY = "middle";
	level.mv_winner_map.x = 320;
	level.mv_winner_map.y = 120;
	level.mv_winner_map.color = (0,1,0);
	level.mv_winner_map.fontscale = 2;
	level.mv_winner_map.label = mapname;

	// Winning game type
	level.mv_winner_gt = newHudElem();
	level.mv_winner_gt.archived = false;
	level.mv_winner_gt.horzAlign = "subleft";
	level.mv_winner_gt.vertAlign = "subtop";
	level.mv_winner_gt.alignX = "center";
	level.mv_winner_gt.alignY = "middle";
	level.mv_winner_gt.x = 320;
	level.mv_winner_gt.y = 140;
	level.mv_winner_gt.fontscale = 1.5;
	level.mv_winner_gt.label = gametypename;

	// Winning weapon mode
	if(isDefined(weaponmodename))
	{
		level.mv_winner_wm = newHudElem();
		level.mv_winner_wm.archived = false;
		level.mv_winner_wm.horzAlign = "subleft";
		level.mv_winner_wm.vertAlign = "subtop";
		level.mv_winner_wm.alignX = "center";
		level.mv_winner_wm.alignY = "middle";
		level.mv_winner_wm.x = 320;
		level.mv_winner_wm.y = 160;
		level.mv_winner_wm.fontscale = 1.5;
		level.mv_winner_wm.label = weaponmodename;
	}

	wait( [[level.ex_fpstime]](5) );

	level.mv_winner fadeOverTime(1);
	level.mv_winner.alpha = 0;
	level.mv_winner_map fadeOverTime(1);
	level.mv_winner_map.alpha = 0;
	level.mv_winner_gt fadeOverTime(1);
	level.mv_winner_gt.alpha = 0;
	if(isDefined(level.mv_winner_wm))
	{
		level.mv_winner_wm fadeOverTime(1);
		level.mv_winner_wm.alpha = 0;
	}
	if(isDefined(level.mv_thumbnail))
	{
		level.mv_thumbnail fadeOverTime(1);
		level.mv_thumbnail.alpha = 0;
	}

	wait( [[level.ex_fpstime]](1) );

	if(isDefined(level.mv_thumbnail)) level.mv_thumbnail destroy();
	if(isDefined(level.mv_winner)) level.mv_winner destroy();
	if(isDefined(level.mv_winner_map)) level.mv_winner_map destroy();
	if(isDefined(level.mv_winner_gt)) level.mv_winner_gt destroy();
	if(isDefined(level.mv_winner_wm)) level.mv_winner_wm destroy();
}

CreateHud(ItemsOnPage)
{
	// Create basic HUD elements

	// Background
	level.mv_bg = newHudElem();
	level.mv_bg.archived = false;
	level.mv_bg.horzAlign = "subleft";
	level.mv_bg.vertAlign = "subtop";
	level.mv_bg.alignX = "left";
	level.mv_bg.alignY = "top";
	level.mv_bg.x = level.mv_originx1; //190;
	level.mv_bg.y = 45;
	level.mv_bg.alpha = .7;
	level.mv_bg.sort = 100;
	level.mv_bg.color = (0,0,0);
	level.mv_bg setShader("white", level.mv_width, 85 + level.mv_heightadj + ItemsOnPage * 16); //260;

	// Title bar
	level.mv_titlebar = newHudElem();
	level.mv_titlebar.archived = false;
	level.mv_titlebar.horzAlign = "subleft";
	level.mv_titlebar.vertAlign = "subtop";
	level.mv_titlebar.alignX = "left";
	level.mv_titlebar.alignY = "top";
	level.mv_titlebar.x = level.mv_originx1 + 3; //193;
	level.mv_titlebar.y = 47;
	level.mv_titlebar.alpha = .3;
	level.mv_titlebar.sort = 101;
	level.mv_titlebar setShader("white", level.mv_width - 5, 21); //255;

	// Separator (bottom line)
	level.mv_bline = newHudElem();
	level.mv_bline.archived = false;
	level.mv_bline.horzAlign = "subleft";
	level.mv_bline.vertAlign = "subtop";
	level.mv_bline.alignX = "left";
	level.mv_bline.alignY = "top";
	level.mv_bline.x = level.mv_originx1 + 3; //193;
	level.mv_bline.y = 110 + level.mv_heightadj + ItemsOnPage * 16;
	level.mv_bline.alpha = .3;
	level.mv_bline.sort = 101;
	level.mv_bline setShader("white", level.mv_width - 5, 1); //255;
	
	// Time left
	level.mv_timeleft = newHudElem();
	level.mv_timeleft.archived = false;
	level.mv_timeleft.horzAlign = "subleft";
	level.mv_timeleft.vertAlign = "subtop";
	level.mv_timeleft.alignX = "left";
	level.mv_timeleft.alignY = "top";
	level.mv_timeleft.x = level.mv_originx1 + 5; //195;
	level.mv_timeleft.y = 115 + level.mv_heightadj + ItemsOnPage * 16;
	level.mv_timeleft.sort = 102;
	level.mv_timeleft.fontscale = 1;
	level.mv_timeleft.label = &"MAPVOTE_TIMELEFT";
	level.mv_timeleft setValue(level.ex_mapvotetime);

	// Title
	level.mv_title = newHudElem();
	level.mv_title.archived = false;
	level.mv_title.horzAlign = "subleft";
	level.mv_title.vertAlign = "subtop";
	level.mv_title.alignX = "left";
	level.mv_title.alignY = "top";
	level.mv_title.x = level.mv_originx1 + 5; //195;
	level.mv_title.y = 50;
	level.mv_title.sort = 102;
	level.mv_title.fontscale = 1.3;
	level.mv_title.label = &"MAPVOTE_TITLE";

	// Create additional info ONLY for players allowed to vote
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		// Catch players joining the map vote just now (do not allow them to vote)
		if(isPlayer(players[i]) && !isDefined(players[i].mv_allowvote))
			players[i].mv_allowvote = false;

		if(players[i].mv_allowvote)
		{
			// Votes column header
			players[i].mv_headers = newClientHudElem(players[i]);
			players[i].mv_headers.archived = false;
			players[i].mv_headers.horzAlign = "subleft";
			players[i].mv_headers.vertAlign = "subtop";
			players[i].mv_headers.alignX = "right";
			players[i].mv_headers.alignY = "middle";
			players[i].mv_headers.x = level.mv_originx2 - 5; //445;
			players[i].mv_headers.y = 90;
			players[i].mv_headers.sort = 102;
			players[i].mv_headers.fontscale = 1;
			players[i].mv_headers.label = &"MAPVOTE_HEADERS";

			// How-to instructions
			players[i].mv_howto = newClientHudElem(players[i]);
			players[i].mv_howto.archived = false;
			players[i].mv_howto.horzAlign = "subleft";
			players[i].mv_howto.vertAlign = "subtop";
			players[i].mv_howto.alignX = "center";
			players[i].mv_howto.alignY = "middle";
			players[i].mv_howto.x = level.mv_originxc;
			players[i].mv_howto.y = 80;
			players[i].mv_howto.sort = 102;
			players[i].mv_howto.fontscale = 1;
			players[i].mv_howto.label = &"MAPVOTE_HOWTO";

			// Page info
			players[i].mv_page = newClientHudElem(players[i]);
			players[i].mv_page.archived = false;
			players[i].mv_page.horzAlign = "subleft";
			players[i].mv_page.vertAlign = "subtop";
			players[i].mv_page.alignX = "right";
			players[i].mv_page.alignY = "top";
			players[i].mv_page.x = level.mv_originx2 - 5; //445;
			players[i].mv_page.y = 115 + level.mv_heightadj + ItemsOnPage * 16;
			players[i].mv_page.sort = 102;
			players[i].mv_page.fontscale = 1;
			players[i].mv_page.label = &"MAPVOTE_PAGE";
			players[i].mv_page setValue(1);
		}
	}
}

FadePlayerHudStage()
{
	// Fade all player-based HUD elements
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].mv_allowvote))
		{
			if(players[i].mv_allowvote)
			{
				// For players allowed to vote
				if(isDefined(self.mv_thumbnail))
				{
					self.mv_thumbnail fadeOverTime(1);
					self.mv_thumbnail.alpha = 0;
				}

				for(j = 0; j < maxItemsOnPage(1); j++)
				{
					if(isDefined(players[i].mv_votes[j]))
					{
						players[i].mv_votes[j] fadeOverTime(1);
						players[i].mv_votes[j].alpha = 0;
					}
				}

				for(j = 0; j < maxItemsOnPage(1); j++)
				{
					if(isDefined(players[i].mv_items[j]))
					{
						players[i].mv_items[j] fadeOverTime(1);
						players[i].mv_items[j].alpha = 0;
					}
				}

				if(isDefined(players[i].mv_indicator))
				{
					players[i].mv_indicator fadeOverTime(1);
					players[i].mv_indicator.alpha = 0;
				}
			}
		}
	}
	
	wait( [[level.ex_fpstime]](1) );
}

FadeHud()
{
	// Fade all player-based HUD elements
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].mv_allowvote))
		{
			if(players[i].mv_allowvote)
			{
				// For players allowed to vote
				for(j = 0; j < maxItemsOnPage(1); j++)
				{
					if(isDefined(players[i].mv_votes[j]))
					{
						players[i].mv_votes[j] fadeOverTime(1);
						players[i].mv_votes[j].alpha = 0;
					}
				}

				for(j = 0; j < maxItemsOnPage(1); j++)
				{
					if(isDefined(players[i].mv_items[j]))
					{
						players[i].mv_items[j] fadeOverTime(1);
						players[i].mv_items[j].alpha = 0;
					}
				}

				if(isDefined(players[i].mv_indicator))
				{
					players[i].mv_indicator fadeOverTime(1);
					players[i].mv_indicator.alpha = 0;
				}

				if(isDefined(players[i].mv_page))
				{
					players[i].mv_page fadeOverTime(1);
					players[i].mv_page.alpha = 0;
				}

				if(isDefined(players[i].mv_howto))
				{
					players[i].mv_howto fadeOverTime(1);
					players[i].mv_howto.alpha = 0;
				}

				if(isDefined(players[i].mv_headers))
				{
					players[i].mv_headers fadeOverTime(1);
					players[i].mv_headers.alpha = 0;
				}
			}
			else
			{
				// For players not allowed to vote
				if(isDefined(players[i].mv_inprogress))
				{
					players[i].mv_inprogress fadeOverTime(1);
					players[i].mv_inprogress.alpha = 0;
				}

				if(isDefined(players[i].mv_notallowed))
				{
					players[i].mv_notallowed fadeOverTime(1);
					players[i].mv_notallowed.alpha = 0;
				}

				if(isDefined(players[i].mv_wait))
				{
					players[i].mv_wait fadeOverTime(1);
					players[i].mv_wait.alpha = 0;
				}
			}
		}
	}

	// Fade all level-based HUD elements
	level.mv_timeleft fadeOverTime(1);
	level.mv_bline fadeOverTime(1);
	level.mv_title fadeOverTime(1);
	level.mv_titlebar fadeOverTime(1);
	level.mv_bg fadeOverTime(1);

	level.mv_timeleft.alpha = 0;
	level.mv_bline.alpha = 0;
	level.mv_title.alpha = 0;
	level.mv_titlebar.alpha = 0;
	level.mv_bg.alpha = 0;
	
	wait( [[level.ex_fpstime]](1) );
}

DeletePlayerHudStage()
{
	// Destroy all player-based HUD elements for maps
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].mv_allowvote))
		{
			if(players[i].mv_allowvote)
			{
				// For players allowed to vote
				if(isDefined(players[i].mv_thumbnail)) players[i].mv_thumbnail destroy();

				for(j = 0; j < maxItemsOnPage(1); j++)
					if(isDefined(players[i].mv_votes[j]))
						players[i].mv_votes[j] destroy();

				for(j = 0; j < maxItemsOnPage(1); j++)
					if(isDefined(players[i].mv_items[j]))
						players[i].mv_items[j] destroy();

				if(isDefined(players[i].mv_indicator))
					players[i].mv_indicator destroy();
			}
		}
	}
}

DeleteHud()
{
	// Destroy all player-based HUD elements
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].mv_allowvote))
		{
			if(players[i].mv_allowvote)
			{
				// For players allowed to vote
				if(isDefined(players[i].mv_thumbnail)) players[i].mv_thumbnail destroy();

				for(j = 0; j < maxItemsOnPage(1); j++)
					if(isDefined(players[i].mv_votes[j]))
						players[i].mv_votes[j] destroy();

				for(j = 0; j < maxItemsOnPage(1); j++)
					if(isDefined(players[i].mv_items[j]))
						players[i].mv_items[j] destroy();

				if(isDefined(players[i].mv_indicator))
					players[i].mv_indicator destroy();

				if(isDefined(players[i].mv_page))
					players[i].mv_page destroy();

				if(isDefined(players[i].mv_howto))
					players[i].mv_howto destroy();

				if(isDefined(players[i].mv_headers))
					players[i].mv_headers destroy();
			}
			else
			{
				// For players not allowed to vote
				if(isDefined(players[i].mv_inprogress))
					players[i].mv_inprogress destroy();

				if(isDefined(players[i].mv_notallowed))
					players[i].mv_notallowed destroy();

				if(isDefined(players[i].mv_wait))
					players[i].mv_wait destroy();
			}
		}
	}
	// Destroy all level-based HUD elements
	if(isDefined(level.mv_timeleft)) level.mv_timeleft destroy();
	if(isDefined(level.mv_bline)) level.mv_bline destroy();
	if(isDefined(level.mv_title)) level.mv_title destroy();
	if(isDefined(level.mv_titlebar)) level.mv_titlebar destroy();
	if(isDefined(level.mv_bg)) level.mv_bg destroy();
}

maxPages()
{
	// Calculate the number of pages available
	pages = int((level.mv_itemsmax + (level.mv_perpage - 1)) / level.mv_perpage);
	return pages;
}

onPage(choice)
{
	// Calculate which page the player is on
	if(choice != 0)
	{
		page = int((choice + (level.mv_perpage - 1)) / level.mv_perpage);
		if(page > maxPages()) page = 1;
	}
	else page = 1;
	return page;
}

maxItemsOnPage(page)
{
	// Calculate number of items on page
	items = level.mv_itemsmax;
	itemsonpage = 0;
	for(i = 1; i <= page; i++)
	{
		if(items >= level.mv_perpage)
		{
			itemsonpage = level.mv_perpage;
			items = items - level.mv_perpage;
		}
		else
		{
			if(items != 0)
			{
				itemsonpage = items;
				items = 0;
			}
			else itemsonpage = 0;
		}
	}
	return itemsonpage;
}

mapvoteMemory(mapname, maxmaps)
{
	level.ex_mapmemory = [];

	// limit the map vote memory to two-third of the maps available for voting (before filtering)
	maxtwothird = int( (maxmaps / 3) * 2);
	if(maxtwothird < 2) maxtwothird = 2;
	if(level.ex_mapvote_memory_max > maxtwothird) level.ex_mapvote_memory_max = maxtwothird;

	mapvoteLoadMemory();
	mapvoteAddMemory(mapname);
	mapvoteSaveMemory();

	if(level.ex_maps_log)
	{
		maps_in_memory = "";
		for(i = 0; i < level.ex_mapmemory.size; i++)
		{
			maps_in_memory += level.ex_mapmemory[i] + " ";
			if(i == level.ex_mapvote_memory_max - 1) maps_in_memory += "| ";
		}
		logprint("MAPVOTE DEBUG: maps in memory, including last map played. The | character marks the max for the current rotation:\n");
		logprint("MAPVOTE DEBUG: memory [ " + maps_in_memory + "]\n");
	}
}

mapvoteLoadMemory()
{
	filename = "memory/_ex_mapvote";
	filehandle = openfile(filename, "read");
	if(filehandle != -1)
	{
		farg = freadln(filehandle);
		if(farg > 0)
		{
			memory = fgetarg(filehandle, 0);
			array = strtok(memory, " ");
			if(array.size > 1)
			{
				fileid = array[0];
				if(fileid == "mapvote")
				{
					arrayend = array.size - 1;
					if(arrayend > 50) arrayend = 50;

					for(i = 0; i < arrayend; i++)
						level.ex_mapmemory[i] = array[i+1];
				}
			}
		}
		closefile(filehandle);
	}
}

mapvoteAddMemory(mapname)
{
	startentry = level.ex_mapmemory.size;
	if(startentry >= level.ex_mapvote_memory_max) startentry = level.ex_mapvote_memory_max - 1;

	for(i = startentry; i > 0; i--)
		level.ex_mapmemory[i] = level.ex_mapmemory[i-1];

	level.ex_mapmemory[0] = tolower(mapname);
}

mapvoteSaveMemory()
{
	filename = "memory/_ex_mapvote";
	filehandle = openfile(filename, "write");
	if(filehandle != -1)
	{
		memory = "mapvote ";
		for(i = 0; i < level.ex_mapmemory.size; i++)
			memory += level.ex_mapmemory[i] + " ";

		fprintln(filehandle, memory);
		closefile(filehandle);
	}
}

mapvoteInMemory(mapname)
{
	lcmapname = tolower(mapname);

	// if number of maps in memory exceeds the memory limit, only check lastest additions
	searchend = level.ex_mapmemory.size;
	if(searchend > level.ex_mapvote_memory_max) searchend = level.ex_mapvote_memory_max;

	for(i = 0; i < searchend; i++)
		if(level.ex_mapmemory[i] == lcmapname) return true;

	return false;
}
