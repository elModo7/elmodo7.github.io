
log(line1, line2, line3, line4, line5, line5)
{
	if(level.ex_logextreme)
	{
		if(isDefined(line1)) logPrint("eXtreme-LOG: " + line1 + "\n");
		if(isDefined(line2)) logPrint("eXtreme-LOG: " + line2 + "\n");
		if(isDefined(line3)) logPrint("eXtreme-LOG: " + line3 + "\n");
		if(isDefined(line4)) logPrint("eXtreme-LOG: " + line4 + "\n");
		if(isDefined(line5)) logPrint("eXtreme-LOG: " + line5 + "\n");
	}
}

cvardef(varname, vardefault, min, max, type)
{
	basevar = varname;
	mapname = getcvar("mapname");
	gametype = getcvar("g_gametype");
	multigtmap = gametype + "_" + mapname;

	// check against gametype
	tempvar = basevar + "_" + gametype;
	if(getcvar(tempvar) != "") varname = tempvar;

	// check against the map name
	tempvar = basevar + "_" + mapname;
	if(getcvar(tempvar) != "") varname = tempvar;

	// check against the gametype and the map name
	tempvar = basevar + "_" + multigtmap;
	if(getcvar(tempvar) != "") varname = tempvar;

	// get the variable's definition
	switch(type)
	{
		case "int":
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getcvarint(varname);
			break;
		case "float":
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getcvarfloat(varname);
			break;
		case "string":
		default:
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getcvar(varname);
			break;
	}

	// check to see if the value is within the min & max parameters
	if(type != "string")
	{
		if(min != 0 && definition < min) definition = min;
			else if(max != 0 && definition > max) definition = max;
	}

	return definition;
}

vectorMulti(vec, size)
{
	x = vec[0] * size;
	y = vec[1] * size;
	z = vec[2] * size;
	vec = (x,y,z);
	return vec;
}

punishment(weaponstatus, movestatus)
{
	if(!isDefined(weaponstatus)) weaponstatus = "keep";

	if(!isDefined(movestatus)) movestatus = "same";

	if(isDefined(self.ex_lock))
	{
		self unlink();
		self.ex_lock delete();
	}

	if(weaponstatus == "disable") self [[level.ex_dWeapon]]();
	else if(weaponstatus == "random" && randomInt(100) < 50)
	{
		if(randomInt(100) < 50)
		{
			self.ex_hasnoweapon = true;
			self [[level.ex_dWeapon]]();
		}
		else self extreme\_ex_weapons::dropcurrentweapon();
	}
	else if(weaponstatus == "drop") self extreme\_ex_weapons::dropcurrentweapon();
	else if(weaponstatus == "enable")
	{
		self [[level.ex_eWeapon]]();
		self.ex_hasnoweapon = false;
	}

	if(movestatus == "freeze")
	{
		// spawn a script origin, and lock the players in place and disable weapon
		self.ex_lock = spawn("script_origin", self.origin);
		self linkTo(self.ex_lock);
	}
	else if(movestatus == "release" && isDefined(self.ex_lock))
	{
		self unlink();
		self.ex_lock delete();
	}		
}

playSoundLoc(sound, position, special)
{
	if(!isDefined(position))
		position = game["playArea_Centre"];
	
	soundloc = spawn( "script_model", position);
	wait( [[level.ex_fpstime]](0.05) );
	soundloc show();

	if(!isDefined(special)) soundloc playSound(sound);
	else
	{
		if(isPlayer(self) && special == "death")
		{
			if(level.ex_diana && isDefined(self.pers["diana"]))
			{
				soundloc playsound(sound + "_russianfem_" + (randomInt(level.ex_voices["diana"])+1) );
			}
			else
			{
				if(self.pers["team"] == "allies") soundloc playsound(sound + "_" + game["allies"] + "_" + (randomInt(level.ex_voices[game["allies"]])+1) );
				else soundloc playsound(sound + "_german_" + (randomInt(level.ex_voices["german"])+1) );
			}
		}
	}

	wait( [[level.ex_fpstime]](5) );
	soundloc delete();
}

playSoundOnPlayer(sound, special)
{
	self endon("kill_thread");

	self notify("ex_soplayer");
	self endon("ex_soplayer");

	if(!isDefined(special)) self playsound(sound);
	else
	{
		if(isPlayer(self) && special == "pain")
		{
			if(level.ex_diana && isDefined(self.pers["diana"]))
			{
				self playsound(sound + "_russianfem_" + (randomInt(level.ex_voices["diana"])+1) );
			}
			else
			{
				if(self.pers["team"] == "allies") self playsound(sound + "_" + game["allies"] + "_" + (randomInt(level.ex_voices[game["allies"]])+1) );
				else self playsound(sound + "_german_" + (randomInt(level.ex_voices["german"])+1) );
			}
		}
	}
}

playSoundOnPlayers(sound, team, spectators)
{
	if(!isDefined(spectators)) spectators = true;

	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			wait( [[level.ex_fpstime]](0.01) );

			if(isPlayer(players[i]) && isDefined(players[i].pers) && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team)
			{
				if(spectators) players[i] playLocalSound(sound);
				else if(players[i].sessionstate != "spectator") players[i] playLocalSound(sound);
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
		{
			wait( [[level.ex_fpstime]](0.01) );

			if(isPlayer(players[i]) && spectators) players[i] playLocalSound(sound);
			else if(isPlayer(players[i]) && isDefined(players[i].sessionstate) && players[i].sessionstate != "spectator") players[i] playLocalSound(sound);
		}
	}

	wait( [[level.ex_fpstime]](1) );
	level notify("psopdone");
}

ex_PrecacheShader(shader)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedshaders)) level.ex_precachedshaders = [];

	if(isInArray(level.ex_precachedshaders, shader)) return;

	level.ex_precachedshaders[level.ex_precachedshaders.size] = shader;
	precacheShader(shader);
}

ex_PrecacheHeadIcon(icon)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedheadicons)) level.ex_precachedheadicons = [];

	if(isInArray(level.ex_precachedheadicons, icon)) return;

	level.ex_precachedheadicons[level.ex_precachedheadicons.size] = icon;
	precacheHeadIcon(icon);
}

ex_PrecacheStatusIcon(icon)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedstatusicons)) level.ex_precachedstatusicons = [];

	if(isInArray(level.ex_precachedstatusicons, icon)) return;

	level.ex_precachedstatusicons[level.ex_precachedstatusicons.size] = icon;
	precacheStatusIcon(icon);
}

ex_PrecacheModel(model)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedmodels)) level.ex_precachedmodels = [];

	if(isInArray(level.ex_precachedmodels, model)) return;

	level.ex_precachedmodels[level.ex_precachedmodels.size] = model;
	precacheModel(model);
}

ex_PrecacheItem(item)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precacheditems)) level.ex_precacheditems = [];

	if(isInArray(level.ex_precacheditems, item)) return;

	level.ex_precacheditems[level.ex_precacheditems.size] = item;
	precacheItem(item);
}

ex_PrecacheString(element)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedstrings)) level.ex_precachedstrings = [];

	if(isInArray(level.ex_precachedstrings, element)) return;

	level.ex_precachedstrings[level.ex_precachedstrings.size] = element;
	precacheString(element);
}

ex_PrecacheMenuItem(menutype)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedmenuitem)) level.ex_precachedmenuitem = [];

	if(isInArray(level.ex_precachedmenuitem, menutype)) return;

	level.ex_precachedmenuitem[level.ex_precachedmenuitem.size] = menutype;
	precacheMenu(menutype);
}

