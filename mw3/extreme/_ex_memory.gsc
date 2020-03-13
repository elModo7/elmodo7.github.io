#include extreme\_ex_utils;

init()
{
	// Either set it to true or false. DO NOT DISABLE!
	level.ex_memory_log = false;

	// registerMemory(memID, itemID, itemDef, itemMin, itemMax, itemType)
	// itemType: "int", "bool", "char", "float", "string"
	// itemMin on itemType "char" can be used as a string with valid characters
	// string defaults should not be empty (messes up parser which delimits on spaces)
	registerMemory("cinematic", "status", 1, 0, 1, "bool");
	registerMemory("diana", "status", 0, 0, 1, "bool");
	registerMemory("lrbind", "key", "m", "1234567890abcdefghijklmnopqrstuvwxyz", "", "char");
	registerMemory("jukebox", "status", level.ex_jukebox_power ,0, 1, "bool");
	registerMemory("jukebox", "loop", 0 ,0 ,1, "bool");
	registerMemory("jukebox", "shuffle", 0, 0, 1, "bool");
	registerMemory("jukebox", "track", 1, 1, 99, "int");
	registerMemory("zoom", "sr", level.ex_zoom_default_sr, level.ex_zoom_min_sr, level.ex_zoom_max_sr, "int");
	registerMemory("zoom", "lr", level.ex_zoom_default_lr, level.ex_zoom_min_lr, level.ex_zoom_max_lr, "int");
	registerMemory("rcon", "pin", "xxxx", "", "", "string");
	registerMemory("clan", "pin", "xxxx", "", "", "string");
	registerMemory("geo", "ip", "0.0.0.0", "", "", "string");
	registerMemory("geo", "country", "UNKNOWN", "", "", "string");
	registerMemory("score", "points", 0, 0, 1000000, "int");
	registerMemory("score", "kills", 0, 0, 1000000, "int");
	registerMemory("score", "deaths", 0, 0, 1000000, "int");
	registerMemory("score", "bonus", 0, 0, 1000000, "int");
	registerMemory("score", "special", 0, 0, 1000000, "int");
	//dumpMemoryStruct();

	if(level.ex_scorememory)
	{
		level.scorememory = [];
		[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
	}
}

onSecond(eventID)
{
	for(i = 0; i < level.scorememory.size; i++)
		if(isDefined(level.scorememory[i].graceperiod) && level.scorememory[i].graceperiod > 0) level.scorememory[i].graceperiod--;
}

setScoreMemory(name)
{
	index = -1;

	// check if name is already in list
	for(i = 0; i < level.scorememory.size; i++)
	{
		if(level.scorememory[i].name == name)
		{
			index = i;
			break;
		}
	}

	// name is not in list, so check for expired records
	if(index == -1)
	{
		for(i = 0; i < level.scorememory.size; i++)
		{
			if(level.scorememory[i].graceperiod == 0)
			{
				index = i;
				break;
			}
		}
	}

	// no expired records, so create new one
	if(index == -1)
	{
		index = level.scorememory.size;
		level.scorememory[index] = spawnstruct();
	}

	level.scorememory[index].graceperiod = level.ex_scorememory;
	level.scorememory[index].name = name;
}

getScoreMemory(name)
{
	index = -1;

	// check if name is in list
	for(i = 0; i < level.scorememory.size; i++)
	{
		if(isDefined(level.scorememory[i].name) && level.scorememory[i].name == name)
		{
			// check if still in grace period
			if(level.scorememory[i].graceperiod > 0) index = i;
			break;
		}
	}

	// return true if player is still in grace period
	return( (index != -1) );
}

registerMemory(memID, itemID, itemDef, itemMin, itemMax, itemType)
{
	if(!isDefined(memID) || !isDefined(itemID) || !isDefined(itemType)) return;
	if(memID == "" || itemID == "") return;

	// checking for valid itemID
	itemType = tolower(itemType);
	if(itemType != "int" && itemType != "char" && itemType != "bool" && itemType != "float" && itemType != "string") return;

	// setting min, max and default if not passed as parameters
	if(!isDefined(itemMin))
	{
		if(itemType == "int" || itemType == "bool" || itemType == "float") itemMin = 0;
		else if(itemType == "char" || itemType == "string") itemMin = "";
	}

	if(!isDefined(itemMax))
	{
		if(itemType == "int" || itemType == "float") itemMax = 999;
		else if(itemType == "bool") itemMax = 1;
		else if(itemType == "char" || itemType == "string") itemMax = "";
	}

	if(!isDefined(itemDef))
	{
		if(itemType == "int" || itemType == "bool" || itemType == "float") itemDef = 0;
		else if(itemType == "char" || itemType == "string") itemDef = "";
	}

	// check if default is within min and max
	if(itemType == "int" || itemType == "bool" || itemType == "float")
	{
		if(itemDef < itemMin)	itemDef = itemMin;
		else if(itemDef > itemMax)	itemDef = itemMax;
	}

	// add to memory structure
	memID = tolower(memID);
	if(!isDefined(level.memID)) level.memID = [];
	if(inArray(level.memID, memID) == -1) level.memID[level.memID.size] = memID;

	itemID = tolower(itemID);
	if(!isDefined(level.memIT)) level.memIT = [];
	if(!isDefined(level.memIT[memID])) level.memIT[memID] = [];
	if(inArray(level.memIT[memID], itemID) == -1) level.memIT[memID][ level.memIT[memID].size] = itemID;

	if(!isDefined(level.memTY)) level.memTY = [];
	if(!isDefined(level.memTY[memID])) level.memTY[memID] = [];
	if(!isDefined(level.memTY[memID][itemID])) level.memTY[memID][itemID] = spawnstruct();
	level.memTY[memID][itemID].type = itemType;
	level.memTY[memID][itemID].min = itemMin;
	level.memTY[memID][itemID].max = itemMax;
	level.memTY[memID][itemID].def = itemDef;
}

checkPlayerStruct()
{
	if(!isPlayer(self)) return false;

	// make sure something has been registered
	if(!checkLevelStruct()) return false;

	// check if player memory has been loaded
	if(!isDefined(self.pers["memory"]))
	{
		self.pers["memory"] = [];
		self.pers["memory"]["-name-"] = sanitizeName(self.name); // remember name, so we load from and save to same file
		self.pers["memory"]["-dirty-"] = false;
		for(i = 0; i < level.memID.size; i++)
		{
			memID = level.memID[i];
			if(!isDefined(self.pers["memory"][memID])) self.pers["memory"][memID] = [];
			for(j = 0; j < level.memIT[memID].size; j++)
				self.pers["memory"][memID][level.memIT[memID][j]] = level.memTY[memID][level.memIT[memID][j]].def;
		}

		loadMemory();
	}

	return true;
}

checkLevelStruct()
{
	if(!isDefined(level.memID) || !isDefined(level.memIT) || !isDefined(level.memTY)) return false;
	return true;
}

loadMemory()
{
	if(!isPlayer(self)) return;

	// make sure player memory has been initialized
	if(!checkPlayerStruct()) return;

	filename = "memory/" + self.pers["memory"]["-name-"] + "-memory";
	filehandle = openfile(filename, "read");
	if(filehandle != -1)
	{
		for(;;)
		{
			farg = freadln(filehandle);
			if(farg == -1) break;
			if(farg == 0) continue;

			mline = fgetarg(filehandle, 0);
			if(level.ex_memory_log) logprint("(READ) " + mline + "\n");
			token_array = strtok(mline, " ");

			memID = "";
			token_expect = "ID";
			type_index = 0;
			for(token_index = 0; token_index < token_array.size; token_index++)
			{
				token = token_array[token_index];
				if(level.ex_memory_log) logprint("Found token (" + token_index + ") \"" + token + "\"\n");
				switch(token_expect)
				{
					case "ID":
						if(level.ex_memory_log) logprint("Expecting identifier...\n");
						if(inArray(level.memID, token) != -1)
						{
							memID = token;
							if(level.ex_memory_log) logprint("Found identifier (" + token_index + ") \"" + token + "\"\n");
							token_expect = "VAL";
							type_index = 0;
						}
						else if(level.ex_memory_log) logprint("Expected identifier, but got  \"" + token + "\"\n");
						break;
					case "VAL":
						// loadMemory should not check for min and max when loading vars into memory!
						if(type_index < level.memTY[memID].size)
						{
							type_expect = level.memTY[memID][level.memIT[memID][type_index]].type;
							if(level.ex_memory_log) logprint("Expecting " + type_expect + " (" + (type_index+1) + " out of " + level.memIT[memID].size + " values)...\n");
							switch(type_expect)
							{
								case "int":
									if(isIntStr(token))
									{
										if(level.ex_memory_log) logprint("Found integer (" + token_index + ") \"" + token + "\"\n");
										self.pers["memory"][memID][level.memIT[memID][type_index]] = int(token);
									}
									else if(level.ex_memory_log) logprint("Expected integer, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][memID][level.memIT[memID][type_index]] + "\"\n");
									break;
								case "bool":
									if(isBoolStr(token))
									{
										if(level.ex_memory_log) logprint("Found bool (" + token_index + ") \"" + token + "\"\n");
										self.pers["memory"][memID][level.memIT[memID][type_index]] = int(token);
									}
									else if(level.ex_memory_log) logprint("Expected bool, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][memID][level.memIT[memID][type_index]] + "\"\n");
									break;
								case "char":
									if(isValidChar(token))
									{
										if(level.ex_memory_log) logprint("Found char (" + token_index + ") \"" + token + "\"\n");
										self.pers["memory"][memID][level.memIT[memID][type_index]] = token;
									}
									else if(level.ex_memory_log) logprint("Expected char, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][memID][level.memIT[memID][type_index]] + "\"\n");
									break;
								case "float":
									if(isFloatStr(token))
									{
										if(level.ex_memory_log) logprint("Found float (" + token_index + ") \"" + token + "\"\n");
										self.pers["memory"][memID][level.memIT[memID][type_index]] = atof(token);
									}
									else if(level.ex_memory_log) logprint("Expected float, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][memID][level.memIT[memID][type_index]] + "\"\n");
									break;
								case "string":
									if(isValidStr(token))
									{
										if(level.ex_memory_log) logprint("Found string (" + token_index + ") \"" + token + "\"\n");
										self.pers["memory"][memID][level.memIT[memID][type_index]] = token;
									}
									else if(level.ex_memory_log) logprint("Expected string, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][memID][level.memIT[memID][type_index]] + "\"\n");
									break;
							}
							type_index++;
							if(type_index == level.memTY[memID].size) token_expect = "ID";
						}
						else token_expect = "ID";
						break;
				}
			}
		}

		closefile(filehandle);
	}
}

saveMemory()
{
	if(!isPlayer(self)) return;
	if(!checkPlayerStruct()) return;

	if(self.pers["memory"]["-dirty-"])
	{
		filename = "memory/" + self.pers["memory"]["-name-"] + "-memory";
		filehandle = openfile(filename, "write");
		if(filehandle != -1)
		{
			mline = "";
			for(i = 0; i < level.memID.size; i++)
			{
				memID = level.memID[i];
				values = "";
				for(j = 0; j < level.memIT[memID].size; j++)
				{
					if(values != "") values += " ";
					values += self.pers["memory"][memID][level.memIT[memID][j]];
				}
				if(mline != "") mline += " ";
				mline += memID + " " + values;
			}

			if(level.ex_memory_log) logprint("(WRITE) " + mline + "\n");
			fprintln(filehandle, mline);
			closefile(filehandle);
			self.pers["memory"]["-dirty-"] = false;
		}
	}
}

setMemory(memID, itemID, itemVal, delay_write)
{
	if(!isPlayer(self)) return;
	if(!isDefined(memID) || !isDefined(itemID)) return;
	if(memID == "" || itemID == "") return;

	// make sure player memory has been initialized
	if(!checkPlayerStruct()) return;

	// delayed write is disabled if not specified
	if(!isDefined(delay_write)) delay_write = false;

	memID = tolower(memID);
	itemID = tolower(itemID);

	memid_index = inArray(level.memID, memID);
	type_index = inArray(level.memIT[memID], itemID);

	if(memid_index != -1 && type_index != -1)
	{
		// setMemory will check for min and max. It will keep current value if out of bounds
		type_expect = level.memTY[memID][itemID].type;
		token = asString(itemVal);
		switch(type_expect)
		{
			case "int":
				if(isIntStr(token))
				{
					token_int = int(token);
					if(token_int >= level.memTY[memID][itemID].min && token_int <= level.memTY[memID][itemID].max)
					{
						if(token_int != self.pers["memory"][memID][itemID])
						{
							if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " set to \"" + token + "\"\n");
							self.pers["memory"][memID][itemID] = token_int;
							self.pers["memory"]["-dirty-"] = true;
						}
						else if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " already set to \"" + token + "\"\n");
					}
					else if(level.ex_memory_log) logprint("Value \"" + token + "\" out of bounce. Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				}
				else if(level.ex_memory_log) logprint("Expected integer but got \"" + token + "\". Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				break;
			case "bool":
				if(isBoolStr(token))
				{
					token_int = int(token);
					if(token_int != self.pers["memory"][memID][itemID])
					{
						if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " set to \"" + token + "\"\n");
						self.pers["memory"][memID][itemID] = token_int;
						self.pers["memory"]["-dirty-"] = true;
					}
					else if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " already set to \"" + token + "\"\n");
				}
				else if(level.ex_memory_log) logprint("Expected bool but got \"" + token + "\". Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				break;
			case "char":
				if(isValidChar(token, level.memTY[memID][itemID].min))
				{
					if(token != self.pers["memory"][memID][itemID])
					{
						if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " set to \"" + token + "\"\n");
						self.pers["memory"][memID][itemID] = token;
						self.pers["memory"]["-dirty-"] = true;
					}
					else if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " already set to \"" + token + "\"\n");
				}
				else if(level.ex_memory_log) logprint("Expected char but got \"" + token + "\". Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				break;
			case "float":
				if(isFloatStr(token))
				{
					token_float = atof(token);
					if(token_float >= level.memTY[memID][itemID].min && token_float <= level.memTY[memID][itemID].max)
					{
						if(token_float != self.pers["memory"][memID][itemID])
						{
							if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " set to \"" + token + "\"\n");
							self.pers["memory"][memID][itemID] = token_float;
							self.pers["memory"]["-dirty-"] = true;
						}
						else if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " already set to \"" + token + "\"\n");
					}
					else if(level.ex_memory_log) logprint("Value \"" + token + "\" out of bounce. Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				}
				else if(level.ex_memory_log) logprint("Expected float but got \"" + token + "\". Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				break;
			case "string":
				if(isValidStr(token))
				{
					if(token != self.pers["memory"][memID][itemID])
					{
						if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " set to \"" + token + "\"\n");
						self.pers["memory"][memID][itemID] = token;
						self.pers["memory"]["-dirty-"] = true;
					}
					else if(level.ex_memory_log) logprint("Variable " + level.memID[memid_index] + "\\" + level.memIT[memID][type_index] + " already set to \"" + token + "\"\n");
				}
				else if(level.ex_memory_log) logprint("Expected string but got \"" + token + "\". Keeping current \"" + self.pers["memory"][memID][itemID] + "\"\n");
				break;
		}

		if(self.pers["memory"]["-dirty-"] && !delay_write) saveMemory();
	}
}

