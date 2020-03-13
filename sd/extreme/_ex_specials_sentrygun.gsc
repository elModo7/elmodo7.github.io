#include extreme\_ex_specials;

sentrygunPerkDelayed(delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );
	self thread sentrygunPerk(0);
}

sentrygunPerk(delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if(!isDefined(self.ex_sentrygun)) self.ex_sentrygun = false;
	if(self.ex_sentrygun) return;
	self.ex_sentrygun = true;

	if(!isDefined(self.ex_sentrygun_moving_timer))
	{
		if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_sentryunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_SENTRY_READY");
	}
	self playlocalsound("sentrygun_readyfor");

	self hudNotifySpecial("sentrygun");
	while(!self playerActionPanel(-1)) wait( [[level.ex_fpstime]](.05) );
	self hudNotifySpecialRemove("sentrygun");

	self.ex_sentrygun = false;
	self playlocalsound("sentrygun_ontheway");

	angles = (0, self.angles[1], 0);
	origin = self.origin;
	level thread sentrygunCreate(self, origin, angles);
	self thread playerStartUsingPerk("sentrygun");

	if(level.ex_sentrygun_messages)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"])) continue;
			else if(player.pers["team"] == self.pers["team"])
			{
				player playlocalsound("sentrygun_deployed");
				player iprintlnbold(&"SPECIALS_SENTRY_DEPLOYED_TEAM", [[level.ex_pname]](self));
			}
			else
			{
				player playlocalsound("sentrygun_enemyincoming");
				player iprintlnbold(&"SPECIALS_SENTRY_DEPLOYED_ENEMY", [[level.ex_pname]](self));
			}
		}
	}
}

sentrygunCreate(owner, origin, angles)
{
	index = sentrygunAllocate();

	level.sentryguns[index].timer = level.ex_sentrygun_timer * 5;
	level.sentryguns[index].firing = false;
	level.sentryguns[index].targeting = false;
	level.sentryguns[index].activated = false;
	level.sentryguns[index].destroyed = false;
	level.sentryguns[index].sabotaged = false;
	level.sentryguns[index].abandoned = false;
	level.sentryguns[index].rotating = 2;
	level.sentryguns[index].nades = 0;
	level.sentryguns[index].org_origin = origin;
	level.sentryguns[index].org_angles = angles;
	level.sentryguns[index].org_owner = owner;
	level.sentryguns[index].org_ownernum = owner getEntityNumber();

	level.sentryguns[index].sentry_base = spawn("script_model", origin);
	level.sentryguns[index].sentry_base hide();
	level.sentryguns[index].sentry_base setmodel("xmodel/sentry_gun_4pod");
	level.sentryguns[index].sentry_base.angles = angles;

	level.sentryguns[index].sentry_gun = spawn("script_model", origin + (0, 0, 35));
	level.sentryguns[index].sentry_gun hide();
	level.sentryguns[index].sentry_gun setmodel("xmodel/caspi_minigun_head");
	level.sentryguns[index].sentry_gun.angles = angles + (75, 0, 0);

	level.sentryguns[index].sentry_trig = spawn("trigger_radius", origin + (0, 0, 20), 0, 30, 30);

	// set owner after creating entities so proximity code can handle it
	level.sentryguns[index].owner = owner;
	level.sentryguns[index].team = owner.pers["team"];

	while(positionWouldTelefrag(level.sentryguns[index].sentry_base.origin)) wait( [[level.ex_fpstime]](.05) );

	level.sentryguns[index].sentry_base show();
	level.sentryguns[index].sentry_gun show();
	level.sentryguns[index].sentry_trig setcontents(1);

	// restore timer and owner after moving sentry gun
	if(isDefined(owner.ex_sentrygun_moving_timer))
	{
		level.sentryguns[index].timer = owner.ex_sentrygun_moving_timer;
		owner.ex_sentrygun_moving_timer = undefined;

		if(isDefined(owner.ex_sentrygun_moving_owner) && isPlayer(owner.ex_sentrygun_moving_owner) && owner.pers["team"] == owner.ex_sentrygun_moving_owner.pers["team"])
			level.sentryguns[index].owner = owner.ex_sentrygun_moving_owner;
		owner.ex_sentrygun_moving_owner = undefined;
	}

	sentrygunActivate(index, false);
	if(isPlayer(owner)) owner playlocalsound("sentrygun_ready");
	level thread sentrygunThink(index);
	//level thread sentryDeveloper(index);
}

sentrygunAllocate()
{
	for(i = 0; i < level.sentryguns.size; i++)
	{
		if(level.sentryguns[i].inuse == 0)
		{
			level.sentryguns[i].inuse = 1;
			return(i);
		}
	}

	level.sentryguns[i] = spawnstruct();
	level.sentryguns[i].inuse = 1;
	return(i);
}

sentrygunRemoveFrom(player)
{
	for(i = 0; i < level.sentryguns.size; i++)
		if(level.sentryguns[i].inuse && isDefined(level.sentryguns[i].owner) && level.sentryguns[i].owner == player) thread sentrygunRemove(i);
}

