
checkDiana()
{
	diana_server = level.ex_diana;
	if(!diana_server && level.ex_diana_memory) diana_server = 2;
	self setClientCvar("ui_diana", diana_server);

	if(diana_server)
	{
		memory = self extreme\_ex_memory::getMemory("diana", "status");
		if(!memory.error && memory.value == 1) self.pers["diana"] = memory.value;

		if(isDefined(self.pers["diana"])) diana_player = true;
			else diana_player = false;
		self setClientCvar("ui_diana_player", diana_player);
	}
}

toggleDiana()
{
	if(level.ex_diana) self.pers["savedmodel"] = undefined;

	if(isDefined(self.pers["diana"]))
	{
		self.pers["diana"] = undefined;
		//self setClientCvar("ui_diana_player", "0");
	}
	else
	{
		self.pers["diana"] = true;
		//self setClientCvar("ui_diana_player", "1");
	}

	if(level.ex_diana) self iprintln(&"MPUI_DIANA_CHANGED");
	if(level.ex_diana_memory)
	{
		if(isDefined(self.pers["diana"])) diana_player = true;
			else diana_player = false;
		self thread extreme\_ex_memory::setMemory("diana", "status", diana_player);
	}
}
