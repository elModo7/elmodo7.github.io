
init()
{
	if(!level.ex_modtext && !level.ex_clantext) return;

	if(!isDefined(level.ex_modinfo))
	{
		level.ex_modinfo = newHudElem();
		level.ex_modinfo.archived = false;
		level.ex_modinfo.horzAlign = "fullscreen";
		level.ex_modinfo.vertAlign = "fullscreen";
		level.ex_modinfo.alignX = "right";
		level.ex_modinfo.alignY = "middle";
		level.ex_modinfo.x = 375;
		level.ex_modinfo.y = 470;
		level.ex_modinfo.alpha = 0;
		level.ex_modinfo.fontScale = 0.8;
	}

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 60, 60, randomInt(30)+30);
}

onRandom(eventID)
{
	if(level.ex_clantext && isDefined(level.ex_clanlotxt))
	{
		level.ex_modinfo setText(level.ex_clanlotxt);
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 1;
		wait( [[level.ex_fpstime]](10) );
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 0;
		wait( [[level.ex_fpstime]](1) );
	}

	if(level.ex_modtext)
	{
		level.ex_modinfo setText(&"CUSTOM_MODINFO_NAME");
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 1;
		wait( [[level.ex_fpstime]](5) );
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 0;
		wait( [[level.ex_fpstime]](1) );

		level.ex_modinfo setText(&"CUSTOM_MODINFO_BY");
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 1;
		wait( [[level.ex_fpstime]](5) );
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 0;
		wait( [[level.ex_fpstime]](1) );

		level.ex_modinfo setText(&"CUSTOM_MODINFO_WEBSITE");
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 1;
		wait( [[level.ex_fpstime]](5) );
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 0;
		wait( [[level.ex_fpstime]](1) );
	}
}
