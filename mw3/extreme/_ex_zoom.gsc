#include extreme\_ex_weapons;

checkZoom()
{
	zoom_server = (level.ex_zoom != 0);
	//if(!zoom_server && level.ex_zoom_memory) zoom_server = 2;
	self setClientCvar("ui_zoom", zoom_server);

	// prepare zoom levels memory
	zoom_level_sr = level.ex_zoom_default_sr;
	zoom_level_lr = level.ex_zoom_default_lr;

	if(level.ex_zoom == 2 && level.ex_zoom_memory)
	{
		memory = self extreme\_ex_memory::getMemory("zoom", "sr");
		if(!memory.error) zoom_level_sr = memory.value;

		memory = self extreme\_ex_memory::getMemory("zoom", "lr");
		if(!memory.error) zoom_level_lr = memory.value;
	}

	thread prepForMemory(zoom_level_sr, zoom_level_lr);
}

main()
{
	self endon("kill_thread");

	// make sure it initializes the zoom
	zoom_reset = true;

	zoom_level = 0;
	zoom_min = 1;
	zoom_max = 10;
	zoom_first_sr = true;
	zoom_first_lr = true;

	zoom_oldclass = 0;
	zoom_oldweapon = "unknown";

	// prepare zoom levels memory
	zoom_oldlevel_sr = level.ex_zoom_default_sr;
	zoom_oldlevel_lr = level.ex_zoom_default_lr;

	if(level.ex_zoom == 2 && level.ex_zoom_memory)
	{
		memory = self extreme\_ex_memory::getMemory("zoom", "sr");
		if(!memory.error) zoom_oldlevel_sr = memory.value;

		memory = self extreme\_ex_memory::getMemory("zoom", "lr");
		if(!memory.error) zoom_oldlevel_lr = memory.value;
	}

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](0.05) );

		if(self playerADS())
		{
			// Exclude binoculars from zooming (playersADS() is true for binocs too)
			if(isDefined(self.ex_binocuse) && self.ex_binocuse) continue;

			// check weapon class
			zoom_weapon = self getCurrentWeapon();
			if((level.ex_zoom_class & 1) == 1 && isWeaponType(zoom_weapon, "snipersr")) zoom_class = 1;
				else if((level.ex_zoom_class & 2) == 2 && level.ex_longrange && isWeaponType(zoom_weapon, "sniperlr")) zoom_class = 2;
					else zoom_class = 0;

			// allow zoom if class allowed
			if(zoom_class)
			{
				zoom_ok = true;

				// load new settings if class changed
				if(zoom_class != zoom_oldclass)
				{
					zoom_oldclass = zoom_class;
					zoom_reset = true;

					switch(zoom_class)
					{
						case 1:
							zoom_min = level.ex_zoom_min_sr;
							zoom_max = level.ex_zoom_max_sr;
							if(zoom_first_sr)
							{
								zoom_first_sr = false;
								zoom_level = level.ex_zoom_default_sr;
								if(level.ex_zoom == 2 && level.ex_zoom_memory)
								{
									memory = self extreme\_ex_memory::getMemory("zoom", "sr");
									if(!memory.error) zoom_level = memory.value;
								}
								zoom_oldlevel_sr = zoom_level;
							}
							else
							{
								zoom_oldlevel_lr = zoom_level;
								zoom_level = zoom_oldlevel_sr;
							}
							break;
						case 2:
							zoom_min = level.ex_zoom_min_lr;
							zoom_max = level.ex_zoom_max_lr;
							if(zoom_first_lr)
							{
								zoom_first_lr = false;
								zoom_level = level.ex_zoom_default_lr;
								if(level.ex_zoom == 2 && level.ex_zoom_memory)
								{
									memory = self extreme\_ex_memory::getMemory("zoom", "lr");
									if(!memory.error) zoom_level = memory.value;
								}
								zoom_oldlevel_lr = zoom_level;
							}
							else
							{
								zoom_oldlevel_sr = zoom_level;
								zoom_level = zoom_oldlevel_lr;
							}
							break;
					}

					if(zoom_level > zoom_max || zoom_level < zoom_min) zoom_reset = true;
				}

				if(zoom_weapon != zoom_oldweapon)
				{
					if(level.ex_zoom_switchreset) zoom_reset = true;
					zoom_oldweapon = zoom_weapon;
				}
			}
			else zoom_ok = false;

			if(zoom_ok)
			{
				if(zoom_reset)
				{
					zoom_reset = false;
					setZoomLevel(zoom_level, false);
					if(zoom_class == 1) thread prepForMemory(zoom_level, undefined);
						else thread prepForMemory(undefined, zoom_level);
					if(level.ex_zoom == 1 && (level.ex_zoom_switchreset || level.ex_zoom_adsreset)) continue;
				}

				if(!isDefined(self.ex_zoomhud))
				{
					self.ex_zoomhud = newClientHudElem(self);
					self.ex_zoomhud.archived = false;
					self.ex_zoomhud.horzAlign = "fullscreen";
					self.ex_zoomhud.vertAlign = "fullscreen";
					self.ex_zoomhud.alignx = "center";
					self.ex_zoomhud.aligny = "middle";
					self.ex_zoomhud.x = 320;
					self.ex_zoomhud.y = 380;
					self.ex_zoomhud.alpha = .9;
					self.ex_zoomhud.fontScale = 2;
					self.ex_zoomhud setvalue(zoom_level);
				}

				if(self useButtonPressed() && zoom_level > zoom_min)
				{
					zoom_level--;
					if(level.ex_zoom_gradual) self playlocalsound("zoomauto");
						else self playlocalsound("zoommanual");
					thread setZoomLevel(zoom_level, level.ex_zoom_gradual);
					if(zoom_class == 1) thread prepForMemory(zoom_level, undefined);
						else thread prepForMemory(undefined, zoom_level);
					wait( [[level.ex_fpstime]](0.2) );
				}
				else
				if(self meleeButtonPressed() && zoom_level < zoom_max)
				{
					zoom_level++;
					if(level.ex_zoom_gradual) self playlocalsound("zoomauto");
						else self playlocalsound("zoommanual");
					thread setZoomLevel(zoom_level, level.ex_zoom_gradual);
					if(zoom_class == 1) thread prepForMemory(zoom_level, undefined);
						else thread prepForMemory(undefined, zoom_level);
					wait( [[level.ex_fpstime]](0.2) );
				}
			}
			else if(isDefined(self.ex_zoomhud)) self.ex_zoomhud destroy();
		}
		else if(isDefined(self.ex_zoomhud))
		{
			self.ex_zoomhud destroy();

			// save zoom level if switching weapons from zoom class to non zoom class during ADS
			if(zoom_oldclass == 1) zoom_oldlevel_sr = zoom_level;
				else if(zoom_oldclass == 2) zoom_oldlevel_lr = zoom_level;

			// reset zoom level if not ADS
			if(level.ex_zoom_adsreset) zoom_reset = true;
		}
	}
}

