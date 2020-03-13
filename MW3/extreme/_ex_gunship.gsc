
main()
{
	level.ex_gunship_player = undefined;
	level.ex_gunship_splayer = undefined;

	x = game["playArea_CentreX"];
	y = game["playArea_CentreY"];
	z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;

	level.ex_gunship_rig = spawn("script_model", (x,y,z));
	level.ex_gunship_rig setmodel("xmodel/tag_origin");
	level.ex_gunship_rig.angles = (0,0,0);
	level.ex_gunship_radius = gunshipGetRadius(level.ex_gunship_rig.origin, level.ex_gunship_radius_tweak);
	rotationspeed = int((level.ex_gunship_rotationspeed / 2000) * level.ex_gunship_radius);
	if(rotationspeed >= level.ex_gunship_rotationspeed) level.ex_gunship_rotationspeed = rotationspeed;

	if(level.ex_gunship)
	{
		level.ex_gunship_model = spawn("script_model", (0,0,0));
		if(level.ex_gunship_visible <= 1) level.ex_gunship_model hide();
		level.ex_gunship_model setmodel("xmodel/vehicle_condor");
		level.ex_gunship_model linkTo(level.ex_gunship_rig, "tag_origin", (level.ex_gunship_radius,0,0), (0,90,-20));
		if(level.ex_gunship_ambientsound == 2) level.ex_gunship_model playloopsound("gunship_ambient");
	
		}

	if(level.ex_gunship_special)
	{
		level.ex_gunship_smodel = spawn("script_model", (0,0,0));
		if(level.ex_gunship_visible <= 1) level.ex_gunship_smodel hide();
		level.ex_gunship_smodel setmodel("xmodel/vehicle_condor");
		level.ex_gunship_smodel linkTo(level.ex_gunship_rig, "tag_origin", (level.ex_gunship_radius * -1,0,0), (0,-90,-20));
		if(level.ex_gunship_ambientsound == 2) level.ex_gunship_smodel playloopsound("gunship_ambient");
	}

	rotations = 0;
	while(!level.ex_gameover)
	{
		level.ex_gunship_rig rotateyaw(360, level.ex_gunship_rotationspeed);
		wait( [[level.ex_fpstime]](level.ex_gunship_rotationspeed) );

		if(level.ex_gunship)
		{
			if(isDefined(level.ex_gunship_player) && (!isPlayer(level.ex_gunship_player) || level.ex_gunship_player.origin[2]+50 != level.ex_gunship_model.origin[2]))
			{
				if(level.ex_gunship_visible == 1) level.ex_gunship_model hide();
				if(level.ex_gunship_ambientsound == 1) level.ex_gunship_model stoploopsound();
				level.ex_gunship_player = undefined;
			}
		}

		if(level.ex_gunship_special)
		{
			if(isDefined(level.ex_gunship_splayer) && (!isPlayer(level.ex_gunship_splayer) || level.ex_gunship_splayer.origin[2]+50 != level.ex_gunship_smodel.origin[2]))
			{
				if(level.ex_gunship_visible == 1) level.ex_gunship_smodel hide();
				if(level.ex_gunship_ambientsound == 1) level.ex_gunship_smodel stoploopsound();
				level.ex_gunship_splayer = undefined;
			}
		}

		rotations++;
		if(rotations == level.ex_gunship_advertise)
		{
			rotations = 0;
			level thread gunshipAdvertise();
		}
	}

	if(level.ex_gunship)
	{
		level.ex_gunship_model hide();
		if(level.ex_gunship_ambientsound) level.ex_gunship_model stoploopsound();
	}

	if(level.ex_gunship_special)
	{
		level.ex_gunship_smodel hide();
		if(level.ex_gunship_ambientsound) level.ex_gunship_smodel stoploopsound();
	}
}

gunshipGetRadius(center, correction)
{
	radius = (((game["playArea_Width"] + game["playArea_Length"]) / 2) / 2) + 500;

	deviations = 0;
	deviations_allowed = 3;

	for(i = 0; i < 360; i += 10)
	{
		pos = gunshipForwardLimit(center, i, radius, true);

		/* Plot radius detection
		if(!isDefined(level.ex_xxx)) level.ex_xxx = [];
		index = level.ex_xxx.size;
		level.ex_xxx[index] = spawn("script_model", pos);
		level.ex_xxx[index] setmodel("xmodel/health_large");
		*/

		radius_temp = distance(center, pos);
		if(radius_temp < radius)
		{
			if( (radius_temp < (radius / 2)) && (deviations < deviations_allowed) ) deviations++;
				else radius = radius_temp;
		}
	}

	radius = radius - correction;

	/* Plot final orbit
	for(i = 0; i < 360; i += 10)
	{
		pos = gunshipForwardLimit(center, i, radius, true);

		if(!isDefined(level.ex_xxx)) level.ex_xxx = [];
		index = level.ex_xxx.size;
		level.ex_xxx[index] = spawn("script_model", pos);
		level.ex_xxx[index] setmodel("xmodel/health_medium");
	}
	*/

	return radius;
}

