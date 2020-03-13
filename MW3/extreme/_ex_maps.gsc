
getgtstring(gt)
{
	switch(gt)
	{
		case "chq":
			gtstring = &"MPUI_CLASSIC_HEADQUARTERS";
			break;
		case "cnq":
			gtstring = &"MPUI_CONQUEST";
			break;
		case "ctf":
			gtstring = &"MPUI_CAPTURE_THE_FLAG";
			break;
		case "ctfb":
			gtstring = &"MPUI_CAPTURE_THE_FLAG_BACK";
			break;
		case "dm":
			gtstring = &"MPUI_DEATHMATCH";
			break;
		case "dom":
			gtstring = &"MPUI_DOMINATION";
			break;
		case "esd":
			gtstring = &"MPUI_ENHANCED_SD";
			break;
		case "ft":
			gtstring = &"MPUI_FREEZETAG";
			break;
		case "hm":
			gtstring = &"MPUI_HITMAN";
			break;
		case "hq":
			gtstring = &"MPUI_HEADQUARTERS";
			break;
		case "htf":
			gtstring = &"MPUI_HOLD_THE_FLAG";
			break;
		case "ihtf":
			gtstring = &"MPUI_I_HOLD_THE_FLAG";
			break;
		case "lib":
			gtstring = &"MPUI_LIBERATION";
			break;
		case "lms":
			gtstring = &"MPUI_LAST_MAN_STANDING";
			break;
		case "lts":
			gtstring = &"MPUI_LAST_TEAM_STANDING";
			break;
		case "ons":
			gtstring = &"MPUI_ONSLAUGHT";
			break;
		case "rbcnq":
			gtstring = &"MPUI_ROUNDBASED_CNQ";
			break;
		case "rbctf":
			gtstring = &"MPUI_ROUNDBASED_CTF";
			break;
		case "sd":
			gtstring = &"MPUI_SEARCH_AND_DESTROY";
			break;
		case "tdm":
			gtstring = &"MPUI_TEAM_DEATHMATCH";
			break;
		case "tkoth":
			gtstring = &"MPUI_TEAM_KING_OF_THE_HILL"; 
			break;
		case "vip":
			gtstring = &"MPUI_VERY_IMPORTANT_PERSON";
			break;
		default:
			gtstring = &"MPUI_UNKNOWN_GT_LONG";
			break;
	}

	return gtstring;
}

getgtstringshort(gt)
{
	switch(gt)
	{
		case "chq":
			gtstring = &"MPUI_CHQ";
			break;
		case "cnq":
			gtstring = &"MPUI_CNQ";
			break;
		case "ctf":
			gtstring = &"MPUI_CTF";
			break;
		case "ctfb":
			gtstring = &"MPUI_CTFB";
			break;
		case "dm":
			gtstring = &"MPUI_DM";
			break;
		case "dom":
			gtstring = &"MPUI_DOM";
			break;
		case "esd":
			gtstring = &"MPUI_ESD";
			break;
		case "ft":
			gtstring = &"MPUI_FT";
			break;
		case "hm":
			gtstring = &"MPUI_HM";
			break;
		case "hq":
			gtstring = &"MPUI_HQ";
			break;
		case "htf":
			gtstring = &"MPUI_HTF";
			break;
		case "ihtf":
			gtstring = &"MPUI_IHTF";
			break;
		case "lib":
			gtstring = &"MPUI_LIB";
			break;
		case "lms":
			gtstring = &"MPUI_LMS";
			break;
		case "lts":
			gtstring = &"MPUI_LTS";
			break;
		case "ons":
			gtstring = &"MPUI_ONS";
			break;
		case "rbcnq":
			gtstring = &"MPUI_RBCNQ";
			break;
		case "rbctf":
			gtstring = &"MPUI_RBCTF";
			break;
		case "sd":
			gtstring = &"MPUI_SD";
			break;
		case "tdm":
			gtstring = &"MPUI_TDM";
			break;
		case "tkoth":
			gtstring = &"MPUI_TKOTH";  
			break;
		case "vip":
			gtstring = &"MPUI_VIP";
			break;
		default:
			gtstring = &"MPUI_UNKNOWN_GT_SHORT";
			break;
	}

	return gtstring;
}