ex_PrecacheShellShock(shocktype)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(level.ex_precachedshellshock)) level.ex_precachedshellshock = [];

	if(isInArray(level.ex_precachedshellshock, shocktype)) return;

	level.ex_precachedshellshock[level.ex_precachedshellshock.size] = shocktype;
	precacheShellShock(shocktype);
}

isInArray(array, element)
{
	if(!isDefined(array) || !array.size) return false;

	i = 0;
	while(i < array.size)
	{
		if(array[i] == element) return true;
		i++;
	}
	return false;
}

monotone( str )
{
	if ( !isDefined( str ) || ( str == "" ) )
		return ( "" );

	_s = "";

	_colorCheck = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( _colorCheck )
		{
			_colorCheck = false;

			switch ( ch )
			{
			  case "0":	// black
			  case "1":	// red
			  case "2":	// green
			  case "3":	// yellow
			  case "4":	// blue
			  case "5":	// cyan
			  case "6":	// pink
			  case "7":	// white
			  case "8":	// Olive
			  case "9":	// Grey
			  	break;
			  default:
			  	_s += ( "^" + ch );
			  	break;
			}
		}
		else if ( ch == "^" )
			_colorCheck = true;
		else
			_s += ch;
	}
	return ( _s );
}

isOutside(origin)
{
	if(!isDefined(origin)) return false;

	trace = bulletTrace(origin, origin+ (0,0,6000), false, false);

	if(distance(origin, trace["position"]) >= 1000) return true;
	else return false;
}

saveHeadIcon()
{
	if(isDefined(self.headicon)) self.oldheadicon = self.headicon;

	if(isDefined(self.headiconteam)) self.oldheadiconteam = self.headiconteam;
}

restoreHeadicon(oldicon)
{
	self endon("kill_thread");

	if(level.drawfriend && level.ex_teamplay && self.pers["team"] != "spectator")
	{
		if(level.ex_ranksystem)
		{
			self.headicon = self thread extreme\_ex_ranksystem::getHeadIcon();
		}
		else
		{
			headicon = "headicon_" + self.pers["team"];
			self.headicon = game[headicon];
		}
	
		if(isDefined(self.sessionteam) && self.sessionteam != "spectator") self.headiconteam = self.sessionteam;
			else self.headiconteam = self.pers["team"];
	}
	else self.headicon = "";
	
	if(isDefined(self.oldheadicon) && isDefined(oldicon))
	{
		if(self.oldheadicon == oldicon) self.oldheadicon = self.headicon;
	}
	else
	{
		if(isDefined(self.oldheadicon)) self.headicon = self.oldheadicon;
		if(isDefined(self.oldheadiconteam)) self.headiconteam = self.oldheadiconteam;
	}		
}

ex_hud_announce(message)
{
	self endon("kill_thread");
	self endon("kill_hud_announce");

	if(!isDefined(message)) return;
	if(!isDefined(self.ex_hud_announce)) self.ex_hud_announce = [];
	if(!isDefined(self.ex_hud_allocating)) self.ex_hud_allocating = false;

	while(self.ex_hud_allocating) wait( [[level.ex_fpstime]](0.1) );
	self.ex_hud_allocating = true;

	free_hud = ex_hud_getfree();
	while(free_hud == -1)
	{
		wait( [[level.ex_fpstime]](1) );
		free_hud = ex_hud_getfree();
	}

	for(i = 0; i < self.ex_hud_announce.size; i++)
	{
		if(isDefined(self.ex_hud_announce[i].hudelem))
		{
			self.ex_hud_announce[i].hudelem moveOverTime(0.2);
			self.ex_hud_announce[i].hudelem.y = self.ex_hud_announce[i].hudelem.y - 15;
		}
	}

	wait( [[level.ex_fpstime]](0.1) );
	self.ex_hud_allocating = false;
	self.ex_hud_announce[free_hud].message = message;
	self.ex_hud_announce[free_hud].status = 1; // on screen

	self.ex_hud_announce[free_hud].hudelem = newClientHudElem(self);
	self.ex_hud_announce[free_hud].hudelem.archived = false;
	self.ex_hud_announce[free_hud].hudelem.horzAlign = "fullscreen";
	self.ex_hud_announce[free_hud].hudelem.vertAlign = "fullscreen";
	self.ex_hud_announce[free_hud].hudelem.alignX = "center";
	self.ex_hud_announce[free_hud].hudelem.alignY = "middle";
	self.ex_hud_announce[free_hud].hudelem.x = 320;
	self.ex_hud_announce[free_hud].hudelem.y = 70;
	self.ex_hud_announce[free_hud].hudelem.alpha = 0;
	self.ex_hud_announce[free_hud].hudelem.fontscale = 1.1;
	self.ex_hud_announce[free_hud].hudelem settext(self.ex_hud_announce[free_hud].message);
	self.ex_hud_announce[free_hud].hudelem fadeOverTime(0.5);
	self.ex_hud_announce[free_hud].hudelem.alpha = 1;
	wait( [[level.ex_fpstime]](7) );
	if(isDefined(self.ex_hud_announce[free_hud].hudelem))
	{
		self.ex_hud_announce[free_hud].hudelem fadeOverTime(0.5);
		self.ex_hud_announce[free_hud].hudelem.alpha = 0;
		wait( [[level.ex_fpstime]](0.5) );
	}
	if(isDefined(self.ex_hud_announce[free_hud].hudelem))
		self.ex_hud_announce[free_hud].hudelem destroy();

	self.ex_hud_announce[free_hud].status = 0; // free slot
	self.ex_hud_announce[free_hud].message = undefined;
}

ex_hud_getfree()
{
	self endon("kill_thread");
	self endon("kill_hud_announce");

	for(i = 0; i < 3; i++)
	{
		if(isDefined(self.ex_hud_announce[i]))
		{
			if(self.ex_hud_announce[i].status == 0) return i; // free slot
		}
		else
		{
			self.ex_hud_announce[i] = spawnstruct();
			return i; // unallocated slot
		}
	}
	return -1; // all slots in use
}

