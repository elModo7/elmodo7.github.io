
init()
{
	if(!level.ex_mortars) return;
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_mortars_delay_min, level.ex_mortars_delay_max, randomInt(30)+30);
}

onRandom(eventID)
{
	// if entities monitor in defcon 1 or 2, suspend
	if(level.ex_entities_defcon)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// two waves
	for(wave = 0; wave < 2; wave++)
	{
		extreme\_ex_utils::playSoundOnPlayers("mortarlaunch_incoming");
		if(!wave) thread extreme\_ex_battlechatter::teamchatter("inform_incoming_mortar", "both");
			else if(randomInt(100) > 50) thread extreme\_ex_battlechatter::teamchatter("order_cover_generic", "both");
		wait( [[level.ex_fpstime]](randomfloat(4) + 0.5) );

		mortarcount = 0;
		mortarnumber = randomInt(level.ex_mortars_max - level.ex_mortars_min) + level.ex_mortars_min / 2;
		if(mortarnumber < 2) mortarnumber = 2;

		for(mortar = 0; mortar < mortarnumber; mortar++)
		{
			thread fireMortar();
			wait( [[level.ex_fpstime]](0.3) );
		}

		wait( [[level.ex_fpstime]](5) );
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

fireMortar()
{
	x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
	y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
	z = game["mapArea_Max"][2] - 200;

	// start point for mortar
	startpoint = (x, y, z);
	endorigin = (x,y,z - 2048);

	// get the impact point
	trace = bulletTrace(startpoint, endorigin, true, undefined);                   
	if(trace["fraction"] < 1) endorigin = trace["position"];
		else endorigin = (endorigin[0], endorigin[1], game["mapArea_Min"][2]);

	// show visible mortar object
	mortar = spawn("script_model", startpoint);
	mortar setModel("xmodel/prop_stuka_bomb");
	mortar.origin = startpoint;
	mortar.angles = vectortoangles(vectornormalize(mortar.origin - startpoint));

	// play the incoming sound
	ms = randomInt(14) + 1;
	mortar playsound("mortar_incoming" + ms);

	falltime = randomfloat(1) + 0.5;

	// move visible mortar
	mortar moveto(endorigin, falltime);

	// wait for it to hit
	wait( [[level.ex_fpstime]](falltime) );

	// play the explosion sound
	ms = randomInt(18) + 1;
	mortar playsound("mortar_explosion" + ms);

	// do the damage!
	surfaceFx = calcImpactSurface(mortar.origin);
	if(level.ex_mortars == 1)
		mortar thread extreme\_ex_utils::scriptedfxradiusdamage(mortar, undefined, "MOD_EXPLOSIVE", "mortar_mp", level.ex_mortar_radius, 0, 0, "generic",  surfaceFX, true, true, true);
                
	if(level.ex_mortars == 2)
		mortar thread extreme\_ex_utils::scriptedfxradiusdamage(mortar, undefined, "MOD_EXPLOSIVE", "mortar_mp", level.ex_mortar_radius, 500, 350, "generic", surfaceFX, true, true, true);

	// hide visible mortar
	mortar hide();
	wait( [[level.ex_fpstime]](1) );
	mortar delete();
}

calcImpactSurface(targetPos)
{
	startOrigin = targetPos + (0, 0, 800);
	endOrigin = targetPos + (0, 0, -2048);

	trace = bulletTrace(startOrigin, endOrigin, true, undefined);
	if(trace["fraction"] < 1.0) surface = trace["surfacetype"];
		else surface = "dirt";

	if(!isDefined(surface)) surface = "dirt";
	return surface;
}
