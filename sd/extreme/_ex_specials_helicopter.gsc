#include extreme\_ex_specials;

heliPerkDelayed(delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );
	self thread heliPerk(0);
}

heliPerk(delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if(!isDefined(self.ex_heli)) self.ex_heli = false;
	if(self.ex_heli) return;
	self.ex_heli = true;

	if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_helicopterunlock", level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_HELI_READY");

	self playlocalsound("heli_ready");

	self hudNotifySpecial("heli");

	while(true)
	{
		wait( [[level.ex_fpstime]](.05) );
		if(self meleebuttonpressed())
		{
			count = 0;
			while(self meleeButtonPressed() && count < 10)
			{
				wait( [[level.ex_fpstime]](.05) );
				count++;
			}

			if(count >= 10 && heliAvailable()) break;
			while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}
	}

	self hudNotifySpecialRemove("heli");
	self thread playerStartUsingPerk("heli");

	level thread heliCreate(self);

	self waittill("heli_over");
	self.ex_heli = false;
}


/*******************************************************************************
CREATE
*******************************************************************************/
heliAvailable()
{
	self endon("kill_thread");

	if(isDefined(level.ex_heli_splayer))
	{
		self iprintlnbold(&"SPECIALS_HELI_INUSE");
		return(false);
	}

	self.usedweapons = true;
	return(true);
}

heliCreate(owner)
{
	level.ex_heli_splayer = owner;

	// get start and initial destination
	info = heliStartPos();

	// main model
	level.helicopter = spawn("script_model", info["start"]);
	level.helicopter setmodel("xmodel/vehicle_apache");
	level.helicopter.angles = vectorToAngles(info["dest"] - info["start"]);

	// set other attributes
	level.helicopter.dest = info["dest"];
	level.helicopter.prevdest = info["start"];
	level.helicopter.nextdest = level.helicopter.dest;
	level.helicopter.owner = owner;
	level.helicopter.ownernum = owner getEntityNumber();
	level.helicopter.team = owner.pers["team"];
	level.helicopter.maxspeed = 25;
	level.helicopter.maxaccel = 1;
	level.helicopter.tilt = 0;
	level.helicopter.health = level.ex_heli_maxhealth;
	level.helicopter.moving = false;
	level.helicopter.deccelerating = false;
	level.helicopter.adjusting = false;
	level.helicopter.targeting = false;
	level.helicopter.firing = false;
	level.helicopter.status = 0;

	// dynamic main rotor: link and rotate
	level.helicopter.mainrotor = spawn("script_model", info["start"]);
	level.helicopter.mainrotor setmodel("xmodel/vehicle_apache_mainrotor");
	level.helicopter.mainrotor thread rotateMainRotor(level.helicopter, .05);

	// static tail rotor: link only
	level.helicopter.tailrotor = spawn("script_model", info["start"]);
	level.helicopter.tailrotor setmodel("xmodel/vehicle_apache_tailrotor_static");
	level.helicopter.tailrotor linkto(level.helicopter, "tag_rotorrear", (0,0,0), (0,0,0));

	// attach missiles
	if(level.ex_heli_missile)
	{
		level.helicopter.missiles = [];
		level.helicopter.missiles[0] = spawnstruct();
		level.helicopter.missiles[0].fired = false;
		level.helicopter.missiles[0].model = spawn("script_model", (0,0,0));
		level.helicopter.missiles[0].model setmodel("xmodel/slamraam_missile");
		level.helicopter.missiles[0].model linkto(level.helicopter, "tag_rocket_l1", (0,0,0), (0,0,0));
		if(level.ex_heli_missile > 1)
		{
			level.helicopter.missiles[1] = spawnstruct();
			level.helicopter.missiles[1].fired = false;
			level.helicopter.missiles[1].model = spawn("script_model", (0,0,0));
			level.helicopter.missiles[1].model setmodel("xmodel/slamraam_missile");
			level.helicopter.missiles[1].model linkto(level.helicopter, "tag_rocket_r1", (0,0,0), (0,0,0));
			if(level.ex_heli_missile > 2)
			{
				level.helicopter.missiles[2] = spawnstruct();
				level.helicopter.missiles[2].fired = false;
				level.helicopter.missiles[2].model = spawn("script_model", (0,0,0));
				level.helicopter.missiles[2].model setmodel("xmodel/slamraam_missile");
				level.helicopter.missiles[2].model linkto(level.helicopter, "tag_rocket_l2", (0,0,0), (0,0,0));
				if(level.ex_heli_missile > 3)
				{
					level.helicopter.missiles[3] = spawnstruct();
					level.helicopter.missiles[3].fired = false;
					level.helicopter.missiles[3].model = spawn("script_model", (0,0,0));
					level.helicopter.missiles[3].model setmodel("xmodel/slamraam_missile");
					level.helicopter.missiles[3].model linkto(level.helicopter, "tag_rocket_r2", (0,0,0), (0,0,0));
				}
			}
		}
	}

	// tubes
	if(level.ex_heli_tube)
	{
		level.helicopter.tubes = [];
		level.helicopter.tubes[0] = spawnstruct();
		level.helicopter.tubes[0].fired = 0;
		if(level.ex_heli_tube > 1)
		{
			level.helicopter.tubes[1] = spawnstruct();
			level.helicopter.tubes[1].fired = 0;
		}
	}

	// play looping sound
	level.helicopter playloopsound("heli_fly_loop");

	// helicopter main logic
	level.helicopter thread heliThink();
}

rotateMainRotor(model, time)
{
	angle = 0;
	while(isDefined(self))
	{
		self linkto(model, "tag_rotormain", (0,0,0), (0,angle,0));
		wait( [[level.ex_fpstime]](time) );
		angle += 45;
		if(angle >= 360) angle = 0;
	}
}

