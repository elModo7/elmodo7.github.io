
GetPlainMapRotation(include_stacker)
{
	if(!isDefined(include_stacker)) include_stacker = true;
	return GetMapRotation(false, false, include_stacker);
}

GetRandomMapRotation(include_stacker)
{
	if(!isDefined(include_stacker)) include_stacker = true;
	return GetMapRotation(true, false, include_stacker);
}

GetCurrentMapRotation()
{
	return GetMapRotation(false, true, false);
}

GetPlayerBasedMapRotation()
{
	return GetMapRotation(false, false, false);
}

GetRandomPlayerBasedMapRotation()
{
	return GetMapRotation(true, false, false);
}

GetMapRotation(random, current, include_stacker)
{
	maprot = "";

	if(current) maprot = getcvar("sv_maprotationcurrent");

	if(maprot == "")
	{
		if(level.ex_pbrotate || level.ex_mapvotemode == 2 || level.ex_mapvotemode == 3)
		{
			players = level.players;
			if(players.size >= level.ex_mapsizing_large) maprot = getcvar("scr_large_rotation");
				else if(players.size >= level.ex_mapsizing_medium) maprot = getcvar("scr_med_rotation");
					else maprot = getcvar("scr_small_rotation");
		}
		else
		{
			if(include_stacker) maprot = extreme\_ex_maps::reconstructMapRotation();
				else maprot = getcvar("sv_maprotation");
		}
	}

	maps = rotationStringToArray(maprot, random);
	return(maps);
}

rotationStringToArray(maprot, random)
{
	maprot = trim(maprot);
	if(maprot == "") return( [] );

	temparr = strtok( maprot, " ");

	xmaps = [];
	lastexec = undefined;
	lastgt = getcvar("g_gametype");

	for(i = 0; i < temparr.size;)
	{
		switch(temparr[i])
		{
			case "exec":
				if(isdefined(temparr[i+1])) lastexec = temparr[i+1];
				i += 2;
				break;

			case "gametype":
				if(isdefined(temparr[i+1])) lastgt = temparr[i+1];
				i += 2;
				break;

			case "map":
				if(isdefined(temparr[i+1]))
				{
					xmaps[xmaps.size]["exec"] = lastexec;
					xmaps[xmaps.size-1]["gametype"] = lastgt;
					xmaps[xmaps.size-1]["map"] = temparr[i+1];
				}

				if(!random)
				{
					lastexec = undefined;
					lastgt = undefined;
				}

				i += 2;
				break;

			default:
				logprint("MAPROTATION ERROR: trying to fix unknown keyword " + temparr[i] + "\n");

				if(isGametype(temparr[i])) lastgt = temparr[i];
				else if(isConfig(temparr[i])) lastexec = temparr[i];
				else
				{
					xmaps[xmaps.size]["exec"] = lastexec;
					xmaps[xmaps.size-1]["gametype"]	= lastgt;
					xmaps[xmaps.size-1]["map"]	= temparr[i];
	
					if(!random)
					{
						lastexec = undefined;
						lastgt = undefined;
					}
				}

				i += 1;
				break;
		}
	}

	if(random)
	{
		for(k = 0; k < 20; k++)
		{
			for(i = 0; i < xmaps.size; i++)
			{
				j = randomInt(xmaps.size);
				element = xmaps[i];
				xmaps[i] = xmaps[j];
				xmaps[j] = element;
			}
		}
	}

	return xmaps;
}

