
start(delay)
{
	self endon("kill_thread");

	if(self.ex_air_strike) return;

	self notify("end_airstrike");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_airstrike");
	
	self.ex_air_strike = true;

	// wait the first
	if(!isDefined(delay)) delay = level.ex_rank_airstrike_first;
	wait( [[level.ex_fpstime]](delay) );

	// check for napalm
	self.ex_napalm = false;

	switch(level.ex_rank_wmdtype)
	{
		case 2: // random rank
			if(self.pers["rank"] >= level.ex_rank_special && randomInt(100) < level.ex_rank_napalm_chance) self.ex_napalm = true;
			break;

		case 3: // allowed random
			if(level.ex_rank_allow_special)
			{
				if(!level.ex_rank_allow_airstrike) self.ex_napalm = true;
				else if(randomInt(100) < level.ex_rank_napalm_chance) self.ex_napalm = true;
			}
			break;

		default: // fixed rank
			if(self.pers["rank"] == 7 && randomInt(100) < level.ex_rank_napalm_chance) self.ex_napalm = true;
			break;
	}

	while(self.ex_air_strike)
	{
		// let them know the airstrike is available
		if(!self.ex_napalm)
		{
			if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_airstrikeunlock", level.ex_arcade_shaders_perk);
				else self iprintlnbold(&"AIRSTRIKE_READY");
		}
		else
		{
			if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_napalmunlock", level.ex_arcade_shaders_perk);
				else self iprintlnbold(&"AIRSTRIKE_READY_NAPALM");
		}

		self teamSound("airstk_ready", 1);
			
		// set up the screen icon
		if(self.ex_napalm) self hudNotify(game["wmd_napalm_hudicon"]);
			else self hudNotify(game["wmd_airstrike_hudicon"]);

		// monitor for binocular fire
		self thread waitForUse();
		
		// wait until they use airstrike
		self waittill("airstrike_over");

		if(!level.ex_arcade_shaders) self iprintlnbold(&"AIRSTRIKE_WAIT");
		self teamSound("airstk_reload",3);

		// now wait for one interval
		wait( [[level.ex_fpstime]](level.ex_rank_airstrike_next) );

		// randomize napalm again
		if(self.ex_napalm && randomInt(100) > level.ex_rank_napalm_chance) self.ex_napalm = false;
	}
}	

waitForUse()
{
	self endon("kill_thread");
	self endon("end_airstrike");
	self endon("end_waitforuse");

	self.callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.callingwmd)
		{
			self thread waitForBinocUse();
			self thread binocHintHud();
		}
		wait( [[level.ex_fpstime]](0.2) );
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_waitforuse");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.callingwmd)
		{
			self.callingwmd = true;
			self thread callRadio();
		}
		wait( [[level.ex_fpstime]](0.01) );
	}
}

callRadio()
{
	self endon("kill_thread");

	if(!level.ex_arcade_shaders) self iprintlnbold(&"AIRSTRIKE_RADIO_IN");

	targetPos = getTargetPosition();
	friendly = friendlyInstrikezone(targetpos);

	self teamSound("airstk_firemission", 3.6);
	for(i = 1; i < 4; i++) self teamsound("airstk_" + randomInt(8), 0.6);
	self teamSound("airstk_pointfuse", 3);

	if(isDefined(targetPos) && isDefined(friendly) && friendly == false)
	{
		// notify threads
		self notify("end_waitforuse");

		// clear hud icon
		self hudNotifyRemove();

		// clear hint icon
		if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();

		if(!level.ex_arcade_shaders) self iprintlnbold(&"AIRSTRIKE_ONWAY");
		self teamSound("airstk_ontheway",4);

		// player has used weapon
		self.usedweapons = true;

		airstrike = spawn("script_origin",targetpos);
		airstrike thread fireBarrage(self);

		if(level.ex_air_raid) airstrike thread extreme\_ex_utils::playSoundLoc("air_raid",targetpos);
	}
	else if(!isDefined(targetPos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_NOT_VALID");
		self teamSound("airstk_novalid",3);
	}
	else if(isDefined(friendly) && friendly == true)
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_FRIENDLY_WARNING");
		self teamSound("airstk_frndly",3);
	}
	else if(isDefined(targetPos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_TO_CLOSE_WARNING");
		self teamSound("airstk_tooclose",3);
	}

	self.callingwmd = false;
}

getTargetPosition()
{
	startOrigin = self getEye() + (0,0,20);
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]](forward, 100000);
	endOrigin = startOrigin + forward;

	trace = bulletTrace( startOrigin, endOrigin, false, self );
	if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") return (undefined);
		else return (trace["position"]);
}

fireBarrage(owner)
{
	// drop flare
	if(level.ex_rank_wmd_flare) playfx(level.ex_effect["flare_indicator"], self.origin);

	if(level.ex_planes_flak) level thread extreme\_ex_skyeffects::fireFlaks(10, 0.25);

	// create planes
	apflangle = randomInt(360);
	self thread createPlanes(self.origin , apflangle, owner);

	owner teamSound("pilot_cmg_target", 4);
	wait( [[level.ex_fpstime]](3) );
	owner teamSound("flack_hang_on", 3);

	self waittill("planes_finished");

	owner notify ("airstrike_over");
	self delete();
}