/*******************************************************************************
DELETE
*******************************************************************************/
heliDelete()
{
	self notify("heli_deleting");

	level thread levelStopUsingPerk(self.ownernum, "heli");
	if(isPlayer(self.owner)) self.owner notify("heli_over");
	level.ex_heli_splayer = undefined;

	if(level.ex_heli_missile)
	{
		for(i = 0; i < self.missiles.size; i++)
			if(!self.missiles[i].fired) self.missiles[i].model delete();
	}

	self stoploopsound();
	self.tailrotor delete();
	self.mainrotor delete();
	self delete();
}

/*******************************************************************************
START THREADS AND WAIT FOR TIMEOUT
*******************************************************************************/
heliThink()
{
	self endon("heli_crashing");
	self endon("heli_deleting");

	thread heliMoveMonitor();
	thread heliTargetMonitor();

	timer = level.ex_heli_timer;
	while(timer > 0)
	{
		wait( [[level.ex_fpstime]](1) );
		timer--;
		if(self.health <= 0) thread heliCrash();
	}

	self.status = 1;
}

/*******************************************************************************
MOVING LOOP
*******************************************************************************/
heliMoveMonitor()
{
	self endon("heli_crashing");

	spawnpoints = getentarray("mp_dm_spawn", "classname");
	if(!spawnpoints.size) spawnpoints = getentarray("mp_tdm_spawn", "classname");
	if(!spawnpoints.size) self.status = 1;

	if(level.ex_heli_crash) crashcheck = randomInt(3) + 5;
		else crashcheck = 0;

	mindist = int((game["playArea_Width"] + game["playArea_Length"]) / 4);

	while(1)
	{
		// check for owner: must be there (player or spectator) or must be playing
		if(!isPlayer(self.owner)) self.status = 1;
		//if(!isPlayer(self.owner) || self.owner.sessionstate != "playing") self.status = 1;

		// prepare for exit if needed
		if(self.status)
		{
			self.dest = heliExitPos();
			self.status = 2;
		}
		else
		{
			// get next destination while moving to current destination
			thread heliDestinationPos(spawnpoints, mindist, 400);

			// wait while hovering (target mode)
			while(self.adjusting) wait( [[level.ex_fpstime]](1) );
		}

		// prepare path to next destination
		self.angles = anglesNormalize(self.angles);
		va = vectorToAngles(self.dest - self.origin);
		forwardvector = anglesToForward(va);

		fdot = vectorDot(anglesToForward(self.angles), forwardvector);
		if(fdot < -1) fdot = -1;
			else if(fdot > 1) fdot = 1;
		fddot = acos(fdot); // difference in degrees
		rdot = vectorDot(anglesToRight(self.angles), forwardvector);
		if(rdot < -1) rdot = -1;
			else if(rdot > 1) rdot = 1;
		rddot = acos(rdot);

		pitch = 0;
		roll = 0;
		if(fdot < 0) // more than 90 degrees turn
		{
			if(rdot < 0) // rotate hard right
			{
				pitch = -10;
				sidevector = anglestoup(va + (0,0,45));
				pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 200));
			}
			else // rotate hard left
			{
				pitch = -10;
				sidevector = anglestoup(va + (0,0,-45));
				pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 200));
			}
		}
		else // less than 90 degrees turn
		{
			if(rdot < 0 && fddot > 45) // rotate soft right
			{
				pitch = 8;
				sidevector = anglestoright(va + (0,45,0));
				pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 100));
			}
			else if(rdot > 0 && fddot > 45) // rotate soft left
			{
				pitch = 8;
				sidevector = anglestoright(va + (0,-45,0));
				pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 100));
			}
			else
			{
				pitch = 4;
				pos1 = self.origin;
			}
		}
		pos2 = self.dest + ([[level.ex_vectorscale]](forwardvector, 0 - 200));

		// move towards destination
		thread cubicBezierCurve(self.origin, pos1, pos2, self.dest);

		// tilt, roll and rotate towards destination
		if(pitch < 0)
		{
			self rotatePitch(pitch, .5);
			wait( [[level.ex_fpstime]](.5) );
			pitch = 8;
		}
		if(roll != 0)
		{
			self rotateRoll(roll, .5);
			wait( [[level.ex_fpstime]](.5) );
		}
		self rotateTo(va + (pitch,0,0), 2);
		self waittill("rotatedone");
		while(!self.deccelerating) wait( [[level.ex_fpstime]](.05) );
		//time = abs(fddot * .01);
		//if(time <= 0) time = 1;
		self rotateTo(va, 2, 1, 1);

		// random crash
		if(crashcheck)
		{
			crashcheck--;
			if(!crashcheck && (randomInt(100) + 1 <= level.ex_heli_crash)) thread heliCrash();
		}

		// wait while still moving
		while(self.moving) wait( [[level.ex_fpstime]](1) );

		self.prevdest = self.dest;
		self.dest = self.nextdest;
		if(self.status == 2 || !isDefined(self.dest)) break;

		// start hovering for a while
		self thread heliHover();
		wait( [[level.ex_fpstime]](randomInt(5) + 3) );
		self notify("heli_stophover");
	}

	thread heliDelete();
}

