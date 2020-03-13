#include extreme\_ex_geolocation;

init()
{
	if(!level.ex_clog && !level.ex_glog) return;

	// set up default file names
	level.ex_clog_src = "log/console_mp.log";
	level.ex_clog_trg = "log/console_x2.log";
	level.ex_glog_src = "log/games_mp.log";
	level.ex_glog_trg = "log/games_x2.log";

	// initialize console log line pointer
	if(getCvar("ex_logmon_lineno") == "")
	{
		level.ex_logmon_lineno = -1;
		setCvar("ex_logmon_lineno", level.ex_logmon_lineno);
	}
	else level.ex_logmon_lineno = getCvarInt("ex_logmon_lineno");

	// if splitting is enabled, get file stamp and set new file names
	if( (level.ex_clog && level.ex_clog_split) || (level.ex_glog && level.ex_glog_split) )
	{
		stamp = getCvar("ex_logmon_stamp");
		if(stamp == "")
		{
			if(level.ex_clog && level.ex_clog_split) stamp = getStampFromFile();
			if(stamp == "") stamp = getStampFromIncr();
			setCvar("ex_logmon_stamp", stamp);
		}

		if(level.ex_clog && level.ex_clog_split) level.ex_clog_trg = "log/console_x2" + stamp + ".log";
		if(level.ex_glog && level.ex_glog_split) level.ex_glog_trg = "log/games_x2" + stamp + ".log";
	}

	// prepare log monitoring if the server just started (only done once)
	if(getCvar("ex_logmon_done") == "")
	{
		setCvar("ex_logmon_done", "1");

		// redirect games_mp.log and restart level
		if(level.ex_glog)
		{
			// reset source file (games_mp.log)
			f = openfile(level.ex_glog_src, "write");
			if(f != -1)
			{
				closefile(f);

				// make sure the target file (games_x2.log) exists
				f = openfile(level.ex_glog_trg, "append");
				if(f == -1) f = openfile(level.ex_glog_trg, "write");
				if(f != -1)
				{
					closefile(f);

					// make a note in the original log that we're changing log location
					logprint("LOGMON: changing location of games_mp.log to scriptdata/" + level.ex_glog_trg + "\n");

					// make the g_log dvar point to our source file
					setcvar("g_log","scriptdata/" + level.ex_glog_src);
					setcvar("g_logsync", "1");

					// reset rotation so the server doesn't skip the first map
					//setCvar("sv_maprotationcurrent", getCvar("sv_maprotation"));
					setCvar("sv_maprotationcurrent", "");

					// restart to activate new settings
					exitlevel(false);

					wait( [[level.ex_fpstime]](30) );
				}
			}

			level.ex_glog = false;
		}
	}

	// set up games log filter
	if(level.ex_glog && level.ex_glog_filter)
	{
		level.gfilters = [];
		count = 0;

		for(;;)
		{
			filter_raw = [[level.ex_drm]]("ex_glog_filter_" + count, "", "", "", "string");
			if(filter_raw == "") break;

			index = level.gfilters.size;
			level.gfilters[index] = filter_raw;
			//logprint("GLOG: added games filter " + level.gfilters[index] + " to array\n");
			count ++;
		}

		if(!level.gfilters.size) level.ex_glog_filter = false;
	}

	// set up console log filter
	if(level.ex_clog && level.ex_clog_filter)
	{
		level.cfilters = [];
		count = 0;

		for(;;)
		{
			filter_raw = [[level.ex_drm]]("ex_clog_filter_" + count, "", "", "", "string");
			if(filter_raw == "") break;

			index = level.cfilters.size;
			level.cfilters[index] = filter_raw;
			//logprint("CLOG: added console filter " + level.cfilters[index] + " to array\n");
			count ++;
		}

		if(!level.cfilters.size) level.ex_clog_filter = false;
	}

	// start main threads
	level.processGamesLog_running = false;
	level.processConsoleLog_running = false;

	if(level.ex_glog) level thread processGamesLog();
	if(level.ex_clog) level thread processConsoleLog();
}

