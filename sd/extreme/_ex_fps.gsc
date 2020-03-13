
init()
{
	// sv_fps: default "20", domain is any integer from 10 to 1000
	level.ex_fps = 20;

	// var to track frame (frame ticker)
	level.ex_frame = 0;

	if(getCvar("sv_fps") != "")
	{
		level.ex_fps = getCvarInt("sv_fps");
		/*
		if(level.ex_fps > 30)
		{
			level.ex_fps = 30;
			setCvar("sv_fps", level.ex_fps);
		}
		*/
	}
	else setCvar("sv_fps", level.ex_fps);
	setMultiplier();

	if(level.ex_spawncontrol) level thread frameTicker();
	level thread monitorFPS();
	//thread testMultiplier();
}

frameTicker()
{
	while(1)
	{
		wait(0.01);
		waittillframeend;
		level.ex_frame++;
		if(level.ex_frame == 20) level.ex_frame = 0;
	}
}

monitorFPS()
{
	while(1)
	{
		wait( [[level.ex_fpstime]](5) );

		new_fps = getCvarInt("sv_fps");

		if(new_fps != level.ex_fps)
		{
			level.ex_fps = new_fps;
			/*
			if(level.ex_fps > 30)
			{
				level.ex_fps = 30;
				setCvar("sv_fps", level.ex_fps);
			}
			*/
			setMultiplier();
		}
	}
}

setMultiplier()
{
	level.ex_fps_multiplier = getMultiplier(level.ex_fps);
	level.ex_fps_frame = 1 / level.ex_fps;

	level.ex_snaps = level.ex_fps;
	if(level.ex_snaps > 30) level.ex_snaps = 30;

	// snaps: default "20", domain is any integer 1 to 30
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] setClientCvar("snaps", level.ex_snaps);
}

getMultiplier(fps)
{
	switch(fps)
	{
		case 10: return 0.5; // base 0.5
		case 11: return 0.565314; // base 0.55
		case 12: return 0.615314; // base 0.6
		case 13: return 0.665314; // base 0.65
		case 14: return 0.715347; // base 0.7
		case 15: return 0.765314; // base 0.75
		case 16: return 0.815347; // base 0.8
		case 17: return 0.865314; // base 0.85
		case 18: return 0.915347; // base 0.9
		case 19: return 0.965314; // base 0.95
		case 20: return 1; // base 1
		case 21: return 1.06535; // base 1.05
		case 22: return 1.11535; // base 1.1
		case 23: return 1.16535; // base 1.15
		case 24: return 1.22091; // base 1.2
		case 25: return 1.25; // base 1.25
		case 26: return 1.31535; // base 1.3
		case 27: return 1.36535; // base 1.35
		case 28: return 1.42925; // base 1.4
		case 29: return 1.47091; // base 1.45
		case 30: return 1.5; // base 1.5
		default: return (fps / 20);
	}
}

testMultiplier()
{
	wait( [[level.ex_fpstime]](10) );

	for(fps = 10; fps <= 30; fps++)
	{
		level.ex_fps = fps;
		setCvar("sv_fps", fps);
		level.ex_fps_multiplier = level.ex_fps / 20;

		logprint("\n");
		logprint("FPS TEST: sv_fps = " + level.ex_fps + ". Base multiplier: " + level.ex_fps_multiplier + "\n");
		logprint("-----------------------------------------------\n");

		goodmulti = [];

		// get multipliers for 1 to 3 second delays. we want highest precision on small delays
		for(test = 1; test <= 3; test++)
		{
			staging = false;
			stage = 0;
			took = 0;
			lastgood = 0;
			lasttook = 0;

			while(stage < 2)
			{
				mark = getTime();
				wait( [[level.ex_fpstime]](test) );
				took = (getTime() - mark) / 1000;
				if(took == test) break;
				if(took < test)
				{
					staging = true;

					switch(stage)
					{
						case 0:
							level.ex_fps_multiplier += 0.01;
							break;
						case 1:
							level.ex_fps_multiplier += 0.0001;
							break;
						case 2:
							level.ex_fps_multiplier = lastgood;
							took = lasttook;
							stage++;
							break;
					}
				}
				else
				{
					lastgood = level.ex_fps_multiplier;
					lasttook = took;
					if(staging)
					{
						stage++;
						staging = false;
					}

					switch(stage)
					{
						case 0:
							level.ex_fps_multiplier -= 0.01;
							break;
						case 1:
							level.ex_fps_multiplier -= 0.001;
							break;
						case 2:
							level.ex_fps_multiplier -= 0.00001;
							break;
					}
				}
			}

			goodmulti[goodmulti.size] = level.ex_fps_multiplier;
			logprint("wait(" + test + ") took " + took + " seconds. Suggested multiplier: " + level.ex_fps_multiplier + "\n");
		}

		// take average
		multitotal = 0;
		for(i = 0; i < goodmulti.size; i++) multitotal += goodmulti[i];
		level.ex_fps_multiplier = multitotal / goodmulti.size;

		// do final test on 1 - 10 second delays
		logprint("\n");
		logprint("FPS TEST: sv_fps = " + level.ex_fps + ". Final multiplier: " + level.ex_fps_multiplier + "\n");
		for(test = 1; test <= 10; test++)
		{
			mark = getTime();
			wait( [[level.ex_fpstime]](test) );
			took = (getTime() - mark) / 1000;
			logprint("wait(" + test + ") took " + took + " seconds\n");
		}
	}
}
