
doPlayerBleed(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	self endon("kill_thread");

	if(self.ex_bleeding) return;
	if(randomInt(100)+1 > level.ex_bleeding) return;

	wait( [[level.ex_fpstime]](1) );

	if(isAlive(self) && self.sessionstate == "playing" && (self.health < level.ex_startbleed))
	{
		bleedV = [];
		bleedV = getBleedData(sMeansOfDeath, sWeapon, sHitLoc);
		if(!isDefined(bleedV["bleedmsg"])) return;

		self.ex_bleeding = true;
		self.ex_bsoundinit = false;
		self.ex_bshockinit = false;

		switch(level.ex_bleedmsg)
		{
			case 1: self iprintln(bleedV["bleedmsg"]); break;
			case 2: self iprintlnbold(bleedV["bleedmsg"]); break;
		}

		bleedcount = level.ex_maxbleed;
		while((bleedcount > 0) && isalive(self) && (self.health < level.ex_startbleed))
		{
			if(self.health > 1)
			{
				self.health--;
				if(!self.ex_bsoundinit) self thread doBleedPainSound();
				if(!self.ex_bshockinit) self thread doBleedPainShock();
				playfxontag(level.ex_effect["bleeding"], self, bleedV["bleedpos"]);
			}
			else
			{
				//self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread [[level.callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, undefined, vDir, sHitLoc, psOffsetTime);
			}

			bleedcount--;
			wait( [[level.ex_fpstime]](bleedV["bleeddly"]) );
		}

		self.ex_bshockinit = false;
		self.ex_bsoundinit = false;
		self.ex_bleeding = false;
		self notify("stopbleeding");

		if(level.ex_bleedmsg && isalive(self) && (self.health > level.ex_startbleed))
		{
			switch(level.ex_bleedmsg)
			{
				case 1: self iprintln(&"BLEED_STOPPED"); break;
				case 2: self iprintlnbold(&"BLEED_STOPPED"); break;
			}
		}
	}
}

doBleedPainSound()
{
	self endon("kill_thread");
	self endon("stopbleeding");

	if(!level.ex_bleedsound) return;

	self.ex_bsoundinit = true;
	sounddelay = 5.0;

	while(isAlive(self) && self.sessionstate == "playing" && (self.health < level.ex_startbleed))
	{
		if(self.health >= 1 && self.health <= 5) sounddelay = 1;
		else if(self.health >= 6 && self.health <= 10) sounddelay = 1.5;
		else if(self.health >= 11 && self.health <= 25) sounddelay = 2;
		else if(self.health >= 26 && self.health <= 50) sounddelay = 3;
		else if(self.health >= 51 && self.health <= 75) sounddelay = 4;
		else sounddelay = 5;

		switch(level.ex_bleedsound)
		{
			case 1:  // Play sound so ALL players can hear (mode 1)
			self thread extreme\_ex_utils::playSoundOnPlayer("generic_pain", "pain");
			break;

			case 2: // Play sound so ONLY the bleeding player can hear (mode 2)
			self playLocalSound("breathing_hurt");
			break;
		}

		wait( [[level.ex_fpstime]](sounddelay + randomInt(5)) );
	}
}

doBleedPainShock()
{
	self endon("kill_thread");
	self endon("stopbleeding");

	if(!level.ex_bleedshock) return;

	self.ex_bshockinit = true;
	shocktime = 1;

	while(isAlive(self) && self.sessionstate == "playing" && (self.health < level.ex_startbleed))
	{
		if(self.health >= 1 && self.health <= 5) shocktime = 10;
		else if(self.health >= 6 && self.health <= 10) shocktime = 5;
		else if(self.health >= 11 && self.health <= 25) shocktime = 4;
		else if(self.health >= 26 && self.health <= 50) shocktime = 3;
		else if(self.health >= 51 && self.health <= 75) shocktime = 2;

		self shellshock("medical", shocktime);
		wait( [[level.ex_fpstime]](shocktime + randomInt(5) + 10) );
	}
}