getmapstring(map)
{
	level.msc = false;
	if(!IsCustomMap(map)) level.msc = true;

	mapstring = level.ex_maps[0].loclname;

	for(i = 0; i < level.ex_maps.size; i++)
	{
		if(level.ex_maps[i].mapname == map)
		mapstring = level.ex_maps[i].loclname;
	}
	return mapstring;
}

trim(s)
{
	if(s == "") return "";

	s2 = "";
	s3 = "";

	i = 0;
	while( (i < s.size) && (s[i] == " ") ) i++;

	// String is just blanks?
	if(i==s.size) return "";

	for(; i < s.size; i++) s2 += s[i];

	i = s2.size - 1;
	while( (s2[i] == " ") && (i > 0) ) i--;

	for(j = 0; j <= i; j++) s3 += s2[j];

	return s3;
}

DisplayMapRotation()
{
	level endon("ex_gameover");

	msgText = &"MAPROTATION_NORMAL";
	if(level.ex_randommaprotation) msgText = &"MAPROTATION_RANDOM";
	if(level.ex_pbrotate) msgText = &"MAPROTATION_PLAYER";
	if(level.ex_mapvote) msgText = &"MAPROTATION_VOTING";

	iprintln(&"CUSTOM_SERVER_NAME", msgText);

	if(level.ex_mapvote) return;

	GetMapRotation();
	sMapname = getmapstring(level.MapRotation[0]["map"]);

	if(level.ex_svrmsg_info == 1 || level.ex_svrmsg_info == 3)
	{
		msgLabel = &"MAPROTATION_NEXT_MAP";
		msgText = sMapname;
		mapAnnounce(msgLabel, msgText, 2);
	}
	
	if(level.ex_svrmsg_info >= 2)
	{
		if(IsCustomMap(level.MapRotation[0]["map"]))
			mapAnnounce(&"MAPROTATION_CUSTOM_NEXT", undefined, 2);

		sGametype = getgtstring(level.MapRotation[0]["gametype"]);

		msgLabel = &"MAPROTATION_NEXT_GT";
		msgText = sGametype;
		mapAnnounce(msgLabel, msgText, 2);
	}

	// if no map rotation display, end here!
	if(!level.ex_svrmsg_rotation) return;

	mapAnnounce(&"MAPROTATION_TITLE", undefined, 2);

	for(i = 0; i < level.MapRotation.size; i++)
	{
		sMapname = getmapstring(level.MapRotation[i]["map"]);
		sGametype = getgtstringshort(level.MapRotation[i]["gametype"]);
		bCustom = IsCustomMap(level.MapRotation[i]["map"]);

		msgLabel = sMapname;
		msgText = sGametype;

		mapAnnounce(msgLabel, msgText, 1.5, bCustom);
	}
}

mapAnnounce(msgLabel, msgText, delay, custom)
{
	if(!isDefined(delay)) delay = 2;
	if(!isDefined(custom) || !custom) color = (1, 1, 1);
	  else color = (0, 1, 0);

	if(!isDefined(level.ex_mapannouncer))
	{
		level.ex_mapannouncer = newHudElem();
		level.ex_mapannouncer.archived = false;
		level.ex_mapannouncer.horzAlign = "fullscreen";
		level.ex_mapannouncer.vertAlign = "fullscreen";
		level.ex_mapannouncer.alignX = "center";
		level.ex_mapannouncer.alignY = "top";
		level.ex_mapannouncer.x = 320;
		level.ex_mapannouncer.y = 43;
		level.ex_mapannouncer.fontscale = 1.2;
	}
	level.ex_mapannouncer.color = color;
	level.ex_mapannouncer.label = msgLabel;
	if(isDefined(msgText)) level.ex_mapannouncer setText(msgText);
	wait( [[level.ex_fpstime]](delay) );

	if(isDefined(level.ex_mapannouncer))
	{
		level.ex_mapannouncer fadeOverTime(.5);
		level.ex_mapannouncer.alpha = 0;
		wait( [[level.ex_fpstime]](0.5) );
	}

	if(isDefined(level.ex_mapannouncer)) level.ex_mapannouncer destroy();
}