time_convert(value)
{
	switch(value)
	{
		case 1: return &"TIME_1_SECOND";
		case 2: return &"TIME_2_SECONDS";
		case 3: return &"TIME_3_SECONDS";
		case 4: return &"TIME_4_SECONDS";
		case 5: return &"TIME_5_SECONDS";
		case 6: return &"TIME_6_SECONDS";
		case 7: return &"TIME_7_SECONDS";
		case 8: return &"TIME_8_SECONDS";
		case 9: return &"TIME_9_SECONDS";
		case 10: return &"TIME_10_SECONDS";

		case 11: return &"TIME_11_SECONDS";
		case 12: return &"TIME_12_SECONDS";
		case 13: return &"TIME_13_SECONDS";
		case 14: return &"TIME_14_SECONDS";
		case 15: return &"TIME_15_SECONDS";
		case 16: return &"TIME_16_SECONDS";
		case 17: return &"TIME_17_SECONDS";
		case 18: return &"TIME_18_SECONDS";
		case 19: return &"TIME_19_SECONDS";
		case 20: return &"TIME_20_SECONDS";
		
		case 21: return &"TIME_21_SECONDS";
		case 22: return &"TIME_22_SECONDS";
		case 23: return &"TIME_23_SECONDS";
		case 24: return &"TIME_24_SECONDS";
		case 25: return &"TIME_25_SECONDS";
		case 26: return &"TIME_26_SECONDS";
		case 27: return &"TIME_27_SECONDS";
		case 28: return &"TIME_28_SECONDS";
		case 29: return &"TIME_29_SECONDS";
		case 30: return &"TIME_30_SECONDS";

		case 31: return &"TIME_31_SECONDS";
		case 32: return &"TIME_32_SECONDS";
		case 33: return &"TIME_33_SECONDS";
		case 34: return &"TIME_34_SECONDS";
		case 35: return &"TIME_35_SECONDS";
		case 36: return &"TIME_36_SECONDS";
		case 37: return &"TIME_37_SECONDS";
		case 38: return &"TIME_38_SECONDS";
		case 39: return &"TIME_39_SECONDS";
		case 40: return &"TIME_40_SECONDS";

		case 41: return &"TIME_41_SECONDS";
		case 42: return &"TIME_42_SECONDS";
		case 43: return &"TIME_43_SECONDS";
		case 44: return &"TIME_44_SECONDS";
		case 45: return &"TIME_45_SECONDS";
		case 46: return &"TIME_46_SECONDS";
		case 47: return &"TIME_47_SECONDS";
		case 48: return &"TIME_48_SECONDS";
		case 49: return &"TIME_49_SECONDS";
		case 50: return &"TIME_50_SECONDS";

		case 51: return &"TIME_51_SECONDS";
		case 52: return &"TIME_52_SECONDS";
		case 53: return &"TIME_53_SECONDS";
		case 54: return &"TIME_54_SECONDS";
		case 55: return &"TIME_55_SECONDS";
		case 56: return &"TIME_56_SECONDS";
		case 57: return &"TIME_57_SECONDS";
		case 58: return &"TIME_58_SECONDS";
		case 59: return &"TIME_59_SECONDS";
		case 60: return &"TIME_60_SECONDS";
	}
}

GetMapDim(debug)
{
	if(!isDefined(debug)) debug = false;

	mark = getTime();

	xMin = 20000;
	xMax = -20000;
	yMin = 20000;
	yMax = -20000;
	zMin = 20000;
	zMax = -20000;
	zSky = -20000;

	entitytypes = [];
	entitytypes[entitytypes.size] = "mp_dm_spawn";
	entitytypes[entitytypes.size] = "mp_tdm_spawn";
	entitytypes[entitytypes.size] = "mp_ctf_spawn_allied";
	entitytypes[entitytypes.size] = "mp_ctf_spawn_axis";
	entitytypes[entitytypes.size] = "mp_sd_spawn_attacker";
	entitytypes[entitytypes.size] = "mp_sd_spawn_defender";

	// get min and max values for x, y and z for all common spawnpoints
	for(e = 0; e < entitytypes.size; e++)
	{
		entities = getentarray(entitytypes[e], "classname");

		for(i = 0; i < entities.size; i++)
		{
			if(isdefined(entities[i].origin))
			{
				origin = entities[i].origin;

				if(origin[0] < xMin) xMin = origin[0];
				if(origin[0] > xMax) xMax = origin[0];
				if(origin[1] < yMin) yMin = origin[1];
				if(origin[1] > yMax) yMax = origin[1];
				if(origin[2] < zMin) zMin = origin[2];
				if(origin[2] > zMax) zMax = origin[2];
				if(zMax > zSky) zSky = zMax;

				trace = bulletTrace(origin, origin + (0,0,20000), false, undefined);
				if(trace["fraction"] != 1 && trace["position"][2] > zSky)
				{
					if(trace["position"][2] < 6000) zSky = trace["position"][2];
						else if(zSky != 6000) zSky = 6000;
				}
			}

			if(i % 100 == 0) wait( [[level.ex_fpstime]](0.01) );
		}
	}

	// set the play area variables
	game["playArea_CentreX"] = int( (xMax + xMin) / 2 );
	game["playArea_CentreY"] = int( (yMax + yMin) / 2 );
	game["playArea_CentreZ"] = int( (zMax + zMin) / 2 );
	game["playArea_Centre"] = (game["playArea_CentreX"], game["playArea_CentreY"], game["playArea_CentreZ"]);

	game["playArea_Min"] = (xMin, yMin, zMin);
	game["playArea_Max"] = (xMax, yMax, zMax);

	game["playArea_Width"] = int(distance((xMin, yMin, 800),(xMax, yMin, 800)));
	game["playArea_Length"] = int(distance((xMin, yMin, 800),(xMin, yMax, 800)));

	// get centre map origin, just below skylimit
	origin = (game["playArea_CentreX"], game["playArea_CentreY"], zSky - 200);

	// get min and max values for x and y for map area
	trace = bulletTrace(origin, origin - (20000,0,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][0] < xMin) xMin = trace["position"][0];

	trace = bulletTrace(origin, origin + (20000,0,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][0] > xMax) xMax = trace["position"][0];

	trace = bulletTrace(origin, origin - (0,20000,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][1] < yMin) yMin = trace["position"][1];

	trace = bulletTrace(origin, origin + (0,20000,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][1] > yMax) yMax = trace["position"][1];

	// set the map area variables
	game["mapArea_CentreX"] = int( (xMax + xMin) / 2 );
	game["mapArea_CentreY"] = int( (yMax + yMin) / 2 );
	game["mapArea_CentreZ"] = int( (zSky + zMin) / 2 );
	game["mapArea_Centre"] = (game["mapArea_CentreX"], game["mapArea_CentreY"], game["mapArea_CentreZ"]);

	game["mapArea_Max"] = (xMax, yMax, zSky);
	game["mapArea_Min"] = (xMin, yMin, zMin);

	game["mapArea_Width"] = int(distance((xMin, yMin, zSky),(xMax, yMin, zSky)));
	game["mapArea_Length"] = int(distance((xMin, yMin, zSky),(xMin, yMax, zSky)));

	if(debug)
	{
		took = (getTime() - mark) / 1000;
		logprint("DEBUG: getMapDim took " + took + " seconds\n");

		ne = (game["mapArea_Max"][0] - 200,game["mapArea_Min"][1] - 200,game["mapArea_Max"][2] - 200);
		se = (game["mapArea_Min"][0] - 200,game["mapArea_Min"][1] - 200,game["mapArea_Max"][2] - 200);
		sw = (game["mapArea_Min"][0] - 200,game["mapArea_Max"][1] - 200,game["mapArea_Max"][2] - 200);
		nw = (game["mapArea_Max"][0] - 200,game["mapArea_Max"][1] - 200,game["mapArea_Max"][2] - 200);
		logprint("DEBUG: ne=" + ne + ", se=" + se + ", sw=" + sw + ", nw=" + nw + ", mapheight=" + game["mapArea_Max"][2] + "\n");
		thread dropLine(ne, se, (1,0,0), true);
		thread dropLine(se, sw, (1,0,0), true);
		thread dropLine(sw, nw, (1,0,0), true);
		thread dropLine(nw, ne, (1,0,0), true);

		ne = (game["playArea_Max"][0],game["playArea_Min"][1],game["mapArea_Max"][2] - 200);
		se = (game["playArea_Min"][0],game["playArea_Min"][1],game["mapArea_Max"][2] - 200);
		sw = (game["playArea_Min"][0],game["playArea_Max"][1],game["mapArea_Max"][2] - 200);
		nw = (game["playArea_Max"][0],game["playArea_Max"][1],game["mapArea_Max"][2] - 200);
		logprint("DEBUG: ne=" + ne + ", se=" + se + ", sw=" + sw + ", nw=" + nw + ", playheight=" + game["playArea_Max"][2] + "\n");
		thread dropLine(ne, se, (1,0,0), true);
		thread dropLine(se, sw, (1,0,0), true);
		thread dropLine(sw, nw, (1,0,0), true);
		thread dropLine(nw, ne, (1,0,0), true);

		logprint("DEBUG: game[\"playArea_CentreX\"] = " + game["playArea_CentreX"] + "\n");
		logprint("DEBUG: game[\"playArea_CentreY\"] = " + game["playArea_CentreY"] + "\n");
		logprint("DEBUG: game[\"playArea_CentreZ\"] = " + game["playArea_CentreZ"] + "\n");
		logprint("DEBUG: game[\"playArea_Centre\"] = " + game["playArea_Centre"] + "\n");
		logprint("DEBUG: game[\"playArea_Max\"] = " + game["playArea_Max"] + "\n");
		logprint("DEBUG: game[\"playArea_Min\"] = " + game["playArea_Min"] + "\n");
		logprint("DEBUG: game[\"playArea_Width\"] = " + game["playArea_Width"] + "\n");
		logprint("DEBUG: game[\"playArea_Length\"] = " + game["playArea_Length"] + "\n");

		logprint("DEBUG: game[\"mapArea_CentreX\"] = " + game["mapArea_CentreX"] + "\n");
		logprint("DEBUG: game[\"mapArea_CentreY\"] = " + game["mapArea_CentreY"] + "\n");
		logprint("DEBUG: game[\"mapArea_CentreZ\"] = " + game["mapArea_CentreZ"] + "\n");
		logprint("DEBUG: game[\"mapArea_Centre\"] = " + game["mapArea_Centre"] + "\n");
		logprint("DEBUG: game[\"mapArea_Max\"] = " + game["mapArea_Max"] + "\n");
		logprint("DEBUG: game[\"mapArea_Min\"] = " + game["mapArea_Min"] + "\n");
		logprint("DEBUG: game[\"mapArea_Width\"] = " + game["mapArea_Width"] + "\n");
		logprint("DEBUG: game[\"mapArea_Length\"] = " + game["mapArea_Length"] + "\n");
	}

	entities = [];
	entities = undefined;
}