getMemory(memID, itemID)
{
	memory = spawnstruct();
	memory.error = 1;
	memory.value = 0;

	if(!isPlayer(self)) return memory;
	if(!isDefined(memID) || !isDefined(itemID)) return memory;
	if(memID == "" || itemID == "") return memory;
	if(level.ex_memory_log) logprint("Getting memory value for " + memID + "\\" + itemID + "\n");
	if(!checkPlayerStruct()) return memory;

	memID = tolower(memID);
	itemID = tolower(itemID);

	memid_index = inArray(level.memID, memID);
	type_index = inArray(level.memIT[memID], itemID);
	if(memid_index != -1 && type_index != -1)
	{
		// getMemory will check for min and max. It will serve default when out of bounds
		type_expect = level.memTY[memID][itemID].type;
		token = self.pers["memory"][memID][itemID];
		switch(type_expect)
		{
			case "int":
			case "float":
				if(token < level.memTY[memID][itemID].min || token > level.memTY[memID][itemID].max)
				{
					token = level.memTY[memID][itemID].def;
					if(level.ex_memory_log) logprint("Value \"" + token + "\" out of bounce. Serving default \"" + token + "\"\n");
				}
				break;
			case "char":
				if(!isValidChar(token, level.memTY[memID][itemID].min))
				{
					token = level.memTY[memID][itemID].def;
					if(level.ex_memory_log) logprint("Value \"" + token + "\" is invalid. Serving default \"" + token + "\"\n");
				}
				break;
		}

		if(level.ex_memory_log) logprint("Returning value for " + memID + "\\" + itemID + ": \"" + token + "\"\n");
		memory.error = 0;
		memory.value = token;
	}

	return memory;
}