pbRotation()
{
	if(!level.ex_pbrotate) return;

	doget = true;
	doset = true;
	if(getCvar("ex_maprotdone") == "")
	{
		if(level.ex_fixmaprotation)
		{
			checkrot = "scr_small_rotation";
			maps = rotationstringToArray(getcvar(checkrot), false);
			if(maps.size)
			{
				newmaprotation = "";
				for(i = 0; i < maps.size; i++)
				{
					if(isdefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
					if(isdefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
					newmaprotation += " map " + maps[i]["map"];
				}

				setCvar(checkrot, trim(newmaprotation));
			}

			checkrot = "scr_med_rotation";
			maps = rotationstringToArray(getcvar(checkrot), false);
			if(maps.size)
			{
				newmaprotation = "";
				for(i = 0; i < maps.size; i++)
				{
					if(isdefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
					if(isdefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
					newmaprotation += " map " + maps[i]["map"];
				}

				setCvar(checkrot, trim(newmaprotation));
			}

			checkrot = "scr_large_rotation";
			maps = rotationstringToArray(getcvar(checkrot), false);
			if(maps.size)
			{
				newmaprotation = "";
				for(i = 0; i < maps.size; i++)
				{
					if(isdefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
					if(isdefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
					newmaprotation += " map " + maps[i]["map"];
				}

				setCvar(checkrot, trim(newmaprotation));
			}

			level.ex_fixmaprotation = 0;
			setCvar("ex_fix_maprotation", "0");
		}

		doset = false;
		maprot = getcvar("sv_maprotation");
		smallrot = getcvar("scr_small_rotation");
		if(maprot != smallrot)
		{
			// if rotate-if-empty is enabled, make main rotation same as small rotation, so it will
			// start to rotate the correct maps after playing the very first map
			if(level.ex_rotateifempty)
			{
				setcvar("sv_maprotation", smallrot);
				setcvar("sv_maprotationcurrent", "");
			}
			doget = false;
		}
	}

	if(doget)
	{
		nextmap = pbNextMap();
		if(doset && nextmap != "") setcvar("sv_maprotationcurrent", nextmap);
	}
}

pbNextMap()
{
	psize = level.players.size;

	// for testing only
	//if(getCvar("ex_maprotdone") == "") psize = level.players.size;
	//	else psize = randomInt(32);

	if(psize >= 1) setCvar("ex_pbplayers", psize);
		else psize = getCvarInt("ex_pbplayers");

	if(psize >= level.ex_mapsizing_large)
	{
		map_rot_cur = "scr_large_rotation_current";
		map_rot = "scr_large_rotation";
	}
	else if(psize >= level.ex_mapsizing_medium)
	{
		map_rot_cur = "scr_med_rotation_current";
		map_rot = "scr_med_rotation";
	}
	else
	{
		map_rot_cur = "scr_small_rotation_current";
		map_rot = "scr_small_rotation";
	}
	
	cur_map_rot = getcvar(map_rot_cur);
	if(cur_map_rot == "" || cur_map_rot == " ")
	{
		setcvar(map_rot_cur, getcvar(map_rot) );
		cur_map_rot = getcvar(map_rot);
	}

	mapstring = "";
	maps = rotationstringToArray(cur_map_rot, false);
	if(maps.size)
	{
		if(isdefined(maps[0]["exec"])) mapstring += " exec " + maps[0]["exec"];
		if(isdefined(maps[0]["gametype"])) mapstring += " gametype " + maps[0]["gametype"];
		mapstring += " map " + maps[0]["map"];

		newcurrentstring = "";
		for(i = 1; i < maps.size; i++)
		{
			if(isdefined(maps[i]["exec"])) newcurrentstring += " exec " + maps[i]["exec"];
			if(isdefined(maps[i]["gametype"])) newcurrentstring += " gametype " + maps[i]["gametype"];
			newcurrentstring += " map " + maps[i]["map"];
		}

		if(newcurrentstring == "") setcvar(map_rot_cur, getcvar(map_rot) );
			else setcvar(map_rot_cur, trim(newcurrentstring));
	}

	return( trim(mapstring) );
}

fixMapRotation()
{
	if(getcvar("sv_maprotation1") != "") return;

	maps = GetPlainMapRotation(false);
	if(!isdefined(maps) || !maps.size) return;

	newmaprotation = "";
	newmaprotationcurrent = "";
	for(i = 0; i < maps.size; i++)
	{
		if(!isdefined(maps[i]["exec"])) exec = "";
			else exec = " exec " + maps[i]["exec"];

		if(!isdefined(maps[i]["gametype"])) gametype = "";
			else gametype = " gametype " + maps[i]["gametype"];

		newmaprotation += exec + gametype + " map " + maps[i]["map"];
		if(i > 0) newmaprotationcurrent += exec + gametype + " map " + maps[i]["map"];
	}

	setCvar("sv_maprotation", trim(newmaprotation));
	setCvar("sv_maprotationcurrent", trim(newmaprotationcurrent));
	setCvar("ex_fix_maprotation", "0");
}

randomMapRotation()
{
	if(level.ex_randommaprotation == 2 || level.ex_mapvote) return;

	maps = GetRandomMapRotation(false);
	if(!isdefined(maps) || !maps.size) return;

	lastexec = "";
	lastgt = "";

	newmaprotation = "";
	for(i = 0; i < maps.size; i++)
	{
		if(!isdefined(maps[i]["exec"]) || lastexec == maps[i]["exec"]) exec = "";
		else
		{
			lastexec = maps[i]["exec"];
			exec = " exec " + maps[i]["exec"];
		}

		if(!isdefined(maps[i]["gametype"]) || lastgt == maps[i]["gametype"]) gametype = "";
		else
		{
			lastgt = maps[i]["gametype"];
			gametype = " gametype " + maps[i]["gametype"];
		}

		newmaprotation += exec + gametype + " map " + maps[i]["map"];
	}

	setCvar("sv_maprotationcurrent", trim(newmaprotation));
	setCvar("ex_random_maprotation", "2"); // do not set to 0; map rotation HUD message needs it
}

trim(s)
{
	if(s == "") return "";

	s2 = "";
	s3 = "";

	i = 0;
	while(i < s.size && s[i] == " ") i++;

	// String is just blanks?
	if(i == s.size) return "";
	
	for(; i < s.size; i++) s2 += s[i];

	i = s2.size - 1;
	while(s2[i] == " " && i > 0) i--;

	for(j = 0; j <= i; j++) s3 += s2[j];
		
	return s3;
}

isGametype(gt)
{
	switch(gt)
	{
		case "chq":
		case "cnq":
		case "ctf":
		case "ctfb":
		case "dm":
		case "dom":
		case "esd":
		case "ft":
		case "hm":
		case "hq":
		case "htf":
		case "ihtf":
		case "lib":
		case "lms":
		case "lts":
		case "ons":
		case "rbcnq":
		case "rbctf":
		case "sd":
		case "tdm":
		case "tkoth":
		case "vip":
			return true;

		default:
			return false;
	}
}

isConfig(cfg)
{
	temparr = explode(cfg, ".");
	if(temparr.size == 2 && temparr[1] == "cfg") return true;
		else return false;
}

explode(s, delimiter)
{
	j = 0;
	temparr[j] = "";	

	for(i = 0; i < s.size; i++)
	{
		if(s[i] == delimiter)
		{
			j++;
			temparr[j] = "";
		}
		else temparr[j] += s[i];
	}

	return temparr;
}