/*******************************************************************************
START AND DESTINATION
*******************************************************************************/
heliStartPos()
{
	startpos = undefined;
	bestdist = 0;
	bestlist = [];

	zcheck = game["playArea_Min"][2] + 800;
	if(game["mapArea_Max"][2] > 1000 && zcheck < game["mapArea_Max"][2]) zpos = zcheck;
		else zpos = game["mapArea_Max"][2] - 200;

	endpos = (game["playArea_CentreX"], game["playArea_CentreY"], zpos);

	for(i = 0; i < 360; i += 10)
	{
		forwardpos = endpos + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), 30000);
		trace = bulletTrace(endpos, forwardpos, true, self);
		if(trace["fraction"] != 1) frontpos = trace["position"];
			else frontpos = forwardpos;

		if(!isDefined(startpos)) startpos = frontpos;
		dist = distance(endpos, frontpos);
		if(dist > bestdist)
		{
			bestdist = dist;
			startpos = frontpos;
		}
		if(trace["surfacetype"] == "default") bestlist[bestlist.size] = frontpos;
	}
	if(bestlist.size) startpos = bestlist[randomInt(bestlist.size)];

	info["start"] = startpos;
	info["dest"] = endpos;
	return info;
}

heliExitPos()
{
	endpos = undefined;
	bestdist = 0;
	bestlist = [];

	for(i = 0; i < 360; i += 10)
	{
		forwardpos = self.origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), 30000);
		trace = bulletTrace(self.origin, forwardpos, true, self);
		if(trace["fraction"] != 1) frontpos = trace["position"];
			else frontpos = forwardpos;

		if(!isDefined(endpos)) endpos = frontpos;
		dist = distance(self.origin, frontpos);
		if(dist > bestdist)
		{
			bestdist = dist;
			endpos = frontpos;
		}
		if(trace["surfacetype"] == "default") bestlist[bestlist.size] = frontpos;
	}

	if(bestlist.size) return(bestlist[randomInt(bestlist.size)]);
		else return(endpos);
}

heliDestinationPos(destarray, mindist, margin)
{
	self.nextdest = undefined;
	bestdist = 0;
	bestlist = [];

	for(i = 0; i < destarray.size; i++)
	{
		index = randomInt(destarray.size);
		dest = destarray[index].origin;
		dest = (dest[0],  dest[1],  self.origin[2]);
		dist = distance(self.dest, dest);

		vf = anglesToForward(vectorToAngles(dest - self.dest));
		frontpos = self.dest + [[level.ex_vectorscale]](vf, dist);
		frontpos = bulletTrace(self.dest, frontpos, false, self)["position"] + [[level.ex_vectorscale]](vf, 0 - margin);
		if(frontpos == self.prevdest || frontpos == self.dest) continue;

		dist = distance(self.dest, frontpos);
		if(dist > bestdist)
		{
			self.nextdest = frontpos;
			bestdist = dist;
		}
		if(dist >= mindist) bestlist[bestlist.size] = frontpos;
		if(bestlist.size >= 10) break;
		if(i % 5 == 0) waittillframeend;
	}

	if(bestlist.size) self.nextdest = bestlist[randomInt(bestlist.size)];
}

/*******************************************************************************
HOVER LOOP
*******************************************************************************/
heliHover()
{
	self endon("heli_stophover");
	self endon("heli_crashing");
	self endon("heli_deleting");

	original_pos = self.origin;

	while(1)
	{
		for(i = 0; i < 5; i++)
		{
			x = 0;
			x -= randomInt(15);
			x += randomInt(15);
			y = 0;
			y -= randomInt(15);
			y += randomInt(15);
			z = 0;
			z -= randomInt(15);
			z += randomInt(15);
			dest = self.origin + (x,y,z);

			movetime = randomFloat(1) + 1;
			self moveto(dest, movetime, 0, .5);
			wait( [[level.ex_fpstime]](movetime) );
		}

		dist = distance(self.origin, original_pos);
		movetime = dist * 0.0254;
		if(movetime < 1) movetime = 1;
		self moveto(original_pos, movetime, 0, .5);
		wait( [[level.ex_fpstime]](movetime) );
	}
}

/*******************************************************************************
TARGETING LOOP
*******************************************************************************/
heliTargetMonitor()
{
	self endon("heli_crashing");
	self endon("heli_deleting");

	interval = .2;
	gun_target = self;
	gun_delay = 0;
	missile_delay = 50; // 10 seconds, 10 * (5 * .2)
	tube_delay = 100; // 20 seconds, 20 * (5 * .2)

	while(!self.status)
	{
		old_target = gun_target;
		gun_target = self;
		missile_target = self;
		tube_target = self;

		wait( [[level.ex_fpstime]](interval) );

		// gun targeting
		if(level.ex_heli_gun && !self.moving)
		{
			if(gun_delay) gun_delay--;
			if(!gun_delay)
			{
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(isPlayer(player) && player.sessionstate == "playing" && player.pers["team"] != self.team)
					{
						if(isPlayer(old_target) && isAlive(old_target) && heliCanSee(old_target, level.ex_heli_gun_fov, level.ex_heli_gun_radius))
						{
							gun_target = old_target;
							break;
						}
						else if(heliCanSee(player, level.ex_heli_gun_fov, level.ex_heli_gun_radius))
						{
							if(!isPlayer(gun_target)) gun_target = player;
							if(closer(self.origin, player.origin, gun_target.origin)) gun_target = player;
						}
					}
				}

				if(isPlayer(gun_target))
				{
					self.adjusting = true;
					va = vectorToAngles(gun_target.origin + (0, 0, 40) - self.origin);
					dot = vectorDot(anglesToForward(self.angles), anglesToForward(va));
					if(dot < -1) dot = -1;
						else if(dot > 1) dot = 1;
					time = abs(acos(dot) * .01998);
					if(time <= 0) time = 0.1;
					if(gun_target == old_target && !self.targeting) self rotateTo((0, va[1], 0), time);
						else thread heliTargeting(va, time);

					wait( [[level.ex_fpstime]](.05) );

					if(!self.targeting) thread fireGun(gun_target);
				}
				else self.adjusting = false;
			}
		}

		// missile targeting
		if(level.ex_heli_missile)
		{
			if(missile_delay) missile_delay--;
			if(!missile_delay)
			{
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(isPlayer(player) && player.sessionstate == "playing" && player.pers["team"] != self.team)
					{
						if(player == gun_target) continue;
						if(heliCanSee(player, level.ex_heli_missile_fov, level.ex_heli_missile_radius))
						{
							if(!isPlayer(missile_target)) missile_target = player;
							if(!closer(self.origin, player.origin, missile_target.origin)) missile_target = player;
						}
					}
				}

				if(isPlayer(missile_target))
				{
					thread fireMissile(missile_target);
					missile_delay = 50; // = 10 seconds, 10 * (5 * .2)
				}
			}
		}

		// grenade tubes targeting
		if(level.ex_heli_tube)
		{
			if(tube_delay) tube_delay--;
			if(!tube_delay)
			{
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(isPlayer(player) && player.sessionstate == "playing" && player.pers["team"] != self.team)
					{
						if(heliCanSee(player, level.ex_heli_tube_fov, level.ex_heli_tube_radius))
						{
							if(player == gun_target || player == missile_target) continue;
							if(!isPlayer(tube_target)) tube_target = player;
							thread fireTube(player);
							wait( [[level.ex_fpstime]](.2) );
						}
					}
				}

				if(isPlayer(tube_target)) tube_delay = 100; // 20 seconds, 20 * (5 * .2)
			}
		}
	}

	self.adjusting = false;
}