asString(value)
{
	string = "" + value;
	return string;
}

isIntStr(str)
{
	if(!isDefined(str) || str == "") return false;

	validchars = "-+0123456789";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return false;

	return true;
}

isBoolStr(str)
{
	if(!isDefined(str) || str == "") return false;

	validchars = "01";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return false;

	boolean = int(str);
	if(boolean != 0 && boolean != 1) return false;

	return true;
}

isFloatStr(str)
{
	if(!isDefined(str) || str == "") return false;

	validchars = "-+0123456789.";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return false;

	return true;
}

isValidChar(str, validchars)
{
	if(!isDefined(str) || str == "" || str.size > 1) return false;

	invalidchars = " ,";
	if(issubstr(invalidchars, str)) return false;
	if(isDefined(validchars) && validchars != "" && !issubstr(validchars, str)) return false;

	return true;
}

isValidStr(str)
{
	if(!isDefined(str) || str == "") return false;

	invalidchars = " ,";
	for(i = 0; i < str.size; i++)
		if(issubstr(invalidchars, str[i])) return false;

	return true;
}

inArray(array, item)
{
	if(!isDefined(array) || !array.size) return -1;

	for(i = 0; i < array.size; i++) if(array[i] == item) return i;
	return -1;
}

dumpMemoryStruct()
{
	for(i = 0; i < level.memID.size; i++)
		for(j = 0; j < level.memIT[ level.memID[i] ].size; j++)
			logprint("MEMDUMP struct(" + i + "," + j + ") " + level.memID[i] + " " + level.memIT[level.memID[i]][j] + " " + level.memTY[level.memID[i]][level.memIT[level.memID[i]][j]].type + "\n");
}

dumpMemoryPlayers()
{
	players = level.players;
	for(i = 0; i < players.size; i++) dumpMemoryPlayer(players[i]);
}

dumpMemoryPlayer(player)
{
	if(!isDefined(player.pers["memory"])) return;

	for(i = 0; i < level.memID.size; i++)
		for(j = 0; j < level.memIT[ level.memID[i] ].size; j++)
			logprint("MEMDUMP " + player.name + "(" + i + "," + j + ") " + level.memID[i] + " " + level.memIT[level.memID[i]][j] + " " + player.pers["memory"][level.memID[i]][level.memIT[level.memID[i]][j]] + "\n");
}