getStance(checkjump)
{
	if(isDefined(self.ex_newmodel)) return 0;

	if(checkjump && !self isOnGround()) return 3; // jumping

	if(isDefined(self.ex_spinemarker))
	{
		dist = self.ex_spinemarker.origin[2] - self.origin[2];
		if(dist < level.ex_tune_prone) return 2; // prone
		else if(dist < level.ex_tune_crouch) return 1; // crouch
		else return 0; // standing
	}
	else return 0;
}

getMax( a, b, c, d )
{
	if( a > b ) ab = a;
	else ab = b;

	if( c > d ) cd = c;
	else cd = d;

	if( ab > cd ) m = ab;
	else m = cd;

	return m;
}

bounceObject(vRotation, vVelocity, vOffset, angles, radius, falloff, bouncesound, bouncefx, objecttype)
{
	level endon("ex_gameover");
	self endon("ex_bounceobject");

	if(!isDefined(objecttype)) return;

	self thread putinQ(objecttype);

	// Setup default values
	if(!isDefined(vRotation))	vRotation = (0,0,0);
	pitch = vRotation[0] * 0.05; // Pitch/frame
	yaw = vRotation[1] * 0.05; // Yaw/frame
	roll = vRotation[2] * 0.05; // Roll/frame

	if(!isDefined(vVelocity))	vVelocity = (0,0,0);
	if(!isDefined(vOffset)) vOffset = (0,0,0);
	if(!isDefined(falloff)) falloff = 0.5;

	if(isDefined(level.ex_gravity)) gravity = level.ex_gravity;
	else gravity = 100;

	// Set gravity
	vGravity = (0,0,-0.02 * gravity);

	check_notrace = 5;
	check_hitground = 0;
	check_runaway = 0;
	check_stopme = false;

	// Drop with gravity
	for(;;)
	{
		// Let gravity do, what gravity do best
		vVelocity += vGravity;

		if(!isDefined(self)) return;

		// Get destination origin
		neworigin = self.origin + vVelocity;

		// Check for impact, check for entities but not myself.
		if(!check_notrace)
		{
			trace = bulletTrace(self.origin, neworigin, false, undefined);
			if(trace["fraction"] != 1)	// Hit something
			{
				// Place object at impact point - radius
				distance = distance(self.origin, trace["position"]);
				if(distance)
				{
					fraction = (distance - radius) / distance;
					delta = trace["position"] - self.origin;
					delta2 = maps\mp\_utility::vectorScale(delta, fraction);
					neworigin = self.origin + delta2;
				}
				else neworigin = self.origin;

				// Play sound if defined
				if(isDefined(bouncesound)) self playSound(bouncesound + trace["surfacetype"]);

				// Test if we are hitting ground and if it's time to stop bouncing
				if(vVelocity[2] <= 0 && vVelocity[2] > -10) check_hitground++;
				if(check_hitground >= 5) check_stopme = true;

				// Test for runaway condition
				check_runaway++;
				if(check_runaway >= 10) check_stopme = true;

				// Time to stop
				if(check_stopme)
				{
					// Set origin to impactpoint
					self.origin = neworigin;
					return;
				}

				// Play effect if defined and it's a hard hit
				if(isDefined(bouncefx) && length(vVelocity) > 20) playfx(bouncefx, trace["position"]);

				// Decrease speed for each bounce.
				vSpeed = length(vVelocity) * falloff;

				// Calculate new direction (Thanks to Hellspawn this is finally done correctly)
				vNormal = trace["normal"];
				vDir = maps\mp\_utility::vectorScale(vectorNormalize( vVelocity ),-1);
				vNewDir = ( maps\mp\_utility::vectorScale(maps\mp\_utility::vectorScale(vNormal,2), vectorDot( vDir, vNormal )) ) - vDir;

				// Scale vector
				vVelocity = maps\mp\_utility::vectorScale(vNewDir, vSpeed);

				// Add a small random distortion
				//vVelocity += (randomFloat(1)-0.5, randomFloat(1)-0.5, randomFloat(1)-0.5);
			}
		}
		else check_notrace--;

		if(!isDefined(self)) return;
		self.origin = neworigin;

		// Rotate pitch
		a0 = self.angles[0] + pitch;
		while(a0 < 0) a0 += 360;
		while(a0 > 359) a0 -= 360;

		// Rotate yaw
		a1 = self.angles[1] + yaw;
		while(a1 < 0) a1 += 360;
		while(a1 > 359) a1 -= 360;

		// Rotate roll
		a2 = self.angles[2] + roll;
		while(a2 < 0) a2 += 360;
		while(a2 > 359) a2 -= 360;
		self.angles = (a0, a1, a2);

		// Wait one frame
		wait( [[level.ex_fpstime]](0.05) );
	}
}

