/*

Authorization:
To use the toolbox, you should add a valid name in the authorized players array:
	authplayers[authplayers.size] = "playername";
Either re-use an existing line, or create a new one:
	authplayers[authplayers.size] = "playername1";
	authplayers[authplayers.size] = "playername2";
The name has to match the in-game name exactly, including color codes.

Third Person tool:
Enable this tool, by setting the tool enabling variable to true:
	tool_thirdperson = true;
After spawning you are able to go into third person mode by holding the USE key
for one second. In this mode, holding the USE key for one second, will change
the distance, until you switch to first person mode again.
By holding the MELEE key for one second, you are able to change the angle.

Show Position tool:
Enable this tool, by setting the tool enabling variable to true:
	tool_showpos = true;
After spawning you will see two lines. First is current origin as (x,y,z).
Second line is angles as (pitch, yaw, roll).
By holding the MELEE key for one second, you are able to record the current
origin and angles in games_mp.log.

*/

main()
{
	level endon("ex_gameover");
	self endon("disconnect");

	authplayers = [];

	// Enable the tools for the following players (include color codes)
	authplayers[authplayers.size] = "playername";

	// Enable the tools you need (preferably only enable one at a time)
	tool_thirdperson = true;
	tool_showpos = false;

	// No need to change anything below this line
	tool_authorized = false;
	for(i = 0; i < authplayers.size; i++)
		if(self.name == authplayers[i]) tool_authorized = true;
	if(!tool_authorized) return;

	if(tool_thirdperson) self thread showThirdPerson();
	if(tool_showpos) self thread showPos();
}

showThirdPerson()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["ex_thirdperson"])) return;
	self.pers["ex_thirdperson"] = true;
	logprint("TOOLBOX: third person view started for player: " + self.name + "\n");

	self.ex_thirdperson = false;
	thirdpersonangle = 0;
	thirdpersonrange = 100;

	meleecount = 0;
	usecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		// Monitor USE key. Reset counter if ADS, sprinting or rearming
		if(self useButtonPressed() && !self playerADS() && !self.ex_sprinting && !self.handling_mine && !isDefined(self.ex_amc_rearm) && !isDefined(self.ex_ishealing))
		{
			// Should have held key for 1 second at least
			if(usecount > 5)
			{
				if(self.ex_thirdperson)
				{
					thirdpersonrange += 20;
					if(thirdpersonrange > 200)
					{
						thirdpersonrange = 100;
						self setClientCvar("cg_thirdperson", 0);
						self.ex_thirdperson = false;
						usecount = 0;
					}
					else self setClientCvar("cg_thirdpersonrange", thirdpersonrange);
				}
				else
				{
					self setClientCvar("cg_thirdpersonangle", thirdpersonangle);
					self setClientCvar("cg_thirdpersonrange", thirdpersonrange);
					self setClientCvar("cg_thirdperson", 1);
					self.ex_thirdperson = true;
					usecount = 0;
				}
			}
			else usecount++;
		}
		else usecount = 0;

		if(self.ex_thirdperson)
		{
			// Monitor MELEE key. Reset counter if ADS, sprinting, planting or defusing
			if(self meleeButtonPressed() && !self playerADS() && !self.ex_plantwire && !self.ex_defusewire)
			{
				// Should have held key for 1 second at least
				if(meleecount > 5)
				{
					thirdpersonangle += 10;
					if(thirdpersonangle == 360) thirdpersonangle = 0;
					self setClientCvar("cg_thirdpersonangle", thirdpersonangle);
				}
				else meleecount++;
			}
			else meleecount = 0;
		}
	}
}