gunshipForwardLimit(pos, angle, dist, oneshot)
{
	forwardvector = anglestoforward( (0, angle, 0) );
	while(true)
	{
		forwardpos = pos + [[level.ex_vectorscale]](forwardvector, dist);
		trace = bulletTrace(pos, forwardpos, true, self);
		if(trace["fraction"] != 1)
		{
			endpos = trace["position"];
			return endpos;
		}
		else
		{
			pos = forwardpos;
			if(oneshot) return forwardpos;
		}
	}
}

gunshipAdvertise()
{
	switch(level.ex_gunship)
	{
		case 1:
			iprintln(&"GUNSHIP_ADVERTISE_MODE1");
			iprintln(&"GUNSHIP_ADVERTISE_MODE1_HOW", level.ex_gunship_killspree);
			break;
		case 2:
			iprintln(&"GUNSHIP_ADVERTISE_MODE2");
			switch(level.ex_rank_wmdtype)
			{
				case 1:
					iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", 7);
					break;
				case 2:
					iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_rank_special);
					break;
				case 3:
					iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_rank_allow_rank);
					break;
			}
			break;
		case 3:
			iprintln(&"GUNSHIP_ADVERTISE_MODE3");
			iprintln(&"GUNSHIP_ADVERTISE_MODE3_HOW", level.ex_gunship_obitladder, gunshipGetLadderStr());
			break;
		case 4:
			if(level.ex_gunship_special && game["specials_stock8"] > 0)
			{
				iprintln(&"GUNSHIP_ADVERTISE_MODE4");
				iprintln(&"GUNSHIP_ADVERTISE_MODE4_HOW");
			}
	}

	wait( [[level.ex_fpstime]](3) );

	random_hint = randomInt(3);
	switch(random_hint)
	{
		case 0:
			iprintln(&"GUNSHIP_ADVERTISE_HINT1");
			break;
		case 1:
			iprintln(&"GUNSHIP_ADVERTISE_HINT2");
			break;
		case 2:
			if(level.ex_gunship_eject)
			{
				if((level.ex_gunship_eject & 7) == 7) iprintln(&"GUNSHIP_ADVERTISE_HINT9");
				else if((level.ex_gunship_eject & 6) == 6) iprintln(&"GUNSHIP_ADVERTISE_HINT8");
				else if((level.ex_gunship_eject & 5) == 5) iprintln(&"GUNSHIP_ADVERTISE_HINT7");
				else if((level.ex_gunship_eject & 4) == 4) iprintln(&"GUNSHIP_ADVERTISE_HINT6");
				else if((level.ex_gunship_eject & 3) == 3) iprintln(&"GUNSHIP_ADVERTISE_HINT5");
				else if((level.ex_gunship_eject & 2) == 2) iprintln(&"GUNSHIP_ADVERTISE_HINT4");
				else if((level.ex_gunship_eject & 1) == 1) iprintln(&"GUNSHIP_ADVERTISE_HINT3");
			}
			break;
	}

	wait( [[level.ex_fpstime]](3) );

	if(level.ex_gunship_nuke && level.ex_gunship_nuke_unlock) iprintln(&"GUNSHIP_ADVERTISE_NUKE_UNLOCK", level.ex_gunship_nuke_unlock);
}

gunshipGetLadderStr()
{
	switch(level.ex_gunship_obitladder)
	{
		case 2: return &"GUNSHIP_ADVERTISE_MODE3_DOUBLE";
		case 3: return &"GUNSHIP_ADVERTISE_MODE3_TRIPLE";
		case 4: return &"GUNSHIP_ADVERTISE_MODE3_MULTI";
		case 5: return &"GUNSHIP_ADVERTISE_MODE3_MEGA";
		case 6: return &"GUNSHIP_ADVERTISE_MODE3_ULTRA";
		case 7: return &"GUNSHIP_ADVERTISE_MODE3_MONSTER";
		case 8: return &"GUNSHIP_ADVERTISE_MODE3_LUDICROUS";
		case 9: return &"GUNSHIP_ADVERTISE_MODE3_TOPGUN";
	}
}