setZoomLevel(zoomlevel, gradual)
{
	self endon("kill_thread");

	self notify("stop_zooming");
	waittillframeend;
	self endon("stop_zooming");

	self.ex_zoomtarget = (81 - (zoomlevel * 8));

	if(gradual && isDefined(self.ex_zoom))
	{
		if(self.ex_zoomtarget > self.ex_zoom)
		{
			for(i = self.ex_zoom + 1; i <= self.ex_zoomtarget; i++) setZoom(zoomlevel, i);
		}
		else
		if(self.ex_zoomtarget < self.ex_zoom)
		{
			for(i = self.ex_zoom - 1; i >= self.ex_zoomtarget; i--) setZoom(zoomlevel, i);
		}
	}
	else setZoom(zoomlevel, self.ex_zoomtarget);
}

setZoom(zoomlevel, zoomvalue)
{
	self endon("kill_thread");

	self.ex_zoom = zoomvalue;
	self setclientCvar("cg_fovmin", self.ex_zoom);

	if(isDefined(self.ex_zoomhud))
		self.ex_zoomhud setvalue(zoomlevel);

	wait( [[level.ex_fpstime]](0.05) );
}

prepForMemory(level_sr, level_lr)
{
	if(isDefined(level_sr)) self.pers["zoom_sr"] = level_sr;
	if(isDefined(level_lr)) self.pers["zoom_lr"] = level_lr;
}

saveZoom()
{
	if(level.ex_zoom == 2)
	{
		self thread extreme\_ex_memory::setMemory("zoom", "sr", self.pers["zoom_sr"], true);
		self thread extreme\_ex_memory::setMemory("zoom", "lr", self.pers["zoom_lr"]);
	}
	else
	{
		self thread extreme\_ex_memory::setMemory("zoom", "sr", level.ex_zoom_default_sr, true);
		self thread extreme\_ex_memory::setMemory("zoom", "lr", level.ex_zoom_default_lr);
	}
}