putinQ(type)
{
	if(!isDefined(type)) self notify("ex_bounceobject");
	else
	{
		index = level.ex_objectQcurrent[type];
	
		level.ex_objectQcurrent[type]++;
	
		if(level.ex_objectQcurrent[type] >= level.ex_objectQsize[type]) level.ex_objectQcurrent[type] = 0;
	
		if(isDefined(level.ex_objectQ[type][index]))
		{
			level.ex_objectQ[type][index] notify("ex_bounceobject");
			wait( [[level.ex_fpstime]](0.05) );
			if(isDefined(level.ex_objectQ[type][index])) level.ex_objectQ[type][index] delete();
		}
		
		level.ex_objectQ[type][index] = self;
	}
}

hotSpot(position, radius, sMeansOfDeath, sWeapon)
{
	self endon("endhotspot");

	if(!isDefined(radius)) radius = 60; // 5ft

	for(;;)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isPlayer(players[i])) player = players[i];
			else continue;

			if(distance(position, player.origin) > radius) continue;
			else player thread [[level.callbackPlayerDamage]](self, self, 5, 1, sMeansOfDeath, sWeapon, undefined, (0,0,0), "none",0);
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
}

scriptedfxradiusdamage(eAttacker, vOffset, sMeansOfDeath, sWeapon, iRange, iMaxDamage, iMinDamage, effect, surfacetype, quake, entignore, zignore, special)
{
	level endon("ex_gameover");

	if(!isDefined(vOffset)) vOffset = (0,0,0);
	if(!isDefined(entignore)) entignore = true; // ignore giving damage to non player entities
	if(!isDefined(zignore)) zignore = false;
	if(!isDefined(special)) special = "false";
	
	iDFlags = 1;

	// set default to dirt or snow on winter maps
	if(level.ex_wintermap) surfacefx = "snow";
		else surfacefx = "dirt";

	if(isDefined(effect) && effect != "none")
	{
		if(isDefined(surfacetype))
		{
			switch(surfacetype)
			{
				case "beach":
				case "sand":
				surfacefx = "beach";
				break;
		
				case "asphalt":
				case "metal":
				case "rock":
				case "gravel":
				case "plaster":
				case "default":
				surfacefx = "concrete";
				break;
		
				case "mud":
				surfacefx = "mud";
				break;

				case "dirt":
				case "grass":
				surfacefx = "dirt";
				break;
		
				case "snow":
				case "ice":
				surfacefx = "snow";
				break;
		
				case "wood":
				case "bark":
				surfacefx = "wood";
				break;
		
				case "water":
				surfacefx = "water";
				break;
			}
		}

		// play the fx
		if(effect == "generic") playfx(level.ex_effect["explosion_" + surfacefx], self.origin);
			else if(special == "false") playfx(level.ex_effect[effect], self.origin);

		// napalm fx
		if(special == "napalm" && sWeapon == "planebomb_mp")
		{
			playfx(level.ex_effect["napalm_bomb"], self.origin);
			wait( [[level.ex_fpstime]](0.25) );
			playfx(level.ex_effect["bodygroundfire"], self.origin);
		}

		if(level.ex_wintermap && sWeapon == "planebomb_mp") thread sciptedfxdelay("explosion_snow", 1.5, self.origin);
	}
	
	if(quake)
	{
		// * Earthquake *
		peqs = randomInt(100);
		strength = 0.5 + 0.5 * peqs /100;
		length = 1 + 3*peqs/100;;
		range = iRange + iRange * peqs/100;
		earthquake(strength, length, self.origin, range);		
	}
	
	if(iMaxDamage == 0 && iMinDamage == 0) return;
	
	// Loop through players and cause damage
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]))
		{			
			// Check that player is in range
			distance = distance((self.origin + vOffset), players[i].origin);
			//zdistance = distance((0,0, self.origin[2]), (0,0, players[i].origin[2]));
				
			if(distance >= iRange || players[i].sessionstate != "playing" || !isAlive(players[i])) continue;

			if(isDefined(players[i].ex_bubble_protected)) continue;

			if(special == "nuke" &&
			  (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == players[i]) ||
				(level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == players[i]) ) continue;

			// ignore if above 5' height
			//if(zignore && distance < iRange && zdistance > 60) continue;
			
			// if player is inside, no damage
			//if(!extreme\_ex_utils::isOutside(players[i].origin)) continue;

			if(players[i] != self)
			{
				//logprint("RADIUS DAMAGE DEBUG: player " + players[i].name + " damage before range check: " + iMaxDamage + "\n");

				percent = (iRange - distance) / iRange;
				iDamage = (iMinDamage + (iMaxDamage - iMinDamage)) * percent;
	
				//logprint("RADIUS DAMAGE DEBUG: player " + players[i].name + " distance " + distance + " within range " + iRange + " is " + percent + "%\n");
				//logprint("RADIUS DAMAGE DEBUG: player " + players[i].name + " damage before trace: " + iDamage + "\n");

				offset = 0;
				stance = players[i] [[level.ex_getStance]](false);
				switch(stance)
				{
					case 2:	offset = (0,0,5);	break;
					case 1:	offset = (0,0,35);	break;
					case 0:	offset = (0,0,55);	break;
				}

				traceorigin = players[i].origin + offset;
				vDir = vectorNormalize(traceorigin - (self.origin + vOffset));

				if(special != "nuke")
				{
					if(isPlayer(self)) trace = bullettrace(self.origin + vOffset, traceorigin, true, self);
						else trace = bullettrace(self.origin + vOffset, traceorigin, true, eAttacker);

					if(trace["fraction"] != 1 && isDefined(trace["entity"]))
					{
						if(isPlayer(trace["entity"]) && trace["entity"] != players[i] && trace["entity"] != eAttacker)
						{
							iDamage = iDamage * .5;	// Damage blocked by other player, remove 50%
							//logprint("RADIUS DAMAGE DEBUG: player " + players[i].name + " damage after trace: " + iDamage + " (obstructed by player " + trace["entity"].name + ")\n");
						}
					}
					else
					{
						trace = bulletTrace(self.origin + vOffset, traceorigin, false, undefined);
						if(trace["fraction"] != 1 && trace["surfacetype"] != "default")
						{
							iDamage = iDamage * .2;	// Damage blocked by other entities, remove 80%
							//logprint("RADIUS DAMAGE DEBUG: player " + players[i].name + " damage after trace: " + iDamage + " (obstructed by entity)\n");
						}
					}
				}
			}
			else
			{
				iDamage = iMaxDamage;
				vDir = (0,0,1);
			}

			if(special == "napalm") players[i] thread napalmDamage(eAttacker);
			else
			{
				if(isPlayer(eAttacker) && eAttacker != players[i] && special == "kamikaze" && iDamage >= players[i].health)
				{
					if(!isDefined(eAttacker.kamikaze_victims)) eAttacker.kamikaze_victims = 0;
					eAttacker.kamikaze_victims++;
				}
				//logprint("RADIUS DAMAGE DEBUG: player " + eAttacker.name + " causing " + iDamage + " damage to player " + players[i].name + "\n");
				players[i] thread [[level.callbackPlayerDamage]](self, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, undefined, vDir, "none", 0);
			}
		}
	}

	if(entignore) return;

	// Loop through entities except players and cause damage
	entities = getentarray();
	for(i=0;i<entities.size;i++)
	{
		// Is it defined and not a player?
		if(isDefined(entities[i]) && !isPlayer(entities[i]))
		{
			// Check that entity is in range
			distance = distance((self.origin + vOffset), entities[i].origin);

			if(distance <= iRange)
			{	
				// Calculate damage
				if(entities[i] != self)
				{
					// bullet trace
					traceorigin = entities[i].origin;
					trace = bullettrace(self.origin + vOffset, traceorigin, true, self);
						
					// Nothing blocked the damage
					if(isDefined(trace["entity"]) && trace["entity"] == entities[i])
					{
						// get new distance and new damage position if we hit the entity directly
						pos = trace["position"];
			
						distance = distance((self.origin + vOffset), pos);
							
						// Calculate damage falloff
						percent = (iRange-distance)/iRange;
						iDamage = iMinDamage + (iMaxDamage - iMinDamage)*percent;
			
						// Cause a small radiusdamage
						if(iDamage > 0)
						{
							// Do radius damage at traced point
							if(isDefined(entities[i].health)) oldhealth = entities[i].health;
							radiusDamage(pos, 5, iDamage, iDamage, eAttacker, self);
						}
					}
					else  // Something blocked the damage
					{
						distance = distance((self.origin + vOffset), entities[i].origin);
			
						// Calculate damage falloff
						percent = (iRange-distance)/iRange;
						iDamage = iMinDamage + (iMaxDamage - iMinDamage)*percent;
			
						if(isDefined(trace["entity"])) iDamage = iDamage * .6; // Damage blocked by entity, remove 40%
							else iDamage = iDamage * .2; // Damage blocked by other stuff(walls etc...), remove 80%
			
						// Cause a small radiusdamage
						if(iDamage > 0) radiusDamage(entities[i].origin, 5, iDamage, iDamage, eAttacker, self);
					}
				}
			}
		}
	}
}