gunshipPerkDelayed(delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );
	self thread gunshipPerk(0);
}

// GUNSHIP ASSIGNMENT PROCEDURES

gunshipAttachPlayer()
{
	self endon("kill_thread");

	if(isDefined(level.ex_gunship_player)) return;
	level.ex_gunship_player = self;
	self.pers["gunship"] = true;

	self extreme\_ex_utils::forceto("stand");
	self.gunship_org_origin = self.origin;
	self.gunship_org_angles = self.angles;

	self.ex_stopwepmon = true;
	wait( [[level.ex_fpstime]](0.1) );
	self notify("weaponsave");
	self waittill("weaponsaved");

	if(level.ex_gunship_airraid) level.ex_gunship_rig playsound("air_raid");
	if(level.ex_gunship_visible == 1) level.ex_gunship_model show();
	if(level.ex_gunship_ambientsound == 1) level.ex_gunship_model playloopsound("gunship_ambient");

	self.ex_gunship_ejected = false;
	if(!level.ex_rank_statusicons) self.statusicon = "gunship_statusicon";
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	if(level.ex_gunship_health) self.health = 100;
	self.ex_gunship_kills = 0;
	self hide();
	self linkTo(level.ex_gunship_rig, "tag_origin", (level.ex_gunship_radius,0,-50), (0,90,-20)); // angles = (pitch, yaw, roll);

	level thread gunshipTimer(self);
	if(level.ex_gunship_inform) self thread gunshipInform(true);
	if(level.ex_gunship_clock) self thread gunshipClock();
	self thread gunshipWeapon();
}

gunshipTimer(player)
{
	player endon("gunship_over");

	gunship_time = level.ex_gunship_time;
	while(gunship_time > 0 && !level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](1) );
		gunship_time--;

		// keep an eye on the player
		if(!isPlayer(player))
		{
			level thread gunshipDetachPlayerLevel(player, true);
			return;
		}
	}

	if(isPlayer(player))
	{
		// player is still there, and has a valid ticket
		if(isDefined(level.ex_gunship_player))
		{
			if(level.ex_gunship_player == player)
			{
				if(!level.ex_gameover && (level.ex_gunship_eject & 1) == 1) player thread gunshipDetachPlayer(true);
					else player thread gunshipDetachPlayer();
			}
		}
		// player is still there, but seems to be in gunship without a valid ticket
		else if(player.origin[2]+50 == level.ex_gunship_model.origin[2])
		{
			if(!level.ex_gameover) player thread gunshipDetachPlayer(false, true);
				else level thread gunshipDetachPlayerLevel(player, true);
		}
	}
}

gunshipDetachPlayer(eject, skipcheck)
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isDefined(level.ex_gunship_player) || !isPlayer(self) || level.ex_gunship_player != self)) return;

	if(!isDefined(eject)) eject = false;
	if(self.ex_gunship_ejected) return;
	if(eject) self.ex_gunship_ejected = true;

	self notify("gunship_over");
	if(isDefined(self.ex_gunship_weapons)) self.ex_gunship_weapons = [];
	if(isDefined(self.gunship_overlay)) self.gunship_overlay destroy();
	if(isDefined(self.gunship_grain)) self.gunship_grain destroy();
	if(isDefined(self.gunship_clock)) self.gunship_clock destroy();
	if(level.ex_gunship_inform) self thread gunshipInform(false);

	self show();
	self unlink();
	self.ex_invulnerable = false;
	if(!level.ex_rank_statusicons) self.statusicon = "";
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;

	self setPlayerAngles(self.gunship_org_angles);
	if(eject) thread gunshipPlayerEject();
		else self setOrigin(self.gunship_org_origin);

	self extreme\_ex_weapons::restoreWeapons(level.ex_gunship_refill);
	self.ex_stopwepmon = false;

	if(level.ex_gunship_visible == 1) level.ex_gunship_model hide();
	if(level.ex_gunship_ambientsound == 1) level.ex_gunship_model stoploopsound();
	level.ex_gunship_player = undefined;
}