GetMapRotation()
{
	// clean up old array
	if(isDefined(level.MapRotation)) level.MapRotation = undefined;

	// get the full rotation string; reconstruct if stacker enabled
	maprot = reconstructMapRotation();

	// convert the rotation string into an array
	rotationArray = rotationToArray(maprot);
	
	// locate the current map and current game type combination
	for(i = 0; i < rotationArray.size; i++)
	{
		if(rotationArray[i]["gametype"] == level.ex_currentgt && rotationArray[i]["map"] == level.ex_currentmap)
			break;
	}

	// if current map is not in rotation string we have to find out what will be next
	if(i >= rotationArray.size)
	{
		maprotcur = getcvar("sv_maprotationcurrent");
		if(maprotcur != "") rotationArray = rotationToArray(maprotcur);
		i = -1;
	}

	// now build the final array - first next map in line to the end of array
	mapnum = 0;
	for(j = i+1; j < rotationArray.size; j++)
	{
		level.MapRotation[mapnum]["gametype"] = rotationArray[j]["gametype"];
		level.MapRotation[mapnum]["map"] = rotationArray[j]["map"];
		mapnum++;
	}
	// ...and from start of array to and including current
	for(j = 0; j <= i; j++)
	{
		level.MapRotation[mapnum]["gametype"] = rotationArray[j]["gametype"];
		level.MapRotation[mapnum]["map"] = rotationArray[j]["map"];
		mapnum++;
	}

	// clean up temp array
	rotationArray = undefined;
}