sentrygunRemove(index)
{
	level.sentryguns[index].destroyed = true; // kills sentrygunThink(index)
	sentrygunDeactivate(index, false);
	wait( [[level.ex_fpstime]](2) );
	sentrygunDeleteWaypoint(index);
	sentrygunFree(index);
}

sentrygunFree(index)
{
	if(isDefined(level.sentryguns) && isDefined(level.sentryguns[index]))
	{
		thread levelStopUsingPerk(level.sentryguns[index].org_ownernum, "sentrygun");
		level.sentryguns[index].owner = undefined;
		if(isDefined(level.sentryguns[index].sentry_trig)) level.sentryguns[index].sentry_trig delete();
		if(isDefined(level.sentryguns[index].sentry_gun)) level.sentryguns[index].sentry_gun delete();
		if(isDefined(level.sentryguns[index].sentry_base)) level.sentryguns[index].sentry_base delete();
		level.sentryguns[index].inuse = 0;
	}
}

sentrygunActivate(index, force)
{
	if(!level.sentryguns[index].inuse || (level.sentryguns[index].activated && !force)) return;
	level.sentryguns[index].activated = true;
	sentrygunCreateWaypoint(index);

	level.sentryguns[index].nades = 0;
	level.sentryguns[index].rotating = 2;
	level.sentryguns[index].sentry_gun playsound("sentrygun_windup");
	level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles, 2);
	wait( [[level.ex_fpstime]](2) );
}

sentrygunAdjust(index, player)
{
	level.sentryguns[index].org_angles = (0, player.angles[1], 0);

	level.sentryguns[index].rotating = 2;
	//level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
	//level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles, 1);
	wait( [[level.ex_fpstime]](2) );
}

sentrygunRepair(index)
{
	if(!level.sentryguns[index].inuse || !level.sentryguns[index].sabotaged) return;
	level.sentryguns[index].sabotaged = false;
	sentrygunActivate(index, level.sentryguns[index].activated);
}

sentrygunMove(index, player)
{
	if(!level.sentryguns[index].inuse || player.ex_sentrygun || isDefined(player.ex_sentrygun_moving_timer)) return;
	level.sentryguns[index].destroyed = true; // kills sentrygunThink(index)
	player.ex_sentrygun_moving_timer = level.sentryguns[index].timer;
	player.ex_sentrygun_moving_owner = level.sentryguns[index].owner;
	wait( [[level.ex_fpstime]](.5) );
	sentrygunRemove(index);
	player thread sentrygunPerk(0);
}

sentrygunDeactivate(index, forcebarrelup)
{
	if(!level.sentryguns[index].inuse || (!level.sentryguns[index].activated && !forcebarrelup)) return;
	level.sentryguns[index].activated = false;
	sentrygunCreateWaypoint(index);

	level.sentryguns[index].sentry_gun playsound("sentrygun_winddown");
	if(forcebarrelup) level.sentryguns[index].sentry_gun rotateTo((-75, level.sentryguns[index].sentry_gun.angles[1], 0), 2);
		else level.sentryguns[index].sentry_gun rotateTo((75, level.sentryguns[index].sentry_gun.angles[1], 0), 2);
	level.sentryguns[index].sentry_gun playsound("sentrygun_servo_long");
	wait( [[level.ex_fpstime]](2) );
}

sentrygunDeactivateTimer(index, timer)
{
	if(!level.sentryguns[index].inuse || (!level.sentryguns[index].activated || level.sentryguns[index].destroyed)) return;

	if(timer && level.sentryguns[index].timer > timer)
	{
		sentrygunDeactivate(index, false);
		wait( [[level.ex_fpstime]](timer) );
		if(!level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed && level.sentryguns[index].timer > 5)
			sentrygunActivate(index, false);
	}
	else level thread sentrygunDeactivate(index, false);
}

sentrygunSabotage(index)
{
	if(!level.sentryguns[index].inuse || level.sentryguns[index].sabotaged) return;
	level.sentryguns[index].sabotaged = true; // stops targeting and firing
	sentrygunMalfunction(index);
	if(level.sentryguns[index].sabotaged) sentrygunDeactivate(index, true);
}

sentrygunDestroy(index)
{
	if(!level.sentryguns[index].inuse || level.sentryguns[index].destroyed) return;
	level.sentryguns[index].destroyed = true; // kills sentrygunThink(index)
	if(isPlayer(level.sentryguns[index].owner)) level.sentryguns[index].owner playlocalsound("sentrygun_destroyed");
	sentrygunMalfunction(index);
	sentrygunRemove(index);
}

sentrygunSteal(index, player)
{
	sentrygunDeleteWaypoint(index);
	level.sentryguns[index].owner = player;
	if(isAlive(player) && (!level.ex_teamplay || player.pers["team"] != level.sentryguns[index].team))
		level.sentryguns[index].team = player.pers["team"];
	level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_OWNERSHIP");

	if(level.sentryguns[index].sabotaged) sentrygunRepair(index);
		else if(!level.sentryguns[index].activated) sentrygunActivate(index, false);
			else sentrygunCreateWaypoint(index);
}

