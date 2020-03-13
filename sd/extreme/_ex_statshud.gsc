
init()
{
	// Process DRM vars
	level.ex_statshud_safemode = [[level.ex_drm]]("ex_statshud_safemode", 1, 0, 1, "int");
	level.ex_statshud_autohide = [[level.ex_drm]]("ex_statshud_autohide", 1, 0, 1, "int");
	level.ex_statshud_autohide_sec = [[level.ex_drm]]("ex_statshud_autohide_sec", 3, 1, 10, "int");
	level.ex_statshud_autohide_toggle = [[level.ex_drm]]("ex_statshud_autohide_toggle", 1, 0, 1, "int");
	level.ex_statshud_transp = [[level.ex_drm]]("ex_statshud_transp", 4, 0, 9, "int");

	level.ex_statshud_cflag = [[level.ex_drm]]("ex_statshud_cflag", 1, 0, 1, "int");   // flag captures
	level.ex_statshud_kills = [[level.ex_drm]]("ex_statshud_kills", 1, 0, 1, "int");   // kills
	level.ex_statshud_skills = [[level.ex_drm]]("ex_statshud_skills", 0, 0, 1, "int"); // sniper kills
	level.ex_statshud_hkills = [[level.ex_drm]]("ex_statshud_hkills", 0, 0, 1, "int"); // headshot kills
	level.ex_statshud_bkills = [[level.ex_drm]]("ex_statshud_bkills", 0, 0, 1, "int"); // bash kills
	level.ex_statshud_tkills = [[level.ex_drm]]("ex_statshud_tkills", 0, 0, 1, "int"); // team kills
	level.ex_statshud_deaths = [[level.ex_drm]]("ex_statshud_deaths", 1, 0, 1, "int"); // deaths
	level.ex_statshud_eff = [[level.ex_drm]]("ex_statshud_eff", 1, 0, 1, "int");       // efficiency
	level.ex_statshud_lspree = [[level.ex_drm]]("ex_statshud_lspree", 1, 0, 1, "int"); // longest spree
	level.ex_statshud_ldist = [[level.ex_drm]]("ex_statshud_ldist", 1, 0, 1, "int");   // longest distance shot
	level.ex_statshud_lhead = [[level.ex_drm]]("ex_statshud_lhead", 0, 0, 1, "int");   // longest headshot

	// Create shader name array
	statsmax = 5;
	level.statshud = [];
	if(level.ex_flagbased && level.ex_statshud_cflag && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_cf";
	if(level.ex_statshud_kills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_kt";
	if(level.ex_statshud_skills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_sk";
	if(level.ex_statshud_hkills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_hk";
	if(level.ex_statshud_bkills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_bk";
	if(level.ex_statshud_tkills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_tk";
	if(level.ex_statshud_deaths && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_dt";
	if(level.ex_statshud_eff && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_ef";
	if(level.ex_statshud_lspree && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_ls";
	if(level.ex_statshud_ldist && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_ld";
	if(level.ex_statshud_lhead && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_lh";

	// If at least one stat is activated, proceed
	if(level.statshud.size > 0)
	{
		// Precache left and right side shaders
		[[level.ex_PrecacheShader]]("statshud_sl"); // left side
		[[level.ex_PrecacheShader]]("statshud_sr"); // right side

		// Precache stats shaders
		for(i = 0; i < level.statshud.size; i++)
			[[level.ex_PrecacheShader]](level.statshud[i]);

		// Start level monitor for player connections
		[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
		[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	}
	// No stat activated, so turn off player stats
	else level.ex_statshud = 0;
}

onPlayerSpawned()
{
	// If allowed, monitor auto-hide toggle
	if(level.ex_statshud_autohide_toggle)
	{
		if(!level.ex_specials) self thread autohideMonitor();
			else level.ex_statshud_autohide_toggle = 0;
	}

	// Create stats dashboard
	self thread createStatsHUD();
}

onPlayerKilled()
{
	// Destroy stats dashboard
	self thread destroyStatsHUD();
}

autohideMonitor()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["statshudautohide"]))
	  self.pers["statshudautohide"] = level.ex_statshud_autohide;

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.5) );
		if(self meleeButtonPressed() && !self playerADS() && !(isDefined(self.ex_thirdperson) && self.ex_thirdperson))
		{
			meleepressed = 0;
			// To toggle, player must be standing and not moving
			while(self meleeButtonPressed() && self.ex_stance == 0 && !self.ex_moving && !self playerADS())
			{
				meleepressed++;
				if(meleepressed > 30) // 3 seconds
				{
					self.pers["statshudautohide"] = !self.pers["statshudautohide"];
					if(self.pers["statshudautohide"]) self thread moveStatsHUD(-1); // down
						else self thread moveStatsHUD(1); // up
					break;
				}
				wait( [[level.ex_fpstime]](0.1) );
			}
		}
	}
}

createStatsHUD()
{
	self endon("kill_thread");

	if(!isDefined(self.statshud_img)) self.statshud_img = [];
	if(!isDefined(self.statshud_val)) self.statshud_val = [];
	self.statshud_moving = 0;
	self.statshud_extrasec = 0;
	self.statshud_lock = undefined;

	posx = 200 - ((level.statshud.size / 2) * 32) - 32;
	posy = 474;

	// Shader for left side of dashboard (no value)
	if(!isDefined(self.statshud_left))
	{
		self.statshud_left = newClientHudElem(self);
		self.statshud_left.archived = false;
		// subleft (def), left, center, right, fullscreen, noscale, alignto640, center_safearea
		self.statshud_left.horzAlign = "subleft";
		// subtop (def), top, middle, bottom, fullscreen, noscale, alignto474, center_safearea
		self.statshud_left.vertAlign = "subtop";
		self.statshud_left.alignX = "center"; // left (def), center, right
		self.statshud_left.alignY = "bottom"; // top (def), middle, bottom
		self.statshud_left.x = posx;
		self.statshud_left.y = posy;
		self.statshud_left.sort = 1;
		self.statshud_left.alpha = 1 - (level.ex_statshud_transp / 10);
		self.statshud_left setShader("statshud_sl", 48, 48);
	}
	posx += 28;

	// Shaders and initial values for selected stats
	for(i = 0; i < level.statshud.size; i++)
	{
		if(!isDefined(self.statshud_img[i]))
		{
			self.statshud_img[i] = newClientHudElem(self);
			self.statshud_img[i].archived = false;
			self.statshud_img[i].horzAlign = "subleft";
			self.statshud_img[i].vertAlign = "subtop";
			self.statshud_img[i].alignX = "center";
			self.statshud_img[i].alignY = "bottom";
			self.statshud_img[i].x = posx;
			self.statshud_img[i].y = posy;
			self.statshud_img[i].sort = 1;
			self.statshud_img[i].alpha = 1 - (level.ex_statshud_transp / 10);
			self.statshud_img[i] setShader(level.statshud[i], 48, 48);
		}
		// Initial values (0)
		if(!isDefined(self.statshud_val[i]))
		{
			self.statshud_val[i] = newClientHudElem(self);
			self.statshud_val[i].archived = false;
			self.statshud_val[i].horzAlign = "subleft";
			self.statshud_val[i].vertAlign = "subtop";
			self.statshud_val[i].alignX = "right";
			self.statshud_val[i].alignY = "bottom";
			self.statshud_val[i].x = posx + 7;
			self.statshud_val[i].y = posy - 12;
			self.statshud_val[i].sort = 2;
			self.statshud_val[i].font = "default";
			self.statshud_val[i].fontScale = 1.2;
			self.statshud_val[i].alpha = 1 - (level.ex_statshud_transp / 10);
			self.statshud_val[i] setValue(0);
		}
		posx += 40;
	}

	// Shader for right side of dashboard (no value)
	if(!isDefined(self.statshud_right))
	{
		self.statshud_right = newClientHudElem(self);
		self.statshud_right.archived = false;
		self.statshud_right.horzAlign = "subleft";
		self.statshud_right.vertAlign = "subtop";
		self.statshud_right.alignX = "center";
		self.statshud_right.alignY = "bottom";
		self.statshud_right.x = posx;
		self.statshud_right.y = posy;
		self.statshud_right.sort = 1;
		self.statshud_right.alpha = 1 - (level.ex_statshud_transp / 10);
		self.statshud_right setShader("statshud_sr", 48, 48);
	}

	// Show stats
	self thread showStatsHud();
}

destroyStatsHUD()
{
	if(isdefined(self.statshud_left)) self.statshud_left destroy();
	if(isdefined(self.statshud_img))
	{
		for(i = 0; i < self.statshud_img.size; i++)
			if(isdefined(self.statshud_img[i])) self.statshud_img[i] destroy();
	}
	if(isdefined(self.statshud_val))
	{
		for(i = 0; i < self.statshud_val.size; i++)
			if(isdefined(self.statshud_val[i])) self.statshud_val[i] destroy();
	}
	if(isdefined(self.statshud_right)) self.statshud_right destroy();
}

showStatsHUD()
{
	self endon("kill_thread");

	self thread updateStatsHUD();
	
	// If toggling auto-hide is enabled, did player disable auto-hide?
	if(level.ex_statshud_autohide_toggle && !self.pers["statshudautohide"]) return;

	// Is auto-hiding disabled globally?
	if(!level.ex_statshud_autohide) return;

	// Move stats HUD up and down
	self thread moveStatsHUD(1); // up
	if(!isDefined(self.statshud_lock))
	{
		self.statshud_lock = true;
		self waittill("statshudup");
		wait( [[level.ex_fpstime]](level.ex_statshud_autohide_sec) );
		while(self.statshud_extrasec > 0)
		{
			self.statshud_extrasec--;
			wait( [[level.ex_fpstime]](1) );
		}
		self.statshud_lock = undefined;
		self thread moveStatsHUD(-1); // down
	}
}

moveStatsHUD(direction)
{
	self endon("kill_thread");

	if(!isDefined(self.statshud_left)) return;
	if(!isDefined(direction)) direction = 1;
	if(direction == 0) return;

	// direction: 1 = move up, -1 = move down
	if(direction == 1)
	{
		posy = 480;
		movetime = 0.5;
	}
	else
	{
		posy = 544;
		movetime = 1;
	}

	// statshud_moving: 1 = moving up, 0 = not moving , -1 = moving down
	if(self.statshud_moving == 0)
	{
		if(self.statshud_left.y == posy)
		{
			if(direction == 1)
			{
				self.statshud_extrasec++;
				wait( [[level.ex_fpstime]](0.1) ); // So we don't fire the notify before it reaches the waittill
				self notify("statshudup");
			}
			return;
		}
	}
	else
	{
		if(self.statshud_moving != direction)
		{
			movetime = (544 - self.statshud_left.y) / 64;
			if(direction == 1) movetime = (1 - movetime) * movetime;
			if(movetime <= 0) movetime = .1;
		}
		else return;
	}

	self.statshud_moving = direction;

	if(isdefined(self.statshud_left)) self.statshud_left moveOverTime(movetime);
	for(i = 0; i < self.statshud_img.size; i++)
		if(isdefined(self.statshud_img[i])) self.statshud_img[i] moveOverTime(movetime);
	for(i = 0; i < self.statshud_val.size; i++)
		if(isdefined(self.statshud_val[i])) self.statshud_val[i] moveOverTime(movetime);
	if(isdefined(self.statshud_right)) self.statshud_right moveOverTime(movetime);

	if(isdefined(self.statshud_left)) self.statshud_left.y = posy;
	for(i = 0; i < self.statshud_img.size; i++)
		if(isdefined(self.statshud_img[i])) self.statshud_img[i].y = posy;
	for(i = 0; i < self.statshud_val.size; i++)
		if(isdefined(self.statshud_val[i])) self.statshud_val[i].y = posy - 15;
	if(isdefined(self.statshud_right)) self.statshud_right.y = posy;

	wait( [[level.ex_fpstime]](movetime) );
	self.statshud_moving = 0;
	if(direction == 1) self notify("statshudup");
}

updateStatsHUD()
{
	self endon("kill_thread");

	if(self.statshud_moving)
 		self waittill("statshudup");

	if(level.ex_gameover) return;

	for(i = 0; i < level.statshud.size; i++)
	{
		switch(level.statshud[i])
		{
			case "statshud_kt":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["kill"]);
				break;
			case "statshud_sk":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["sniperkill"]);
				break;
			case "statshud_hk":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["headshotkill"]);
				break;
			case "statshud_bk":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["bashkill"]);
				break;
			case "statshud_tk":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["teamkill"]);
				break;
			case "statshud_dt":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["death"]);
				break;
			case "statshud_ef":
			{
				if(self.pers["kill"] == 0 || (self.pers["kill"] - self.pers["death"]) <= 0) efficiency = 0;
					else efficiency = int( (100 / self.pers["kill"]) * (self.pers["kill"] - self.pers["death"]) );
				if(efficiency > 100) efficiency = 0;
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(efficiency);
				break;
			}
			case "statshud_ld":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["longdist"]);
				break;
			case "statshud_lh":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["longhead"]);
				break;
			case "statshud_ls":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["longspree"]);
				break;
			case "statshud_cf":
				if(isdefined(self.statshud_val[i]))
					self.statshud_val[i] SetValue(self.pers["flagcap"]);
				break;
		}
	}
}