reconstructMapRotation()
{
	if(level.ex_pbrotate)
	{
		players = level.players;
		if(players.size >= level.ex_mapsizing_large) maprot = getcvar("scr_large_rotation");
			else if(players.size >= level.ex_mapsizing_medium) maprot = getcvar("scr_med_rotation");
				else maprot = getcvar("scr_small_rotation");
	}
	else maprot = getcvar("sv_maprotation");
	maprot = trim(maprot);

	// if rotation stacker is enabled, reconstruct rotation (not if player based rotation is enabled)
	// we CANNOT simply reconstruct to sv_mapRotation[ORG] + sv_mapRotation[X]
	mapstack = getcvar("sv_maprotation1");
	if(!level.ex_pbrotate && mapstack != "")
	{
		maprotno_str = getCvar("ex_maprotno");
		// if stacker enabled but still in original sv_mapRotation
		if(maprotno_str == "")
		{
			// sv_mapRotation (maprot) = sv_mapRotation[ORG]
			// reconstruct to sv_mapRotation[ORG] + sv_mapRotation[X]
			maprotno = 1;
			while(mapstack != "")
			{
				maprot = maprot + " " + trim(mapstack);
				maprotno++;
				mapstack = getcvar("sv_maprotation" + maprotno);
			}
			//logprint("DEBUG [ORG]: " + maprot + "\n");
		}
		else
		{
			maprotno = getCvarInt("ex_maprotno");
			// did we just rotate stacker lines?
			if(getcvar("sv_maprotationcurrent") == "")
			{
				// yes we just rotated stacker lines; are we still playing the last stacker line?
				if(maprotno == 0)
				{
					// sv_mapRotation (maprot) = sv_mapRotation[LAST]
					// reconstruct to sv_mapRotation[LAST] + sv_mapRotation[ORG] + sv_mapRotation[X]
					maprotno_act = 2;
					while(1)
					{
						mapstack = getcvar("sv_maprotation" + maprotno_act);
						if(mapstack == "") break;
							else maprotno_act++;
					}
					maprotno_act--;
					mapstack = getcvar("sv_maprotation" + maprotno_act);
					maprot_org = getCvar("ex_maprotation");
					maprot = trim(mapstack) + " " + trim(maprot_org);
					for(i = 1; i < maprotno_act; i++)
					{
						mapstack = getcvar("sv_maprotation" + i);
						maprot = maprot + " " + trim(mapstack);
					}
					//logprint("DEBUG [STL]->ORG: " + maprot + "\n");
				}
				// yes we just rotated stacker lines; are we still playing the original sv_mapRotation?
				else if(maprotno == 1)
				{
					// sv_mapRotation (maprot) = sv_mapRotation[ORG]
					// reconstruct to sv_mapRotation[ORG] + sv_mapRotation[X]
					mapstack_tmp = trim(mapstack);
					while(1)
					{
						maprotno++;
						mapstack = getcvar("sv_maprotation" + maprotno);
						if(mapstack != "") mapstack_tmp = mapstack_tmp + " " + trim(mapstack);
							else break;
					}
					maprot_org = getCvar("ex_maprotation");
					maprot = trim(maprot_org) + " " + mapstack_tmp;
					//logprint("DEBUG [ORG]->ST1: " + maprot + "\n");
				}
				// yes we just rotated stacker lines; we are playing another stacker line
				else
				{
					// sv_mapRotation (maprot) = sv_mapRotation[PREV]
					// reconstruct to sv_mapRotation[X] + sv_mapRotation[ORG] + sv_mapRotation[X]
					maprotno--;
					maprotno_act = maprotno;
					mapstack = getcvar("sv_maprotation" + maprotno);
					mapstack_tmp = trim(mapstack);
					while(1)
					{
						maprotno++;
						mapstack = getcvar("sv_maprotation" + maprotno);
						if(mapstack != "") mapstack_tmp = mapstack_tmp + " " + trim(mapstack);
							else break;
					}
					maprot_org = getCvar("ex_maprotation");
					maprot = mapstack_tmp + " " + trim(maprot_org);
					for(i = 1; i < maprotno_act; i++)
					{
						mapstack = getcvar("sv_maprotation" + i);
						maprot = maprot + " " + trim(mapstack);
					}
					//logprint("DEBUG [STX]->STX: " + maprot + "\n");
				}
			}
			else
			{
				// no we did not rotate stacker lines; are we playing the original sv_mapRotation?
				if(maprotno == 0)
				{
					// sv_mapRotation (maprot) = sv_mapRotation[ORG]
					// reconstruct to sv_mapRotation[ORG] + sv_mapRotation[X]
					mapstack_tmp = "";
					while(1)
					{
						maprotno++;
						mapstack = getcvar("sv_maprotation" + maprotno);
						if(mapstack != "") mapstack_tmp = mapstack_tmp + " " + trim(mapstack);
							else break;
					}
					maprot = maprot + " " + trim(mapstack_tmp);
					//logprint("DEBUG STL->[ORG]: " + maprot + "\n");
				}
				// no we did not rotate stacker lines; are we playing the first stacker line?
				else if(maprotno == 1)
				{
					// sv_mapRotation (maprot) = sv_mapRotation[1]
					// reconstruct to sv_mapRotation[FIRST] + sv_mapRotation[ORG] + sv_mapRotation[X]
					mapstack_tmp = maprot;
					while(1)
					{
						maprotno++;
						mapstack = getcvar("sv_maprotation" + maprotno);
						if(mapstack != "") mapstack_tmp = mapstack_tmp + " " + trim(mapstack);
							else break;
					}
					maprot_org = getCvar("ex_maprotation");
					maprot = mapstack_tmp + " " + trim(maprot_org);
					//logprint("DEBUG ORG->[ST1]: " + maprot + "\n");
				}
				// no we did not rotate stacker lines; we are playing another stacker line
				else
				{
					// sv_mapRotation (maprot) = sv_mapRotation[X]
					// reconstruct to sv_mapRotation[X] + sv_mapRotation[ORG] + sv_mapRotation[X]
					maprotno_act = maprotno;
					mapstack = getcvar("sv_maprotation" + maprotno);
					mapstack_tmp = trim(mapstack);
					while(1)
					{
						maprotno++;
						mapstack = getcvar("sv_maprotation" + maprotno);
						if(mapstack != "") mapstack_tmp = mapstack_tmp + " " + trim(mapstack);
							else break;
					}
					maprot_org = getCvar("ex_maprotation");
					maprot = mapstack_tmp + " " + trim(maprot_org);
					for(i = 1; i < maprotno_act; i++)
					{
						mapstack = getcvar("sv_maprotation" + i);
						maprot = maprot + " " + trim(mapstack);
					}
					//logprint("DEBUG STX->[STX]: " + maprot + "\n");
				}
			}
		}
	}

	return(maprot);
}

