#include extreme\_ex_weapons;
#include extreme\_ex_utils;

main()
{
	level endon("ex_gameover");

	if(!level.ex_amc_perteam) return;

	spawnpoints = getentarray("mp_tdm_spawn", "classname");
	if(!spawnpoints.size) spawnpoints = getentarray("mp_dm_spawn", "classname");
	if(spawnpoints.size < 2) return;
	ammocratesInit(spawnpoints);

	// Routine for debugging objective slot management and crate status
	level.ammocrate_debug = false; // Do NOT comment out; set to false if no debugging messages are needed
	if(level.ammocrate_debug) level thread showObjectiveSlots();

	if(level.ex_amc_chutein)
	{
		// Chuting crate logic
		drop_wait = level.ex_amc_chutein;
		drop_switcher = 0;
		
		while(level.ex_amc_perteam)
		{
			wait( [[level.ex_fpstime]](drop_wait) );
			drop_wait = level.ex_amc_chutein_pause_all;

			// if entities monitor in defcon 1 or 2, suspend
			if(level.ex_entities_defcon) continue;

			drop_count = 0;
			if(level.ex_amc_chutein_neutral)
			{
				ammocrate_team = "neutral";
				drop_count = (level.ex_amc_perteam * 2) - getAmmocratesAllocated();
				if(drop_count < 0) drop_count = 0; // Merely to let debug messages look nice
				if(drop_count > 0 && level.ex_amc_chutein_slice)
				{
					if(level.ex_amc_chutein_slice < drop_count)
						drop_count = level.ex_amc_chutein_slice;
					drop_wait = level.ex_amc_chutein_pause_slice;
				}
			}
			else
			{
				if(drop_switcher%2 == 0) ammocrate_team = "allies";
					else ammocrate_team = "axis";

				drop_count = level.ex_amc_perteam - getAmmocratesForTeam(ammocrate_team);
				if(drop_count < 0) drop_count = 0; // Merely to let debug messages look nice
				if(drop_count > 0)
				{
					if(level.ex_amc_chutein_slice && level.ex_amc_chutein_slice < drop_count)
						drop_count = level.ex_amc_chutein_slice;
					drop_switcher++;
					if(drop_switcher%2 == 0) drop_wait = level.ex_amc_chutein_pause_slice;
						else drop_wait = 0.5;
				}
			}

			if(level.ammocrate_debug && drop_count) logprint("AMMOCRATES: dropping " + drop_count + " crates for " + ammocrate_team + "\n");

			plane_angle = randomInt(360);
			for(i = 0; i < drop_count; i++)
			{
				ammocrate_index = getAmmocrateIndex();
				if(ammocrate_index != 999)
				{
					ammocrate_compass = level.ex_amc_compass;
					// If not a neutral drop, don't let a team allocate all or too many compass slots at once
					if(!level.ex_amc_chutein_neutral && !level.ex_amc_chutein_slice && (i > level.ex_amc_maxobjteam - 1)) ammocrate_compass = false;
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " has compass request flag: " + ammocrate_compass + "\n");
					ammoCrateAlloc(ammocrate_index, ammocrate_team, ammocrate_compass);
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " acquired objective index: " + level.ammocrates[ammocrate_index].objective + "\n");
					level thread ammoCratePlane(ammocrate_index, plane_angle);
				}
				else level.ex_amc_perteam--;
				wait( [[level.ex_fpstime]](1) ); // A longer wait will increase mutual distance between planes within the same slice
			}

			if(drop_count == 0)
			{
				if(!level.ex_amc_chutein_lifespan) break;
				level thread ammocratesOnGroundMonitor();
				level waittill("ammocrate_countdown");
				drop_wait += level.ex_amc_chutein_lifespan;
				if(level.ammocrate_debug) logprint("AMMOCRATES: all crates touched ground. Waiting " + drop_wait + " seconds for next drop.\n");
			}
		}
	}
	else
	{
		// Fixed crate logic
		drop_count = level.ex_amc_perteam;
		ammocrate_team = "allies";
		for(i = 0; i < 2; i++)
		{
			if(level.ammocrate_debug && drop_count) logprint("AMMOCRATES: dropping " + drop_count + " crates for " + ammocrate_team + "\n");

			for(j = 0; j < drop_count; j++)
			{
				ammocrate_index = getAmmocrateIndex();
				if(ammocrate_index != 999)
				{
					ammocrate_compass = level.ex_amc_compass;
					// Don't let a team allocate all or too many compass slots at once
					if(j > level.ex_amc_maxobjteam - 1) ammocrate_compass = false;
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " has compass request flag: " + ammocrate_compass + "\n");
					ammoCrateAlloc(ammocrate_index, ammocrate_team, ammocrate_compass);
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " acquired objective index: " + level.ammocrates[ammocrate_index].objective + "\n");
					level thread ammoCrateFixed(ammocrate_index);
				}
			}

			ammocrate_team = "axis";
		}
	}
}

