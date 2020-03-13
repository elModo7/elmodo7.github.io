#include extreme\_ex_specials;
#include extreme\_ex_gunship;

// PERK ASSIGNMENT PROCEDURES

gunshipSpecialPerk(delay)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_gunship)) self.ex_gunship = false;
	if(self.ex_gunship) return;
	self.ex_gunship = true;
	self.ex_gunship_special = true;

	if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_gunshipunlock", level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"GUNSHIP_READY");

	self playlocalsound("sentrygun_readyfor");

	self hudNotifySpecial("gunship");

	// specialty store method of activating gunship (hold melee)
	while(true)
	{
		wait( [[level.ex_fpstime]](.05) );
		if(!self isOnGround()) continue;
		if(self meleebuttonpressed())
		{
			count = 0;
			while(self meleeButtonPressed() && count < 10)
			{
				wait( [[level.ex_fpstime]](.05) );
				count++;
			}

			if(count >= 10 && gunshipSpecialBoard()) break;
			while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}
	}

	self hudNotifySpecialRemove("gunship");

	wait( [[level.ex_fpstime]](delay) );

	self waittill("gunship_over");
	self.ex_gunship = false;
	self.ex_gunship_special = false;
}

gunshipSpecialWaitForBinocEnter()
{
	self endon("kill_thread");
	self endon("end_gunship");
	self endon("end_binoc");

	self.callinggunship = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.callinggunship)
		{
			self thread gunshipSpecialWaitForBinocUse();
			self thread binocHintHud();
		}
	}
}

gunshipSpecialWaitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_binoc");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.callinggunship)
		{
			self.callinggunship = true;
			self thread gunshipSpecialBoard();
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

gunshipSpecialBoard()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](randomFloat(0.5)) );

	if(isDefined(level.ex_gunship_splayer))
	{
		self iprintlnbold(&"GUNSHIP_OCCUPIED");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		self.callinggunship = false;
		return(false);
	}

	if(level.ex_flagbased && isDefined(self.flag))
	{
		self iprintlnbold(&"GUNSHIP_FLAGCARRIER");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		self.callinggunship = false;
		return(false);
	}

	self notify("end_binoc");
	self.usedweapons = true;
	self thread gunshipSpecialAttachPlayer();
	self.callinggunship = false;
	return(true);
}

// GUNSHIP ASSIGNMENT PROCEDURES

gunshipSpecialAttachPlayer()
{
	self endon("kill_thread");

	if(isDefined(level.ex_gunship_splayer)) return;
	level.ex_gunship_splayer = self;

	self thread playerStartUsingPerk("gunship");

	self extreme\_ex_utils::forceto("stand");
	self.gunship_org_origin = self.origin;
	self.gunship_org_angles = self.angles;

	self.ex_stopwepmon = true;
	wait( [[level.ex_fpstime]](0.1) );
	self notify("weaponsave");
	self waittill("weaponsaved");

	if(level.ex_gunship_airraid) level.ex_gunship_rig playsound("air_raid");
	if(level.ex_gunship_visible == 1) level.ex_gunship_smodel show();
	if(level.ex_gunship_ambientsound == 1) level.ex_gunship_smodel playloopsound("gunship_ambient");

	self.ex_gunship_ejected = false;
	if(!level.ex_rank_statusicons) self.statusicon = "gunship_statusicon";
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	if(level.ex_gunship_health) self.health = 100;
	self.ex_gunship_kills = 0;
	self hide();
	self linkTo(level.ex_gunship_rig, "tag_origin", (level.ex_gunship_radius * -1,0,-50), (0,-90,-20)); // angles = (pitch, yaw, roll);

	level thread gunshipSpecialTimer(self);
	if(level.ex_gunship_inform) self thread gunshipInform(true);
	if(level.ex_gunship_clock) self thread gunshipClock();
	self thread gunshipSpecialWeapon();
}

gunshipSpecialTimer(player)
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
			level thread gunshipSpecialDetachPlayerLevel(player, true);
			return;
		}
	}

	if(isPlayer(player))
	{
		// player is still there, and has a valid ticket
		if(isDefined(level.ex_gunship_splayer))
		{
			if(level.ex_gunship_splayer == player)
			{
				if(!level.ex_gameover && (level.ex_gunship_eject & 1) == 1) player thread gunshipSpecialDetachPlayer(true);
					else player thread gunshipSpecialDetachPlayer();
			}
		}
		// player is still there, but seems to be in gunship without a valid ticket
		else if(player.origin[2]+50 == level.ex_gunship_smodel.origin[2])
		{
			if(!level.ex_gameover) player thread gunshipSpecialDetachPlayer(false, true);
				else level thread gunshipSpecialDetachPlayerLevel(player, true);
		}
	}
}

gunshipSpecialDetachPlayer(eject, skipcheck)
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isDefined(level.ex_gunship_splayer) || !isPlayer(self) || level.ex_gunship_splayer != self)) return;

	self thread playerStopUsingPerk("gunship");

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

	if(level.ex_gunship_visible == 1) level.ex_gunship_smodel hide();
	if(level.ex_gunship_ambientsound == 1) level.ex_gunship_smodel stoploopsound();
	level.ex_gunship_splayer = undefined;
}

gunshipSpecialDetachPlayerLevel(playerent, skipcheck)
{
	level endon("ex_gameover");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isDefined(level.ex_gunship_splayer) || !isPlayer(playerent) || level.ex_gunship_splayer != playerent)) return;

	if(isPlayer(playerent)) playerent thread playerStopUsingPerk("gunship");

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

	if(level.ex_gunship_visible == 1) level.ex_gunship_smodel hide();
	if(level.ex_gunship_ambientsound == 1) level.ex_gunship_smodel stoploopsound();
	level.ex_gunship_splayer = undefined;
}

gunshipSpecialWeapon()
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
			thread gunshipSpecialDetachPlayer(true);
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