heliTargeting(vector, time)
{
	self endon("heli_deleting");

	if(self.targeting) return;
	self.targeting = true;

	self rotateTo((0, vector[1], 0), time);
	wait( [[level.ex_fpstime]](time) );
	self.targeting = false;
}

heliCanSee(player, fov, radius)
{
	self endon("heli_deleting");

	cansee = false;
	dir = vectorNormalize(player.origin + (0, 0, 40) - self.origin);
	dot = vectorDot(anglesToForward(self.angles), dir);
	if(dot < -1) dot = -1;
		else if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle <= fov)
	{
	 	if(distance(player.origin, self.origin) <= radius)
	 	{
			cansee = (bullettrace(self.origin + (0, 0, 10), player.origin + (0, 0, 10), false, self)["fraction"] == 1);
			if(!cansee) cansee = (bullettrace(self.origin + (0, 0, 10), player.origin + (0, 0, 40), false, self)["fraction"] == 1);
			if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(self.origin + (0, 0, 10), player.ex_eyemarker.origin, false, self)["fraction"] == 1);
		}
	}
	return(cansee);
}

/*******************************************************************************
GUN
*******************************************************************************/
fireGun(target)
{
	thread fireGunFX();

	// using weapon dummy1_mp so we don't have to precache another weapon. We will convert dummy2_mp to heligun_mp for MOD_PROJECTILE later on
	va = vectorToAngles(target.origin + (0, 0, 40) - self.origin);
	if(isPlayer(self.owner) && self.owner.sessionstate != "spectator" && (!level.ex_teamplay || self.owner.pers["team"] == self.team))
		target thread [[level.callbackPlayerDamage]](self, self.owner, 20, 1, "MOD_PROJECTILE", "dummy2_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
	else
		target thread [[level.callbackPlayerDamage]](self, self, 20, 1, "MOD_PROJECTILE", "dummy2_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
}

fireGunFX()
{
	if(self.firing) return;
	self.firing = true;
	numshots = 15;
	self playsound("heli_firegun");
	for(i = 0; i < numshots; i++)
	{
		playfxontag(level.ex_effect["heli_gun"], self, "tag_gun");
		wait( [[level.ex_fpstime]](.075) );
	}
	self.firing = false;
}

/*******************************************************************************
MISSILE
*******************************************************************************/
fireMissile(target)
{
	missile = 0;
	while(1)
	{
		if(!self.missiles[missile].fired) break;
		missile++;
		if(missile == 4) return;
	}

	self.missiles[missile].fired = true;
	self.missiles[missile].model unlink();
	self.missiles[missile].model thread fireMissileFX(self.owner, self.team, target);
}

fireMissileFX(owner, team, target)
{
	self playsound("weap_panzerfaust_fire");
	self.speed = 30;
	self.finishedrotating = true;

	self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
	if(time <= 0)
	{
		self delete();
		return;
	}
	self moveto(self.dest, time, 0.5, 0);
	wait( [[level.ex_fpstime]](.25) ); // no turn for .25 second to let it detach properly

	olddest = (0,0,0);
	totaltime = 0;
	lifespan = 30 * level.ex_fps;
	trace = bulletTrace(self.origin, self.dest, true, self);
	ftime = int(distance(self.origin, trace["position"]) * 0.0254) / self.speed;
	for(t = 0; t < ftime * level.ex_fps; t++)
	{
		wait( [[level.ex_fpstime]](.05) );

		newtrace = bulletTrace(self.origin, self.dest, true, self);
		if(distance(newtrace["position"], trace["position"]) > 1)
		{
			trace = newtrace;
			ftime = int(distance(self.origin, trace["position"]) * 0.0254) / self.speed;
			t = 0;
		}

		// handle fx
		totaltime++;
		if(totaltime % 4 == 0) playfxontag(level.ex_effect["heli_missile"], self, "tag_flash");

		// handle flying time
		if(lifespan && totaltime > lifespan) break;

		// check if owner still exist
		if(!isPlayer(owner))
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 999999);
			time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
			if(time <= 0) break;
			self moveto(self.dest, time, 0, 0);
			continue;
		}

		// check if target still exist
		if(!isPlayer(target) || target.sessionstate != "playing")
		{
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isPlayer(player) && player.sessionstate == "playing" && player.pers["team"] != team)
				{
					if(!isPlayer(target)) target = player;
					if(closer(self.dest, player.origin, target.origin)) target = player;
				}
			}

			if(!isPlayer(target))
			{
				self.dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 999999);
				time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
				if(time <= 0) break;
				self moveto(self.dest, time, 0, 0);
				continue;
			}
		}

		// try to follow target
		newdest = target.ex_spinemarker.origin;
		if(!isDefined(newdest) || newdest == olddest) continue;
		olddest = self.dest;
		self.dest = newdest;

		if(self.finishedrotating)
		{
			dir = vectorNormalize(self.dest - self.origin);
			forward = anglesToForward(self.angles);
			dot = vectordot(dir, forward);
			if(dot < 0.85)
			{
				rotate = vectorToAngles(self.dest - self.origin);
				dot = vectorDot(anglesToForward(self.angles), anglesToForward(rotate));
				if(dot < -1) dot = -1;
					else if(dot > 1) dot = 1;
				time = abs(acos(dot) * .0075);
				if(time <= 0) time = 0.1;

				self rotateto(rotate, time, 0, 0);
				self.finishedrotating = false;
				self thread waitForRotate(time);
			}
		}

		if(self.finishedrotating) angle = vectorToAngles(self.dest - self.origin);
		else
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
			angle = undefined;
		}
		if(isDefined(angle)) self.angles = angle;

		time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
		if(time <= 0) break;
		self moveto(self.dest, time, 0, 0);
	}

	// handle explosion
	self hide();
	playfx(level.ex_effect["artillery"], self.origin);
	ms = randomInt(18) + 1;
	self playsound("mortar_explosion" + ms);

	surfaceFx = calcImpactSurface(self.origin);
	// using weapon dummy2_mp so we don't have to precache another weapon. We will convert dummy2_mp to helimissile_mp for MOD_EXPLOSIVE later on
	if(isPlayer(owner) && owner.sessionstate != "spectator" && (!level.ex_teamplay || owner.pers["team"] == team))
		self thread extreme\_ex_utils::scriptedfxradiusdamage(owner, undefined, "MOD_EXPLOSIVE", "dummy2_mp", 500, 200, 50, "generic", surfaceFx, true, true, true);
	else
		self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "dummy2_mp", 500, 0, 0, "generic", surfaceFx, true, true, true);

	wait( [[level.ex_fpstime]](3) );
	self delete();
}