createPlanes(targetpos, apflangle, owner)
{
	level endon("ex_gameover");

	// pick a plane team
	if(isPlayer(owner))
	{
		if(owner.pers["team"] == "axis") apteam = 0;
			else apteam = 1;
	}
	else return;

	// set team definition
	if(apteam == 0) level.apteam = "axis";
		else level.apteam = "allies";

	// set planes in sky values
	if(apteam == 0) level.ex_pallieapinsky++;
		else level.ex_paxisapinsky++;
				
	x = targetpos[0];
	y = targetpos[1];
	z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;
	droppos = (x,y,z);

	stenpos = getPlaneStartEnd( droppos, apflangle );
	stenpos2 = getPlaneStartEnd( (stenpos[1]), apflangle );
	if(stenpos2[2] == 1) stenpos[1] = stenpos2[1];

	apstpoint = stenpos[0];
	apenpoint = stenpos[1];

	// plane models
	if(apteam == 0)
		apmodel = "xmodel/vehicle_mig29";
	else
		apmodel = "xmodel/vehicle_mig29";

	// plane sounds
	apsoundchoice = [];
	apsoundchoice[0] = "spitfire_flyby_1";
	apsoundchoice[1] = "spitfire_flyby_1";

	apsound = apsoundchoice[randomInt(apsoundchoice.size)];

	planetype = 1; // bomber

	plane = spawn("script_model", apstpoint);
	plane setModel(apmodel);
	plane.angles = (plane.angles[0], apflangle, plane.angles[2]);
	if(apteam == 1)

	plane.apdivesound = spawn("script_model", apstpoint - (0,50,0));
	plane.apdivesound linkto(plane);

	plane.apsound = spawn("script_model", apstpoint - (0,50,0));
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
	apspeed = 60; // bombers

	// flighttime
	flighttime = calcTime(apstpoint, apenpoint, apspeed);
	plane moveto(apenpoint, flighttime);

	plane.isbombing = false;
	// chance that plane will crash, but
	// - only condor, because memphis has axis mixed up. Looks silly.
	// - only if there weren't enough crashes already (4 max)
	planecrash = false;
	if(randomInt(100) < 5 && level.ex_planescrashed < 4 && apteam == 0) planecrash = true;

	for(i = 0; i < flighttime; i += 0.05)
	{
		if(!plane.isbombing && (distance(droppos, plane.origin) < dropdist) )
		{
			// DEBUG: black line from drop to target
			//level thread extreme\_ex_utils::dropLine(droppos, targetpos, (0,0,0));
			owner teamSound("fire_away",1);
			plane thread bombSetup(owner, targetpos, droprate);
			plane.isbombing = true;
		}

		if(planecrash && !plane.isbombing && (distance(game["playArea_Centre"], plane.origin) < dropdist * 2) )
		{
			owner teamsound("airstk_vbc",1);
			plane thread airplaneCrash(apspeed, apteam, self);
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

	if(apteam == 0) level.ex_paxisapinsky--;
		else level.ex_pallieapinsky--;

	if(isDefined(plane)) plane delete();

	wait( [[level.ex_fpstime]](5) );
	self notify("planes_finished");
}

bombSetup(owner, targetpos, droprate)
{
	bombcount = 0;
	bombno = randomInt(3) + 4;

	linecolor = (randomFloat(1),randomFloat(1),randomFloat(1));

	while(bombcount < bombno)
	{
		self thread dropBomb(owner, targetpos, linecolor);
		bombcount++;
		wait( [[level.ex_fpstime]](droprate) );
	}
}

dropBomb(owner, targetpos, linecolor)
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
	bomb setModel("xmodel/slamraam_missile");
	bomb moveto(impactpos + (0,0,-100), falltime);

	// play the incoming sound falling sound
	ms = randomInt(14) + 1;
	bomb playsound("mortar_incoming" + ms);

	// wait for it to hit
	wait( [[level.ex_fpstime]](falltime) );

	// do the damage
	if(isPlayer(owner) && owner.sessionstate != "spectator")
	{
		if(isDefined(owner.ex_napalm) && owner.ex_napalm == true)
			bomb thread extreme\_ex_utils::scriptedfxradiusdamage(owner, undefined, "MOD_GRENADE", "planebomb_mp", level.ex_airstrike_radius, 500, 400, "plane_bomb", undefined, true, true, true, "napalm");
		else
			bomb thread extreme\_ex_utils::scriptedfxradiusdamage(owner, undefined, "MOD_GRENADE", "planebomb_mp", level.ex_airstrike_radius, 500, 400, "plane_bomb", undefined, true, true, true);
	}
	else
		bomb thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_GRENADE", "planebomb_mp", level.ex_airstrike_radius, 0, 0, "plane_bomb", undefined, true, true, true);

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
	radius = randomFloat(level.ex_rank_airstrike_radius);
	impactpos += (cos(angle) * radius, sin(angle) * radius, 0);

	vangles = vectortoangles(vectornormalize(impactpos - pos));
	if(isDefined(self.mebelle)) vangles = (vangles[0], self.angles[1]-90, vangles[2]);
		else vangles = (vangles[0], self.angles[1], vangles[2]);
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

friendlyInStrikeZone(targetPos)
{
	// return if friendly fire check has been disabled
	if(level.ex_rank_wmd_checkfriendly == 0) return false;

	// dont need to check friendly if gametype is not teamplay
	if(!level.ex_teamplay) return false;

	if(!isDefined(targetPos)) return (undefined);

	if(distance(targetPos, self.origin) <= 1000) return (undefined);

	// check if players in the same team are in targetzone
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(self) && isPlayer(players[i]))
		{
			if(players[i].sessionstate == "playing" && players[i].pers["team"] == self.pers["team"])
			{
				if(distance(targetpos, players[i].origin) <= 1000)
					return true;
			}
		}
	}
	return false;
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

airplaneCrash(speed, apteam, owner)
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

	if(apteam == 0) level.ex_paxisapinsky--;
		else level.ex_pallieapinsky--;

	self planeCrashSmokeFX();
	self delete();
	owner notify("planes_finished");
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

teamSound(aliasPart, waitTime)
{
	if (self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
			case "american":
				self playLocalSound("us_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
			case "british":
				self playLocalSound("uk_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
			default:
				self playLocalSound("ru_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
		}
	}
	else
	{
		self playLocalSound("ge_" + aliasPart);
		wait( [[level.ex_fpstime]](waitTime) );
	}
}

hudNotify(shader)
{
	self endon("kill_thread");

	self hudNotifyRemove();

	self.ex_wmd_icon = newClientHudElem(self);
	self.ex_wmd_icon.archived = true;
	self.ex_wmd_icon.horzAlign = "fullscreen";
	self.ex_wmd_icon.vertAlign = "fullscreen";
	self.ex_wmd_icon.alignX = "center";
	self.ex_wmd_icon.alignY = "middle";
	self.ex_wmd_icon.x = 620;
	self.ex_wmd_icon.y = 360;
	self.ex_wmd_icon.alpha = level.ex_iconalpha;
	self.ex_wmd_icon setShader(shader, 16, 16);
	self.ex_wmd_icon scaleOverTime(.5, 24, 24);

	if(!isDefined(self.ex_binocular_hint))
	{
		self.ex_binocular_hint = newClientHudElem( self );
		self.ex_binocular_hint.archived = false;
		self.ex_binocular_hint.horzAlign = "fullscreen";
		self.ex_binocular_hint.vertAlign = "fullscreen";
		self.ex_binocular_hint.alignX = "center";
		self.ex_binocular_hint.alignY = "middle";
		self.ex_binocular_hint.x = 350;
		self.ex_binocular_hint.y = 460;
		self.ex_binocular_hint.fontScale = 1;
		self.ex_binocular_hint.sort = 5;
		self.ex_binocular_hint setText(&"WMD_ACTIVATE_HINT");

		// do not show hint if planting a tripwire
		if(level.ex_tweapon)
		{
			if(!self.ex_plantwire && !self.ex_defusewire && !isDefined(self.ex_actimer) || self [[level.ex_getstance]](false) != 2 && !isDefined(self.ex_actimer))
				self.ex_binocular_hint.alpha = 1;
			else self.ex_binocular_hint.alpha = 0;
		}
		else self.ex_binocular_hint.alpha = 1;
	}
}

hudNotifyRemove()
{
	if(isDefined(self.ex_wmd_icon)) self.ex_wmd_icon destroy();
}

binocHintHud()
{
	self endon("binocular_exit");

	if(!isDefined(self.ex_binocular_hint))
	{
		self.ex_binocular_hint = newClientHudElem( self );
		self.ex_binocular_hint.archived = false;
		self.ex_binocular_hint.horzAlign = "fullscreen";
		self.ex_binocular_hint.vertAlign = "fullscreen";
		self.ex_binocular_hint.alignX = "center";
		self.ex_binocular_hint.alignY = "middle";
		self.ex_binocular_hint.x = 350;
		self.ex_binocular_hint.y = 460;
		self.ex_binocular_hint.fontScale = 1;
		self.ex_binocular_hint.sort = 5;
		self.ex_binocular_hint.alpha = 1;
	}

	if(!self.ex_napalm) self.ex_binocular_hint setText(&"WMD_AIRSTRIKE_HINT");
		else self.ex_binocular_hint setText(&"WMD_NAPALM_HINT");

	self thread binocHintHudDestroy();
}

binocHintHudDestroy()
{
	self endon("kill_thread");
	self endon("binocular_enter");

	self waittill("binocular_exit");

	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();
}
