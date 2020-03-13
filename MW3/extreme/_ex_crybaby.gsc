
start()
{
	self endon("kill_thread");

	if(!level.ex_crybaby) return;
	if(isDefined(self.ex_crybaby)) return;

	// mark and make invulnerable
	self.ex_invulnerable = true;
	self.ex_crybaby = true;

	// save and replace head icon
	self thread extreme\_ex_utils::saveHeadicon();
	self.headicon = game["headicon_crybaby"];
	self.headiconteam = "none";

	// lock player
	self freezecontrols(true);

	// play sound
	self.ex_headmarker playloopsound("crybaby_loop");
	//self thread startSound();

	// show crybaby image and txt
	if(!isdefined(self.crybaby_img))
	{
		self.crybaby_img = newClientHudElem(self);
		self.crybaby_img.horzAlign = "fullscreen";
		self.crybaby_img.vertAlign = "fullscreen";
		self.crybaby_img.alignX = "center";
		self.crybaby_img.alignY = "middle";
		self.crybaby_img.x = 320;
		self.crybaby_img.y = 240;
		self.crybaby_img.archived = false;
		self.crybaby_img.sort = 100;
		self.crybaby_img.alpha = 1 - (level.ex_crybaby_transp / 10);
		self.crybaby_img setShader("exg_crybaby", 64, 64);
	}

	if(isdefined(self.crybaby_img))
	{
		waittime = 1.5;
		self.crybaby_img scaleOverTime(waittime, 384, 384);
		self.crybaby_img fadeOverTime(waittime);
	}

	if(!isdefined(self.crybaby_txt))
	{
		self.crybaby_txt = newClientHudElem(self);
		self.crybaby_txt.horzAlign = "fullscreen";
		self.crybaby_txt.vertAlign = "fullscreen";
		self.crybaby_txt.alignX = "center";
		self.crybaby_txt.alignY = "middle";
		self.crybaby_txt.x = 320;
		self.crybaby_txt.y = 420;
		self.crybaby_txt.archived = false;
		self.crybaby_txt.sort = 101;
		self.crybaby_txt.fontscale = 1.3;
		self.crybaby_txt.color = (1,0,0);
		self.crybaby_txt.alpha = 1;
		self.crybaby_txt setText(&"MISC_CRYBABY");
	}

	for(i = 0; i < level.ex_crybaby_time; i++)
	{
		wait( [[level.ex_fpstime]](0.5) );
		self.crybaby_txt.alpha = !self.crybaby_txt.alpha;
		wait( [[level.ex_fpstime]](0.5) );
		self.crybaby_txt.alpha = !self.crybaby_txt.alpha;

		self.headicon = game["headicon_crybaby"];
		self.headiconteam = "none";
	}

	// stop sound
	self.ex_headmarker stopLoopSound();
	//self notify("stop_crybaby_sound");

	// remove crybaby image and txt
	if(isdefined(self.crybaby_img)) self.crybaby_img destroy();
	if(isdefined(self.crybaby_txt)) self.crybaby_txt destroy();

	// release player
	self freezecontrols(false);

	// restore head icon
	self thread extreme\_ex_utils::restoreHeadicon(game["headicon_protect"]);

	// unmark and make vulnerable
	self.ex_invulnerable = false;
	self.ex_crybaby = undefined;

	// smite
	playfx(level.ex_effect["barrel"], self.origin);
	if(isPlayer(self))
	{
		self.ex_forcedsuicide = true;
		self playSound("artillery_explosion");
		//self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "artillery_mp", 3, 0, 0, "generic", "dirt", true, true, true);
		//self thread [[level.callbackPlayerDamage]](self, self, 200, 1, "MOD_EXPLOSIVE", "artillery_mp", undefined, (0,0,1), "none", 0);
		self suicide();
	}
}

startSound()
{
	self endon("stop_crybaby_sound");
	while(1)
	{
		self playLocalSound("crybaby");
		wait( [[level.ex_fpstime]](13.1) );
	}
}