waitForRotate(time)
{
	self notify("stop_rotate_thread");
	self endon("stop_rotate_thread");

	wait( [[level.ex_fpstime]](time) );
	if(isDefined(self)) self.finishedrotating = true;
}

/*******************************************************************************
TUBES
*******************************************************************************/
fireTube(target)
{
	tube = 0;
	while(1)
	{
		if(self.tubes[tube].fired <= 19) break;
		tube++;
		if(tube == 2) return;
	}

	self.tubes[tube].fired++;
	thread fireTubeFX(tube, target);
}

fireTubeFX(tube, target)
{
	self playsound("heli_firetube");
	if(tube == 0) playfxontag(level.ex_effect["heli_tube"], self, "tag_tube_l");
		else playfxontag(level.ex_effect["heli_tube"], self, "tag_tube_r");

	delay = (distance(self.origin, target.origin) / 100) * 0.05;
	wait( [[level.ex_fpstime]](delay) );

	// handle explosion
	impactloc = spawn("script_origin", target.origin);
	impactloc playSound("grenade_explode_default");

	surfaceFx = calcImpactSurface(target.origin);
	// using weapon dummy2_mp so we don't have to precache another weapon. We will convert dummy2_mp to helitube_mp for MOD_GRENADE later on
	if(isPlayer(self.owner) && self.owner.sessionstate != "spectator" && (!level.ex_teamplay || self.owner.pers["team"] == self.team))
		impactloc thread extreme\_ex_utils::scriptedfxradiusdamage(self.owner, undefined, "MOD_GRENADE", "dummy2_mp", 256, 200, 50, "generic", surfaceFx, true, true, true);
	else
		impactloc thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_GRENADE", "dummy2_mp", 256, 0, 0, "generic", surfaceFx, true, true, true);

	wait( [[level.ex_fpstime]](1) );
	impactloc delete();
}

/*******************************************************************************
CRASH
*******************************************************************************/
heliCrash()
{
	wait(0);
	self notify("heli_crashing");

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_1");

	self stoploopsound();
	self playloopsound("heli_damaged_loop");

	shortest = 50000;
	endpos = undefined;
	for(i = 0; i < 360; i += 10)
	{
		forwardpos = self.origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), 30000);
		trace = bulletTrace(self.origin, forwardpos, true, self);
		if(trace["fraction"] != 1) temppos = trace["position"];
			else temppos = forwardpos;

		if(!isDefined(endpos)) endpos = temppos;
		dist = distance(self.origin, temppos);
		if(dist < shortest)
		{
			shortest = dist;
			endpos = temppos;
		}
	}

	time = calctime(endpos, self.origin, 10);
	self moveto(endpos, time * 0.999, 0, 0);

	thread heliCrashFX();
	thread heliCrashRotate();

	wait( [[level.ex_fpstime]](time) );

	self notify("heli_stopfx");
	playfx(level.ex_effect["plane_explosion"], self.origin);
	heliDelete();
}

heliCrashRotate()
{
	self endon("heli_stopfx");

	while(1)
	{
		self rotateyaw(-360, 3);
		wait( [[level.ex_fpstime]](3) );
	}
}

heliCrashFX()
{
	self endon("heli_stopfx");

	while(1)
	{
		playfx(level.ex_effect["planecrash_smoke"], self.origin);
		playfxontag(level.ex_effect["planecrash_smoke"], self, "tag_rotorrear");
		if(randomInt(100) < 10) self playsound("plane_explosion_2");
		wait( [[level.ex_fpstime]](.4) );
	}
}