gunshipDetachPlayerLevel(playerent, skipcheck)
{
	level endon("ex_gameover");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isDefined(level.ex_gunship_player) || !isPlayer(playerent) || level.ex_gunship_player != playerent)) return;

	if(isPlayer(playerent)) playerent notify("gunship_over");
	if(isPlayer(playerent) && isDefined(playerent.ex_gunship_weapons)) playerent.ex_gunship_weapons = [];
	if(isPlayer(playerent) && isDefined(playerent.gunship_overlay)) playerent.gunship_overlay destroy();
	if(isPlayer(playerent) && isDefined(playerent.gunship_grain)) playerent.gunship_grain destroy();
	if(isPlayer(playerent) && isDefined(playerent.gunship_clock)) playerent.gunship_clock destroy();
	if(isPlayer(playerent) && level.ex_gunship_inform) playerent thread gunshipInform(false);

	if(isPlayer(playerent)) playerent show();
	if(isPlayer(playerent)) playerent unlink();
	if(isPlayer(playerent)) playerent.ex_invulnerable = false;
	if(!level.ex_rank_statusicons && isPlayer(playerent)) self.statusicon = "";
	if(level.ex_gunship == 1 && isPlayer(playerent)) playerent.pers["conseckill"] = 0;
	if(level.ex_gunship == 3 && isPlayer(playerent)) playerent.pers["conskillnumb"] = 0;

	if(level.ex_gunship_visible == 1) level.ex_gunship_model hide();
	if(level.ex_gunship_ambientsound == 1) level.ex_gunship_model stoploopsound();
	level.ex_gunship_player = undefined;
}

gunshipPlayerEject()
{
	level endon("ex_gameover");
	self endon("disconnect");

	self.ex_isparachuting = true;
	if(level.ex_gunship_eject_protect) self.ex_invulnerable = true;

	startpoint = self.origin;
	if(!level.ex_gunship_eject_dropzone)
	{
		spawnpoint = getNearestSpawnpoint(self.origin);
		endpoint = spawnpoint.origin + (0, 0, 30);
	}
	else endpoint = self.gunship_org_origin + (0, 0, 30);

	chute = level createParachute(startpoint, self.angles, false);
	self linkto(level.chutes[chute].anchor);
	level thread dropOnParachute(chute, startpoint, endpoint);

	while(isPlayer(self) && isAlive(self) && level.chutes[chute].anchor.origin[2] > endpoint[2])
	{
		if(level.ex_gunship_eject_protect == 2 && isAlive(self) && self.sessionstate == "playing" &&
			(self attackButtonPressed() && self getCurrentWeapon() != "none" )) self.ex_invulnerable = false;

		self setClientCvar("cl_stance", "0");
		wait( [[level.ex_fpstime]](0.2) );
	}

	if(isPlayer(self))
	{
		self unlink();
		if(isAlive(self))
		{
			self playSound("para_land");
			earthquake(0.4, 1.2, self.origin, 70);
		}
		self.ex_invulnerable = false;
		self.ex_isparachuting = undefined;
	}
}