sentrygunMalfunction(index)
{
	for(i = 0; i < 20; i++)
	{
		// quit malfunctioning if sentry has been removed or repaired
		if(!level.sentryguns[index].inuse || (!level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed)) break;

		random_time = randomFloatRange(.5, 1);
		// do not want two malfunctions to run at once when sentrygunSabotage(index) is called from checkProximitySentryGuns()
		if(level.sentryguns[index].activated)
		{
			random_pitch = randomIntRange(-20, 20);
			random_yaw = randomIntRange(0 - level.ex_sentrygun_reach, level.ex_sentrygun_reach);
			random_time = randomFloatRange(.1, 1);
			level.sentryguns[index].sentry_gun playsound("sentrygun_servo_short");
			level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (random_pitch, random_yaw, 0), random_time);
		}
		playfx(level.ex_effect["sentrygun_sparks"], level.sentryguns[index].sentry_gun.origin);
		wait( [[level.ex_fpstime]](random_time) );
	}
}

sentrygunThink(index)
{
	limit = sin(level.ex_sentrygun_reach) - 0.0001;
	target = level.sentryguns[index].sentry_gun;

	for(;;)
	{
		target_old = target;
		target = level.sentryguns[index].sentry_gun;

		// signaled to destroy by proximity checks, or when being moved
		if(level.sentryguns[index].destroyed) return;

		// remove sentry gun if it reached end of life
		if(level.sentryguns[index].timer <= 0)
		{
			if(isPlayer(level.sentryguns[index].owner)) level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_REMOVED");
			level thread sentrygunRemove(index);
			return;
		}

		// check if owner left the game or switched teams
		if(!level.sentryguns[index].abandoned)
		{
			// owner left
			if(!isPlayer(level.sentryguns[index].owner))
			{
				if((level.ex_sentrygun_remove & 1) == 1)
				{
					level thread sentrygunRemove(index);
					return;
				}
				level.sentryguns[index].abandoned = true;
				level.sentryguns[index].owner = level.sentryguns[index].sentry_gun;
				sentrygunDeactivate(index, false);
				sentrygunCreateWaypoint(index);
			}
			// owner switched teams
			else if((level.ex_sentrygun_remove & 2) != 2 && level.sentryguns[index].owner.pers["team"] != level.sentryguns[index].team)
			{
				level.sentryguns[index].abandoned = true;
				sentrygunDeleteWaypoint(index);
				level.sentryguns[index].owner = level.sentryguns[index].sentry_gun;
				sentrygunDeactivate(index, false);
				sentrygunCreateWaypoint(index);
			}
		}

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player))
			{
				// check for actions. removed for now: sentrygunCanSee(index, self)
				if(level.sentryguns[index].inuse && player meleebuttonpressed() && sentrygunInRadius(index, player)) player thread playerActionPanel(index);

				// check for targets if activated and not sabotaged
				if( (!level.ex_teamplay && player != level.sentryguns[index].owner) || (level.ex_teamplay && player.pers["team"] != level.sentryguns[index].team) )
				{
					if(level.sentryguns[index].activated && !level.sentryguns[index].sabotaged)
					{
						// check if old target is still alive and in range
						if(isPlayer(target_old) && isAlive(target_old) && sentrygunAngle(index, target_old) && sentrygunCanSee(index, target_old))
						{
							target = target_old;
							break;
						}
						// check other player
						else if(sentrygunAngle(index, player) && sentrygunCanSee(index, player))
						{
							if(!isPlayer(target)) target = player;
							if(closer(level.sentryguns[index].sentry_base.origin, player.origin, target.origin)) target = player;
						}
					}
				}
			}
		}

		// if still active and not sabotaged, show some action
		if(level.sentryguns[index].activated && !level.sentryguns[index].sabotaged)
		{
			if(isPlayer(target))
			{
				level.sentryguns[index].rotating = 0;
				va = vectorToAngles(target.origin + (0, 0, 40) - level.sentryguns[index].sentry_gun.origin);

				if(target == target_old && !level.sentryguns[index].targeting) level.sentryguns[index].sentry_gun rotateTo(va, .2);
					else thread sentrygunTargeting(index, va, .5);

				wait( [[level.ex_fpstime]](.05) );

				if(!level.sentryguns[index].targeting)
				{
					thread sentrygunFiring(index);

					// using weapon dummy1_mp so we don't have to precache another weapon. We will convert dummy1_mp to sentrygun_mp for MOD_PROJECTILE later on
					if(isPlayer(level.sentryguns[index].owner) && (!level.ex_teamplay || level.sentryguns[index].owner.pers["team"] == level.sentryguns[index].team))
						target thread [[level.callbackPlayerDamage]](level.sentryguns[index].sentry_gun, level.sentryguns[index].owner, level.ex_sentrygun_damage, 1, "MOD_PROJECTILE", "dummy1_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
					else
						target thread [[level.callbackPlayerDamage]](level.sentryguns[index].sentry_gun, level.sentryguns[index].sentry_gun, level.ex_sentrygun_damage, 1, "MOD_PROJECTILE", "dummy1_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
				}
			}
			else
			{
				if(level.sentryguns[index].rotating == 2) // start the rotation of the barrel if no target has been found yet (activation and angle reset)
				{
					level.sentryguns[index].rotating = 1;
					level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (0, level.ex_sentrygun_reach, 0), 1); // to left
					level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
				}
				else if(level.sentryguns[index].rotating == 0) // resetting (after shooting a target and no next target)
				{
					level.sentryguns[index].rotating = 1;
					while(level.sentryguns[index].firing) wait( [[level.ex_fpstime]](.05) );
					dot = vectorDot(anglesToRight(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
					if(dot < 0) level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (0, level.ex_sentrygun_reach, 0), .5); // to left
						else level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles - (0, level.ex_sentrygun_reach, 0), .5); // to right
					level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
					wait( [[level.ex_fpstime]](.3) );
				}
				else
				{
					dot = vectorDot(anglesToForward(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
					if(dot < 0) // when resetting the angle of the sentry more than 90 degrees
					{
						level.sentryguns[index].rotating = 0;
						level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles, .2);
					}
					else
					{
						dot = vectorDot(anglesToRight(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
						if(dot < 0 - limit) // to right (hitting left limit)
						{
							level.sentryguns[index].rotating = -1;
							level.sentryguns[index].sentry_gun playsound("sentrygun_servo_long");
							level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles - (0, level.ex_sentrygun_reach, 0), 2);
						}
						else if(dot > limit) // to left (hitting right limit)
						{
							level.sentryguns[index].rotating = 1;
							level.sentryguns[index].sentry_gun playsound("sentrygun_servo_long");
							level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (0, level.ex_sentrygun_reach, 0), 2);
						}
					}
				}
			}
		}

		level.sentryguns[index].timer--;
		wait( [[level.ex_fpstime]](.2) );
	}
}

