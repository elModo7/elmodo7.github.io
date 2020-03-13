
init()
{
	// _ex_varcache
	if(level.ex_wintermap)
	{
		level.ex_effect["weather_0"] = loadfx("fx/misc/snow_0.efx");
		level.ex_effect["weather_1"] = loadfx("fx/misc/snow_1.efx");
		level.ex_effect["weather_2"] = loadfx("fx/misc/snow_2.efx");
		level.ex_effect["weather_3"] = loadfx("fx/misc/snow_3.efx");
		level.ex_effect["weather_4"] = loadfx("fx/misc/snow_4.efx");
		level.ex_effect["weather_5"] = loadfx("fx/misc/snow_5.efx");
		level.ex_effect["weather_6"] = loadfx("fx/misc/snow_6.efx");
		level.ex_effect["weather_7"] = loadfx("fx/misc/snow_7.efx");
		level.ex_effect["weather_8"] = loadfx("fx/misc/snow_8.efx");
		level.ex_effect["weather_9"] = loadfx("fx/misc/snow_9.efx");
		level.ex_effect["weather_10"] = loadfx("fx/misc/snow_10.efx");
	}
	else
	{
		level.ex_effect["weather_0"] = loadfx("fx/misc/rain_0.efx");
		level.ex_effect["weather_1"] = loadfx("fx/misc/rain_1.efx");
		level.ex_effect["weather_2"] = loadfx("fx/misc/rain_2.efx");
		level.ex_effect["weather_3"] = loadfx("fx/misc/rain_3.efx");
		level.ex_effect["weather_4"] = loadfx("fx/misc/rain_4.efx");
		level.ex_effect["weather_5"] = loadfx("fx/misc/rain_5.efx");
		level.ex_effect["weather_6"] = loadfx("fx/misc/rain_6.efx");
		level.ex_effect["weather_7"] = loadfx("fx/misc/rain_7.efx");
		level.ex_effect["weather_8"] = loadfx("fx/misc/rain_8.efx");
		level.ex_effect["weather_9"] = loadfx("fx/misc/rain_9.efx");
		level.ex_effect["weather_10"] = loadfx("fx/misc/rain_10.efx");
		if(level.ex_weather_lightning) level.ex_effect["lightning"] = loadfx("fx/misc/lightning.efx");
	}
}

main()
{
	// _ex_main level
	level.ex_weather_level = 0;
	level.ex_effect["weather"] = level.ex_effect["weather_" + level.ex_weather_level];
	if(level.ex_weather_visibility) visibilityChange(0, 0);

	if(level.ex_wintermap)
	{
		level.ex_weather_maxlevel = level.ex_weather_snow_max;
		x = game["playArea_CentreX"];
		y = game["playArea_CentreY"];
		z = 450;
		z_max = game["mapArea_Max"][2] - 100;
		if(z > z_max) z = z_max;
		level.ex_weather_snow = spawn("script_origin", (x,y,z));
		thread snowMain();
	}
	else
	{
		level.ex_weather_maxlevel = level.ex_weather_rain_max;
		if(level.ex_weather_lightning) thread lightningMain();
	}

	//thread weatherHUD();

	wait( [[level.ex_fpstime]](30 + randomint(60)) );

	weather = [];
	weather[weather.size] = "none";
	weather[weather.size] = "light";
	weather[weather.size] = "medium";
	weather[weather.size] = "hard";
	weather[weather.size] = "extreme";

	while(!level.ex_gameover)
	{
		type = randomint(weather.size);
		subtype = 0;
		allowed = true;
		transition = 5 + randomint(level.ex_weather_transition);
		duration = 30 + randomint(level.ex_weather_duration);

		switch(weather[type])
		{
			case "none":
				subtype = 0;
				break;
			case "light":
				subtype = randomint(3) + 1;
				allowed = randomint(100) <= level.ex_weather_prob_light;
				break;
			case "medium":
				subtype = randomint(3) + 4;
				allowed = randomint(100) <= level.ex_weather_prob_medium;
				break;
			case "hard":
				subtype = randomint(3) + 7;
				allowed = randomint(100) <= level.ex_weather_prob_hard;
				break;
			case "extreme":
				subtype = 10;
				allowed = randomint(100) <= level.ex_weather_prob_extreme;
				duration = 15 + randomint(30);
				break;
		}

		if(subtype > level.ex_weather_maxlevel || !allowed)
		{
			duration /= 2;
			if(level.ex_weather_none_fallback) weatherChange(0, transition, duration);
				else wait( [[level.ex_fpstime]](duration) );
		}
		else weatherChange(subtype, transition, duration);
	}
}

// -----------------------------------------------------------------------------
// RAIN OR SNOW TRANSITION
// -----------------------------------------------------------------------------
weatherChange(weather_level, transition, duration)
{
	transition_step = 0;
	if(level.ex_weather_level > weather_level) transition_step = -1;
	if(level.ex_weather_level < weather_level) transition_step = 1;
	transition_steps = maps\mp\_utility::abs(level.ex_weather_level - weather_level);

	if(transition_steps)
	{
		transition_wait = transition / transition_steps;
		for(i = 0; i < transition_steps; i++)
		{
			wait( [[level.ex_fpstime]](transition_wait) );
			level.ex_weather_level += transition_step;
			level.ex_effect["weather"] = level.ex_effect["weather_" + level.ex_weather_level];
		}
	}

	if(level.ex_weather_visibility)
	{
		vis_delay = (transition_steps * level.ex_weather_visibility) + 1;
		vis_trans = (transition_steps * level.ex_weather_visibility) + transition_steps;
		visibilityChange(vis_delay, vis_trans);
	}

	wait( [[level.ex_fpstime]](duration) );
}

