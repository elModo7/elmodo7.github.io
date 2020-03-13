
main()
{
	level endon("ex_gameover");
	self endon("disconnect");

	self.ex_arcade_test = 0;
	self notify("arcade_test");
	wait( [[level.ex_fpstime]](0.1) );
	if(self.ex_arcade_test) return;
	self thread arcadeActive();

	if(!isDefined(self.ex_arcade)) self.ex_arcade = newClientHudElem(self);
	if(isDefined(self.ex_arcade))
	{
		self.ex_arcade.archived = true;
		self.ex_arcade.horzAlign = "fullscreen";
		self.ex_arcade.vertAlign = "fullscreen";
		self.ex_arcade.alignX = "center";
		self.ex_arcade.alignY = "middle";
		self.ex_arcade.x = 300;
		self.ex_arcade.y = 255;
		self.ex_arcade.fontscale = 1.5;
		self.ex_arcade.alpha = 0;
		self.ex_arcade fontPulseInit();
	}
	else
	{
		logprint("ARCADE: could not create self.ex_arcade for " + self.name + "\n");
		return;
	}

	if(level.ex_arcade_shaders)
	{
		if(!isDefined(self.ex_arcade_shader)) self.ex_arcade_shader = newClientHudElem(self);
		if(isDefined(self.ex_arcade_shader))
		{
			self.ex_arcade_shader.archived = true;
			self.ex_arcade_shader.horzAlign = "fullscreen";
			self.ex_arcade_shader.vertAlign = "fullscreen";
			self.ex_arcade_shader.alignX = "center";
			self.ex_arcade_shader.alignY = "middle";
			self.ex_arcade_shader.x = 330;
			self.ex_arcade_shader.y = 200;
			self.ex_arcade_shader.alpha = 0;
		}
		else
		{
			logprint("ARCADE: could not create self.ex_arcade_shader for " + self.name + "\n");
			return;
		}
	}

	self.ex_arcade_oldscore = self.score;
	while(1)
	{
		self waittill("update_playerscore_hud");
		self thread checkScoreUpdate();
	}
}

checkScoreUpdate()
{
	level endon("ex_gameover");
	self endon("disconnect");

	scorediff = self.score - self.ex_arcade_oldscore;
	if(scorediff != 0) self thread showScoreUpdate(scorediff);
}

showScoreUpdate(scorediff)
{
	level endon("ex_gameover");
	self endon("disconnect");

	self notify("kill_scoreupdate");
	waittillframeend;
	self endon("kill_scoreupdate");

	// wait a brief moment to let quick consecutive kills come through
	wait( [[level.ex_fpstime]](0.1) );

	if(isDefined(self.ex_arcade))
	{
		self.ex_arcade.alpha = 0;

		if(scorediff < 0)
		{
			self.ex_arcade.label = &"MP_MINUS";
			self.ex_arcade.color = (1, 0, 0);
		}
		else if(scorediff > 0)
		{
			self.ex_arcade.label = &"MP_PLUS";
			self.ex_arcade.color = (level.ex_arcade_red, level.ex_arcade_green, level.ex_arcade_blue);
		}

		scoreabs = abs(scorediff);
		self.ex_arcade setValue(scoreabs);
		self.ex_arcade.alpha = 1;

		self.ex_arcade fontPulse(self);

		if(isDefined(self.ex_arcade))
		{
			self.ex_arcade fadeOverTime(1);
			self.ex_arcade.alpha = 0;
		}
	}

	self.ex_arcade_oldscore = self.score;
}

showArcadeShader(shader, time)
{
	level endon("ex_gameover");
	self endon("disconnect");

	self notify("kill_shaderupdate");
	waittillframeend;
	self endon("kill_shaderupdate");

	// wait a brief moment to let quick consecutive kills come through
	wait( [[level.ex_fpstime]](0.5) );

	if(isDefined(self.ex_arcade_shader))
	{
		if(!isDefined(time)) time = 1;
		self.ex_arcade_shader.alpha = 0;
		self.ex_arcade_shader setShader(shader, 150, 150);
		self.ex_arcade_shader.alpha = 1;

		if(time > 2) wait( [[level.ex_fpstime]](time - 1) );
			else wait( [[level.ex_fpstime]](time) );

		if(isDefined(self.ex_arcade_shader))
		{
			self.ex_arcade_shader fadeOverTime(1);
			self.ex_arcade_shader.alpha = 0;
		}
	}
}

arcadeActive()
{
	level endon("ex_gameover");
	self endon("disconnect");

	while(1)
	{
		self waittill("arcade_test");
		self.ex_arcade_test = 1;
	}
}

fontPulseInit()
{
	self.pulse_orgfontscale = self.fontscale;
	self.pulse_maxfontscale = self.fontscale * 1.5;
	self.pulse_inframes = 3;
	self.pulse_outframes = 4;
}

fontPulse(player)
{
	self notify("fontpulse");
	self endon("fontpulse");

	level endon("ex_gameover");
	player endon("kill_scoreupdate");
	player endon("disconnect");

	scalerange = self.pulse_maxfontscale - self.pulse_orgfontscale;

	while(self.fontscale < self.pulse_maxfontscale)
	{
		self.fontScale = min(self.pulse_maxfontscale, self.fontscale + (scalerange / self.pulse_inframes));
		wait( [[level.ex_fpstime]](level.ex_fps_frame) );
	}

	while(self.fontscale > self.pulse_orgfontscale)
	{
		self.fontScale = max(self.pulse_orgfontscale, self.fontscale - (scalerange / self.pulse_outframes));
		wait( [[level.ex_fpstime]](level.ex_fps_frame) );
	}
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}

min(x, y)
{
	if(x < y) return(x);
	return(y);
}

max(x, y)
{
	if(x > y) return(x);
	return(y);
}