gunshipWeapon()
{
	self endon("kill_thread");
	self endon("gunship_over");

	wait( [[level.ex_fpstime]](0.2) );
	self takeAllWeapons();

	self.ex_gunship_weapons = [];
	for(i = 0; i < level.ex_gunship_weapons.size; i++)
	{
		self.ex_gunship_weapons[i] = spawnstruct();

		if(level.ex_gunship_weapons[i].clip >= level.ex_gunship_weapons[i].ammo)
		{
			weapon_clip = level.ex_gunship_weapons[i].ammo;
			weapon_reserve = 0;
		}
		else
		{
			weapon_clip = level.ex_gunship_weapons[i].clip;
			weapon_reserve = level.ex_gunship_weapons[i].ammo - level.ex_gunship_weapons[i].clip;
		}

		self.ex_gunship_weapons[i].clip = weapon_clip;
		self.ex_gunship_weapons[i].reserve = weapon_reserve;
		self.ex_gunship_weapons[i].enabled = level.ex_gunship_weapons[i].enabled;
		self.ex_gunship_weapons[i].locked = level.ex_gunship_weapons[i].locked;
	}

	current = -1;
	stop_switch = false;
	force_eject = false;
	manual_eject = false;
	weapon_switch = getTime();

	for(;;)
	{
		if(current != -1) while(!self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );

		manual_eject = ((level.ex_gunship_eject & 8) == 8 && self useButtonPressed() && self meleeButtonPressed());

		if(force_eject || manual_eject)
		{
			if(force_eject) self iprintlnbold(&"GUNSHIP_FORCED_EJECT");
			thread gunshipDetachPlayer(true);
			break;
		}

		if(!stop_switch)
		{
			if(current != -1)
			{
				self.ex_gunship_weapons[current].clip = self getWeaponSlotClipAmmo("primary");
				self.ex_gunship_weapons[current].reserve = self getWeaponSlotAmmo("primary");
				if(self.ex_gunship_weapons[current].clip == 0)
				{
					if(self.ex_gunship_weapons[current].reserve > 0)
					{
						self.ex_gunship_weapons[current].clip = 1;
						self.ex_gunship_weapons[current].reserve--;
					}
					else self.ex_gunship_weapons[current].enabled = false;
				}
			}

			check_switch = false;
			newcurrent = current;
			while(1)
			{
				newcurrent++;
				if(newcurrent == current)
				{
					if(!self.ex_gunship_weapons[newcurrent].enabled || self.ex_gunship_weapons[newcurrent].locked) newcurrent = -1;
					break;
				}
				else if(newcurrent < self.ex_gunship_weapons.size)
				{
					if(self.ex_gunship_weapons[newcurrent].enabled && !self.ex_gunship_weapons[newcurrent].locked) break;
				}
				else
				{
					check_switch = true;
					newcurrent = -1;
				}
			}

			skip_switch = false;
			if(newcurrent == -1)
			{
				skip_switch = true;
				if((level.ex_gunship_eject & 4) == 4) force_eject = true;
			}
			else if(newcurrent == current) skip_switch = true;

			current = newcurrent;

			if(!skip_switch)
			{
				if(check_switch)
				{
					weapon_switch_prev = weapon_switch;
					weapon_switch = getTime();
					weapon_cycle = (weapon_switch - weapon_switch_prev) / 1000;
					if(weapon_cycle < level.ex_gunship_weapons.size * 1)
					{
						self takeAllWeapons();
						if(isDefined(self.gunship_overlay)) self.gunship_overlay.alpha = 0;
						self iprintlnbold(&"GUNSHIP_SWITCH_TOO_FAST");
						wait( [[level.ex_fpstime]](3) );
						if(isDefined(self.gunship_overlay)) self.gunship_overlay.alpha = 1;
					}
				}

				self setWeaponSlotWeapon("primary", level.ex_gunship_weapons[current].weapon);
				self setWeaponClipAmmo(level.ex_gunship_weapons[current].weapon, self.ex_gunship_weapons[current].clip);
				self setWeaponSlotAmmo("primary", self.ex_gunship_weapons[current].reserve);
				self switchToWeapon(level.ex_gunship_weapons[current].weapon);
				thread gunshipWeaponOverlay(level.ex_gunship_weapons[current].overlay);

				if(level.ex_gunship_weapons.size == 1) stop_switch = true;
			}
		}

		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
	}
}

gunshipWeaponUnlock(attacker)
{
	attacker endon("disconnect");

	if(isPlayer(attacker) && ( (isDefined(level.ex_gunship_player) && level.ex_gunship_player == attacker) || (isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == attacker) ))
	{
		attacker.ex_gunship_kills++;

		// wait a brief moment to let other arcade shaders display first
		wait( [[level.ex_fpstime]](1) );
		if(!isPlayer(attacker)) return;

		for(i = 0; i < attacker.ex_gunship_weapons.size; i++)
		{
			switch(level.ex_gunship_weapons[i].weapon)
			{
				case "gunship_40mm_mp":
					if(level.ex_gunship_40mm_unlock && attacker.ex_gunship_kills >= level.ex_gunship_40mm_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(level.ex_arcade_shaders) attacker thread extreme\_ex_arcade::showArcadeShader("x2_40mmunlock", level.ex_arcade_shaders_perk);
				                   else attacker iprintlnbold(&"GUNSHIP_40MM_UNLOCK");

						}
					}
					break;
				case "gunship_105mm_mp":
					if(level.ex_gunship_105mm_unlock && attacker.ex_gunship_kills >= level.ex_gunship_105mm_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(level.ex_arcade_shaders) attacker thread extreme\_ex_arcade::showArcadeShader("x2_105mmunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_105MM_UNLOCK");
						}
					}
					break;
				case "gunship_nuke_mp":
					if(level.ex_gunship_nuke_unlock && attacker.ex_gunship_kills >= level.ex_gunship_nuke_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(level.ex_arcade_shaders) attacker thread extreme\_ex_arcade::showArcadeShader("x2_nukeunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_NUKE_UNLOCK");
						}
					}
					break;
			}
		}
	}
}