/*******************************************************************************
BEZIER CURVES
*******************************************************************************/
linearBezierCurve(pos0, pos1)
{
	self endon("heli_crashing");

	self.moving = true;
	node = pointLinearBezierCurve(pos0, pos1, 1);
	length = distance(pos0, node);
	if(length > 3000) speed = self.maxspeed;
		else if(length > 1500) speed = 15;
			else speed = 5;
	movetime = calcTime(self.origin, node, speed);
	self moveto(node, movetime);
	wait( [[level.ex_fpstime]](movetime * .999) );
	self.moving = false;
}

quadraticBezierCurve(pos0, pos1, pos2)
{
	self endon("heli_crashing");

	self.moving = true;

	length = 0;
	nodes = 10;
	node_prev = pos0;
	for(i = 1; i <= nodes; i++)
	{
		node = pointQuadraticBezierCurve(pos0, pos1, pos2, i / nodes);
		x_diff = node[0] - node_prev[0];
		y_diff = node[1] - node_prev[1];
		length += sqrt( (x_diff * x_diff) + (y_diff * y_diff) );
		node_prev = node;
	}

	node_length = 100;
	nodes = int(length / node_length);
	if(!nodes) nodes = 2;

	if(length > 3000) speed = self.maxspeed;
		else if(length > 1500) speed = 15;
			else speed = 5;
	movetime = (node_length * 0.0254) / speed;
	if(movetime <= 0) movetime = 0.5;

	for(i = 1; i <= nodes; i++)
	{
		node = pointQuadraticBezierCurve(pos0, pos1, pos2, i / nodes);
		if(i * node_length >= length - 500)
		{
			self.deccelerating = true;
			movetime_dec = movetime + (i / nodes) + (i / nodes) * movetime;
			self moveto(node, movetime_dec);
			wait( [[level.ex_fpstime]](movetime_dec * .999) );
		}
		else
		{
			self moveto(node, movetime);
			wait( [[level.ex_fpstime]](movetime * .999) );
		}
	}

	self.deccelerating = false;
	self.moving = false;
}

cubicBezierCurve(pos0, pos1, pos2, pos3)
{
	self endon("heli_crashing");

	self.moving = true;
	//debugVec(); // DEBUG

	length = 0;
	nodes = 10;
	node_prev = pos0;
	for(i = 1; i <= nodes; i++)
	{
		node = pointCubicBezierCurve(pos0, pos1, pos2, pos3, i / nodes);
		x_diff = node[0] - node_prev[0];
		y_diff = node[1] - node_prev[1];
		length += sqrt( (x_diff * x_diff) + (y_diff * y_diff) );
		node_prev = node;
	}

	node_length = 100;
	nodes = int(length / node_length);
	if(!nodes) nodes = 2;

	if(length > 3000) speed = self.maxspeed;
		else if(length > 1500) speed = 15;
			else speed = 5;
	movetime = (node_length * 0.0254) / speed;
	if(movetime <= 0) movetime = 0.5;

	for(i = 1; i <= nodes; i++)
	{
		node = pointCubicBezierCurve(pos0, pos1, pos2, pos3, i / nodes);
		//debugVec(node); // DEBUG
		if(i * node_length >= length - 500)
		{
			self.deccelerating = true;
			movetime_dec = movetime + (i / nodes) + (i / nodes) * movetime;
			self moveto(node, movetime_dec);
			wait( [[level.ex_fpstime]](movetime_dec * .999) );
		}
		else
		{
			self moveto(node, movetime);
			wait( [[level.ex_fpstime]](movetime * .999) );
		}
	}

	self.deccelerating = false;
	self.moving = false;
}

pointLinearBezierCurve(pos0, pos1, t)
{
	// B(t) = (1-t)*P0 + t*P1
	tvec = [[level.ex_vectorscale]](pos0, 1 - t) +
	       [[level.ex_vectorscale]](pos1, t);
	vec = (tvec[0], tvec[1], tvec[2]);
	return vec;
}

pointQuadraticBezierCurve(pos0, pos1, pos2, t)
{
	// B(t) = (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 2)) +
	       [[level.ex_vectorscale]](pos1, t * (2 * (1 - t))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2));
	vec = (tvec[0], tvec[1], tvec[2]);
	return vec;
}

pointCubicBezierCurve(pos0, pos1, pos2, pos3, t)
{
	// B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 3)) +
	       [[level.ex_vectorscale]](pos1, t * (3 * pow(1 - t, 2))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2) * (3 * (1 - t))) +
	       [[level.ex_vectorscale]](pos3, pow(t, 3));
	vec = (tvec[0], tvec[1], tvec[2]);
	return vec;
}

/*******************************************************************************
DAMAGE
*******************************************************************************/
onFrameInit()
{
	weapon = self getcurrentweapon();
	if(weapon == self getweaponslotweapon("primary")) weaponslot = "primary";
		else weaponslot = "primaryb";
	ammo = self getWeaponslotclipammo(weaponslot);

	self.heli_weapon = weapon;
	self.heli_ammo = ammo;

	[[level.ex_registerPlayerEvent]]("onFrame", ::onFrame, true);
}