sentrygunCanSee(index, player)
{
	cansee = false;
 	if(distance(player.origin, level.sentryguns[index].sentry_base.origin) <= level.ex_sentrygun_fireradius)
 	{
		cansee = (bullettrace(level.sentryguns[index].sentry_gun.origin + (0, 0, 10), player.origin + (0, 0, 10), false, level.sentryguns[index].sentry_trig)["fraction"] == 1);
		if(!cansee) cansee = (bullettrace(level.sentryguns[index].sentry_gun.origin + (0, 0, 10), player.origin + (0, 0, 40), false, level.sentryguns[index].sentry_trig)["fraction"] == 1);
		if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.sentryguns[index].sentry_gun.origin + (0, 0, 10), player.ex_eyemarker.origin, false, level.sentryguns[index].sentry_trig)["fraction"] == 1);
	}
	return(cansee);
}

sentrygunInRadius(index, player)
{
	if(distance(player.origin, level.sentryguns[index].sentry_gun.origin) < level.ex_sentrygun_actionradius) return(true);
	return(false);
}

sentrygunTargeting(index, vector, duration)
{
	if(level.sentryguns[index].targeting) return;
	level.sentryguns[index].targeting = true;
	if(randomInt(2)) level.sentryguns[index].sentry_gun playsound("sentrygun_servo_short");
		else level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
	level.sentryguns[index].sentry_gun rotateTo(vector, duration);
	wait( [[level.ex_fpstime]](duration) );
	level.sentryguns[index].targeting = false;
}

sentrygunFiring(index)
{
	if(level.sentryguns[index].firing) return;
	level.sentryguns[index].firing = true;
	level.sentryguns[index].sentry_gun playsound("sentrygun_fire");

	firingtime = 1.3;
	for(i = 0; i < firingtime; i += .1)
	{
		vfwd1 = [[level.ex_vectorscale]](anglesToForward(level.sentryguns[index].sentry_gun.angles), 36);
		vu = [[level.ex_vectorscale]](anglesToUp(level.sentryguns[index].sentry_gun.angles), 9);
		playfx(level.ex_effect["sentrygun_shot"], level.sentryguns[index].sentry_gun.origin + vfwd1 + vu, vfwd1);
		wait( [[level.ex_fpstime]](.1) );
	}

	level.sentryguns[index].firing = false;
}

sentrygunAngle(index, player)
{
	dir = vectorNormalize(player.origin + (0, 0, 40) - level.sentryguns[index].sentry_gun.origin);

	// check if player is within the limits of sentry movement
	dot = vectorDot(anglesToForward(level.sentryguns[index].org_angles), dir);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle > level.ex_sentrygun_reach) return(false);

	// check if player is in line of sight
	dot = vectorDot(anglesToForward(level.sentryguns[index].sentry_gun.angles), dir);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle > level.ex_sentrygun_viewangle) return(false);
	return(true);
}

sentrygunOwnership(index, player)
{
	if(!isPlayer(level.sentryguns[index].owner))
	{
		sentrygunDeleteWaypoint(index);
		level.sentryguns[index].owner = player;
		level.sentryguns[index].abandoned = false;
		sentrygunCreateWaypoint(index);

		if(!level.ex_teamplay || player.pers["team"] != level.sentryguns[index].team) level.sentryguns[index].team = player.pers["team"];
		level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_OWNERSHIP_ABANDONED");
	}
}