gunshipWeaponOverlay(overlay)
{
	self endon("kill_thread");
	self endon("gunship_over");

	if(!isDefined(self.gunship_overlay))
	{
		self.gunship_overlay = newClientHudElem(self);
		self.gunship_overlay.horzAlign = "center";
		self.gunship_overlay.vertAlign = "middle";
		self.gunship_overlay.alignX = "center";
		self.gunship_overlay.alignY = "middle";
		self.gunship_overlay.x = 0;
		self.gunship_overlay.y = 0;
	}
	self.gunship_overlay setshader(overlay, 640, 480);

	if(level.ex_gunship_grain)
	{
		if(!isDefined(self.gunship_grain))
		{
			self.gunship_grain = newClientHudElem(self);
			self.gunship_grain.horzAlign = "fullscreen";
			self.gunship_grain.vertAlign = "fullscreen";
			self.gunship_grain.alignX = "left";
			self.gunship_grain.alignY = "top";
			self.gunship_grain.x = 0;
			self.gunship_grain.y = 0;
			self.gunship_grain.alpha = 0.5;
		}
		self.gunship_grain setShader("gunship_overlay_grain", 640, 480);
	}
}

gunshipClock()
{
	if(!isDefined(self.gunship_clock))
	{
		self.gunship_clock = newClientHudElem(self);
		self.gunship_clock.horzAlign = "fullscreen";
		self.gunship_clock.vertAlign = "fullscreen";
		self.gunship_clock.horzAlign = "left";
		self.gunship_clock.vertAlign = "top";
		self.gunship_clock.x = 6;
		self.gunship_clock.y = 76;
		self.gunship_clock setClock(level.ex_gunship_time, level.ex_gunship_time, "hudStopwatch", 48, 48);
	}
}

gunshipInform(boarding)
{
	if(!level.ex_teamplay)
	{
		if(boarding) iprintln(&"GUNSHIP_ACTIVATED_ALL", [[level.ex_pname]](self));
			else iprintln(&"GUNSHIP_DEACTIVATED_ALL", [[level.ex_pname]](self));
	}
	else
	{
		if(level.ex_gunship_inform == 1)
		{
			if(boarding) gunshipInformTeam(&"GUNSHIP_ACTIVATED_TEAM", self.pers["team"]);
				else gunshipInformTeam(&"GUNSHIP_DEACTIVATED_TEAM", self.pers["team"]);
		}
		else
		{
			if(self.pers["team"] == "allies") enemyteam = "axis";
				else enemyteam = "allies";

			if(boarding)
			{
				gunshipInformTeam(&"GUNSHIP_ACTIVATED_TEAM", self.pers["team"]);
				gunshipInformTeam(&"GUNSHIP_ACTIVATED_ENEMY", enemyteam);
			}
			else
			{
				gunshipInformTeam(&"GUNSHIP_DEACTIVATED_TEAM", self.pers["team"]);
				gunshipInformTeam(&"GUNSHIP_DEACTIVATED_ENEMY", enemyteam);
			}
		}
	}

	if(!level.ex_gunship_clock) self iprintln(&"GUNSHIP_TIME", level.ex_gunship_time);
}

gunshipInformTeam(locstring, team)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers) && isDefined(player.pers["team"]))
			if(player.pers["team"] == team) player iprintln(locstring, [[level.ex_pname]](self));
	}
}

// PROJECTILE MONITORING PROCEDURES

