
main(command)
{
	self endon("disconnect");

	// Catch pin entry commands for CLANLOGIN Main Menu
	pin_entry = 999;
	for(i = 0; i <= 9; i++)
	{
		if(command == "clanlogin_cmd_pin" + i)
		{
			pin_entry = i;
			command = "clanlogin_cmd_pin";
			break;
		}
	}

	// Handle other commands for CLANLOGIN Main Menu
	switch(command)
	{
		case "clanlogin_cmd_pin":
		{
			//logprint("CLANLOGIN: player " + self.name + " sent PIN number " + pin_entry + ".\n");
			self.ex_clanlogin_pin += pin_entry;
			break;
		}
		case "clanlogin_cmd_pinenter":
		{
			if(self.ex_clanlogin_pin != "")
			{
				logprint("CLANLOGIN: player " + self.name + " submitted PIN \"" + self.ex_clanlogin_pin +"\" for validation.\n");
				if(self.ex_clanlogin_pin == level.ex_clanlogin_pin)
				{
					logprint("CLANLOGIN: player " + self.name + ": AUTHORIZED.\n");
					self setClientCvar("ui_clanlogin", "1");
					thread clanLoginTimeframe(5);
				}
				else
				{
					logprint("CLANLOGIN: player " + self.name + ": INVALID PIN.\n");
					self setClientCvar("ui_clanlogin", "0");
					clanLoginFalsePIN();
				}
			}

			self.ex_clanlogin_pin = "";
			break;
		}
		case "clanlogin_cmd_pinclear":
		{
			//logprint("CLANLOGIN: player " + self.name + " cleared PIN.\n");
			self.ex_clanlogin_pin = "";
			self setClientCvar("ui_clanlogin", "0");
			break;
		}
		case "clanlogin_cmd_login":
		{
			logprint("CLANLOGIN: player " + self.name + ": LOGGED IN.\n");
			self.ex_clanlogin = false;
			self setClientCvar("ui_clanlogin", "2");
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
			self closeMenu();
			self closeInGameMenu();
			self openMenu(game["menu_team"]);
			break;
		}
	}
}

clanLoginTimeframe(seconds)
{
	self endon("disconnect");

	loggedin = false;
	for(i = 0; i < seconds; i++)
	{
		if(self.ex_clanlogin == false)
		{
			loggedin = true;
			break;
		}
		wait( [[level.ex_fpstime]](1) );
	}

	if(!loggedin)
	{
		logprint("CLANLOGIN: player " + self.name + " missed the window of opportunity (" + seconds + " seconds).\n");
		self setClientCvar("ui_clanlogin", "0");
	}
	else self thread extreme\_ex_memory::setMemory("clan", "pin", level.ex_clanlogin_pin);
}

clanLoginFalsePIN()
{
	if(!isDefined(self.ex_clanlogin_fallspins)) self.ex_clanlogin_fallspins = 1;
		else self.ex_clanlogin_fallspins += 1;

	if(self.ex_clanlogin_fallspins >= 5)
	{
		logprint("CLANLOGIN: player " + self.name + " kicked for exceeding allowed number of login attempts.\n");
		kick(self getEntityNumber());
	}
}