playerActionPanel(index)
{
	self endon("kill_thread");

	if(isDefined(self.ex_sentrygun_action) || !isAlive(self) || !self isOnGround()) return(false);

	// if this is a deployment call (index -1), first check basic requirements before setting ex_sentrygun_action flag
	candeploy = false;
	if(index == -1)
	{
		if(self.ex_moving || self [[level.ex_getstance]](false) == 2) return(false);
		candeploy = true;
	}

	self.ex_sentrygun_action = true;

	// check if they really mean to activate the panel
	progresstime = 0;
	while(self meleebuttonpressed() && progresstime < 0.5)
	{
		progresstime += level.ex_fps_frame;
		wait( [[level.ex_fpstime]](level.ex_fps_frame) );
	}

	// check if they still fit the requirements
	if(progresstime < 0.5 || !self isOnGround() || self.ex_moving || self [[level.ex_getstance]](false) == 2)
	{
		if(candeploy && self.ex_moving) self iprintln(&"SPECIALS_SENTRY_NO_MOVE");
		self.ex_sentrygun_action = undefined;
		return(false);
	}

	if(candeploy)
	{
		if(self tooCloseToEntities(true))
		{
			// keep on top! This will allow a second playerActionPanel call to perform actions on another sentry
			self.ex_sentrygun_action = undefined;
			// keep the deploy thread locked until melee button is released. This prevents scrolling messages
			while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			return(false);
		}
	}

	canactivate = false;
	canadjust = false;
	canrepair = false;
	canmove = false;
	candeactivate = false;
	cansabotage = false;
	candestroy = false;
	cansteal = false;

	panel = game["spc_sentry_actionpanel_owner"];
	if(!candeploy)
	{
		// check sentry gun ownership if not deploying
		sentrygunOwnership(index, self);

		// check owner actions
		if(self == level.sentryguns[index].owner && (!level.ex_teamplay || self.pers["team"] == level.sentryguns[index].team))
		{
			canactivate = ((level.ex_sentrygun_owneraction & 1) == 1 && !level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canadjust = ((level.ex_sentrygun_owneraction & 2) == 2 && level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canrepair = ((level.ex_sentrygun_owneraction & 4) == 4 && level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canmove = ((level.ex_sentrygun_owneraction & 8) == 8 && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed && !self.ex_sentrygun);
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.ex_sentrygun_action = undefined;
				return(false);
			}
		}
		// check teammates actions
		else if(level.ex_teamplay && self.pers["team"] == level.sentryguns[index].team)
		{
			canactivate = ((level.ex_sentrygun_teamaction & 1) == 1 && !level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canadjust = ((level.ex_sentrygun_teamaction & 2) == 2 && level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canrepair = ((level.ex_sentrygun_teamaction & 4) == 4 && level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canmove = ((level.ex_sentrygun_teamaction & 8) == 8 && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed && !self.ex_sentrygun);
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.ex_sentrygun_action = undefined;
				return(false);
			}
		}
		// check enemy actions
		else if(!level.ex_teamplay || self.pers["team"] != level.sentryguns[index].team)
		{
			panel = game["spc_sentry_actionpanel_enemy"];
			candeactivate = ((level.ex_sentrygun_enemyaction & 1) == 1 && level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			cansabotage = ((level.ex_sentrygun_enemyaction & 2) == 2 && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			candestroy = ((level.ex_sentrygun_enemyaction & 4) == 4 && !level.sentryguns[index].destroyed);
			cansteal = ((level.ex_sentrygun_enemyaction & 8) == 8 && !level.sentryguns[index].destroyed);
			if(!candeactivate && !cansabotage && !candestroy && !cansteal)
			{
				self.ex_sentrygun_action = undefined;
				return(false);
			}
		}
	}

	// show the action panel
	if(!isDefined(self.sentry_progress_bg))
	{
		self.sentry_progress_bg = newClientHudElem(self);
		self.sentry_progress_bg.x = 0;
		self.sentry_progress_bg.y = 160;
		self.sentry_progress_bg.alignX = "center";
		self.sentry_progress_bg.alignY = "middle";
		self.sentry_progress_bg.horzAlign = "center_safearea";
		self.sentry_progress_bg.vertAlign = "center_safearea";
		self.sentry_progress_bg.alpha = 1;
	}
	self.sentry_progress_bg setShader(panel, 256, 256);

	// show progress bar
	if(!isDefined(self.sentry_progress))
	{
		self.sentry_progress = newClientHudElem(self);
		self.sentry_progress.x = int(200 / (-2.0));
		self.sentry_progress.y = 161;
		self.sentry_progress.alignX = "left";
		self.sentry_progress.alignY = "middle";
		self.sentry_progress.horzAlign = "center_safearea";
		self.sentry_progress.vertAlign = "center_safearea";
		self.sentry_progress.color = (0,1,0);
	}
	self.sentry_progress setShader("white", 0, 11);
	self.sentry_progress scaleOverTime(level.ex_sentrygun_actiontime * 4, 200, 11);

	// show disabled indicator for action 1
	actiontimer_autostop = 0;
	if(!(candeploy || canactivate || candeactivate))
	{
		if(!isDefined(self.sentry_action1))
		{
			self.sentry_action1 = newClientHudElem(self);
			self.sentry_action1.x = -45;
			self.sentry_action1.y = 112;
			self.sentry_action1.alignX = "center";
			self.sentry_action1.alignY = "middle";
			self.sentry_action1.horzAlign = "center_safearea";
			self.sentry_action1.vertAlign = "center_safearea";
		}
		self.sentry_action1 setShader(game["spc_sentry_action_denied"], 45, 45);
	}
	else actiontimer_autostop = 1;
	// show disabled indicator for action 2
	if(!(canadjust || cansabotage))
	{
		if(!isDefined(self.sentry_action2))
		{
			self.sentry_action2 = newClientHudElem(self);
			self.sentry_action2.x = 3;
			self.sentry_action2.y = 112;
			self.sentry_action2.alignX = "center";
			self.sentry_action2.alignY = "middle";
			self.sentry_action2.horzAlign = "center_safearea";
			self.sentry_action2.vertAlign = "center_safearea";
		}
		self.sentry_action2 setShader(game["spc_sentry_action_denied"], 45, 45);
	}
	else actiontimer_autostop = 2;
	// show disabled indicator for action 3
	if(!(canrepair || candestroy))
	{
		if(!isDefined(self.sentry_action3))
		{
			self.sentry_action3 = newClientHudElem(self);
			self.sentry_action3.x = 51;
			self.sentry_action3.y = 112;
			self.sentry_action3.alignX = "center";
			self.sentry_action3.alignY = "middle";
			self.sentry_action3.horzAlign = "center_safearea";
			self.sentry_action3.vertAlign = "center_safearea";
		}
		self.sentry_action3 setShader(game["spc_sentry_action_denied"], 45, 45);
	}
	else actiontimer_autostop = 3;
	// show disabled indicator for action 4
	if(!(canmove || cansteal))
	{
		if(!isDefined(self.sentry_action4))
		{
			self.sentry_action4 = newClientHudElem(self);
			self.sentry_action4.x = 99;
			self.sentry_action4.y = 112;
			self.sentry_action4.alignX = "center";
			self.sentry_action4.alignY = "middle";
			self.sentry_action4.horzAlign = "center_safearea";
			self.sentry_action4.vertAlign = "center_safearea";
		}
		self.sentry_action4 setShader(game["spc_sentry_action_denied"], 45, 45);
	}
	else actiontimer_autostop = 4;

	// now see for how long the melee key is pressed
	granted = false;
	progresstime = 0;
	while(self meleebuttonpressed() && (progresstime < level.ex_sentrygun_actiontime * actiontimer_autostop))
	{
		if(!self isOnGround() || self.ex_moving || self [[level.ex_getstance]](false) == 2) break;
		if(!candeploy && !level.sentryguns[index].inuse) break;
		if(!candeploy && !sentrygunCanSee(index, self) && !sentrygunInRadius(index, self)) break;

		progresstime += level.ex_fps_frame;
		wait( [[level.ex_fpstime]](level.ex_fps_frame) );
	}

	if(isDefined(self.sentry_action1)) self.sentry_action1 destroy();
	if(isDefined(self.sentry_action2)) self.sentry_action2 destroy();
	if(isDefined(self.sentry_action3)) self.sentry_action3 destroy();
	if(isDefined(self.sentry_action4)) self.sentry_action4 destroy();
	if(isDefined(self.sentry_progress)) self.sentry_progress destroy();
	if(isDefined(self.sentry_progress_bg)) self.sentry_progress_bg destroy();

	if(candeploy && progresstime >= level.ex_sentrygun_actiontime) granted = true;
	if(!candeploy && level.sentryguns[index].inuse)
	{
		// 4th action (8 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime * 4)
		{
			if(canmove && !self.ex_sentrygun)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_MOVED_BY", [[level.ex_pname]](self));
				level thread sentrygunMove(index, self);
			}
			else if(cansteal)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_STOLEN_BY", [[level.ex_pname]](self));
				level thread sentrygunSteal(index, self);
			}
		}

		// 3rd action (6 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime * 3)
		{
			if(canrepair)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_REPAIRED_BY", [[level.ex_pname]](self));
				level thread sentrygunRepair(index);
			}
			else if(candestroy)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_DESTROYED_BY", [[level.ex_pname]](self));
				level thread sentrygunDestroy(index);
			}
		}

		// 2nd action (4 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime * 2)
		{
			if(canadjust)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_ADJUSTED_BY", [[level.ex_pname]](self));
				level thread sentrygunAdjust(index, self);
			}
			else if(cansabotage)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_SABOTAGED_BY", [[level.ex_pname]](self));
				level thread sentrygunSabotage(index);
			}
		}

		// 1st action (2 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime)
		{
			if(canactivate)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_ACTIVATED_BY", [[level.ex_pname]](self));
				level thread sentrygunActivate(index, false);
			}
			else if(candeactivate)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_DEACTIVATED_BY", [[level.ex_pname]](self));
				level thread sentrygunDeactivate(index, false);
			}
		}
	}

	wait( [[level.ex_fpstime]](.2) );
	self.ex_sentrygun_action = undefined;
	if(!granted) return(false);
		else if(!candeploy) while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
	return(true);
}