weatherHUD()
{
	while(!level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](0.5) );

		if(!isDefined(level.ex_weatherDebugHUD))
		{
			level.ex_weatherDebugHUD = newHudElem();
			level.ex_weatherDebugHUD.archived = false;
			level.ex_weatherDebugHUD.horzAlign = "fullscreen";
			level.ex_weatherDebugHUD.vertAlign = "fullscreen";
			level.ex_weatherDebugHUD.alignX = "center";
			level.ex_weatherDebugHUD.alignY = "top";
			level.ex_weatherDebugHUD.x = 320;
			level.ex_weatherDebugHUD.y = 10;
			level.ex_weatherDebugHUD.fontscale = 2.0;
			level.ex_weatherDebugHUD.color = (1, 0, 0);
		}
		level.ex_weatherDebugHUD setValue(level.ex_weather_level);
	}

	if(isDefined(level.ex_weatherDebugHUD)) level.ex_weatherDebugHUD destroy();
}

// -----------------------------------------------------------------------------
// SNOW
// -----------------------------------------------------------------------------
snowMain()
{
	current_fxid = -1;

	while(!level.ex_gameover)
	{
		if(current_fxid != level.ex_effect["weather"])
		{
			level notify("stop_snow");
			if(level.ex_weather_level) thread snowLoop(level.ex_effect["weather"], level.ex_weather_snow.origin, 2);
			current_fxid = level.ex_effect["weather"];
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

snowLoop(fxId, fxPos, fxDelay)
{
	wait( [[level.ex_fpstime]](0.05) );

	fxAngle = vectorNormalize((fxPos + (0,0,100)) - fxPos);
	looper = playLoopedFx(fxId, fxDelay, fxPos, 0, fxAngle);
	level waittill("stop_snow");
	if(isdefined(looper)) looper delete();
}

// -----------------------------------------------------------------------------
// LIGHTNING
// -----------------------------------------------------------------------------
lightningMain()
{
	next_lightning = gettime() + 10000 + randomfloat(4000);
	lightning = gettime() + ((lightningWait(false) + lightningWait(true)) * 1000);
	if(lightning < next_lightning) next_lightning = lightning;

	while(!level.ex_gameover)
	{
		timer = (next_lightning - gettime()) * 0.001;
		if(timer > 0) wait( [[level.ex_fpstime]](timer) );
			
		if(level.ex_weather_level) lightningSky();
		next_lightning = gettime() + ((lightningWait(false) + lightningWait(true)) * 1000);
	}
}

lightningSky()
{
	flash = [];
	flash[flash.size] = "single";
	flash[flash.size] = "double";
	flash[flash.size] = "triple";
	flash_type = randomint(flash.size);

	x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
	y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
	z = game["mapArea_Max"][2] - 200;
	position = (x, y, z);

	if(level.ex_weather_thunder) thread lightningThunder(position);

	switch(flash[flash_type])
	{
		case "single":
		{
			playfx(level.ex_effect["lightning"], position);
			break;
		}
		case "double":
		{
			playfx(level.ex_effect["lightning"], position);
			wait( [[level.ex_fpstime]](0.2) );
			playfx(level.ex_effect["lightning"], position);
			break;
		}
		case "triple":
		{
			playfx(level.ex_effect["lightning"], position);
			wait( [[level.ex_fpstime]](0.2) );
			playfx(level.ex_effect["lightning"], position);
			wait( [[level.ex_fpstime]](0.4) );
			playfx(level.ex_effect["lightning"], position);
			break;
		}
	}
}

lightningThunder(position)
{
	seconds = ((11 - level.ex_weather_level) / 2);
	seconds += randomfloat(seconds);

	thunder = spawn("script_origin", position);
	thunder playsound("elm_thunder", "sounddone");
	thunder waittill("sounddone");
	thunder delete();	
}

lightningWait(random)
{
	seconds = (11 - level.ex_weather_level) * 3;
	if(random) seconds = randomfloat(seconds);
	return seconds;
}

// -----------------------------------------------------------------------------
// VISIBILITY
// -----------------------------------------------------------------------------
visibilityChange(delay, transition)
{
	red = 0.6;
	green = 0.7;
	blue = 0.8;
	density = visibilityValue();
	if(level.ex_weather_visibility_modifier) density *= level.ex_weather_visibility_modifier;

	if(delay) wait( [[level.ex_fpstime]](delay) );
	setExpFog(density, red, green, blue, transition);
	if(transition) wait( [[level.ex_fpstime]](transition) );
}

visibilityValue()
{
	switch(level.ex_weather_level)
	{
		case  0: return 0.00001;
		case  1: return 0.00002;
		case  2: return 0.00003;
		case  3: return 0.00005;
		case  4: return 0.00007;
		case  5: return 0.00008;
		case  6: return 0.00009;
		case  7: return 0.0001;
		case  8: return 0.0002;
		case  9: return 0.0003;
		case 10: return 0.0004;
	}
}