processGamesLog()
{
	wait( [[level.ex_fpstime]](10) );

	// init games_mp subsystem "bad language"
	if(level.ex_glog_badword)
	{
		level.badwords = [];
		count = 0;

		for(;;)
		{
			badword_raw = [[level.ex_drm]]("ex_glog_badword_" + count, "", "", "", "string");
			if(badword_raw == "") break;

			badword_array = strtok(badword_raw, ",");
			if(badword_array.size != 2) continue;

			badword_weight = int(badword_array[1]);
			if(badword_weight == 0) continue;

			index = level.badwords.size;
			level.badwords[index] = spawnstruct();
			level.badwords[index].word = badword_array[0];
			level.badwords[index].weight = badword_weight;
			//logprint("GLOG: added bad word " + level.badwords[index].word + " (weight " + level.badwords[index].weight + ") to array\n");
			count ++;
		}
	}

	// abort if none of the games_mp subsystems is ready
	ready = 0;
	if(level.ex_glog_badword && level.badwords.size) ready++;
		else level.ex_glog_badword = false;
	if(level.ex_glog_filter) ready++;
	if(!ready) return;

	// start main processing loop for games_mp
	for(;;)
	{
		while(level.processConsoleLog_running) wait( [[level.ex_fpstime]](1) );
		level.processGamesLog_running = true;
		while(level.geo_lookup_inprogress) wait( [[level.ex_fpstime]](1) );

		f1 = openfile(level.ex_glog_src, "read");
		if(f1 != -1)
		{
			f2 =  openfile(level.ex_glog_trg, "append");
			if(f2 != -1)
			{
				while(true)
				{
					arg = freadln(f1);
					if(arg == -1) break;
					if(arg != 0) str = fgetarg(f1, 0);
						else str = "";

					if(str != "")
					{
						// subsystem "bad language"
						if(level.ex_glog_badword) badWordsCheck(str);

						// subsystem "filter"
						if(!level.ex_glog_filter || !filterGames(str)) fprintln(f2, "\n" + str);
					}
				}
				closefile(f2);
			}
			closefile(f1);
		}

		// reset source file to zero
		f = openfile(level.ex_glog_src, "write");
		if(f != -1) closefile(f);

		level.processGamesLog_running = false;
		wait( [[level.ex_fpstime]](level.ex_glog_interval) );
	}
}

processConsoleLog()
{
	wait( [[level.ex_fpstime]](20) );

	// init console_mp subsystem "geolocation"
	if(level.ex_clog_geo) geoInit();

	// abort if none of the console_mp subsystems is ready
	ready = 0;
	if(level.ex_clog_geo) ready++;
	if(level.ex_clog_filter) ready++;
	if(!ready) return;

	// start main processing loop for console_mp
	for(;;)
	{
		while(level.processGamesLog_running) wait( [[level.ex_fpstime]](1) );
		level.processConsoleLog_running = true;
		while(level.geo_lookup_inprogress) wait( [[level.ex_fpstime]](1) );

		lineno = 0;

		f1 = openfile(level.ex_clog_src, "read");
		if(f1 != -1)
		{
			f2 =  openfile(level.ex_clog_trg, "append");
			if(f2 != -1)
			{
				while(true)
				{
					arg = freadln(f1);
					if(arg == -1) break;
					if(arg != 0) str = fgetarg(f1, 0);
						else str = "";

					lineno++;
					if(lineno <= level.ex_logmon_lineno) continue;

					if(str != "")
					{
						// subsystem "geolocation"
						if(level.ex_clog_geo)
						{
							// look for IP address
							geoFindIP(str, "ping from", lineno);

							// look for client ID
							geoFindID(str, "to CS_CONNECTED for", lineno);

							// we can only have 1 file open for "read". We cannot open the geo database
							// right now, because the log is still open. We have to delay the announcement
							// by collecting IP addresses and IDs now and show them after the log closes.
						}

						// subsystem "filter"
						if(!level.ex_clog_filter || !filterConsole(str)) fprintln(f2, "\n" + str);
					}
				}
				closefile(f2);
			}
			closefile(f1);
		}

		level.ex_logmon_lineno = lineno;
		lineno_check = getCvarInt("ex_logmon_lineno");
		if(lineno != lineno_check) setCvar("ex_logmon_lineno", level.ex_logmon_lineno);

		// show geolocation info to players
		if(level.ex_clog_geo) level thread geoShow();

		level.processConsoleLog_running = false;
		wait( [[level.ex_fpstime]](level.ex_clog_interval) );
	}
}