sentrygunCreateWaypoint(index)
{
	if(level.ex_sentrygun_waypoints != 1 || !isPlayer(level.sentryguns[index].owner)) levelCreateWaypoint(index);
		else level.sentryguns[index].owner playerCreateWaypoint(index);
}

sentrygunDeleteWaypoint(index)
{
	if(level.ex_sentrygun_waypoints != 1 || !isPlayer(level.sentryguns[index].owner)) levelDeleteWaypoint(index);
		else level.sentryguns[index].owner playerDeleteWaypoint(index);
}

levelCreateWaypoint(index)
{
	if(!level.ex_sentrygun_waypoints) return;
	if(!isDefined(level.ex_sentry_waypoints)) level.ex_sentry_waypoints = [];

	level levelDeleteWaypoint(index);

	if(level.ex_sentrygun_waypoints == 3 || !isPlayer(level.sentryguns[index].owner))
	{
		if(level.sentryguns[index].abandoned) shader = game["waypoint_abandoned"];
		else if(level.sentryguns[index].activated)
		{
			if(game[level.sentryguns[index].team] == "german") shader = game["waypoint_activated_axis"];
				else shader = game["waypoint_activated_allies"];
		}
		else
		{
			if(game[level.sentryguns[index].team] == "german") shader = game["waypoint_deactivated_axis"];
				else shader = game["waypoint_deactivated_allies"];
		}

		waypoint = newHudElem();
	}
	else
	{
		if(level.sentryguns[index].abandoned) shader = game["waypoint_abandoned"];
			else if(level.sentryguns[index].activated) shader = game["waypoint_activated"];
				else shader = game["waypoint_deactivated"];

		waypoint = newTeamHudElem(level.sentryguns[index].team);
	}

	waypoint.id = index;
	waypoint.x = level.sentryguns[index].org_origin[0];
	waypoint.y = level.sentryguns[index].org_origin[1];
	waypoint.z = level.sentryguns[index].org_origin[2] + 60;
	waypoint.alpha = .6;
	waypoint.archived = true;
	waypoint setShader(shader, 7, 7);
	waypoint setwaypoint(true);

	level.ex_sentry_waypoints[level.ex_sentry_waypoints.size] = waypoint;
}

