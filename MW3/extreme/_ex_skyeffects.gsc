
init()
{
	// tracers
	if(level.ex_tracers) [[level.ex_registerLevelEvent]]("onRandom", ::onTracerEvent, false, level.ex_tracersdelaymin, level.ex_tracersdelaymax, randomInt(30)+30);

	// flak fx
	if(level.ex_flakfx) [[level.ex_registerLevelEvent]]("onRandom", ::onFlakEvent, false, level.ex_flakfxdelaymin, level.ex_flakfxdelaymax, randomInt(30)+30);
}

onTracerEvent(eventID)
{
	for(i = 0; i < level.ex_tracers; i++)
	{
		switch(randomInt(4))
		{
			// North side of map area
			case 0:
				xpos = game["playArea_Max"][0] + int(abs(game["mapArea_Max"][0] - game["playArea_Max"][0]) / 2 );
				ypos = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
				break;
			// East side of map area
			case 1:
				xpos = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
				ypos = game["playArea_Min"][1] - int(abs(game["mapArea_Min"][1] - game["playArea_Min"][1]) / 2 );
				break;
			// South side of map area
			case 2:
				xpos = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
				ypos = game["playArea_Max"][1] + int(abs(game["mapArea_Max"][1] - game["playArea_Max"][1]) / 2 );
				break;
			// West side of map area
			default:
				xpos = game["playArea_Min"][0] - int(abs(game["mapArea_Min"][0] - game["playArea_Min"][0]) / 2 );
				ypos = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
				break;
		}

		position = (xpos, ypos, game["playArea_Max"][2]);

		if(level.ex_tracers_sound) thread extreme\_ex_utils::playSoundLoc("tracer_fire", position);
		playfx(level.ex_effect["tracer"], position);
		wait( [[level.ex_fpstime]](0.5) );
		playfx(level.ex_effect["tracer"], position);
		wait( [[level.ex_fpstime]](2) );
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

onFlakEvent(eventID)
{
	thread fireFlaks(level.ex_flakfx, 0.5);
}

fireFlaks(count, delay)
{
	if(level.ex_axisapinsky + level.ex_allieapinsky + level.ex_paxisapinsky + level.ex_pallieapinsky > 4) return;

	for(i = 0; i < count; i++)
	{
		xpos = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
		ypos = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
		zpos = game["mapArea_Max"][2] - 200;
		position = (xpos, ypos, zpos);

		flak = spawn("script_model", position);
		flak playsound("flak_explosion");
		playfx(level.ex_effect["flak_flash"], position);
		wait( [[level.ex_fpstime]](0.25) );
		playfx(level.ex_effect["flak_smoke"], position);
		wait( [[level.ex_fpstime]](0.25) );
		playfx(level.ex_effect["flak_dust"], position);
		wait( [[level.ex_fpstime]](0.25) );
		flak delete();

		wait( [[level.ex_fpstime]](delay) );
	}
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return var;
}