rotationToArray(maprot)
{
	rotationArray = [];

	// convert to array of strings
	maprotarray = strtok(maprot, " ");

	// now build a proper array out of this
	sGametype = getcvar("g_gametype");
	arraypos = 0;
	mapnum = 0;

	while(arraypos < maprotarray.size)
	{
		if(maprotarray[arraypos] == "gametype")
		{
			// found in array string "gametype type map mapname"
			sGametype = maprotarray[arraypos + 1];
			rotationArray[mapnum]["gametype"] = maprotarray[arraypos + 1];
			rotationArray[mapnum]["map"] = maprotarray[arraypos + 3];
			arraypos = arraypos + 4;
		}
		else
		{
			// no gametype so presumably just a map "map mapname"
			rotationArray[mapnum]["gametype"] = sGametype;
			rotationArray[mapnum]["map"] = maprotarray[arraypos + 1];
			arraypos = arraypos + 2;
		}

		mapnum++;
	}

	return(rotationArray);
}

IsCustomMap(map)
{
	switch(map)
	{
		case "mp_breakout":
		case "mp_brecourt":
		case "mp_burgundy":
		case "mp_carentan":
		case "mp_dawnville":
		case "mp_decoy":
		case "mp_downtown":
		case "mp_harbor":
		case "mp_farmhouse":
		case "mp_leningrad":
		case "mp_matmata":
		case "mp_railyard":
		case "mp_toujane":
		case "mp_trainstation":
		case "mp_rhine":
			return false;

		default:
			return true;
	}
}

getColor(color)
{
	switch(color)
	{
		case "red":
		case "1":
		case 1:
			colorstr = &"COLOUR_RED";
			break;
		case "green":
		case "2":
		case 2:
			colorstr = &"COLOUR_GREEN";
			break;
		case "yellow":
		case "3":
		case 3:
			colorstr = &"COLOUR_YELLOW";
			break;
		case "blue":
		case "4":
		case 4:
			colorstr = &"COLOUR_BLUE";
			break;
		case "cyan":
		case "5":
		case 5:
			colorstr = &"COLOUR_CYAN";
			break;
		case "pink":
		case "6":
		case 6:
			colorstr = &"COLOUR_PINK";
			break;
		case "white":
		case "7":
		case 7:
			colorstr = &"COLOUR_WHITE";
			break;
		case "olive":
		case "8":
		case 8:
			colorstr = &"COLOUR_OLIVE";
			break;
		case "grey":
		case "9":
		case 9:
			colorstr = &"COLOUR_GREY";
			break;
		default:
			colorstr = &"COLOUR_WHITE";;
			break;
	}

	return colorstr;
}
