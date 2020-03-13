
init()
{
	if(!level.ex_mylogo) return;

	if(!level.ex_mylogo_looptime) alpha = 1 - (level.ex_mylogo_transp / 10);
	  else alpha = 0;

	if(!isDefined(level.mylogo_img))
	{
		level.mylogo_img = newHudElem();
		level.mylogo_img.archived = false;
		level.mylogo_img.horzAlign = "fullscreen";
		level.mylogo_img.vertAlign = "fullscreen";
		level.mylogo_img.alignX = "center";
		level.mylogo_img.alignY = "middle";
		level.mylogo_img.x = level.ex_mylogo_posx;
		level.mylogo_img.y = level.ex_mylogo_posy;
		level.mylogo_img.sort = 3;
		level.mylogo_img.alpha = alpha;
		level.mylogo_img setShader("logo", level.ex_mylogo_sizex, level.ex_mylogo_sizey);
	}

	if(level.ex_mylogo_looptime)
	{
		looptime = level.ex_mylogo_looptime + level.ex_mylogo_fadewait;
		[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, looptime, looptime, randomInt(30)+30);
	}
}

onRandom(eventID)
{
	level endon("ex_gameover");

	if(isDefined(level.mylogo_img))
	{
		level.mylogo_img fadeOverTime(2);
		level.mylogo_img.alpha = 1 - (level.ex_mylogo_transp / 10);
	}

	wait( [[level.ex_fpstime]](level.ex_mylogo_fadewait) );

	if(isDefined(level.mylogo_img))
	{
		level.mylogo_img fadeOverTime(2);
		level.mylogo_img.alpha = 0;
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