gunshipMonitorProjectile(entity, gunship)
{
	if(gunship == 1) entity_by = level.ex_gunship_player;
		else entity_by = level.ex_gunship_splayer;
	entity_wp = entity_by getcurrentweapon();
	if(!isDefined(entity_wp)) return;

	// Screen shaking when firing (on player in gunship)
	switch(entity_wp)
	{
		case "gunship_25mm_mp":
			duration = 0.1;
			scale = 0.2;
			break;
		case "gunship_40mm_mp":
			duration = 0.3;
			scale = 0.4;
			break;
		case "gunship_105mm_mp":
			duration = 0.5;
			scale = 0.6;
			break;
		case "gunship_nuke_mp":
			duration = 0.5;
			scale = 0.6;
			entity_by.ex_invulnerable = true; // begin nuke survival hack
			break;
		default:
			duration = 0;
			scale = 0;
			break;
	}

	if(duration) earthquake(scale, duration, entity_by.origin, 100);

	// wait for projectile to explode
	lastorigin = entity.origin;
	while(isDefined(entity))
	{
		lastorigin = entity.origin;
		wait( [[level.ex_fpstime]](0.05) );
	}

	// Screen shaking on impact
	switch(entity_wp)
	{
		case "gunship_40mm_mp":
			duration = 1;
			scale = 0.2;
			break;
		case "gunship_105mm_mp":
			duration = 2;
			scale = 0.2;
			break;
		case "gunship_nuke_mp":
			duration = 4;
			scale = 1;
			entity_by.ex_invulnerable = false; // end nuke survival hack
			if(level.ex_gunship_nuke_fx) playfx(level.ex_effect["gunship_nuke"], lastorigin);
			if(level.ex_gunship_nuke_wipeout)
			{
				nuke_radius = spawn("script_origin", lastorigin);
				nuke_radius thread extreme\_ex_utils::scriptedfxradiusdamage(entity_by, undefined, "MOD_PROJECTILE_SPLASH", entity_wp, 5000, 300, 300, "none", undefined, false, true, true, "nuke");
				nuke_radius delete();
			}
			if(level.ex_heli && isDefined(level.helicopter)) level.helicopter.health = 0;
			break;
		default:
			duration = 0;
			scale = 0;
			break;
	}

	if(duration && isDefined(lastorigin))
	{
		earthquake(scale, duration, lastorigin, 1000);
		wait( [[level.ex_fpstime]](0.2) );
		if(isDefined(level.ex_gunship_player) && isPlayer(entity_by) && level.ex_gunship_player == entity_by)
			earthquake(0.5, duration, entity_by.origin, 100);
	}
}

// PERK ASSIGNMENT PROCEDURES

gunshipPerk(delay)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_gunship)) self.ex_gunship = false;
	if(self.ex_gunship) return;

	if(isDefined(level.ex_gunship_player) && isPlayer(level.ex_gunship_player) && level.ex_gunship_player == self) return;

	self notify("end_gunship");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_gunship");

	self.ex_gunship = true;

	if(level.ex_ranksystem)
	{
		if(level.ex_gunship == 2)
		{
			if(!isDefined(delay)) delay = level.ex_rank_gunship_first;
			wait( [[level.ex_fpstime]](delay) );
		}
		else
		{
			while(isDefined(self.ex_checkingwmd)) wait( [[level.ex_fpstime]](0.05) );
			wait( [[level.ex_fpstime]](1) );
			self extreme\_ex_ranksystem::wmdStop();
		}
	}

	while(self.ex_gunship)
	{
		if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_gunshipunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"GUNSHIP_READY");
                  self playlocalsound("ac130_readyfor");

		self hudNotify(game["wmd_gunship_hudicon"]);
		self thread waitForBinocEnter();

		self waittill("gunship_over");

		if(level.ex_gunship == 2)
		{
			if(level.ex_rank_gunship_next) wait( [[level.ex_fpstime]](level.ex_rank_gunship_next) );
			else
			{
				wait( [[level.ex_fpstime]](level.ex_rank_airstrike_next) );
				break;
			}
		}
		else break;
	}

	self.ex_gunship = false;
}

gunshipBoard()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](randomFloat(0.5)) );

	if(isDefined(level.ex_gunship_player))
	{
		self iprintlnbold(&"GUNSHIP_OCCUPIED");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		self.callingwmd = false;
		return;
	}

	if(level.ex_flagbased && isDefined(self.flag))
	{
		self iprintlnbold(&"GUNSHIP_FLAGCARRIER");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		self.callingwmd = false;
		return;
	}

	self notify("end_binoc");
	self hudNotifyRemove();
	self.usedweapons = true;
	self thread gunshipAttachPlayer();
	self.callingwmd = false;
}

waitForBinocEnter()
{
	self endon("kill_thread");
	self endon("end_gunship");
	self endon("end_binoc");

	self.callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.callingwmd)
		{
			self thread waitForBinocUse();
			self thread binocHintHud();
		}
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_binoc");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.callingwmd)
		{
			self.callingwmd = true;
			self thread gunshipBoard();
		}
		wait( [[level.ex_fpstime]](0.05) );
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
	self.ex_wmd_icon setShader(game["wmd_gunship_hudicon"], 16, 16);
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
		self.ex_binocular_hint.alpha = 1;
		self.ex_binocular_hint setText(&"WMD_ACTIVATE_HINT");
	}
}

hudNotifyRemove()
{
	if(isDefined(self.ex_wmd_icon)) self.ex_wmd_icon destroy();
	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();
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

	self.ex_binocular_hint setText(&"WMD_GUNSHIP_HINT");
	self thread binocHintHudDestroy();
}