filterGames(s)
{
	for(i = 0; i < level.gfilters.size; i++)
		if(isSubStr(s, level.gfilters[i])) return(true);

	return(false);
}

filterConsole(s)
{
	for(i = 0; i < level.cfilters.size; i++)
		if(isSubStr(s, level.cfilters[i])) return(true);

	return(false);
}

badWordsCheck(s)
{
	if(s.size == 0) return;

	// look for first semicolon
	i = 0;
	while(s[i] != ";") { i++; if(i > s.size - 1) return; }

	// look for say or sayteam
	if(s[i - 1] != "y" && s[i - 1] != "m") return;

	// look for next semicolon
	i++;
	while(s[i] != ";") { i++; if(i > s.size - 1) return; }

	// get entity number
	i++;
	num = "";
	while(s[i] != ";") { num += s[i]; i++; if(i > s.size - 1) return; }

	// get name
	i++;
	name = "";
	while(s[i] != ";") { name += s[i]; i++; if(i > s.size - 1) return; }

	// get text
	i++;
	text = "";
	while(i < s.size) { if(s[i] != "") text += s[i]; i++; }

	badwords_weight = badWordsCheckArray(text);
	if(badwords_weight > 0)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			//players[i] thread extreme\_ex_utils::execClientCommand("rcon status");

			if(players[i] getentitynumber() == int(num))
			{
				guid = players[i] getGuid();

				// can't ban with guid 0. Switch to kick instead
				badwords_action = level.ex_glog_badword_action;
				if(badwords_action == 2 && int(guid) == 0) badwords_action = 1;

				players[i].pers["badword_status"] += badwords_weight;
				if(players[i].pers["badword_status"] >= level.ex_glog_badword_max)
				{
					//logprint(" ACTION: " + players[i].name + " (GUID " + guid + ") '" + text + "' [+" + badwords_weight + " makes " + players[i].pers["badword_status"] + "/" + level.ex_glog_badword_max + "]\n");

					switch(badwords_action)
					{
					  case 0:
							players[i] iprintlnbold(&"LOGMON_DISCONNECT_PLAYER");
							wait( [[level.ex_fpstime]](2) );
							iprintln(&"LOGMON_DISCONNECT_ALL", players[i].name);
							players[i] setClientCvar("com_errorTitle", "eXtreme+ Message");
							players[i] setClientCvar("com_errorMessage", "You have been disconnected from the server\nfor foul language, racial or sexual remarks!");
							wait( [[level.ex_fpstime]](1) );
							if(isPlayer(players[i])) players[i] thread extreme\_ex_utils::execClientCommand("disconnect");
							break;
					  case 1:
							players[i] iprintlnbold(&"LOGMON_KICK_PLAYER");
							wait( [[level.ex_fpstime]](2) );
							iprintln(&"LOGMON_KICK_ALL", players[i].name);
							if(isPlayer(players[i])) kick(int(num));
							break;
					  case 2:
							players[i] iprintlnbold(&"LOGMON_BAN_PLAYER");
							wait( [[level.ex_fpstime]](2) );
							iprintln(&"LOGMON_BAN_ALL", players[i].name);
							if(isPlayer(players[i])) ban(int(num));
							break;
					}
				}
				else
				{
					//logprint("WARNING: " + players[i].name + " (GUID " + guid + ") '" + text + "' [+" + badwords_weight + " makes " + players[i].pers["badword_status"] + "/" + level.ex_glog_badword_max + "]\n");

					players[i] iprintlnbold(&"LOGMON_WARN_PLAYER", players[i].name);
					players[i] iprintlnbold(&"LOGMON_WARN_PLAYER_STAT1", players[i].pers["badword_status"]);
					players[i] iprintlnbold(&"LOGMON_WARN_PLAYER_STAT2", level.ex_glog_badword_max);
					iprintln(&"LOGMON_WARN_ALL", players[i].name);
				}
			}
		}
	}
}

