
init()
{
	if(!level.ex_planes) return;

	if(randomInt(100) < 50) level.ex_planes_team = 1;
		else level.ex_planes_team = 0;

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_planes_delay_min, level.ex_planes_delay_max, randomInt(30)+30);
}

onRandom(eventID)
{
	// if entities monitor in defcon 1 or 2, suspend
	if(level.ex_entities_defcon)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// set up plane amount (normal)
	apcount = randomInt(level.ex_planes_max - level.ex_planes_min) + level.ex_planes_min;
	apflangle = randomInt(360);

	// set planes in sky values
	if(level.ex_planes_team == 0) level.ex_allieapinsky += apcount;
		else level.ex_axisapinsky += apcount;

	if(level.ex_air_raid) thread extreme\_ex_utils::playSoundLoc("air_raid",(0,0,0));
	if(level.ex_planes_flak) level thread extreme\_ex_skyeffects::fireFlaks(10, 0.25);

	level.ex_planes_globaldelay = 0;

	for(i = 0; i < apcount; i++)
	{
		droppos = (game["playArea_CentreX"], game["playArea_CentreY"], game["mapArea_Max"][2] - 200);

		iterations = 0;
		while(iterations <= 50)
		{
			iterations++;
			wait( [[level.ex_fpstime]](0.05) );

			switch(randomInt(4))
			{
				// North-East quadrant of map area
				case 0:
					x = game["playArea_Max"][0] - randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Min"][1] + randomInt( int(game["playArea_Length"] / 2) );
					break;
				// South-East quadrant of map area
				case 1:
					x = game["playArea_Min"][0] + randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Min"][1] + randomInt( int(game["playArea_Length"] / 2) );
					break;
				// South-West quadrant of map area
				case 2:
					x = game["playArea_Min"][0] + randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Max"][1] - randomInt( int(game["playArea_Length"] / 2) );
					break;
				// North-West quadrant of map area
				default:
					x = game["playArea_Max"][0] - randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Max"][1] - randomInt( int(game["playArea_Length"] / 2) );
					break;
			}

			z = game["mapArea_Max"][2] - 200;
			if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;
			droppos = (x,y,z);

			trace = bulletTrace(droppos, droppos + (0,0,-10000), false, undefined);
			if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") continue;
			targetpos = trace["position"];
			targetdist = distance(droppos, targetpos);
			if(targetdist <= game["mapArea_Max"][2] + 1000) break;
			//else logprint("DEBUG: targetdist " + targetdist + " > " + game["mapArea_Max"][2] + " maparea_max\n");
		}

		stenpos = getPlaneStartEnd( droppos, apflangle );
		stenpos2 = getPlaneStartEnd( (stenpos[1]), apflangle );
		if(stenpos2[2] == 1) stenpos[1] = stenpos2[1];

		// create the plane
		thread planestart(apflangle, stenpos[0], stenpos[1], level.ex_planes_team, droppos);
	}

	// switch teams for next event
	level.ex_planes_team = !level.ex_planes_team;

	// wait for all planes to finish
	for(i = 0; i < apcount; i++)
		level waittill("ambplane_finished");

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

planestart(apflangle, apstpoint, apenpoint, apteam, droppos)
{
	level.ex_planes_globaldelay += randomFloatRange( 2, 5 );
	wait( [[level.ex_fpstime]](level.ex_planes_globaldelay) );

	trace = bulletTrace(droppos, droppos + (0,0,-10000), false, undefined);
	targetpos = trace["position"];

	apmodel = [];
	apsoundchoice = [];

	if(apteam == 0)
	{
		// plane models
		apmodel[0] = "xmodel/vehicle_mig29";
		apmodel[1] = "xmodel/vehicle_mig29";

		// plane sounds
		apsoundchoice[0] = "spitfire_flyby_1";
		apsoundchoice[1] = "spitfire_flyby_1";
	}
	else
	{
		// plane models
		apmodel[0] = "xmodel/vehicle_mig29";
		apmodel[1] = "xmodel/vehicle_mig29";
		apmodel[2] = "xmodel/vehicle_mig29";

		// plane sounds
		apsoundchoice[0] = "spitfire_flyby_1";
	}

	aprand = randomInt(apmodel.size);
	apsound = apsoundchoice[randomInt(apsoundchoice.size)];

	planetype = 0; // fighter
	if(apteam == 0 && aprand == 1) planetype = 1; // axis bomber
		else if(apteam == 1 && aprand == 2) planetype = 1; // allies bomber

	plane = spawn("script_model", apstpoint);
	plane setModel(apmodel[aprand]);

	if(apteam == 1 && aprand == 2)
	{
		plane.angles = (plane.angles[0], apflangle, plane.angles[2]);

	}
	else if(apteam == 0 && aprand == 0) plane.angles = (plane.angles[0] + 10, apflangle, plane.angles[2]);
		else plane.angles = (plane.angles[0], apflangle, plane.angles[2]);

	plane.apdivesound = spawn("script_model", (0,0,0));
	plane.apdivesound.origin = apstpoint - (0,50,0);
	plane.apdivesound linkto(plane);

	plane.apsound = spawn("script_model", (0,0,0));
	plane.apsound.origin = apstpoint - (0,50,0);
	plane.apsound linkto(plane);
	plane.apsound playloopsound(apsound);

	// calculate drop distance
	mapsquare = (game["mapArea_Width"] + game["mapArea_Length"]) / 2;
	mapheight = game["mapArea_Max"][2];
	if(mapsquare >= 10500 && mapheight >= 4500) dropdist = 5000;
		else if(mapsquare >= 9500 && mapheight >= 4000) dropdist = 4500;
			else dropdist = 4000;
	maxdist = distance(apstpoint, droppos);
	if(maxdist < dropdist) dropdist = maxdist;
	if(dropdist < 1000) droprate = 0.1;
		else droprate = 0.2;

	// set speed
	if(planetype == 0) apspeed = 85; // fighters
		else apspeed = 60; // bombers

	// flighttime
	flighttime = calcTime(apstpoint, apenpoint, apspeed);
	plane moveto(apenpoint, flighttime);

	plane.isbombing = false;
	// chance that plane will crash, but
	// - only fighters, because memphis has axis mixed up (and I'm too lazy to include the other bomber)
	// - only if there weren't enough crashes already (4 max)
	planecrash = false;
	if(randomInt(100) < 10 && level.ex_planescrashed < 4 && planetype == 0) planecrash = true;

	for(i = 0; i < flighttime; i += 0.05)
	{
		if(!plane.isbombing && level.ex_planes >= 2 /*&& planetype == 1*/ && (distance(droppos, plane.origin) < dropdist) )
		{
			// DEBUG: black line from drop to target
			//level thread extreme\_ex_utils::dropLine(droppos, targetpos, (0,0,0));
			plane thread bombSetup(targetpos, droprate);
			plane.isbombing = true;
		}

		if(planecrash && !plane.isbombing && (distance(game["playArea_Centre"], plane.origin) < dropdist * 2) )
		{
			plane thread airplanecrash(apspeed, apteam);
			return;
		}
		wait( [[level.ex_fpstime]](0.05) );
	}

	if(isDefined(plane.apsound))
	{
		plane.apsound stopLoopSound();
		plane.apsound delete();
	}

	if(isDefined(plane.apdivesound))
	{
		plane.apdivesound stopLoopSound();
		plane.apdivesound delete();
	}

	if(apteam == 0) level.ex_axisapinsky--;
		else level.ex_allieapinsky--;

	if(isDefined(plane)) plane delete();
	level notify("ambplane_finished");
}

bombSetup(targetpos, droprate)
{
	bombcount = 0;
	bombno = randomInt(3) + 4;

	linecolor = (randomFloat(1),randomFloat(1),randomFloat(1));

	while(bombcount < bombno)
	{
		self thread dropBomb(targetpos, linecolor);
		bombcount++;
		wait( [[level.ex_fpstime]](droprate) );
	}
}

dropBomb(targetpos, linecolor)
{
	if(!isDefined(self)) return;

	// get the impact point
	startpos = self.origin;
	impactpos = calcShellPos(startpos, targetpos, 10000, true);

	// DEBUG: colored line from plane origin to impact
	//level thread extreme\_ex_utils::dropLine(startpos, impactpos, linecolor, true);

	// bomb falltime
	falltime = calcTime(startpos, impactpos, 25);

	// spawn the bomb and drop it
	bomb = spawn("script_model", startpos);
	bomb.angles = self.angles + (-180 + randomint(50),0,0);
	bomb setModel("xmodel/prop_stuka_bomb");
	bomb moveto(impactpos + (0,0,-100), falltime);

	// play the incoming sound falling sound
	ms = randomInt(14) + 1;
	bomb playsound("mortar_incoming" + ms);

	// wait for it to hit
	wait( [[level.ex_fpstime]](falltime) );

	// do the damage
	if(level.ex_planes == 2)
		bomb thread extreme\_ex_utils::scriptedfxradiusdamage(bomb, undefined, "MOD_EXPLOSIVE", "planebomb_mp", level.ex_airstrike_radius, 0, 0, "plane_bomb", undefined, true, true, true);

	if(level.ex_planes == 3)
		bomb thread extreme\_ex_utils::scriptedfxradiusdamage(bomb, undefined, "MOD_EXPLOSIVE", "planebomb_mp", level.ex_airstrike_radius, 500, 400, "plane_bomb", undefined, true, true, true);

	// play the explosion sound
	ms = randomInt(18) + 1;
	bomb playsound("mortar_explosion" + ms);

	bomb hide();
	wait( [[level.ex_fpstime]](1) );
	bomb delete();
}

calcShellPos(pos, targetpos, dist, oneshot)
{
	impactpos = targetpos;
	angle = randomFloat(360);
	radius = randomFloat(500);
	impactpos += (cos(angle) * radius, sin(angle) * radius, 0);

	random_yaw = randomInt(30);
	if(randomInt(2)) random_yaw = random_yaw * -1;
	vangles = vectortoangles(vectornormalize(impactpos - pos));
	if(isDefined(self.mebelle)) vangles = (vangles[0], (self.angles[1]-90) + random_yaw, vangles[2]);
		else vangles = (vangles[0], self.angles[1] + random_yaw, vangles[2]);
	forwardvector = anglestoforward(vangles);

	iterations = 0;
	while(iterations <= 20)
	{
		forwardpos = pos + [[level.ex_vectorscale]](forwardvector, dist);
		trace = bulletTrace(pos, forwardpos, false, self);
		if(trace["fraction"] != 1)
		{
			pos = trace["position"];
			break;
		}
		else
		{
			pos = forwardpos;
			if(oneshot) break;
		}

		iterations++;
	}

	return(pos);
}

getPlaneStartEnd(targetpos, angle)
{
	forwardvector = anglestoforward( (0, angle, 0) );
	backpos = targetpos + ([[level.ex_vectormulti]](forwardvector, -30000));
	frontpos = targetpos + ([[level.ex_vectormulti]](forwardvector, 30000));
	fronthit = 0;

	trace = bulletTrace(targetpos, backpos, false, undefined);
	if(trace["fraction"] != 1) start = trace["position"];
		else start = backpos;

	trace = bulletTrace(targetpos, frontpos, false, undefined);
	if(trace["fraction"] != 1)
	{
		endpoint = trace["position"];
		fronthit = 1;
	}
	else endpoint = frontpos;

	startpos = start + ([[level.ex_vectormulti]](forwardvector, -3000));
	endpoint = endpoint + ([[level.ex_vectormulti]](forwardvector, 3000));
	stenpos[0] = startpos;
	stenpos[1] = endpoint;
	stenpos[2] = fronthit;
	return stenpos;
}

calcTime(startpos, endpos, speedvalue)
{
	distunit = 1;	// Metres
	speedunit = 1; // Metres per second
	distvalue = distance(startpos, endpos);
	distvalue = int(distvalue * 0.0254); // convert to metres
	timeinsec = (distvalue * distunit) / (speedvalue * speedunit);
	if(timeinsec <= 0) timeinsec = 0.1;
	return timeinsec;
}

airplaneCrash(speed, apteam)
{
	level.ex_planescrashed++;

	playfx(level.ex_effect["flak_flash"], self.origin - (0, 200, 0));
	self playsound("plane_explosion_2");
	wait( [[level.ex_fpstime]](0.2) );
	playfx(level.ex_effect["flak_smoke"], self.origin - (0, 200, 0));
	wait( [[level.ex_fpstime]](0.2) );
	playfx(level.ex_effect["flak_dust"], self.origin - (0, 200, 0));
	wait( [[level.ex_fpstime]](0.5) );
	playfx(level.ex_effect["plane_smoke"], self.origin);
	wait( [[level.ex_fpstime]](0.05) );
	playfx(level.ex_effect["plane_smoke"], self.origin);
	wait( [[level.ex_fpstime]](0.05) );
	self.apdivesound playloopsound("plane_dive");
	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_2");
	wait( [[level.ex_fpstime]](0.5) );
	playfx(level.ex_effect["plane_explosion"], self.origin);

	self.fire = 0;
	if(randomInt(100) > 50) self.fire = 1;

	angle = self.angles;
	pitch = randomInt(25) + 25;
	yaw = randomInt(50) - 25;
	roll = 200 - randomInt(400);
	angle_start = angle + (pitch,yaw,0);
	forwardvector = anglestoforward(angle_start);

	endpoint = self.origin + ([[level.ex_vectormulti]](forwardvector,30000));
	trace=bulletTrace(self.origin,endpoint, true, undefined);
	if(trace["fraction"] < 1 && trace["position"][2] > game["mapArea_Min"][2] - 500) endpoint = trace["position"];
		else endpoint = self.origin + ([[level.ex_vectormulti]](forwardvector,100));

	falltime = calcTime(self.origin, endpoint, speed);
	rotdone = "notdone";

	if(falltime > 1)
	{
		start_turn = 0;

		self moveto(endpoint,falltime);

		np = (pitch/(0.5/0.05));
		ny = (yaw/(0.5/0.05));
		nr = (roll/(falltime/0.05));

		for(i=0;i<falltime;i+=0.05)
		{
			if(i <= 0.5)
			{
				self.angles += (np,0,0);
				self.angles += (0,ny,0);
				self.angles += (0,0,nr);
			}
			else if(start_turn == 0)
			{
				start_turn = 1;
				self.angles += (0,0,nr);
			}

			playfx(level.ex_effect["plane_smoke"], self.origin);

			if(self.fire == 1) playfx(level.ex_effect["plane_smoke"], self.origin);

			wait( [[level.ex_fpstime]](0.05) );
		}
	}

	wait( [[level.ex_fpstime]](0.05) );

	self stoploopsound();

	if(isDefined(self.apsound))
	{
		self.apsound stopLoopSound();
		self.apsound delete();
	}

	if(isDefined(self.apdivesound))
	{
		self.apdivesound stopLoopSound();
		self.apdivesound delete();
	}

	// explosions
	hm = randomInt(2) + 1; // how many explosions, at least 1

	for(i = 0; i < 2;i++)
	{
		for(exp=0; exp < hm; exp++)
		{
			// play the incoming falling sound
			planecrashsfx[0] = "plane_explosion_1";
			planecrashsfx[1] = "plane_explosion_2";
			planecrashsfx[2] = "plane_explosion_3";
			pc = randomInt(planecrashsfx.size);
			self playsound(planecrashsfx[pc]);

			// do the damage
			if(level.ex_planes == 3)
				self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "plane_mp", level.ex_planecrash_radius, 500, 300, "plane_explosion", undefined, true, true, true);
	
			playfx(level.ex_effect["plane_smoke"], self.origin);
	
			if(exp != 2)
			{
				wait( [[level.ex_fpstime]](0.3) );
				wait( [[level.ex_fpstime]](randomFloat(1)) );
			}
			else
			{
				wait( [[level.ex_fpstime]](0.3) );
				wait( [[level.ex_fpstime]](randomFloat(2)) );
			}
		}
	}

	if(apteam == 0) level.ex_axisapinsky--;
		else level.ex_allieapinsky--;

	self planeCrashSmokeFX();
	self delete();
	level notify("ambplane_finished");
}

planeCrashSmokeFX()
{
	self thread extreme\_ex_utils::hotSpot(self.origin, 120, "MOD_EXPLOSIVE", "plane_mp");

	for(i = 0; i < 25; i++)
	{
		playfx(level.ex_effect["planecrash_fire"], self.origin);
		wait( [[level.ex_fpstime]](0.5) );
		playfx(level.ex_effect["planecrash_ball"], self.origin);
		wait( [[level.ex_fpstime]](0.5) );
	}

	self notify("endhotspot");
	self hide();
	thread planeCrashDelayedSmokeFX(self.origin);
}

planeCrashDelayedSmokeFX(position)
{
	for(i = 0; i < 25; i++)
	{
		playfx(level.ex_effect["planecrash_smoke"], position);
		wait( [[level.ex_fpstime]](0.5) );
		if(i < 15) playfx(level.ex_effect["planecrash_ball"], position);
		wait( [[level.ex_fpstime]](0.5) );
	}
}