binocHintHudDestroy()
{
	self endon("kill_thread");
	self endon("binocular_enter");

	self waittill("binocular_exit");

	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();
}

// PARACHUTE PROCEDURES

getNearestSpawnpoint(origin)
{
	level endon("ex_gameover");
	self endon("disconnect");

	spawnpoints = [];
	if(level.ex_currentgt == "dm")
	{
		spawn_entities = getentarray("mp_dm_spawn", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size || level.ex_teamplay)
	{
		spawn_entities = getentarray("mp_tdm_spawn", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size || level.ex_flagbased)
	{
		spawn_entities = getentarray("mp_ctf_spawn_allied", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
		spawn_entities = getentarray("mp_ctf_spawn_axis", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size)
	{
		spawn_entities = getentarray("mp_sd_spawn_attacker", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
		spawn_entities = getentarray("mp_sd_spawn_defender", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}

	if(isDefined(level.ex_spawnpoints)) for(i = 0; i < level.ex_spawnpoints.size; i++) spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];

	nearest_spot = spawnpoints[0];
	nearest_dist = distance(origin, spawnpoints[0].origin);

	for(i = 1; i < spawnpoints.size; i++)
	{
		trace = bullettrace(spawnpoints[i].origin, spawnpoints[i].origin + (0,0,300), true, undefined);
		trace_dist = int(distance(spawnpoints[i].origin, trace["position"]));

		if(!isDefined(trace_dist) || trace_dist == 300)
		{
			dist = distance(origin, spawnpoints[i].origin);
			if(dist < nearest_dist)
			{
				nearest_spot = spawnpoints[i];
				nearest_dist = dist;
			}
		}
	}

	return nearest_spot;
}

createParachute(chute_origin, chute_angles, chute_hide)
{
	chute = allocateParachute();

	level.chutes[chute].anchor = spawn("script_model", chute_origin);
	level.chutes[chute].anchor.angles = chute_angles;

	level.chutes[chute].model = spawn("script_model", chute_origin);
	if(chute_hide) hideParachute(chute);
	level.chutes[chute].model setModel("xmodel/am_fallschirm");
	level.chutes[chute].model.angles = chute_angles + (0,0,90);
	level.chutes[chute].model linkto(level.chutes[chute].anchor);
	level.chutes[chute].autokill = 180;
	thread monitorParachute(chute);
	return chute;
}

dropOnParachute(chute, chute_start, chute_end)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
	{
		level.chutes[chute].endpoint = chute_end;
		level.chutes[chute].anchor.origin = chute_start;
		level.chutes[chute].anchor playLoopSound ("para_wind");
		falltime = distance(chute_start, chute_end) / 100 + randomint(4);
		level.chutes[chute].autokill = (falltime * 2) + 10;
		level.chutes[chute].anchor moveto(chute_end, falltime);
		wait( [[level.ex_fpstime]](falltime) );
		level.chutes[chute].anchor stopLoopSound();
		level.chutes[chute].flag = 2; // 2 = delete
	}
}

hideParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
		level.chutes[chute].model hide();
}

showParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
		level.chutes[chute].model show();
}

monitorParachute(chute)
{
	chute_time = 0;
	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );
		chute_time++;
		if(level.chutes[chute].flag == 2 || chute_time >= level.chutes[chute].autokill)
		{
			if(level.chutes[chute].flag == 2) // 2 = delete
			{
				level.chutes[chute].model unlink();
				level.chutes[chute].model rotatepitch(85,10,9,1);
				level.chutes[chute].model moveto(level.chutes[chute].endpoint - (0,400,400), 7,6,1);
				wait( [[level.ex_fpstime]](5) );
			}

			freeParachute(chute);
			break;
		}
	}
}

allocateParachute()
{
	if(!isDefined(level.chutes)) level.chutes = [];

	for(i = 0; i < level.chutes.size; i++)
	{
		if(level.chutes[i].flag == 0) // 0 = free
		{
			level.chutes[i].flag = 1; // 1 = in use
			return i;
		}
	}

	level.chutes[i] = spawnstruct();
	level.chutes[i].flag = 1; // 1 = in use
	return i;
}

freeParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
	{
		if(isDefined(level.chutes[chute].model))
			level.chutes[chute].model delete();

		if(isDefined(level.chutes[chute].anchor))
			level.chutes[chute].anchor delete();

		level.chutes[chute].flag = 0; // 0 = free
	}
}
