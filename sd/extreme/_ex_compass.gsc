
init()
{
	if(level.ex_compass_changer)
	{
		level.ex_compass_transp = [[level.ex_drm]]("ex_compass_transp", 0, 0, 9, "int");
		level.ex_compass_interval = [[level.ex_drm]]("ex_compass_interval", 300, 0, 3600, "int");
		if(level.ex_compass_interval > 0 && level.ex_compass_interval < 30) level.ex_compass_interval = 30;
		level.ex_compass_still = [[level.ex_drm]]("ex_compass_still", 0, 0, 999, "int");
		level.ex_compass_stock = [[level.ex_drm]]("ex_compass_stock", 1, 0, 1, "int");
		level.ex_compass_fade = [[level.ex_drm]]("ex_compass_fade", 2, 0, 5, "int");

		// Init image array, and set slot 0 (stock compass background)
		level.ex_compassback = [];
		level.ex_compassback[0] = "compassback";

		// Get the custom compass images
		count = 1;
		for(;;)
		{
			compassback = [[level.ex_drm]]("ex_compass_image_" + count, "", "", "", "string");
			if(compassback == "") break;
			level.ex_compassback[level.ex_compassback.size] = compassback;
			count++;
		}

		// If only the stock image present, disable compass changer
		if(level.ex_compassback.size == 1)
		{
			level.ex_compassback = undefined;
			level.ex_compass_changer = 0;
		}
	}

	// Tell the client
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_compass_changer", level.ex_compass_changer);
	if(!level.ex_compass_changer) return;

	compass_rotate = true;
	level.ex_compass_startimage = 0;
	if(!level.ex_compass_interval && (level.ex_compass_still < level.ex_compassback.size))
	{
		level.ex_compass_startimage = level.ex_compass_still;
		compass_rotate = false;
	}
	else
	{
		if(!level.ex_compass_stock)
		{
			level.ex_compass_startimage = 1;
			if(level.ex_compassback.size == 1) compass_rotate = false;
		}
	}

	// Make sure we have a proper waiting time for the while loop
	if(!level.ex_compass_interval) level.ex_compass_interval = 300;

	// Set the image to start with
	level.ex_compass_no = level.ex_compass_startimage;

	// Prepare HUD elements
	for(i = 0; i < level.ex_compassback.size; i++)
		[[level.ex_PrecacheShader]](level.ex_compassback[i]);

	if(level.ex_teamplay)
	{
		if(!isDefined(level.compass_imgA))
		{
			level.compass_imgA = newTeamHudElem("allies");
			level.compass_imgA.horzAlign = "left";
			level.compass_imgA.vertAlign = "bottom";
			level.compass_imgA.alignX = "left";
			level.compass_imgA.alignY = "middle";
			level.compass_imgA.x = -15;
			level.compass_imgA.y = -60;
			level.compass_imgA.sort = 3;
			level.compass_imgA.alpha = 1 - (level.ex_compass_transp / 10);
			level.compass_imgA setShader(level.ex_compassback[level.ex_compass_no], 50, 50);
		}

		if(!isDefined(level.compass_imgX))
		{
			level.compass_imgX = newTeamHudElem("axis");
			level.compass_imgX.horzAlign = "left";
			level.compass_imgX.vertAlign = "bottom";
			level.compass_imgX.alignX = "left";
			level.compass_imgX.alignY = "middle";
			level.compass_imgX.x = -15;
			level.compass_imgX.y = -60;
			level.compass_imgX.sort = 3;
			level.compass_imgX.alpha = 1 - (level.ex_compass_transp / 10);
			level.compass_imgX setShader(level.ex_compassback[level.ex_compass_no], 50, 50);
		}
	}
	else
	{
		if(!isDefined(level.compass_img))
		{
			level.compass_img = newHudElem();
			level.compass_img.horzAlign = "left";
			level.compass_img.vertAlign = "bottom";
			level.compass_img.alignX = "left";
			level.compass_img.alignY = "middle";
			level.compass_img.x = -15;
			level.compass_img.y = -60;
			level.compass_img.sort = 3;
			level.compass_img.alpha = 1 - (level.ex_compass_transp / 10);
			level.compass_img setShader(level.ex_compassback[level.ex_compass_no], 50, 50);
		}
	}

	if(!compass_rotate) return;
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, level.ex_compass_interval);
}

onRandom(eventID)
{
	level endon("ex_gameover");

	// Fade out
	if(level.ex_compass_fade)
	{
		if(level.ex_teamplay)
		{
			if(isDefined(level.compass_imgA))
			{
				level.compass_imgA fadeOverTime(level.ex_compass_fade);
				level.compass_imgA.alpha = 0;
			}
			if(isDefined(level.compass_imgX))
			{
				level.compass_imgX fadeOverTime(level.ex_compass_fade);
				level.compass_imgX.alpha = 0;
			}
		}
		else
		{
			if(isDefined(level.compass_img))
			{
				level.compass_img fadeOverTime(level.ex_compass_fade);
				level.compass_img.alpha = 0;
			}
		}

		wait( [[level.ex_fpstime]](level.ex_compass_fade) );
	}

	// Set new image
	level.ex_compass_no++;
	if(level.ex_compass_no > (level.ex_compassback.size - 1))
		level.ex_compass_no = level.ex_compass_startimage;

	if(level.ex_teamplay)
	{
		if(isDefined(level.compass_imgA))
			level.compass_imgA setShader(level.ex_compassback[level.ex_compass_no], 80, 80);
		if(isDefined(level.compass_imgX))
			level.compass_imgX setShader(level.ex_compassback[level.ex_compass_no], 80, 80);
	}
	else
	{
		if(isDefined(level.compass_img))
			level.compass_img setShader(level.ex_compassback[level.ex_compass_no], 80, 80);
	}

	// Fade in
	if(level.ex_compass_fade)
	{
		if(level.ex_teamplay)
		{
			if(isDefined(level.compass_imgA))
			{
				level.compass_imgA fadeOverTime(level.ex_compass_fade);
				level.compass_imgA.alpha = 1 - (level.ex_compass_transp / 10);
			}
			if(isDefined(level.compass_imgX))
			{
				level.compass_imgX fadeOverTime(level.ex_compass_fade);
				level.compass_imgX.alpha = 1 - (level.ex_compass_transp / 10);
			}
		}
		else
		{
			if(isDefined(level.compass_img))
			{
				level.compass_img fadeOverTime(level.ex_compass_fade);
				level.compass_img.alpha = 1 - (level.ex_compass_transp / 10);
			}
		}
	}
}