levelDeleteWaypoint(index)
{
	if(!level.ex_sentrygun_waypoints) return;
	if(!isDefined(level.ex_sentry_waypoints)) return;

	remove_element = undefined;
	for(i = 0; i < level.ex_sentry_waypoints.size; i++)
	{
		if(level.ex_sentry_waypoints[i].id != index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		last_element = level.ex_sentry_waypoints.size - 1;
		level.ex_sentry_waypoints[remove_element] destroy();
		if(remove_element != last_element) level.ex_sentry_waypoints[remove_element] = level.ex_sentry_waypoints[last_element];
		level.ex_sentry_waypoints[last_element] = undefined;
	}
}

playerCreateWaypoint(index)
{
	if(!level.ex_sentrygun_waypoints) return;
	if(!isDefined(self.ex_sentry_waypoints)) self.ex_sentry_waypoints = [];

	self playerDeleteWaypoint(index);

	if(level.sentryguns[index].abandoned) shader = game["waypoint_abandoned"];
		if(level.sentryguns[index].activated) shader = game["waypoint_activated"];
			else shader = game["waypoint_deactivated"];

	waypoint = newClientHudElem(self);
	waypoint.id = index;
	waypoint.x = level.sentryguns[index].org_origin[0];
	waypoint.y = level.sentryguns[index].org_origin[1];
	waypoint.z = level.sentryguns[index].org_origin[2] + 60;
	waypoint.alpha = .6;
	waypoint.archived = true;
	waypoint setShader(shader, 7, 7);
	waypoint setwaypoint(true);

	self.ex_sentry_waypoints[self.ex_sentry_waypoints.size] = waypoint;
}

playerDeleteWaypoint(index)
{
	if(!level.ex_sentrygun_waypoints) return;
	if(!isDefined(self.ex_sentry_waypoints)) return;

	remove_element = undefined;
	for(i = 0; i < self.ex_sentry_waypoints.size; i++)
	{
		if(self.ex_sentry_waypoints[i].id != index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		last_element = self.ex_sentry_waypoints.size - 1;
		self.ex_sentry_waypoints[remove_element] destroy();
		if(remove_element != last_element) self.ex_sentry_waypoints[remove_element] = self.ex_sentry_waypoints[last_element];
		self.ex_sentry_waypoints[last_element] = undefined;
	}
}

checkProximitySentryGuns(origin, launcher, cpx)
{
	if(level.ex_sentrygun && level.ex_sentrygun_cpx)
	{
		for(index = 0; index < level.sentryguns.size; index++)
		{
			if(level.sentryguns[index].inuse && !level.sentryguns[index].destroyed)
			{
				//dist = int( distance(origin, level.sentryguns[index].org_origin) );
				//dist = int( distance(origin, level.sentryguns[index].sentry_base.origin) );
				//dist = int( distance(origin, level.sentryguns[index].sentry_trig.origin) );
				dist = int( distance(origin, level.sentryguns[index].sentry_gun.origin) );
				if(isDefined(level.sentryguns[index].owner) && (dist <= cpx))
				{
					level.sentryguns[index].nades++;
					if(level.sentryguns[index].nades >= level.ex_sentrygun_cpx_nades)
					{
						if(level.ex_teamplay && isDefined(launcher) && isPlayer(launcher) && launcher.pers["team"] == level.sentryguns[index].team)
						{

							if((level.ex_sentrygun_cpx & 4) == 4) level thread sentrygunDestroy(index);
							else if((level.ex_sentrygun_cpx & 2) == 2) level thread sentrygunSabotage(index);
							else if((level.ex_sentrygun_cpx & 1) == 1) level thread sentrygunDeactivateTimer(index, level.ex_sentrygun_cpx_timer);
						}
						else
						{
							if((level.ex_sentrygun_cpx & 32) == 32) level thread sentrygunDestroy(index);
							else if((level.ex_sentrygun_cpx & 16) == 16) level thread sentrygunSabotage(index);
							else if((level.ex_sentrygun_cpx & 8) == 8) level thread sentrygunDeactivateTimer(index, level.ex_sentrygun_cpx_timer);
						}
					}
				}
			}
		}
	}
}

tooCloseToEntities(report)
{
	spawnpointname = undefined;

	if(level.ex_sentrygun_dist_spawn)
	{
		switch(level.ex_currentgt)
		{
			case "sd":
			case "esd": return(false);
			case "ctf":
			case "rbctf":
			case "ctfb":
				if(self.pers["team"] == "axis") spawnpointname = "mp_ctf_spawn_allied";
					else if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_axis";
				break;
			case "dm":
			case "hm":
			case "lms":
			case "ihtf": spawnpointname = "mp_dm_spawn"; break;
			case "tdm":
			case "cnq":
			case "rbcnq":
			case "hq":
			case "htf": spawnpointname = "mp_tdm_spawn"; break;
		}

		if(isDefined(spawnpointname))
		{
			spawnpoints = getentarray(spawnpointname, "classname");
			for(i = 0; i < spawnpoints.size; i++)
			{
				spawnpoint = spawnpoints[i];
				if(isDefined(self) && distance(self.origin, spawnpoint.origin) < level.ex_sentrygun_dist_spawn)
				{
					if(report) self iprintln(&"SPECIALS_TOOCLOSE_SPAWN");
					return(true);
				}
			}
		}
	}

	if(level.ex_sentrygun_dist_sentry)
	{
		for(i = 0; i < level.sentryguns.size; i++)
		{
			if(level.sentryguns[i].inuse && distance(level.sentryguns[i].org_origin, self.origin) < level.ex_sentrygun_dist_sentry)
			{
				if(report) self iprintln(&"SPECIALS_TOOCLOSE_SENTRY");
				return(true);
			}
		}
	}

	if(level.ex_sentrygun_dist_turret)
	{
		turrets = getentarray("misc_turret", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(self) && isDefined(turrets[i]) && distance(turrets[i].origin, self.origin) < level.ex_sentrygun_dist_turret)
			{
				if(report) self iprintln(&"SPECIALS_TOOCLOSE_TURRET");
				return(true);
			}
		}

		turrets = getentarray("misc_mg42", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(self) && isDefined(turrets[i]) && distance(turrets[i].origin, self.origin) < level.ex_sentrygun_dist_turret)
			{
				if(report) self iprintln(&"SPECIALS_TOOCLOSE_TURRET");
				return(true);
			}
		}
	}

	if(level.ex_sentrygun_dist_flag)
	{
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
		{
			if(self.pers["team"] == "axis") flag_name = "axis_flag";
				else if(self.pers["team"] == "allies") flag_name = "allied_flag";
					else return(true);

			flags = getentarray(flag_name, "targetname");
			for(i = 0; i < flags.size; i++)
			{
				flag = flags[i];
				if(isDefined(self) && distance(self.origin, flag.origin) < level.ex_sentrygun_dist_flag)
				{
					if(report) self iprintln(&"SPECIALS_TOOCLOSE_FLAG");
					return(true);
				}
			}
		}
	}

	return(false);
}