sciptedfxdelay(effect, delay, pos)
{
	wait( [[level.ex_fpstime]](delay) );
	playfx(level.ex_effect[effect], pos);
}

strToInt(str)
{
	if(!isDefined(str) || !str.size) return(0);

	ctoi = [];
	ctoi["0"] = 0;
	ctoi["1"] = 1;
	ctoi["2"] = 2;
	ctoi["3"] = 3;
	ctoi["4"] = 4;
	ctoi["5"] = 5;
	ctoi["6"] = 6;
	ctoi["7"] = 7;
	ctoi["8"] = 8;
	ctoi["9"] = 9;

	val = 0;
	for(i = 0; i < str.size; i++)
	{
		switch(str[i])
		{
			case "0":
			case "1":
			case "2":
			case "3":
			case "4":
			case "5":
			case "6":
			case "7":
			case "8":
			case "9":
				val = val * 10 + ctoi[str[i]];
				break;
			default:
				return(0);
		}
	}

	return(val);
}

lowercase(str)
{
	return(convertChar(str, "U-L" ));
}

uppercase(str)
{
	return(convertChar(str, "L-U" ));
}

convertChar(str, conv)
{
	if(!isDefined(str) || str == "") return "";

	switch ( conv )
	{
		case "U-L":	case "U-l":	case "u-L":	case "u-l":
		from = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		to   = "abcdefghijklmnopqrstuvwxyz";
		break;

		case "L-U":	case "L-u":	case "l-U":	case "l-u":
		from = "abcdefghijklmnopqrstuvwxyz";
		to   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		break;

		default:
		return str;
	}

	string = "";

	for(i = 0; i < str.size; i++)
	{
		chr = str[i];

		for(j = 0; j < from.size; j++)
		{
			if(chr == from[j])
			{
				chr = to[j];
				break;
			}
		}

		string += chr;
	}

	return string;
}

justalphabet(str)
{
	if(!isDefined(str) || str == "") return "";

	uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	lowercase = "abcdefghijklmnopqrstuvwxyz";

	string = "";
	
	for(i = 0; i < str.size; i++)
	{
		chr = str[i];

		for(j = 0; j < uppercase.size; j++)
		{
			if(chr == uppercase[j]) string += uppercase[j];
			else if(chr == lowercase[j]) string += lowercase[j];
		}
	}

	return string;
}

friendlyInRange(range)
{
	if(!range) return true;

	// Get all players and pick out the ones that are playing and are in the same team
	rplayers = [];
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i]) && players[i].sessionstate == "playing" && players[i].pers["team"] == self.pers["team"])
				rplayers[rplayers.size] = players[i];
	}

	// Get the players that are in range
	sortedplayers = sortByDist(rplayers, self);

	// Need at least 2 players (myself + one team mate)
	if(sortedplayers.size < 2) return false;

	// First player will be myself so check against second player
	distance = distance(self.origin, sortedplayers[1].origin);

	if(distance <= range) return true;
	else return false;
}

friendlyInRangeView(range)
{
	if(!range) return false;

	targetpos = self getTargetPos(range);

	if(!isDefined(targetpos)) return false;

	// Get all players and pick out the ones that are playing and are in the same team
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(self) && isPlayer(players[i]))
		{
			if(players[i].sessionstate == "playing" && players[i].pers["team"] == self.pers["team"])
			{
				if(distance(targetPos, players[i].origin) <= range * 4)
					return players[i];
			}
		}
	}

	return false;
}

enemyInRange(range)
{
	if(!range) return true;

	// Get all players and pick out the ones that are playing and are in the same team
	rplayers = [];
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i]) && players[i].sessionstate == "playing" && players[i].pers["team"] != self.pers["team"])
			rplayers[rplayers.size] = players[i];
	}

	// Get the players that are in range
	sortedplayers = sortByDist(rplayers, self);

	// Need at least 2 players (myself + one team mate)
	if(sortedplayers.size < 2) return false;

	// First player will be myself so check against second player
	distance = distance(self.origin, sortedplayers[1].origin);

	self.ex_targetwarn = sortedplayers[1];

	if(distance <= range) return true;
	else return false;
}

enemyInRangeView(range)
{
	if(!range) return false;

	targetpos = self getTargetPos(range);

	if(!isDefined(targetpos)) return false;

	// Get all players and pick out the ones that are playing and are in the same team
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(self) && isPlayer(players[i]))
		{
			if(players[i].sessionstate == "playing" && players[i].pers["team"] != self.pers["team"])
			{
				if(distance(targetPos, players[i].origin) <= range * 4)
					return players[i];
			}
		}
	}

	return false;
}

getTargetPos(range)
{
	startOrigin = self.origin;
	forward = anglesToForward( self getplayerangles() );
	forward = [[level.ex_vectorscale]]( forward, range * 5);
	endOrigin = startOrigin + forward;
	return endOrigin;
}

sortByDist(points, startpoint, maxdist, mindist)
{
	if(!isDefined(points)) return undefined;
	if(!isDefined(startpoint)) return undefined;

	if(!isDefined(mindist)) mindist = -1000000;
	if(!isDefined(maxdist)) maxdist = 1000000; // almost 16 miles, should cover everything.

	sortedpoints = [];

	max = points.size-1;
	for(i = 0; i < max; i++)
	{
		nextdist = 1000000;
		next = undefined;

		for(j = 0; j < points.size; j++)
		{
			thisdist = distance(startpoint.origin, points[j].origin);
			if(thisdist <= nextdist && thisdist <= maxdist && thisdist >= mindist)
			{
				next = j;
				nextdist = thisdist;
			}
		}

		// didn't find one that fit the range, stop trying
		if(!isDefined(next)) break;

		sortedpoints[i] = points[next];

		// shorten the list, fewer compares
		points[next] = points[points.size-1]; // replace the closest point with the end of the list
		points[points.size-1] = undefined; // cut off the end of the list
	}

	sortedpoints[sortedpoints.size] = points[0]; // the last point in the list

	return sortedpoints;
}