getBleedData(sMeansOfDeath, sWeapon, sHitLoc)
{
	pmsg = undefined;
	tagloc = undefined;
	delay = undefined;

	switch(sHitLoc)
	{
		case "head":
		case "helmet": pmsg = &"BLEED_HEAD"; tagloc = "j_head"; delay = 0.5; break;
		case "neck": pmsg = &"BLEED_NECK"; tagloc = "j_neck"; delay = 0.7; break;
		case "torso_upper": pmsg = &"BLEED_UPPERBODY"; tagloc = "j_neck"; delay = 1; break;
		case "torso_lower": pmsg = &"BLEED_LOWERBODY"; tagloc = "j_hip_le"; delay = 1; break;
		case "left_leg_upper": pmsg = &"BLEED_UPPERLEFTLEG"; tagloc = "j_knee_le"; delay = 1.2; break;
		case "right_leg_upper": pmsg = &"BLEED_UPPERRIGHTLEG"; tagloc = "j_knee_ri"; delay = 1.2; break;
		case "left_leg_lower": pmsg = &"BLEED_LOWERLEFTLEG"; tagloc = "j_knee_le"; delay = 1.5; break;
		case "right_leg_lower": pmsg = &"BLEED_LOWERRIGHTLEG"; tagloc = "j_knee_ri"; delay = 1.5; break;
		case "left_foot": pmsg = &"BLEED_LEFTFOOT"; tagloc = "j_ankle_le"; delay = 2.5; break;
		case "right_foot": pmsg = &"BLEED_RIGHTFOOT"; tagloc = "j_ankle_ri"; delay = 2.5; break;
		case "left_arm_upper": pmsg = &"BLEED_UPPERLEFTARM"; tagloc = "j_shoulder_le"; delay = 1.5; break;
		case "right_arm_upper": pmsg = &"BLEED_UPPERRIGHTARM"; tagloc = "j_shoulder_ri"; delay = 1.5; break;
		case "left_arm_lower": pmsg = &"BLEED_LOWERLEFTARM"; tagloc = "j_wrist_le"; delay = 1.5; break;
		case "right_arm_lower": pmsg = &"BLEED_LOWERRIGHTARM"; tagloc = "j_wrist_ri"; delay = 1.5; break;
		case "left_hand": pmsg = &"BLEED_LEFTHAND"; tagloc = "j_wrist_le"; delay = 2; break;
		case "right_hand": pmsg = &"BLEED_RIGHTHAND"; tagloc = "j_wrist_ri"; delay = 2; break;
		case "none":
		{
			switch(sMeansOfDeath)
			{
				case "MOD_EXPLOSIVE":
				{
					switch(sWeapon)
					{
						case "artillery_mp": pmsg = &"BLEED_ARTILLERY"; break;
						case "plane_mp": pmsg = &"BLEED_PLANECRASH"; break;
						case "tripwire_mp": pmsg = &"BLEED_TRIPWIRE"; break;
						case "planebomb_mp": pmsg = &"BLEED_PLANEBOMB"; break;
					}
				}
				break;

				case "MOD_GRENADE":
				{
					switch(sWeapon)
					{
						case "mortar_mp": pmsg = &"BLEED_MORTAR"; break;
						case "planebomb_mp": pmsg = &"BLEED_PLANEBOMB"; break;
					}
				}
				break;

				case "MOD_GRENADE_SPLASH": pmsg = &"BLEED_GRENADE_SPLASH"; break;
				case "MOD_FALLING": pmsg = &"BLEED_FALLING"; break;
			}
		}

		tagloc = "j_hip_le";
		delay = 2;
		break;

		default: pmsg = &"BLEED_GENERIC"; tagloc = "j_hip_le"; delay = 2; break;
	}

	bleedV["bleedmsg"] = pmsg;
	bleedV["bleedpos"] = tagloc;
	bleedV["bleeddly"] = delay;

	return bleedV;
}