ammocratesOnGroundMonitor()
{
	level endon("ex_gameover");

	wait( [[level.ex_fpstime]](0.1) ); // Wait in case all crates already touched ground (the monitor would fire its notify before the waittill started).
	if(level.ammocrate_debug) logprint("AMMOCRATES: waiting for " + getAmmocratesAllocated() + " crates to touch ground.\n");
	while(getAmmocratesAllocated() != getAmmocratesWithStatus("onground")) wait( [[level.ex_fpstime]](1) );
	level notify("ammocrate_countdown");
}

ammocratesInit(spawnpoints)
{
	level.ammocrates = [];
	level.ex_amc_maxobjteam = 4;

	for(i = 0; i < spawnpoints.size; i++)
	{
		level.ammocrates[i] = spawnstruct();
		level.ammocrates[i].spawnpoint = spawnpoints[i].origin;
		level.ammocrates[i].allocated = false;
		level.ammocrates[i].objective = 0;
		level.ammocrates[i].team = "none";
		level.ammocrates[i].status = "none";
	}

	if(level.ex_teamplay)
	{
		if((level.ex_amc_perteam * 2) > level.ammocrates.size)
			level.ex_amc_perteam = int(level.ammocrates.size / 2);
	}
	else
	{
		level.ex_amc_perteam = int(level.ex_amc_perteam / 2);
		if(level.ex_amc_perteam > level.ammocrates.size)
			level.ex_amc_perteam = level.ammocrates.size;
	}
}

ammoCrateAlloc(ammocrate_index, ammocrate_team, oncompass)
{
	if(!isDefined(level.ammocrates)) return false;

	crate_objnum = 0;
	if(oncompass)
	{
		if(ammocrate_team == "neutral")
		{
			if(getAmmocratesOnCompass() < (level.ex_amc_maxobjteam * 2)) crate_objnum = getObjective();
		}
		else if(getAmmocratesOnCompassForTeam(ammocrate_team) < level.ex_amc_maxobjteam) crate_objnum = getObjective();
	}

	level.ammocrates[ammocrate_index].allocated = true;
	level.ammocrates[ammocrate_index].objective = crate_objnum;
	level.ammocrates[ammocrate_index].team = ammocrate_team;
	level.ammocrates[ammocrate_index].status = "alloc";
	return true;
}

ammoCrateFree(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return;

	if(level.ammocrates[ammocrate_index].objective)
		deleteObjective(level.ammocrates[ammocrate_index].objective);

	level.ammocrates[ammocrate_index].allocated = false;
	level.ammocrates[ammocrate_index].objective = 0;
	level.ammocrates[ammocrate_index].team = "none";
	level.ammocrates[ammocrate_index].status = "none";
}

IsAmmocrateAllocated(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return true;
	if(ammocrate_index > level.ammocrates.size-1) return true;

	return level.ammocrates[ammocrate_index].allocated;
}

