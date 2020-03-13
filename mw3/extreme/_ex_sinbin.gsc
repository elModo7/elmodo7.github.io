
main()
{
	self endon("kill_thread");

	if(self.ex_sinbin) return;

	if(isPlayer(self) && self.sessionstate == "playing")
	{
		self.ex_sinbin = true;

		if(randomInt(100) < 50 && extreme\_ex_utils::isOutside(self.origin)) self sinSplat();
			else self sinFreeze();
		
		if(isPlayer(self)) self.ex_sinbin = false;
	}
}

sinFreeze()
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self thread sinTimer(level.ex_sinfrztime);

		msg1 = &"SINBIN_FREEZE";
		msg2 = extreme\_ex_utils::time_convert(level.ex_sinfrztime);

		switch(level.ex_sinbinmsg)
		{
			case 0:
				self iprintln(msg1);
				self iprintln(msg2);
				break;
			case 1:
				self iprintlnbold(msg1);
				self iprintlnbold(msg2);
				break;
		}
	}

	if(isPlayer(self))
	{
		// drop flag
		self extreme\_ex_utils::dropTheFlag(true);
		self thread extreme\_ex_utils::punishment("random", "freeze");
	}

	self waittill("sinbin_timer_done");
	if(isPlayer(self)) self thread extreme\_ex_utils::punishment("enable", "release");
}

sinSplat()
{
	self endon("kill_thread");

	self notify("ex_freefall");

	if(isPlayer(self))
	{
		msg1 = &"SINBIN_FREEFALL";

		switch(level.ex_sinbinmsg)
		{
			case 0:
				self iprintln(msg1);
				break;
			case 1:
				self iprintlnbold(msg1);
				break;
		}

		if(isPlayer(self))
		{
			// drop flag
			self extreme\_ex_utils::dropTheFlag(true);
			self thread extreme\_ex_punishments::doWarp(false);
		}
	}
}

sinTimer(time)
{
	self endon("kill_thread");

	// make them drop their grenades
	if(isPlayer(self)) self thread maps\mp\gametypes\_weapons::dropOffhand(true);

	while(isPlayer(self) && time > 0)
	{
		wait( [[level.ex_fpstime]](1) );
		time--;
	}

	self notify("sinbin_timer_done");
}