sentryDebug(index)
{
	dot1 = vectorDot(anglesToForward(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
	dot2 = vectorDot(anglesToRight(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
	slimit = sin(level.ex_sentrygun_reach);
	climit = cos(level.ex_sentrygun_reach);

	logprint("dot1 = " + dot1 + ", angles = " + level.sentryguns[index].sentry_gun.angles + "\n");
	logprint("dot2 = " + dot2 + ", slimit = " + slimit + ", climit = " + climit + "\n");
}

sentryDeveloper(index)
{
	while(level.sentryguns[index].activated)
	{
		angle = (level.sentryguns[index].org_angles[0], level.sentryguns[index].org_angles[1] + level.ex_sentrygun_reach, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (0, .8, .8), false);

		angle = (level.sentryguns[index].org_angles[0], level.sentryguns[index].org_angles[1] - level.ex_sentrygun_reach, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (0, .8, .8), false);

		angle = (level.sentryguns[index].sentry_gun.angles[0], level.sentryguns[index].sentry_gun.angles[1] + level.ex_sentrygun_viewangle, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (1, 0, 0), false);

		angle = (level.sentryguns[index].sentry_gun.angles[0], level.sentryguns[index].sentry_gun.angles[1] - level.ex_sentrygun_viewangle, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (1, 0, 0), false);

		wait( [[level.ex_fpstime]](.05) );
	}
}