onFrame(eventID)
{
	self endon("kill_thread");

	if(isDefined(level.ex_heli_splayer) && level.helicopter.health > 0)
	{
		weapon = self getcurrentweapon();
		if(weapon == self getweaponslotweapon("primary")) weaponslot = "primary";
			else weaponslot = "primaryb";
		ammo = self getWeaponslotclipammo(weaponslot);

		if(self attackbuttonpressed())
		{
			if(ammo < self.heli_ammo && canDamageHeli(weapon))
			{
				endorigin = self.ex_eyemarker.origin + maps\mp\_utility::vectorScale(anglesToForward(self getplayerangles()), 10000);
				trace = bulletTrace(self.ex_eyemarker.origin, endorigin, true, self);
				if(trace["fraction"] != 1 && isDefined(trace["entity"]))
				{
					if(level.ex_heli_candamage == 2 && trace["entity"] == level.helicopter)
					{
						dist = distance(self.ex_eyemarker.origin, trace["position"]);
						level.helicopter.health -= maxDamageHeli(3, weapon, dist);
						if(level.ex_heli_damagehud) thread hudDamageHeli(2);
					}
					else if(trace["entity"] == level.helicopter.tailrotor)
					{
						dist = distance(self.ex_eyemarker.origin, trace["position"]);
						level.helicopter.health -= maxDamageHeli(1, weapon, dist);
						if(level.ex_heli_damagehud) thread hudDamageHeli(2);
					}
				}
			}
		}

		self.heli_weapon = weapon;
		self.heli_ammo = ammo;
	}

	[[level.ex_enablePlayerEvent]]("onFrame", eventID);
}

canDamageHeli(weapon)
{
	if(self.pers["team"] == level.helicopter.team) return(false);

	switch(weapon)
	{
		case "none":
		case "ignore":
		case "knife_mp":
		case "rpg_mp":
		case "panzerschreck_mp":
		case "panzerschreck_allies":
		case "flamethrower_axis":
		case "flamethrower_allies":
		case "gunship_nuke_mp": return(false);
		default: return(true);
	}
}

maxDamageHeli(modifier, weapon, dist)
{
	distmod = int(100 - (dist / 100));
	if(distmod <= 0) return(0);

	maxdamage = 0;
	if(weapon == "gunship_105mm_mp") maxdamage = 1000;
	else if(weapon == "gunship_40mm_mp") maxdamage = 500;
	else if(weapon == "gunship_25mm_mp") maxdamage = 20;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "sniperlr")) maxdamage = 100;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "snipersr")) maxdamage = 50;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "rifle")) maxdamage = 40;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "mg")) maxdamage = 30;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "smg")) maxdamage = 20;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) maxdamage = 10;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "pistol")) maxdamage = 5;

	damage = int((maxdamage / modifier) * (distmod / 100));
	if(damage > level.helicopter.health) damage = level.helicopter.health;
	return(damage);
}

hudDamageHeli(duration)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_heli_damage_bg))
	{
		if(isDefined(level.helicopter)) status = level.helicopter.health;
			else status = 0;
		if(status <= 0) return;
		status = int( (114 / level.ex_heli_maxhealth) * status);
		if(status <= 0) return;

		self.ex_heli_damage_bg = newclienthudelem(self);
		self.ex_heli_damage_bg.archived = false;
		self.ex_heli_damage_bg.horzAlign = "right";
		self.ex_heli_damage_bg.vertAlign = "bottom";
		self.ex_heli_damage_bg.alignX = "right";
		self.ex_heli_damage_bg.alignY = "bottom";
		self.ex_heli_damage_bg.x = -53;
		self.ex_heli_damage_bg.y = -200;
		self.ex_heli_damage_bg setShader("hud_temperature_gauge", 35, 150);
		self.ex_heli_damage_bg.sort = 2;

		if(!isDefined(self.ex_heli_damage_health))
		{
			self.ex_heli_damage_health = newclienthudelem(self);
			self.ex_heli_damage_health.archived = false;
			self.ex_heli_damage_health.horzAlign = "right";
			self.ex_heli_damage_health.vertAlign = "bottom";
			self.ex_heli_damage_health.alignX = "right";
			self.ex_heli_damage_health.alignY = "bottom";
			self.ex_heli_damage_health.x = -65;
			self.ex_heli_damage_health.y = -232;
			self.ex_heli_damage_health setShader("white", 10, status);
			self.ex_heli_damage_health.color = hudDamageHeliColor();
			self.ex_heli_damage_health.alpha = 1;
			self.ex_heli_damage_health.sort = 1;

			self.ex_heli_damage_health.timeonscreen = duration;
			self thread hudDamageHeliRemove();
		}
	}
	else
	{
		self.ex_heli_damage_health.timeonscreen = duration;
	}
}

hudDamageHeliColor()
{
	if(isDefined(level.helicopter)) status = level.helicopter.health;
		else status = 0;
	perc = int( (100 / level.ex_heli_maxhealth) * status);
	if(perc > 50) return( (0,1,0) );
	if(perc > 40) return( (1,1,0) );
	if(perc > 20) return( (1,0.5,0) );
	return( (1,0,0) );
}

hudDamageHeliRemove()
{
	self endon("kill_thread");

	while(isDefined(level.helicopter) && isDefined(self.ex_heli_damage_health) && self.ex_heli_damage_health.timeonscreen > 0)
	{
		wait( [[level.ex_fpstime]](0.1) );

		if(isDefined(level.helicopter)) status = level.helicopter.health;
			else status = 0;
		if(status <= 0) break;
		status = int( (114 / level.ex_heli_maxhealth) * status);
		if(status <= 0) break;

		self.ex_heli_damage_health setShader("white", 10, status);
		self.ex_heli_damage_health.color = hudDamageHeliColor();

		self.ex_heli_damage_health.timeonscreen -= 0.1;
	}

	if(isDefined(self.ex_heli_damage_health)) self.ex_heli_damage_health destroy();
	if(isDefined(self.ex_heli_damage_bg)) self.ex_heli_damage_bg destroy();
}