getAmmocrateIndex()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrate_index = 999;
	rejected = true;
	mindist = 750;
	iterations = 0;

	while(rejected && iterations < level.ammocrates.size * 2)
	{
		wait( [[level.ex_fpstime]](0.05) );
		iterations++;

		ammocrate_index = randomInt(level.ammocrates.size);
		if(IsAmmocrateAllocated(ammocrate_index)) continue;

		rejected = false;
		for(i = ammocrate_index; i < level.ammocrates.size; i++)
			if(level.ammocrates[i].allocated && distance(level.ammocrates[i].spawnpoint, level.ammocrates[ammocrate_index].spawnpoint) < mindist)
				rejected = true;

		if(!rejected)
		{
			for(i = 0; i < ammocrate_index; i++)
				if(level.ammocrates[i].allocated && distance(level.ammocrates[i].spawnpoint, level.ammocrates[ammocrate_index].spawnpoint) < mindist)
					rejected = true;
		}

		if(level.ammocrate_debug && rejected) logprint("AMMOCRATES: crate index " + ammocrate_index + " rejected.\n");
	}

	if(IsAmmocrateAllocated(ammocrate_index))
	{
		// Still no valid spawnpos? Get the first free one in the list
		for(i = 0; i < level.ammocrates.size; i++)
		{
			ammocrate_index = i;
			if(!level.ammocrates[i].allocated) break;
		}
	}

	if(IsAmmocrateAllocated(ammocrate_index)) return 999;
		else return ammocrate_index;
}

getAmmocratesAllocated()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].allocated) ammocrates++;

	return ammocrates;
}

getAmmocrateSpawnpoint(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return 0;

	return level.ammocrates[ammocrate_index].spawnpoint;
}

getAmmocrateObjective(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return 0;

	return level.ammocrates[ammocrate_index].objective;
}

getAmmocrateTeam(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return "none";

	return level.ammocrates[ammocrate_index].team;
}

setAmmocrateTeam(ammocrate_index, ammocrate_team)
{
	if(!isDefined(level.ammocrates)) return;

	// Valid are: "neutral", "allies", "axis"
	level.ammocrates[ammocrate_index].team = ammocrate_team;
	if(level.ex_teamplay && level.ex_amc_compass && level.ammocrates[ammocrate_index].objective)
		objective_team(level.ammocrates[ammocrate_index].objective, ammocrate_team);
}

getAmmocrateStatus(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return "none";

	return level.ammocrates[ammocrate_index].status;
}

getAmmocratesWithStatus(ammocrate_status)
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].status == ammocrate_status) ammocrates++;

	return ammocrates;
}

setAmmocrateStatus(ammocrate_index, ammocrate_status)
{
	if(!isDefined(level.ammocrates)) return;

	// Valid are: "none", "alloc", "inplane", "inair", "onground"
	if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " acquired status " + ammocrate_status + "\n");
	level.ammocrates[ammocrate_index].status = ammocrate_status;
}

getAmmocratesForTeam(ammocrate_team)
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].team == ammocrate_team) ammocrates++;

	return ammocrates;
}

getAmmocratesOnCompassForTeam(ammocrate_team)
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].team == ammocrate_team && level.ammocrates[i].objective != 0) ammocrates++;

	return ammocrates;
}

getAmmocratesOnCompass()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].objective != 0) ammocrates++;

	return ammocrates;
}

getAmmocratesDropped()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = getentarray("ammocrate_chute", "targetname");

	return ammocrates.size;
}

getAmmocratesFixed()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = getentarray("ammocrate_fixed", "targetname");

	return ammocrates.size;
}