printOnPlayersInRange(owner, msg1, msg2, targetpos)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if(player != owner && player.pers["team"] == owner.pers["team"] && isalive(player)) 
		{
			dist = distance( player.origin, targetpos );
				
			// only play the warning if they are close to the strike area
			if(dist < 1000)
			{
				player iprintlnbold(msg1, [[level.ex_pname]](owner));
				player iprintlnbold(msg2);
			}
		}
	}
}

// Strip blanks at start and end of string
strip(str)
{
	if(str=="") return "";

	str2="";
	str3="";

	i=0;
	while(i<str.size && str[i]==" ") i++;

	// String is just blanks?
	if(i==str.size) return "";
	
	for(;i<str.size;i++) str2 += str[i];

	i=str2.size-1;

	while(str2[i]==" " && i>0) i--;

	for(j=0;j<=i;j++) str3 += str2[j];
		
	return str3;
}

explode(str, delimiter)
{
	j = 0;
	temp_array[j] = "";	

	for(i = 0; i < str.size; i++)
	{
		if(str[i] == delimiter)
		{
			j++;
			temp_array[j] = "";
		}
		else temp_array[j] += str[i];
	}

	return temp_array;
}

convertMUJ(string)
{
	string = monotone(string);
	string = uppercase(string);
	string = justalphabet(string);
	return string;
}

convertMLJ(string)
{
	string = monotone(string);
	string = lowercase(string);
	string = justalphabet(string);
	return string;
}

weaponPause(time)
{
	self endon("kill_thread");

	self [[level.ex_dWeapon]]();
	wait( [[level.ex_fpstime]](time) );
	if(isPlayer(self)) self [[level.ex_eWeapon]]();
}

weaponWeaken(time)
{
	self endon("kill_thread");

	self.ex_weakenweapon = true;
	wait( [[level.ex_fpstime]](time) );
	if(isPlayer(self)) self.ex_weakenweapon = undefined;
}

createBarGraphic(barsize,bartime)
{
	self endon("kill_thread");

	cleanBarGraphic();
	
	// Background
	self.ex_pbbgrd = newClientHudElem(self);
	self.ex_pbbgrd.archived = false;
	self.ex_pbbgrd.horzAlign = "fullscreen";
	self.ex_pbbgrd.vertAlign = "fullscreen";
	self.ex_pbbgrd.alignX = "center";
	self.ex_pbbgrd.alignY = "middle";
	self.ex_pbbgrd.x = 320;
	self.ex_pbbgrd.y = 410;
	self.ex_pbbgrd.alpha = 0.5;
	self.ex_pbbgrd.color = (0,0,0);
	self.ex_pbbgrd setShader("white", (barsize + 4), 12);

	self.ex_pb = newClientHudElem(self);				
	self.ex_pb.archived = false;
	self.ex_pb.horzAlign = "fullscreen";
	self.ex_pb.vertAlign = "fullscreen";
	self.ex_pb.alignX = "left";
	self.ex_pb.alignY = "middle";
	self.ex_pb.x = (320 - (barsize / 2.0));
	self.ex_pb.y = 410;
	self.ex_pb setShader("white", 0, 8);
	self.ex_pb scaleOverTime(bartime , barsize, 8);
}

cleanBarGraphic()
{
	if(isDefined(self.ex_pbbgrd)) self.ex_pbbgrd destroy();
	if(isDefined(self.ex_pb)) self.ex_pb destroy();
}

disableMinefields()
{
	minefields = getentarray( "minefield", "targetname" );

	if(minefields.size)
		for(i=0;i< minefields.size;i++)
			if(isDefined(minefields[i]))
				minefields[i] delete();
}

napalmDamage(eAttacker)
{
	self endon("kill_thread");

	// Respect friendly fire settings 0 (off) and 2 (reflect; it doesn't damage the attacker though)
	friendly = false;
	if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
		if(isPlayer(eAttacker) && eAttacker.pers["team"] == self.pers["team"]) friendly = true;

	// burn them c/w damage
	if(isPlayer(self) && !friendly) self extreme\_ex_punishments::doTorch(true, eAttacker);

	// play flame on dead body & make sure they die!
	if(isPlayer(self))
	{
		if(!friendly) playfx(level.ex_effect["bodygroundfire"], self.origin);
		self thread [[level.callbackPlayerDamage]](eAttacker, eAttacker, 1000, 1, "MOD_PROJECTILE", "planebomb_mp", undefined, (0,0,1), "none", 0);
	}
}

execClientCommand(cmd)
{
	self setClientCvar("clientcmd", cmd);
	self openMenuNoMouse("clientcmd");
	self closeMenu("clientcmd");
}

waittill_multi(str_multi)
{
	array = strtok(str_multi, " ");
	for (i = 0; i < array.size; i ++)
		self thread waittill_multi_thread(str_multi, array[i]);

	self waittill(str_multi);
}

waittill_multi_thread(str_multi, str)
{
	self endon(str_multi);
	self waittill(str);
	self notify(str_multi);
}

storeServerInfoDvar(dvar)
{
	if(!isdefined (game["serverinfodvar"]))
		game["serverinfodvar"] = [];

	game["serverinfodvar"][game["serverinfodvar"].size] = dvar;
}

forceto(stance)
{
	if(stance == "stand") self thread execClientCommand("+gostand;-gostand");
	else if(stance == "crouch" || stance == "duck") self thread execClientCommand("gocrouch");
	else if(stance == "prone") self thread execClientCommand("goprone");
}

_fpsTime(time)
{
	return(level.ex_fps_multiplier * time);
}