/*******************************************************************************
ROCKET MONITOR
*******************************************************************************/
heliMonitorProjectile(entity, player)
{
	origin = entity.origin;
	angles = entity.angles;
	entity delete();
	rocket = spawn("script_model", origin);
	// WARNING: this is only safe if panzerschreck weapon is enabled (precached)!
	rocket setmodel("xmodel/weapon_temp_panzershreck_rocket");
	rocket.angles = angles;
	rocket thread rocketChaseHeli();

	if(level.ex_heli_damagehud && isPlayer(player)) player thread hudDamageHeli(10);
}

rocketChaseHeli()
{
	self.speed = 20;
	self.finishedrotating = true;

	self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
	if(time <= 0)
	{
		self delete();
		return;
	}
	self moveto(self.dest, time, 0, 0);
	wait( [[level.ex_fpstime]](.25) ); // no turn for .25 second to let it detach properly

	olddest = (0,0,0);
	totaltime = 0;
	lifespan = 30 * level.ex_fps;
	trace = bulletTrace(self.origin, self.dest, true, self);
	ftime = int(distance(self.origin, trace["position"]) * 0.0254) / self.speed;
	for(t = 0; t < ftime * level.ex_fps; t++)
	{
		wait( [[level.ex_fpstime]](.05) );

		newtrace = bulletTrace(self.origin, self.dest, true, self);
		if(distance(newtrace["position"], trace["position"]) > 1)
		{
			trace = newtrace;
			ftime = int(distance(self.origin, trace["position"]) * 0.0254) / self.speed;
			t = 0;
		}

		// handle fx
		totaltime++;
		if(totaltime % 4 == 0) playfxontag(level.ex_effect["heli_missile"], self, "tag_origin");

		// handle flying time
		if(lifespan && totaltime > lifespan) break;

		// check if heli still exist
		if(!isDefined(level.helicopter))
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 999999);
			time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
			if(time <= 0) break;
			self moveto(self.dest, time, 0, 0);
			continue;
		}

		// try to follow target
		newdest = level.helicopter.origin;
		if(!isDefined(newdest) || newdest == olddest) continue;
		olddest = self.dest;
		self.dest = newdest;

		if(self.finishedrotating)
		{
			dir = vectorNormalize(self.dest - self.origin);
			forward = anglesToForward(self.angles);
			dot = vectordot(dir, forward);
			if(dot < 0.85)
			{
				rotate = vectorToAngles(self.dest - self.origin);
				dot = vectorDot(anglesToForward(self.angles), anglesToForward(rotate));
				if(dot < -1) dot = -1;
					else if(dot > 1) dot = 1;
				time = abs(acos(dot) * .0075);
				if(time <= 0) time = 0.1;

				self rotateto(rotate, time, 0, 0);
				self.finishedrotating = false;
				self thread waitForRotate(time);
			}
		}

		if(self.finishedrotating) angle = vectorToAngles(self.dest - self.origin);
		else
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
			angle = undefined;
		}
		if(isDefined(angle)) self.angles = angle;

		time = int(distance(self.origin, self.dest) * 0.0254) / self.speed;
		if(time <= 0) break;
		self moveto(self.dest, time, 0, 0);
	}

	// handle explosion
	self hide();
	playfx(level.ex_effect["artillery"], self.origin);
	ms = randomInt(18) + 1;
	self playsound("mortar_explosion" + ms);
	self delete();

	if(trace["fraction"] != 1 && isDefined(trace["entity"]))
	{
		if(level.ex_heli_candamage == 2 && (trace["entity"] == level.helicopter || trace["entity"] == level.helicopter.tailrotor))
		{
			damage = 500;
			if(damage > level.helicopter.health) damage = level.helicopter.health;
			level.helicopter.health -= damage;
		}
	}
}

/*******************************************************************************
MISC
*******************************************************************************/
calcTime(p1, p2, speed)
{
	time = ((distance(p1, p2) * 0.0254) / speed);
	if(time <= 0) time = 1;
	return time;
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

anglesNormalize(angles)
{
	pitch = 0.0 + angles[0];
	while(pitch >= 360) pitch -= 360;
	yaw = 0.0 + angles[1];
	while(yaw >= 360) yaw -= 360;
	roll = 0.0 + angles[2];
	while(roll >= 360) roll -= 360;
	return( (pitch, yaw, roll) );
}

pow(numb, power)
{
	result = 1.0;
	for(i = 0; i < power; i++)
		result = result * numb;
	return result;
}

abs(x)
{
	if(x < 0) x *= -1;
	return x;
}

sqrt(X)
{
	if(X < 0) return -1;
	e = 0.000000000001;
	while(e > X) e /= 10;
	b = (1.0 + X) / 2;
	c = (b - X / b) / 2;
	iterations = 0;
	while(c > e && iterations < 1000)
	{
		f = b;
		b -= c;
		if(f == b) return b;
		c = (b - X / b) / 2;
		iterations++;
	}
	return b;
}

/*******************************************************************************
VECTOR DEBUG CODE
*******************************************************************************/
debugVec(vec, vecmodel)
{
	if(isDefined(vec))
	{
		if(!isDefined(level.ex_debug_models)) level.ex_debug_models = [];
		if(!isDefined(vecmodel)) vecmodel = "default";

		model = undefined;
		switch(vecmodel)
		{
			case  "large": model = "xmodel/health_large"; break;
			case "medium": model = "xmodel/health_medium"; break;
			default      : model = "xmodel/health_small"; break;
		}
		if(isDefined(model))
		{
			level.ex_debug_models[level.ex_debug_models.size] = spawn("script_model", vec);
			level.ex_debug_models[level.ex_debug_models.size-1] setmodel(model);
		}
	}
	else
	{
		if(isDefined(level.ex_debug_models))
		{
			for(i = 0; i < level.ex_debug_models.size; i++) level.ex_debug_models[i] delete();
			level.ex_debug_models = undefined;
		}
	}
}