ammoCratePlane(ammocrate_index, plane_angle)
{
	level endon("ex_gameover");

	setAmmocrateStatus(ammocrate_index, "inplane");

	plane_models[0] = "xmodel/vehicle_condor";
	plane_models[1] = "xmodel/mebelle1";

	if(getAmmocrateTeam(ammocrate_index) == "axis") plane_index = 0;
		else if(getAmmocrateTeam(ammocrate_index) == "allies") plane_index = 1;
			else plane_index = randomInt(plane_models.size);
	plane_model = plane_models[ plane_index ];

	plane_sounds[0] = "stuka_flyby_1";
	plane_sounds[1] = "stuka_flyby_2";
	plane_sound = plane_sounds[ plane_index ];

	// Get height of plane and drop position
	targetpos = getAmmocrateSpawnpoint(ammocrate_index);
	targetpos_x = targetpos[0] - 150  + randomInt(300);
	targetpos_y = targetpos[1] - 150  + randomInt(300);
	targetpos_z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= targetpos_z)) targetpos_z = level.ex_planes_altitude;
	plane_droppos = (targetpos_x, targetpos_y, targetpos_z);

	// Calculate plane waypoints
	plane_firsthalf = getPlaneStartEnd(plane_droppos, plane_angle);
	plane_sechalf = getPlaneStartEnd((plane_firsthalf[1]), plane_angle);
	if(plane_sechalf[2] == 1) plane_firsthalf[1] = plane_sechalf[1];
	plane_startpos = plane_firsthalf[0];
	plane_endpos = plane_firsthalf[1];

	// Create plane and move it (rotate if needed)
	plane = spawn("script_model", plane_startpos);
	plane setModel(plane_model);
	plane.angles = plane.angles + (0, plane_angle, 0);
	if(plane_index == 1) plane rotateyaw(90, .1);

	plane.sound = spawn("script_model", plane_startpos + (0, -50, 0));
	plane.sound linkto(plane);
	plane.sound playloopsound(plane_sound);

	plane_speed = 30;
	flighttime = calcTime(plane_startpos, plane_endpos, plane_speed);
	plane moveto(plane_endpos, flighttime);

	// Drop crate when passing drop position
	crate_dropped = false;
	for(i = 0; i < flighttime; i += 0.1)
	{
		if((distance(plane_droppos, plane.origin) < 200) && !crate_dropped)
		{
			plane thread ammoCrateDrop(ammocrate_index);
			crate_dropped = true;
		}
		wait( [[level.ex_fpstime]](0.1) );
	}

	// Cleaning up
	if(isDefined(plane.sound))
	{
		plane.sound stopLoopSound();
		plane.sound delete();
	}
	if(isDefined(plane)) plane delete();
	if(!crate_dropped) ammoCrateFree(ammocrate_index);
}

ammoCrateDrop(ammocrate_index)
{
	level endon("ex_gameover");

	setAmmocrateStatus(ammocrate_index, "inair");

	crate_models[0] = "xmodel/prop_mortar_crate2";
	crate_models[1] = "xmodel/prop_crate_smallshipping_open1";
	crate_index = randomInt(crate_models.size);
	crate_model = crate_models[ crate_index ];

	crate = spawn("script_model", self.origin);
	crate setmodel(crate_model);
	crate.targetname = "ammocrate_chute";
	crate.index = ammocrate_index;
	crate.timeout = false;

	// Let it freefall for a brief moment
	crate_speed = 10;
	crate_endpos = crate.origin + (0, 0, -400);
	falltime = calcTime(crate.origin, crate_endpos, crate_speed);
	crate moveto(crate_endpos, falltime);
	wait( [[level.ex_fpstime]](falltime) );
	
	// Define final position
	targetpos = getAmmocrateSpawnpoint(ammocrate_index);
	crate_endpos = targetpos - ( 15, 15, 0) + ( randomInt(31), randomInt(31), 0);
	trace = bulletTrace(crate_endpos + (0, 0, 100), crate_endpos + (0, 0, -1200), false, undefined);
	if(trace["fraction"] < 1.0)
	{
		ground = trace["position"];
		if(ground[2] > targetpos[2] && (ground[2] - targetpos[2] > 50)) ground = targetpos;
	}
	else ground = targetpos;

	// Create parachute
	crate.parachute = spawn("script_model", crate.origin);
	crate.parachute setModel("xmodel/am_fallschirm");
	crate.parachute.angles = crate.angles + (0, 0, 90);

	// Create anchor and link parachute to it
	crate.anchor = spawn("script_model", crate.parachute.origin);
	crate.anchor.angles = crate.angles;
	crate.parachute linkto(crate.anchor);
	crate linkto(crate.anchor);
	crate.anchor.origin = crate.origin;

	// Descent to final position
	crate_speed = 3;
	falltime = calcTime(crate.origin, crate_endpos, crate_speed);
	crate.anchor moveto(crate_endpos, falltime);
	wait( [[level.ex_fpstime]](falltime) );

	// Clean up parachute (part I)
	chute = spawn("script_model", crate.parachute.origin);
	chute setModel("xmodel/am_fallschirm");
	chute.angles = crate.parachute.angles;
	crate unlink();
	crate.parachute delete();
	crate.anchor delete();
	crate.origin = ground;

	// If crate has limited lifespan, wait for signal to start countdown
	crate thread ammoCrateTimer(level.ex_amc_chutein_lifespan);

	// Now let the crate do the thinking
	crate thread ammoCrateThink();

	// Clean up parachute (part II)
	chute rotatepitch(85, 10, 9, 1);
	chute moveto(crate_endpos + (0, -400, -400), 7, 6, 1);
	wait( [[level.ex_fpstime]](5) );
	chute delete();
}

