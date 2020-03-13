
checkInit()
{
	self endon("disconnect");

	// check persona non grata status
	//self checkPersonaNonGrata();

	// init vars for bad word filer
	self.pers["badword_status"] = 0;

	// check what clan they are in
	self checkClan();

	// check if this is an authorized member
	if(level.ex_checkmembers) self checkMembers();

	// check if guid number is authorised for extra privileges
	if(level.ex_security && !self checkGuid())
	{
		self.ex_name = undefined;
		self.ex_clid = undefined;
	}

	// for clan PIN handling
	if(level.ex_clanlogin && isDefined(self.ex_name))
	{
		self.ex_clanlogin = true;
		self.ex_clanlogin_pin = "";

		memory = self extreme\_ex_memory::getMemory("clan", "pin");
		if(!memory.error && memory.value == level.ex_clanlogin_pin)
		{
			self.ex_clanlogin = false;
			self setClientCvar("ui_clanlogin", "2");
		}
		else self setClientCvar("ui_clanlogin", "0");
	}
}

checkPersonaNonGrata()
{
	non_grata = false;

	// Non grata tags (remove color codes)
	nonGrataTags = [];
	//nonGrataTags[nonGrataTags.size] = "tag";

	// Non grata names (include tag, remove color codes)
	nonGrataNames = [];
	//nonGrataNames[nonGrataNames.size] = "name";

	// Non grata GUIDs (short GUID, not PunkBuster long GUID)
	nonGrataGUIDs = [];
	//nonGrataGUIDs[nonGrataGUIDs.size] = 0;

	// prepare player info
	playername_nocol = extreme\_ex_utils::monotone(self.name);
	playerguid = self getGuid();

	// Check tags
	for(i = 0; i < nonGrataTags.size; i++)
	{
		if(playername_nocol.size <= nonGrataTags[i].size) continue;
		sizediff = playername_nocol.size - nonGrataTags[i].size;

		cnfront = "";
		cnback = "";
		for(j = 0; j < nonGrataTags[i].size; j++)
		{
			cnfront += playername_nocol[j];
			cnback  += playername_nocol[sizediff + j];
		}

		if(cnfront == nonGrataTags[i] || cnback == nonGrataTags[i])
		{
			non_grata = true;
			break;
		}
	}

	// Check names
	if(!non_grata)
	{
		for(i = 0; i < nonGrataNames.size; i++)
		{
			if(playername_nocol == nonGrataNames[i])
			{
				non_grata = true;
				break;
			}
		}
	}

	// Check GUIDs
	if(!non_grata && playerguid)
	{
		for(i = 0; i < nonGrataGUIDs.size; i++)
		{
			if(playerguid == nonGrataGUIDs[i])
			{
				non_grata = true;
				break;
			}
		}
	}

	if(non_grata)
	{
		self setClientCvar("com_errorTitle", "eXtreme+ Message");
		self setClientCvar("com_errorMessage", "You have been disconnected from the server\nbecause you are a Persona Non Grata!");
		wait( [[level.ex_fpstime]](1) );
		self thread extreme\_ex_utils::execClientCommand("disconnect");
	}
}

checkGuid()
{
	self endon("disconnect");

	playerGuid = self getGuid();

	if(!playerGuid) return false;

	count = 0;
		
	for(;;)
	{
		guid = [[level.ex_drm]]("ex_guid_" + count, 0, 0, 9999999, "int");

		if(!guid) break;
			else if(guid == playerGuid) return true;
				else count ++;
	}

	return false;
}

checkClan()
{
	self endon("disconnect");

	self.ex_name = undefined;
	self.ex_clid = undefined;

	clan_num = false;
	
	for(i = 1; i < 5; i++)
	{
		if(checkClanID(i))
		{
			clan_num = i;
			break;
		}
	}

	if(!clan_num) return;

	// Changed: self.ex_name now stores the clan tag (unmodified)
	self.ex_name = level.ex_cltag[clan_num];
	self.ex_clid = clan_num;

	return;
}

checkClanID(check)
{
	// decolorize name and tag
	namestr = extreme\_ex_utils::monotone(self.name);
	tagstr = extreme\_ex_utils::monotone(level.ex_cltag[check]);

	if(namestr.size <= tagstr.size) return false;
	sizediff = namestr.size - tagstr.size;

	// check clan tag in front or at end of player's name
	cnfront = "";
	cnback = "";
	for(i = 0; i < tagstr.size; i++)
	{
		cnfront += namestr[i];
		cnback  += namestr[sizediff + i];
	}

	if(cnfront == tagstr || cnback == tagstr) return true;

	return false;
}

checkMembers()
{
	if(isDefined(self.ex_name) && self.ex_clid <= level.ex_checkmembers)
	{
		// decolorize name
		name_nocol = extreme\_ex_utils::monotone(self.name);

		count = 0;
		for(;;)
		{
			member_nocol = [[level.ex_drm]]("ex_member_name_" + count, "", "", "", "string");
			if(member_nocol == "") break;
			if(member_nocol == name_nocol) break;
				else count++;
		}

		if(member_nocol == "")
		{
			self setClientCvar("com_errorTitle", "eXtreme+ Message");
			self setClientCvar("com_errorMessage", "You have been disconnected from the server\ndue to illegal clan tag use!\nYou can reconnect to our server after removing our clan tag from your name.");
			wait( [[level.ex_fpstime]](1) );
			self thread extreme\_ex_utils::execClientCommand("disconnect");
		}
	}
}

checkIgnoreInactivity()
{
	self endon("disconnect");

	self.pers["dontkick"] = false;

	count = 0;
	clan_check = "";

	if(isDefined(self.ex_name))
	{
		// convert the clan name
		playerclan = extreme\_ex_utils::convertMUJ(self.ex_name);

		for(;;)
		{
			// get the preset clan name
			clan_check = [[level.ex_drm]]("ex_inactive_exclude_clan_" + count, "", "", "", "string");

			// check if there is a preset clan name, if not end here!
			if(clan_check == "") break;

			// convert clan name
			clan_check = extreme\_ex_utils::convertMUJ(clan_check);

			// if the names match, break here and set kick status
			if(clan_check == playerclan) break;
				else count++;
		}
	}

	if(clan_check != "")
	{
		self.pers["dontkick"] = true;
		return;
	}

	// convert the players name
	playername = extreme\_ex_utils::convertMUJ(self.name);

	count = 0;
		
	for(;;)
	{
		// get the preset player name
		name_check = [[level.ex_drm]]("ex_inactive_exclude_name_" + count, "", "", "", "string");

		// check if there is a preset player name, if not end here!
		if(name_check == "") break;

		// convert name_check
		name_check = extreme\_ex_utils::convertMUJ(name_check);

		// if the names match, break here and set kick status
		if(name_check == playername) break;
			else count++;
	}

	if(name_check != "")
		self.pers["dontkick"] = true;
}
