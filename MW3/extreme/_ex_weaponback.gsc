/*------------------------------------------------------------------------------
Based on Weapons on Back code from R&R Projects
------------------------------------------------------------------------------*/

init()
{
	if(!level.ex_weaponsonback || (level.ex_weaponsonback == 1 && !level.ex_wepo_secondary) ) return;
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
}

onPlayerSpawned()
{
	if(level.ex_wepo_secondary) self thread wob_twoslotmonitor();
		else self thread wob_oneslotmonitor();
}

wob_twoslotmonitor()
{
	self endon("kill_thread");

	// when carrying a flamethrower (any slot), the tank is on the back
	if(isFlamethrower(self.pers["weapon1"]) || isFlamethrower(self.pers["weapon2"])) return;

	self.weapononback = undefined;
	wob = "none";

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.5) );

		attach_enabled = true;
		if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) attach_enabled = false;

		currentweapon = self getcurrentweapon();

		if(isValidWeapon(currentweapon))
		{
			if(currentweapon == self.pers["weapon1"]) newwob = self.pers["weapon2"];
				else if(currentweapon == self.pers["weapon2"]) newwob = self.pers["weapon1"];
					else newwob = wob;

			if(newwob != wob)
			{
				wob = newwob;

				if(isDefined(self.weapononback))
				{
					if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
					self.weapononback = undefined;
				}

				wait( [[level.ex_fpstime]](0.05) );

				if(attach_enabled)
				{
					if(isValidWeaponOnBack(wob))
					{
						self.weapononback = wob;
						if(!checkAttached(self.weapononback)) self attach("xmodel/" + self.weapononback, "");
					}
				}
			}
		}
	}
}

wob_oneslotmonitor()
{
	self endon("kill_thread");

	// when carrying a flamethrower (any slot), the tank is on the back
	if(isFlamethrower(self.pers["weapon"])) return;

	self.weapononback = undefined;
	oldweapon = "none";
	wob = "none";

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.5) );

		attach_enabled = true;
		if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) attach_enabled = false;

		currentweapon = self getcurrentweapon();

		if(isValidWeapon(currentweapon))
		{
			if(wob == "none") newwob = currentweapon;
				else if(currentweapon != oldweapon) newwob = oldweapon;
					else newwob = wob;

			if(newwob != wob)
			{
				oldweapon = currentweapon;
				wob = newwob;

				if(isDefined(self.weapononback))
				{
					if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
					self.weapononback = undefined;
				}

				wait( [[level.ex_fpstime]](0.05) );

				if(attach_enabled)
				{
					if(isValidWeaponOnBack(wob))
					{
						self.weapononback = wob;
						if(!checkAttached(self.weapononback)) self attach("xmodel/" + self.weapononback, "");
					}
				}
			}
			else oldweapon = currentweapon;
		}
	}
}

checkAttached(model)
{
	self endon("kill_thread");

	model_attached = false;
	model_full = "xmodel/" + model;

	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == model_full)
		{
			model_attached = true;
			break;
		}
	}

	return(model_attached);
}

isValidWeapon(weapon)
{
	if(!isDefined(weapon)) return false;
	if(weapon == game["sprint"]) return false;

	switch(weapon)
	{
		case "none":
		case "ignore":
		case "knife_mp":
		case "colt_mp":
		case "webley_mp":
		case "tt30_mp":
		case "luger_mp":
		case "flamethrower_axis":
		case "flamethrower_allies":
		case "colt_vip_mp":
		case "webley_vip_mp":
		case "tt30_vip_mp":
		case "luger_vip_mp":
		case "raygun_mp":
		case "binoculars_mp": return false;
	}

	return true;
}

isFlamethrower(weapon)
{
	if(!isDefined(weapon)) return false;

	switch(weapon)
	{
		case "flamethrower_axis":
		case "flamethrower_allies": return true;
	}

	return false;
}

isValidWeaponOnBack(weapon)
{
	if(!isDefined(weapon)) return false;

	switch(weapon)
	{
		case "dummy1_mp":
		case "dummy2_mp":
		case "dummy3_mp":
		case "flamethrower_axis":
		case "flamethrower_allies":
		case "springfield_2_mp":
		case "enfield_scope_2_mp":
		case "mosin_nagant_sniper_2_mp":
		case "kar98k_sniper_2_mp":
		case "g43_sniper_2":
		case "gunship_25mm_mp":
		case "gunship_40mm_mp":
		case "gunship_105mm_mp":
		case "gunship_nuke_mp": return false;
	}

	return true;
}