ammoCrateFixed(ammocrate_index)
{
	crate_models[0] = "xmodel/prop_mortar_crate2";
	crate_models[1] = "xmodel/prop_crate_smallshipping_open1";
	crate_index = randomInt(crate_models.size);
	crate_model = crate_models[ crate_index ];

	// Define fixed position
	targetpos = getAmmocrateSpawnpoint(ammocrate_index);
	crate_endpos = targetpos - ( 15, 15, 0) + ( randomInt(31), randomInt(31), 0);
	trace = bulletTrace(crate_endpos + (0, 0, 100), crate_endpos + (0, 0, -1200), false, undefined);
	ground = trace["position"];
	if(ground[2] > targetpos[2] && (ground[2] - targetpos[2] > 50)) ground = targetpos;

	crate = spawn("script_model", ground);
	crate setmodel(crate_model);
	crate.targetname = "ammocrate_fixed";
	crate.index = ammocrate_index;
	crate.timeout = false;

	// Now let the crate do the thinking
	crate thread ammoCrateThink();
}

ammoCrateThink()
{
	level endon("ex_gameover");
	level endon("round_ended");

	setAmmocrateStatus(self.index, "onground");

	self thread ammoCrateShowObjective();
	
	while(!self.timeout)
	{
		wait( [[level.ex_fpstime]](0.1) );

		ammocrate_team = getAmmocrateTeam(self.index);
		
		// Look for any players near enough to the crate to rearm
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(!isPlayer(players[i])) continue;

			// Clear the rearming messages if present and team checking or rearming!
			if(isDefined(players[i].ex_amc_msg) && !isDefined(players[i].ex_amc_rearm) && !isDefined(players[i].ex_amc_check))
				players[i] thread clearAmmoMsg();

			// If crate reached end-of-life, stop all services (but continue clearing messages)
			if(self.timeout) continue;

			// If sprinting, don't try to rearm the player
			if(isDefined(players[i].ex_sprinting) && players[i].ex_sprinting || players[i] [[level.ex_getstance]](false) == 2) continue;

			// If player is ADS, do not rearm
			if(players[i] playerADS()) continue;

			// Do not rearm bots
			if(isDefined(players[i].pers["isbot"])) continue;

			// Prevent rearming while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(players[i].frozenstate) && players[i].frozenstate == "frozen") continue;

			if(players[i].sessionstate == "playing" && players[i] isOnGround() && !isDefined(players[i].ex_amc_rearm))
			{
				dist = distance(players[i].origin, self.origin);
				if((dist < 36) && (!level.ex_teamplay || (level.ex_teamplay && (ammocrate_team == players[i].pers["team"] || ammocrate_team == "neutral" )))) players[i] thread ammoCratePlayerRearm(self);
			}
		}
	}

	self notify("ammocrate_deleted"); // Signal ammoCrateShowObjective() to end
	wait( [[level.ex_fpstime]](0.1) ); // Wait for all threads to die
	ammoCrateFree(self.index);
	self delete();
}

