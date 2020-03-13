#include extreme\_ex_utils;

main()
{
	if(isExcluded()) return;

	self endon("kill_thread");

	if(!isDefined(self.ex_laserdot))
	{
		self.ex_laserdot = newClientHudElem(self);
		self.ex_laserdot.archived = false;
		self.ex_laserdot.horzAlign = "fullscreen";
		self.ex_laserdot.vertAlign = "fullscreen";
		self.ex_laserdot.alignX = "center";
		self.ex_laserdot.alignY = "middle";
		self.ex_laserdot.x = 320;
		self.ex_laserdot.y = 242;
		self.ex_laserdot.alpha = 0;
		self.ex_laserdot.color = (level.ex_laserdotred, level.ex_laserdotgreen, level.ex_laserdotblue);
		self.ex_laserdot setShader("white", level.ex_laserdotsize, level.ex_laserdotsize );
	}

	if(level.ex_laserdot == 1) self.ex_laserdot.alpha = 1;
		else [[level.ex_registerPlayerEvent]]("onHalfSecond", ::onHalfSecond);
}

onHalfSecond(eventID)
{
	self endon("kill_thread");

	if(isDefined(self.ex_laserdot))
	{
		switch(level.ex_laserdot)
		{
			case 2:
				if(self playerads()) self.ex_laserdot.alpha = 1;
					else self.ex_laserdot.alpha = 0;
				break;
			case 3:
				if(self playerads()) self.ex_laserdot.alpha = 0;
					else self.ex_laserdot.alpha = 1;
				break;
		}
	}
}

isExcluded()
{
	self endon("disconnect");

	count = 0;
	clan_check = "";

	if(isDefined(self.ex_name))
	{
		playerclan = convertMUJ(self.ex_name);

		for(;;)
		{
			clan_check = [[level.ex_drm]]("ex_laserdot_clan_" + count, "", "", "", "string");
			if(clan_check == "") break;
			clan_check = convertMUJ(clan_check);
			if(clan_check == playerclan) break;
				else count++;
		}
	}

	if(clan_check != "") return true;

	count = 0;
	playername = convertMUJ(self.name);

	for(;;)
	{
		name_check = [[level.ex_drm]]("ex_laserdot_name_" + count, "", "", "", "string");
		if(name_check == "") break;
		name_check = convertMUJ(name_check);
		if(name_check == playername) break;
			else count++;
	}

	if(name_check != "") return true;

	return false;
}
