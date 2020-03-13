
init()
{
	if(!level.ex_flares) return;
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_flares_delay_min, level.ex_flares_delay_max, randomInt(30)+30);
}

onRandom(eventID)
{
	// if entities monitor in defcon 1 or 2, suspend
	if(level.ex_entities_defcon)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// flares entity on random target position
	flares = spawn("script_origin", getTargetPosition());

	// calculate number of flares
	flaresNumber = randomInt(level.ex_flares_max - level.ex_flares_min) + level.ex_flares_min / 2;

	// alert players
	if(level.ex_flare_alert)
	{
		thread extreme\_ex_battlechatter::teamchatter("order_cover_generic", "both");
		wait( [[level.ex_fpstime]](1) );
	}

	// fire flares
	flares.flaresGlobalDelay = 0;
	for(i = 0; i < flaresNumber; i++)
		flares thread fireFlare(calcFlaresPos(flares.origin));

	// wait for all flares to finish
	for(i = 0; i < flaresNumber; i++)
		flares waittill("flare_end");

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
	flares delete();
}

fireFlare(flareTargetPos)
{
	self.flaresGlobalDelay += randomFloatRange( .5, 1.5 );
	wait( [[level.ex_fpstime]](self.flaresGlobalDelay) );
	wait( [[level.ex_fpstime]](randomFloatRange(1.5, 2.5)) );

	// spawn entity for sound positioning
	flare = spawn("script_model", flareTargetPos);
	flare playSound("flare_fire");
	playfx(level.ex_effect["flare_ambient"], flareTargetPos);
	wait( [[level.ex_fpstime]](1) );
	flare playSound("flare_burn");

	if(!level.ex_flare_type) wait( [[level.ex_fpstime]](30) ); // delay for normal flares
		else wait( [[level.ex_fpstime]](40) ); // bright flares last longer

	flare delete();
	self notify("flare_end");
}

getTargetPosition()
{
	x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
	y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
	z = game["playArea_Min"][2];

	return (x, y, z);
}

calcFlaresPos(targetPos)
{
	flaresPos = undefined;
	iterations = 0;

	while(!isDefined(flaresPos) && iterations < 5)
	{
		flaresPos = targetPos;
		angle = randomFloat(360);
		radius = randomFloat(2250);
		randomOffset = (cos(angle) * radius, sin(angle) * radius, 0);
		flaresPos += randomOffset;
		startOrigin = flaresPos + (0, 0, 800);
		endOrigin = flaresPos + (0, 0, -2048);

		trace = bulletTrace( startOrigin, endOrigin, true, undefined );
		if(trace["fraction"] < 1.0) flaresPos = trace["position"];
			else flaresPos = undefined;

		iterations++;
	}

	if(!isDefined(flaresPos)) flaresPos = targetPos;
	return flaresPos;
}