ammoCrateTimer(timeout)
{
	level endon("ex_gameover");
	level endon("round_ended");

	if(!timeout) return;
	
	level waittill("ammocrate_countdown");

	for(i = 0; i < timeout; i++) wait( [[level.ex_fpstime]](1) );

	self.timeout = true;
}

ammoCratePlayerRearm(crate)
{
	self endon("disconnect");

	if(isDefined(self.ex_amc_rearm)) return;
	self.ex_amc_rearm = true;

	monitor = true;
	linked = false;

	// Set how long it takes to replenish
	prog_limit = 5;
	if(level.ex_medicsystem) prog_limit = 8;

	while(monitor && isDefined(crate) && !crate.timeout && isPlayer(self) && self.sessionstate == "playing" && distance(self.origin, crate.origin) < 36 && self [[level.ex_getstance]](true) != 2)
	{
		// Display the message
		if(!isDefined(self.ex_amc_msg_displayed))
		{
			self.ex_amc_msg_displayed = true;
			self ammoCrateMessage(&"AMMOCRATE_ACTIVATE");
		}

		wait( [[level.ex_fpstime]](0.05) );

		// Wait until they press the USE key
		if(!self useButtonPressed()) continue;

		// Optionally give points if player conquered a neutral crate
		if(getAmmocrateTeam(crate.index) == "neutral")
		{
			setAmmocrateTeam(crate.index, self.pers["team"]);

			if(level.ex_amc_chutein_score == 1 || level.ex_amc_chutein_score == 3)
			{
				self.score++;
				self.pers["bonus"]++;
				if(!level.ex_teamplay) self notify("update_playerscore_hud");
			}

			if(level.ex_teamplay && level.ex_amc_chutein_score > 1)
			{
				teamscore = getTeamScore(self.pers["team"]);
				teamscore++;
				setTeamScore(self.pers["team"], teamscore);
				level notify("update_teamscore_hud");
			}
		}

		// Make sure they want to rearm, and have not just stopped sprinting over one
		count = 0;
		while(self useButtonPressed() && count < 20)
		{
			wait( [[level.ex_fpstime]](0.05) );
			count++;
		}
		if(count < 20) continue;

		// if you got into the gunship by hitting USE, stop rearming attempt
		if( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == self) ||
		    (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == self) ) continue;

		// OK, they're still holding so lets rearm them
		if(self useButtonPressed())
		{
			// If the bar graphic is not displayed, do it now
			if(!isDefined(self.pbgrd)) self thread extreme\_ex_utils::createBarGraphic(288, prog_limit);

			if(isDefined(crate))
			{
				self linkTo(crate);
				linked = true;
			}
			
			weaponsdone = undefined;
			grenadesdone = undefined;
			firstaiddone = undefined;
			self ammoCrateMessage(&"AMMOCRATE_REARMING_WEAPONS");

			progresstime = 0;

			while(isPlayer(self) && isDefined(crate) && self useButtonPressed() && progresstime <= prog_limit && !crate.timeout)
			{
				progresstime += level.ex_fps_frame;
				wait( [[level.ex_fpstime]](level.ex_fps_frame) );

				if(progresstime >= 2 && !isDefined(weaponsdone))
				{
					self thread replenishWeapons();
					self thread ammoCrateMessage(&"AMMOCRATE_REARMING_GRENADES");
					weaponsdone = true;
				}
				else if(progresstime >= 5 && !isDefined(grenadesdone))
				{
					self thread replenishGrenades();
					if(level.ex_medicsystem) self ammoCrateMessage(&"AMMOCRATE_REARMING_FIRSTAID");
					grenadesdone = true;
				}
				else if(progresstime >= 8 && !isDefined(firstaiddone))
				{
					self thread replenishFirstaid();
					firstaiddone = true;
				}
			}

			monitor = false;
		}
	}

	// Clear the bar graphic and reset the variables
	if(linked) self unlink();
	self [[level.ex_eWeapon]]();
	self thread clearAmmoMsg();
	self thread extreme\_ex_utils::cleanBarGraphic();
	self.ex_amc_msg_displayed = undefined;
	self.ex_amc_rearm = undefined;
}