badWordsCheckArray(text)
{
	weight = 0;
	text = tolower(text);

	for(i = 0; i < level.badwords.size; i++)
	{
		badword = tolower(level.badwords[i].word);

		index = 0;
		for(j = 0; j < text.size; j++)
		{
			if(text[j] == badword[index]) index++;
				else index = 0;

			if(index == badword.size)
			{
				weight += level.badwords[i].weight;
				index = 0;
			}
		}
	}

	return(weight);
}

getStampFromIncr()
{
	counter = 0;
	stamp = "_" + numToStr(counter, 5);
	file = "log/games_x2" + stamp + ".log";

	for(;;)
	{
		f = openfile(file, "read");
		if(f != -1)
		{
			closefile(f);
			counter++;
			stamp = "_" + numToStr(counter, 5);
			file = "log/games_x2" + stamp + ".log";
		}
		else break;
	}

	return(stamp);
}

getStampFromFile()
{
	// example: logfile opened on Thu Aug 26 21:20:41 2010
	stamp = "";

	f = openfile(level.ex_clog_src, "read");
	if(f != -1)
	{
		arg = freadln(f);
		if(arg != -1)
		{
			stamp = "";
			if(arg != 0)
			{
				str = fgetarg(f, 0);
				tokens = strtok(str, " ");
				if(tokens.size)
				{
					for(i = 0; i < tokens.size; i++) if(convertWeekDay(tokens[i])) break;
					i++;
					if(i < tokens.size)
					{
						month = numToStr(convertMonth(tokens[i]), 2);
						i++;
						if(i < tokens.size && month != "00")
						{
							day = numToStr(int(tokens[i]), 2);
							i++;
							if(i < tokens.size)
							{
								time = convertTime(tokens[i]);
								i++;
								if(i < tokens.size)
								{
									year = tokens[i];
									stamp = "_" + year + month + day + "_" + time;
								}
							}
						}
					}
				}
			}
		}
		closefile(f);
	}

	return(stamp);
}

convertMonth(abbr)
{
	switch(abbr)
	{
		case "Jan": return 1;
		case "Feb": return 2;
		case "Mar": return 3;
		case "Apr": return 4;
		case "May": return 5;
		case "Jun": return 6;
		case "Jul": return 7;
		case "Aug": return 8;
		case "Sep": return 9;
		case "Oct": return 10;
		case "Nov": return 11;
		case "Dec": return 12;
		default   : return 0;
	}
}

convertWeekday(abbr)
{
	switch(abbr)
	{
		case "Mon": return 1;
		case "Tue": return 2;
		case "Wed": return 3;
		case "Thu": return 4;
		case "Fri": return 5;
		case "Sat": return 6;
		case "Sun": return 7;
		default   : return 0;
	}
}

convertTime(s)
{
	str = "";
	for(i = 0; i < s.size; i++)
		if(isSubStr("0123456789", s[i])) str += s[i];
	return(str);
}

numToStr(number, length)
{
	string = "" + number;
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) string = dupChar("0", diff) + string;
	return(string);
}

dupChar(char, length)
{
	string = "";
	for(i = 0; i < length; i++) string = string + char;
	return(string);
}