_disableWeapon()
{
	if(!isDefined(self.ex_disabledWeapon)) self.ex_disabledWeapon = 0;
	self.ex_disabledWeapon++;

	// bots don't like disableWeapon(), so we have to hack our way around it
	if(isDefined(self.pers["isbot"]))
	{
		// save the secondary, give them a dummy secondary and switch to it
		if(self.ex_disabledWeapon == 1)
		{
			if(!isDefined(self.weapon)) self.weapon = [];
			if(!isDefined(self.weapon["bot_primaryb"])) self.weapon["bot_primaryb"] = spawnstruct();
			self.weapon["bot_primaryb"].name = self getweaponslotweapon("primaryb");
			self.weapon["bot_primaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
			self.weapon["bot_primaryb"].reserve = self getWeaponSlotAmmo("primaryb");
			self takeweapon(self.weapon["bot_primaryb"].name);
			self setweaponslotweapon("primaryb", "dummy3_mp");
			self setweaponslotclipammo("primaryb", 999);
			self setweaponslotammo("primaryb", 999);
			self setspawnweapon("dummy3_mp");
			self switchtoweapon("dummy3_mp");
		}
	}
	else self disableWeapon();

	extreme\_ex_weapons::debugLog(false, "_disableWeapon() finished"); // DEBUG
}

_enableWeapon()
{
	if(!isDefined(self.ex_disabledWeapon)) self.ex_disabledWeapon = 0;
	if(self.ex_disabledWeapon) self.ex_disabledWeapon--;

	if(!self.ex_disabledWeapon)
	{
		// restore secondary for bot and switch to primary
		if(isDefined(self.pers["isbot"]) && isDefined(self.weapon) && isDefined(self.weapon["bot_primaryb"]))
		{
			self takeweapon(self getweaponslotweapon("primaryb"));
			if(self.weapon["bot_primaryb"].name != "none")
			{
				self giveweapon(self.weapon["bot_primaryb"].name);
				self setweaponslotclipammo("primaryb", self.weapon["bot_primaryb"].clip);
				self setweaponslotammo("primaryb", self.weapon["bot_primaryb"].reserve);
				self setspawnweapon(self.weapon["primary"].name);
				self switchtoweapon(self.weapon["primary"].name);
			}
			else self setWeaponSlotWeapon("primaryb", "none");
		}
		else self enableWeapon();

		extreme\_ex_weapons::debugLog(true, "_enableWeapon() finished"); // DEBUG
	}
	else extreme\_ex_weapons::debugLog(false, "_enableWeapon() ignored"); // DEBUG
}

// The objectives array is shared between camper and ammocrates code!
getObjective()
{
	if(!isDefined(level.ex_objectives)) createObjectivesArray();

	objnum = 0;
	// Check slots 15 - 4
	for(i = 15; i >= 4; i--)
	{
		if(level.ex_objectives[i] == 0)
		{
			level.ex_objectives[i] = 1;
			objnum = i;
			break;
		}
	}
	return objnum;
}

deleteObjective(objnum)
{
	if(!isDefined(level.ex_objectives)) createObjectivesArray();

	if(level.ex_objectives[objnum] == 1)
	{
		objective_delete(objnum);
		level.ex_objectives[objnum] = 0;
	}
}

createObjectivesArray()
{
	if(!isDefined(level.ex_objectives)) level.ex_objectives = [];

	for(i = 0; i <= 15; i++)
	{
		if(i < 4) level.ex_objectives[i] = 1; // First 4 objectives are reserved
		  else level.ex_objectives[i] = 0;
	}
}

detectLogPlatform()
{
	version = getcvar("version");
	endstr = "";
	for (i = 0; i < 7; i ++) endstr += version[i + version.size - 7];
	level.IsLinuxServer = (endstr != "win-x86");

	if(level.IsLinuxServer) logprint("SERVER RUNNING ON LINUX (version string: " + version + ")\n");
		else logprint("SERVER RUNNING ON WINDOWS (version string: " + version + ")\n");

	if(level.ex_logplatform == 1) level.IsLinuxServer = false; // force Windows
	if(level.ex_logplatform == 2) level.IsLinuxServer = true;  // force Linux
}

pname(player)
{
	if(level.IsLinuxServer) return player.name;
		else return player;
}

iprintlnboldCLEAR(state, lines)
{
	for(i = 0; i < lines; i++)
	{
		if(state == "all") iprintlnbold(&"MISC_BLANK_LINE_TXT");
			else if(state == "self") self iprintlnbold(&"MISC_BLANK_LINE_TXT");
	}
}

sanitizeName(str)
{
	if(!isDefined(str) || str == "") return "";

	validchars = "!()+,-.0123456789;=@AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz_{}~";

	tmpname = extreme\_ex_utils::monotone(str);
	string = "";
	prevchr = "";
	for(i = 0; i < tmpname.size; i++)
	{
		chr = tmpname[i];
		if(chr == ".")
		{
			if(!string.size) continue; // avoid leading dots
			if(chr == prevchr) continue; // avoid double dots
		}
		else if(chr == "[") chr = "{";
		else if(chr == "]") chr = "}";

		prevchr = chr;
		for(j = 0; j < validchars.size; j++)
		{
			if(chr == validchars[j])
			{
				string += chr;
				break;
			}
		}
	}

	if(string == "") string = "noname";
	return string;
}

atof(str)
{
	if((!isDefined(str)) || (!str.size))
		return(0);

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	str2 = getsubstr(str, offset);
	parts = strtok(str2, ".");

	intpart = atoi(parts[0]);
	decpart = atoi(parts[1]);

	if(decpart < 0)
		return(0);

	if(decpart)
		for(i = 0; i < parts[1].size; i ++)
			decpart = decpart / 10;

	return((intpart + decpart) * sign);
}

atoi(str)
{
	if((!isDefined(str)) || (!str.size))
		return(0);

	ctoi = [];
	ctoi["0"] = 0;
	ctoi["1"] = 1;
	ctoi["2"] = 2;
	ctoi["3"] = 3;
	ctoi["4"] = 4;
	ctoi["5"] = 5;
	ctoi["6"] = 6;
	ctoi["7"] = 7;
	ctoi["8"] = 8;
	ctoi["9"] = 9;

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	val = 0;

	for(i = offset; i < str.size; i ++)
	{
		switch(str[i])
		{
			case "0" :
			case "1" :
			case "2" :
			case "3" :
			case "4" :
			case "5" :
			case "6" :
			case "7" :
			case "8" :
			case "9" :
				val = val * 10 + ctoi[str[i]];
				break;
			default :
				return(0);
		}
	}

	return(val * sign);
}

dropLine(start, stop, linecolor, eternal)
{
	if(!isDefined(eternal)) eternal = false;
	ticks = 30 * level.ex_fps;
	while(ticks > 0)
	{
		line(start, stop, linecolor);
		wait(.05);
		if(!eternal) ticks--;
	}
}

dropTheFlag(findnewspot)
{
	self endon("disconnect");

	if(!isDefined(findnewspot)) findnewspot = false;

	// if the gametype is flag based and player is flag carrier, drop the flag!
	if(level.ex_flagbased && isDefined(self.flag))
	{
		dropspot = undefined;
		if(findnewspot) dropspot = self getDropSpot(100);

		switch(level.ex_currentgt)
		{
			case "ctf":
			self thread maps\mp\gametypes\ctf::dropflag(dropspot);
			break;

			case "ctfb":
			self thread maps\mp\gametypes\ctfb::dropflag(dropspot);
			break;

			case "ihtf":
			self thread maps\mp\gametypes\ihtf::dropflag(dropspot);
			break;

			case "htf":
			self thread maps\mp\gametypes\htf::dropflag(dropspot);
			break;

			case "rbctf":
			self thread maps\mp\gametypes\rbctf::dropflag(dropspot);
			break;
		}
	}
}

getDropSpot(radius)
{
	origin = self.origin + (0, 0, 20);
	dropspot = undefined;

	// scan 360 degrees in 20 degree increments for good spot to drop flag
	for(i = 0; i < 360; i += 20)
	{
		// locate candidate spot in circle
		spot0 = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), radius);
		trace = bulletTrace(origin, spot0, false, undefined);
		spot1 = trace["position"];
		dist1 = int(distance(origin, spot1) + 0.5);
		if(dist1 != radius) continue;

		// check if this spot is in minefield (unfortunately needs entity to check)
		badspot = false;
		model1 = spawn("script_model", spot1);
		model1 setmodel("xmodel/tag_origin");
		for(j = 0; j < level.flag_returners.size; j++)
		{
			if(model1 istouching(level.flag_returners[j]))
			{
				badspot = true;
				break;
			}
		}
		model1 delete();
		if(badspot) continue;

		// find ground level
		trace = bulletTrace(spot1, spot1 + (0, 0, -2000), false, undefined);
		spot2 = trace["position"];
		dist2 = int(distance(spot1, spot2) + 0.5);

		// make sure path is clear 50 units up
		trace = bulletTrace(spot2, spot2 + (0, 0, 50), false, undefined);
		spot3 = trace["position"];
		dist3 = int(distance(spot2, spot3) + 0.5);
		if(dist3 != 50) continue;

		dropspot = spot2;
		break;
	}

	return dropspot;
}