ammoCrateMessage(msg)
{
	self endon("kill_thread");

	if(!isDefined(msg)) return;

	switch(level.ex_amc_msg)
	{
		case 0:  self iprintln(msg); break;
		case 1:  self iprintlnbold(msg); break;
		case 2:  self thread extreme\_ex_utils::ex_hud_announce(msg); break;
		default: self thread ammoCrateOnScreenMsg(msg); break;
	}
}

ammoCrateOnScreenMsg(msg)
{
	self endon("kill_thread");

	if(!isDefined(msg)) return;

	if(!isDefined(self.ex_amc_msg))
	{
		self.ex_amc_msg = newClientHudElem(self);
		self.ex_amc_msg.archived = false;
		self.ex_amc_msg.horzAlign = "fullscreen";
		self.ex_amc_msg.vertAlign = "fullscreen";
		self.ex_amc_msg.alignX = "center";
		self.ex_amc_msg.alignY = "middle";
		self.ex_amc_msg.x = 320;
		self.ex_amc_msg.y = 408;
		self.ex_amc_msg.alpha = 1;
		self.ex_amc_msg.sort = 1;
		self.ex_amc_msg.fontScale = 0.80;
	}
	self.ex_amc_msg setText(msg);
}

clearAmmoMsg()
{
	self endon("kill_thread");

	if(isDefined(self.ex_amc_msg)) self.ex_amc_msg destroy();
	self.ex_amc_msg = undefined;
	self.ex_amc_msg_displayed = undefined;
}

ammoCrateShowObjective()
{
	level endon("ex_gameover");
	self endon("ammocrate_deleted");

	crate_objnum = getAmmocrateObjective(self.index);
	if(!crate_objnum) return;
	
	// Show to all
	crate_objteam = "none";

	// If team based game, make sure teams only can see own crates
	if(level.ex_teamplay)
	{
		switch(getAmmocrateTeam(self.index))
		{
			case "allies":
				crate_objteam = "allies"; // Show to allies only
				break;
			case "axis":
				crate_objteam = "axis"; // Show to axis only
				break;
		}
	}

	objective_add(crate_objnum, "current", self.origin, "compassping_ammocrate");
	objective_team(crate_objnum, crate_objteam);

	if(level.ex_amc_compass < 2) return;
	if(!level.ex_teamplay && !level.ex_amc_chutein_score) return;

	while(getAmmocrateTeam(self.index) == "neutral")
	{
		wait( [[level.ex_fpstime]](0.5) );
		objective_state(crate_objnum, "invisible");
		wait( [[level.ex_fpstime]](0.5) );
		objective_state(crate_objnum, "current");
	}
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

showObjectiveSlots()
{
	level endon("ex_gameover");

	while(true)
	{
		wait( [[level.ex_fpstime]](1) );

		if(!isDefined(level.ex_objectives)) continue;

		debugval = 0;
		for(i = 0; i < level.ex_objectives.size; i++)
			if(level.ex_objectives[i] == 0) debugval++;

		if(!isDefined(level.ex_debughud))
		{
			level.ex_debughud = newHudElem();
			level.ex_debughud.archived = false;
			level.ex_debughud.horzAlign = "fullscreen";
			level.ex_debughud.vertAlign = "fullscreen";
			level.ex_debughud.alignX = "center";
			level.ex_debughud.alignY = "top";
			level.ex_debughud.x = 320;
			level.ex_debughud.y = 55;
			level.ex_debughud.fontscale = 2.0;
			level.ex_debughud.color = (1, 0, 0);
		}
		level.ex_debughud setValue(debugval);
	}

	if(isDefined(level.ex_debughud)) level.ex_debughud destroy();
}