showPos()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["ex_showpos"])) return;
	self.pers["ex_showpos"] = true;
	logprint("TOOLBOX: position indicator started for player: " + self.name + "\n");

	meleecount = 0;
	savecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		origin = self.origin;

		// Position X
		if(!isDefined(self.ex_showposx))
		{
			self.ex_showposx = newClientHudElem(self);
			self.ex_showposx.archived = false;
			self.ex_showposx.horzAlign = "fullscreen";
			self.ex_showposx.vertAlign = "fullscreen";
			self.ex_showposx.alignX = "center";
			self.ex_showposx.alignY = "top";
			self.ex_showposx.x = 250;
			self.ex_showposx.y = 155;
			self.ex_showposx.fontscale = 1.0;
			self.ex_showposx.color = (1, 0, 0);
		}
		self.ex_showposx setValue(origin[0]);

		// Position Y
		if(!isDefined(self.ex_showposy))
		{
			self.ex_showposy = newClientHudElem(self);
			self.ex_showposy.archived = false;
			self.ex_showposy.horzAlign = "fullscreen";
			self.ex_showposy.vertAlign = "fullscreen";
			self.ex_showposy.alignX = "center";
			self.ex_showposy.alignY = "top";
			self.ex_showposy.x = 320;
			self.ex_showposy.y = 155;
			self.ex_showposy.fontscale = 1.0;
			self.ex_showposy.color = (1, 0, 0);
		}
		self.ex_showposy setValue(origin[1]);

		// Position Z
		if(!isDefined(self.ex_showposz))
		{
			self.ex_showposz = newClientHudElem(self);
			self.ex_showposz.archived = false;
			self.ex_showposz.horzAlign = "fullscreen";
			self.ex_showposz.vertAlign = "fullscreen";
			self.ex_showposz.alignX = "center";
			self.ex_showposz.alignY = "top";
			self.ex_showposz.x = 390;
			self.ex_showposz.y = 155;
			self.ex_showposz.fontscale = 1.0;
			self.ex_showposz.color = (1, 0, 0);
		}
		self.ex_showposz setValue(origin[2]);

		angles = self getplayerangles();

		// Angle X
		if(!isDefined(self.ex_showanglex))
		{
			self.ex_showanglex = newClientHudElem(self);
			self.ex_showanglex.archived = false;
			self.ex_showanglex.horzAlign = "fullscreen";
			self.ex_showanglex.vertAlign = "fullscreen";
			self.ex_showanglex.alignX = "center";
			self.ex_showanglex.alignY = "top";
			self.ex_showanglex.x = 250;
			self.ex_showanglex.y = 175;
			self.ex_showanglex.fontscale = 1.0;
			self.ex_showanglex.color = (1, 0, 0);
		}
		self.ex_showanglex setValue(angles[0]);

		// Angle Y
		if(!isDefined(self.ex_showangley))
		{
			self.ex_showangley = newClientHudElem(self);
			self.ex_showangley.archived = false;
			self.ex_showangley.horzAlign = "fullscreen";
			self.ex_showangley.vertAlign = "fullscreen";
			self.ex_showangley.alignX = "center";
			self.ex_showangley.alignY = "top";
			self.ex_showangley.x = 320;
			self.ex_showangley.y = 175;
			self.ex_showangley.fontscale = 1.0;
			self.ex_showangley.color = (1, 0, 0);
		}
		self.ex_showangley setValue(angles[1]);

		// Angle Z
		if(!isDefined(self.ex_showanglez))
		{
			self.ex_showanglez = newClientHudElem(self);
			self.ex_showanglez.archived = false;
			self.ex_showanglez.horzAlign = "fullscreen";
			self.ex_showanglez.vertAlign = "fullscreen";
			self.ex_showanglez.alignX = "center";
			self.ex_showanglez.alignY = "top";
			self.ex_showanglez.x = 390;
			self.ex_showanglez.y = 175;
			self.ex_showanglez.fontscale = 1.0;
			self.ex_showanglez.color = (1, 0, 0);
		}
		self.ex_showanglez setValue(angles[2]);

		// Monitor MELEE key. Reset counter if ADS, sprinting, planting or defusing
		if(self meleeButtonPressed() && !self playerADS() && !self.ex_plantwire && !self.ex_defusewire)
		{
			// Should have held key for 1 second at least
			if(meleecount > 5)
			{
				savecount++;
				logprint("TOOLBOX: [" + savecount + "] " + "origin " + origin + ", " + "angles " + angles + "\n");
				meleecount = 0;
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}
