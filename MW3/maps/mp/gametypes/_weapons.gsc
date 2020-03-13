#include extreme\_ex_weapons;

init()
{
	level.allow_pistol_drop = [[level.ex_drm]]("ex_allow_pistol_drop", 1, 0, 1, "int"); 
	level.allow_sniper_drop = [[level.ex_drm]]("ex_allow_sniper_drop", 1, 0, 1, "int");
	level.allow_sniperlr_drop = [[level.ex_drm]]("ex_allow_sniperlr_drop", 1, 0, 1, "int");
	level.allow_mg_drop = [[level.ex_drm]]("ex_allow_mg_drop", 1, 0, 1, "int");
	level.allow_smg_drop = [[level.ex_drm]]("ex_allow_smg_drop", 1, 0, 1, "int");
	level.allow_rifle_drop = [[level.ex_drm]]("ex_allow_rifle_drop", 1, 0, 1, "int"); 
	level.allow_boltrifle_drop = [[level.ex_drm]]("ex_allow_boltrifle_drop", 1, 0, 1, "int");
	level.allow_shotgun_drop = [[level.ex_drm]]("ex_allow_shotgun_drop", 1, 0, 1, "int"); 
	level.allow_rl_drop = [[level.ex_drm]]("ex_allow_rl_drop", 1, 0, 1, "int");
	level.allow_ft_drop = [[level.ex_drm]]("ex_allow_ft_drop", 1, 0, 1, "int");
	level.allow_knife_drop = [[level.ex_drm]]("ex_allow_knife_drop", 1, 0, 1, "int");

	// create weapons array
	createWeaponsArray();

	// set initial allowed status for all weapons. Read from DRM pool, so they can include map and/or gametype.
	// write to cvars so updateAllowed() can run reliably
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		if(level.weapons[weaponname].classname == "sniperlr")
		{
			level.weapons[weaponname].allow = 1;
			continue;
		}

		if(level.weapons[weaponname].server_allowcvar != "")
		{
			level.weapons[weaponname].allow = [[level.ex_drm]](level.weapons[weaponname].server_allowcvar, level.weapons[weaponname].allow_default, 0, 1, "int");
			setCvar(level.weapons[weaponname].server_allowcvar, level.weapons[weaponname].allow);
			if(level.ex_wepo_limiter)
			{
				// Set weapon limit to 0 if disallowed so it isn't re-enabled by the weapon limiter
				if(!level.weapons[weaponname].allow) level.weapons[weaponname].limit = 0;

				if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
				{
					level.weapons[weaponname].allow_allies = level.weapons[weaponname].allow;
					level.weapons[weaponname].allow_axis = level.weapons[weaponname].allow;
					level.weapons[weaponname].limit_allies = level.weapons[weaponname].limit;
					level.weapons[weaponname].limit_axis = level.weapons[weaponname].limit;
				}
			}
		}
		else
		{
			logprint("*** ERROR: weapon " + weaponname + " in weapons array (_weapons.gsc) has no server_allowcvar. Weapon disabled!\n");
			level.weapons[weaponname].allow = 0;
			level.weapons[weaponname].allow_allies = level.weapons[weaponname].allow;
			level.weapons[weaponname].allow_axis = level.weapons[weaponname].allow;
		}
	}

	// precache the weapons
	precacheWeapons();

	// Update the allowed status for the weapons. This includes weapon limiter settings
	updateAllowed();

	// delete all restricted weapons from the map (in case the map includes weapons)
	thread deleteRestrictedWeapons();

	// create weapon damage modifiers array
	thread initWeaponDamageModifiers();

	// monitor allowed status
	thread cycleUpdateAllowed();
}

deleteRestrictedWeapons()
{
	// remove all weapons from the map that are not allowed (only checking weapons array)
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		if(level.weapons[weaponname].classname == "nade")
		{
			if(!level.weapons[weaponname].allow)
			{
				maps\mp\_utility::deletePlacedEntity("weapon_frag_grenade_american_mp");
				maps\mp\_utility::deletePlacedEntity("weapon_frag_grenade_british_mp");
				maps\mp\_utility::deletePlacedEntity("weapon_frag_grenade_russian_mp");
				maps\mp\_utility::deletePlacedEntity("weapon_frag_grenade_german_mp");
			}
		}
		else if(level.weapons[weaponname].classname == "smoke")
		{
			if(!level.weapons[weaponname].allow)
			{
				maps\mp\_utility::deletePlacedEntity("weapon_smoke_grenade_american_mp");
				maps\mp\_utility::deletePlacedEntity("weapon_smoke_grenade_british_mp");
				maps\mp\_utility::deletePlacedEntity("weapon_smoke_grenade_russian_mp");
				maps\mp\_utility::deletePlacedEntity("weapon_smoke_grenade_german_mp");
			}
		}
		else
		{
			if(level.ex_bash_only || !level.weapons[weaponname].allow)
				maps\mp\_utility::deletePlacedEntity("weapon_" + weaponname);
		}
	}	

	// if using modern weapons, remove all ww2 weapons from the map (shadow array)
	if(level.ex_modern_weapons)
	{
		for(i = 0; i < level.oldweaponnames.size; i++)
		{
			weaponname = level.oldweaponnames[i];
			maps\mp\_utility::deletePlacedEntity("weapon_" + weaponname);
		}
	}
}

dropWeapon()
{
	self endon("disconnect");

	// do not drop weapons if bots enabled
	if(level.ex_weapondrop_override) return;

	if(!level.ex_wepo_drop_weps) return;

	clipsize1 = 0;
	clipsize2 = 0;
	reservesize1 = 0;
	reservesize2 = 0;
	currentslot = undefined;
	current = undefined;

	// get primary information
	weapon1 = self getweaponslotweapon("primary");
	if(weapon1 != "none" && weapon1 != game["sprint"] && weapon1 != "dummy1_mp" && weapon1 != "dummy2_mp" && weapon1 != "dummy3_mp")
	{
		clipsize1 = self getweaponslotclipammo("primary");
		reservesize1 = self getweaponslotammo("primary");
	}
	else weapon1 = "none";

	// get primaryb information
	weapon2 = self getweaponslotweapon("primaryb");
	if(weapon2 != "none" && weapon2 != game["sprint"] && weapon2 != "dummy1_mp" && weapon2 != "dummy2_mp" && weapon2 != "dummy3_mp")
	{
		clipsize2 = self getweaponslotclipammo("primaryb");
		reservesize2 = self getweaponslotammo("primaryb");
	}
	else weapon2 = "none";

	if(level.ex_wepo_drop_weps == 1)
	{
		current = self getcurrentweapon();

		if(current == weapon1) currentslot = "primary";
			else currentslot = "primaryb";

		if(isdefined(currentslot))
		{
			if(currentslot == "primary") if(clipsize1 || reservesize1) self dropItemIfAllowed(weapon1);
				else if(clipsize2 || reservesize2) self dropItemIfAllowed(weapon2);
		}
	}
	else if(level.ex_wepo_drop_weps == 2)
	{
		if(clipsize1 || reservesize1) self dropItemIfAllowed(weapon1);
	}
	else if(level.ex_wepo_drop_weps == 3)
	{
		if(clipsize2 || reservesize2) self dropItemIfAllowed(weapon2);
	}
	else if(level.ex_wepo_drop_weps == 4)
	{
		if(clipsize1 || reservesize1) self dropItemIfAllowed(weapon1);
		if(clipsize2 || reservesize2) self thread dropItemDelayed(weapon2, 0.2);
	}
}

dropItemDelayed(weapon, delay)
{
	wait( [[level.ex_fpstime]](delay) );
	if(isPlayer(self)) self dropItemIfAllowed(weapon);
}

dropOffhand(forced)
{
	self endon("disconnect");

	// do not drop weapons if bots enabled
	//if(level.ex_weapondrop_override) return;

	if(!isDefined(forced)) forced = false;
	if(!level.ex_wepo_drop_frag && !level.ex_wepo_drop_smoke && !forced) return;

	// teams share the same weapon file for special nades, so if one them is enabled, only count own type
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges)
	{
		fragsize = self getammocount(self.pers["fragtype"]);
		enemy_fragsize = 0;
	}
	else
	{
		fragsize = self getammocount(self.pers["fragtype"]);
		enemy_fragsize = self getammocount(self.pers["enemy_fragtype"]);
	}

	smokesize = self getammocount(self.pers["smoketype"]);
	enemy_smokesize = self getammocount(self.pers["enemy_smoketype"]);

	if(level.ex_wepo_drop_frag || forced)
	{
		if(fragsize) self dropItemIfAllowed(self.pers["fragtype"]);
		if(enemy_fragsize) self dropItemIfAllowed(self.pers["enemy_fragtype"]);
	}

	if(level.ex_wepo_drop_smoke || forced)
	{
		if(smokesize) self dropItemIfAllowed(self.pers["smoketype"]);
		if(enemy_smokesize) self dropItemIfAllowed(self.pers["enemy_smoketype"]);
	}
}

dropItemIfAllowed(weapon)
{
	if(isMainWeapon(weapon)) 
	{
		if(level.weapons[weapon].classname == "sniper" && !level.allow_sniper_drop) return;
		if(level.weapons[weapon].classname == "sniperlr" && !level.allow_sniperlr_drop) return;
		if(level.weapons[weapon].classname == "mg" && !level.allow_mg_drop) return;
		if(level.weapons[weapon].classname == "smg" && !level.allow_smg_drop) return;
		if(level.weapons[weapon].classname == "rifle" && !level.allow_rifle_drop) return; 
		if(level.weapons[weapon].classname == "boltrifle" && !level.allow_boltrifle_drop) return;
		if(level.weapons[weapon].classname == "shotgun" && !level.allow_shotgun_drop) return; 
		if(level.weapons[weapon].classname == "rl" && !level.allow_rl_drop) return;
		if(level.weapons[weapon].classname == "flamethrower" && !level.allow_ft_drop) return;
		if(level.weapons[weapon].classname == "boltsniper" && !level.allow_boltsniper_drop) return;
	}
	else
	{
		// do not drop FreezeTag raygun (not considered main weapon in isMainWeapon() )
		if(weapon == "raygun_mp") return;
		// do not drop VIP pistols (not part of weapons array)
		if(isWeaponType(weapon, "vippistol")) return;
		// check knife (not considered main weapon in isMainWeapon() )
		if(isWeaponType(weapon, "knife") && !level.allow_knife_drop) return;
		// check normal pistols (not considered main weapon in isMainWeapon() )
		if(isWeaponType(weapon, "pistol") && !level.allow_pistol_drop) return;
	}

	// convert frag, smoke and special grenades to a proper array index string
	weaponindex = weapon;
	if(isWeaponType(weapon, "fraggrenade") || isWeaponType(weapon, "fragspecial")) weaponindex = "fraggrenade";
		else if(isWeaponType(weapon, "smokegrenade") || isWeaponType(weapon, "smokespecial")) weaponindex = "smokegrenade";

	if(isDefined(level.weapons[weaponindex]) && level.weapons[weaponindex].allow) self dropItem(weapon);
}

getFireGrenadeCount()
{
	if(self.pers["team"] == "allies") grenadetype = "fire_mp";
	else
	{
		assert(self.pers["team"] == "axis");
		grenadetype = "fire_mp";
	}

	count = self getammocount(grenadetype);
	return count;
}

getGasGrenadeCount()
{
	if(self.pers["team"] == "allies") grenadetype = "gas_mp";
	else
	{
		assert(self.pers["team"] == "axis");
		grenadetype = "gas_mp";
	}

	count = self getammocount(grenadetype);
	return count;
}

getSatchelChargeCount()
{
	if(self.pers["team"] == "allies") grenadetype = "satchel_mp";
	else
	{
		assert(self.pers["team"] == "axis");
		grenadetype = "satchel_mp";
	}

	count = self getammocount(grenadetype);
	return count;
}

getFragGrenadeCount()
{
	if(self.pers["team"] == "allies") grenadetype = getFragTypeAllies();
		else grenadetype = getFragTypeAxis();

	count = self getammocount(grenadetype);
	return count;
}

getSmokeGrenadeCount()
{
	if(self.pers["team"] == "allies") grenadetype = "smoke_grenade_" + game["allies"] + GetSmokeColour(level.ex_smoke[game["allies"]]) + "mp";
		else grenadetype = "smoke_grenade_" + game["axis"] + GetSmokeColour(level.ex_smoke[game["axis"]]) + "mp";

	count = self getammocount(grenadetype);
	return count;
}

getBinocularCount()
{
	count = 0;

	// get the players array
	players = level.players;

	for(i = 0; i < players.size; i++)
		if(isDefined(players[i].ex_haswmdbinocs) && players[i].ex_haswmdbinocs) count++;
		
	return count;
}

isMainWeapon(weapon)
{
	// Include any main weapons that can be picked up
	if(!level.ex_modern_weapons)
	{
		switch(weapon)
		{
			case "greasegun_mp":
			case "m1carbine_mp":
			case "m1garand_mp":
			case "thompson_mp":
			case "bar_mp":
			case "springfield_mp":
			case "springfield_2_mp":
			case "sten_mp":
			case "enfield_mp":
			case "bren_mp":
			case "enfield_scope_mp":
			case "enfield_scope_2_mp":
			case "mosin_nagant_mp":
			case "svt40_mp":
			case "pps42_mp":
			case "ppsh_mp":
			case "mosin_nagant_sniper_mp":
			case "mosin_nagant_sniper_2_mp":
			case "kar98k_mp":
			case "g43_mp":
			case "g43_sniper":
			case "g43_sniper_2":
			case "mp40_mp":
			case "mp44_mp":
			case "kar98k_sniper_mp":
			case "kar98k_sniper_2_mp":
			case "shotgun_mp":
			case "panzerschreck_mp":
			case "panzerschreck_allies":
			case "mobile_30cal":
			case "mobile_mg42":
			case "flamethrower_allies":
			case "flamethrower_axis":
				return true;

			default:
				return false;
		}
	}
	else
	{
		switch(weapon)
		{
			case "ak_47_mp":
			case "ak_74_mp":
			case "ar_10_mp":
			case "ar_10_2_mp":
			case "aug_a3_mp":
			case "barrett_mp":
			case "barrett_2_mp":
			case "beretta_mp":
			case "deagle_mp":
			case "dragunov_mp":
			case "dragunov_2_mp":
			case "famas_mp":
			case "glock_mp":
			case "hk_g36_mp":
			case "m249_mp":
			case "m40a3_mp":
			case "m40a3_2_mp":
			case "m4a1_mp":
			case "m60_mp":
			case "mp5_mp":
			case "mp5a4_mp":
			case "mac10_mp":
			case "p90_mp":
			case "rpg_mp":
			case "sig_552_mp":
			case "hk45_mp":
			case "spas_12_mp":
			case "tmp_mp":
			case "ump45_mp":
			case "uzi_mp":
			case "xm1014_mp":
			case "mobile_30cal":
			case "mobile_mg42":
				return true;

			default:
				return false;
		}
	}
}

restrictWeaponByServerCvars(response)
{
	// allow "none" type for bots only (secondary weapon)
	if(response == "none")
	{
		if(isDefined(self.pers["isbot"])) return response;
			else return "restricted";
	}

	// weapon limiter check
	if(level.ex_wepo_limiter)
	{
		if(isDefined(level.weapons[response]))
		{
			if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
			{
				if(self.pers["team"] == "allies")
				{
					if(isDefined(level.weapons[response].allow_allies))
					{
						if(level.weapons[response].allow_allies == 0) return "restricted";
							else return response;
					}
					else logprint("DEBUG: level.weapons[" + response + "].allow_allies does not exist\n");
				}
				else
				{
					if(isDefined(level.weapons[response].allow_axis))
					{
						if(level.weapons[response].allow_axis == 0) return "restricted";
							else return response;
					}
					else logprint("DEBUG: level.weapons[" + response + "].allow_axis does not exist\n");
				}
			}
			else
			{
				if(isDefined(level.weapons[response].allow))
				{
					if(level.weapons[response].allow == 0) return "restricted";
						else return response;
				}
				else logprint("DEBUG: level.weapons[" + response + "].allow does not exist\n");
			}
		}
		else logprint("DEBUG: level.weapons[" + response + "] does not exist\n");
	}

	if(!getWeaponStatus(response)) return "restricted";
		else return response;
}

getWeaponStatus(weapon)
{
	cvarvalue = 0;
	if(isDefined(level.weapons[weapon]) && level.weapons[weapon].server_allowcvar != "")
		cvarvalue = getCvarInt(level.weapons[weapon].server_allowcvar);

	return cvarvalue;
}

getWeaponName(weapon)
{
	if(!isDefined(weapon)) return &"WEAPON_UNKNOWNWEAPON";

	switch(weapon)
	{
		// classic weapons
		case "bar_mp": return &"WEAPON_BAR";
		case "bren_mp": return &"WEAPON_BREN";
		case "enfield_mp": return &"WEAPON_LEEENFIELD";
		case "enfield_scope_mp": return &"WEAPON_SCOPEDLEEENFIELD";
		case "enfield_scope_2_mp": return &"WEAPON_SCOPEDLEEENFIELD_LR";
		case "flamethrower_allies": return &"WEAPON_FLAMETHROWER";
		case "flamethrower_axis": return &"WEAPON_FLAMMENWERFER";
		case "g43_mp": return &"WEAPON_G43";
		case "g43_sniper": return &"WEAPON_SCOPEDG43";
		case "g43_sniper_2": return &"WEAPON_SCOPEDG43_LR";
		case "greasegun_mp": return &"WEAPON_GREASEGUN";
		case "kar98k_mp": return &"WEAPON_KAR98K";
		case "kar98k_sniper_mp": return &"WEAPON_SCOPEDKAR98K";
		case "kar98k_sniper_2_mp": return &"WEAPON_SCOPEDKAR98K_LR";
		case "m1carbine_mp": return &"WEAPON_M1A1CARBINE";
		case "m1garand_mp": return &"WEAPON_M1GARAND";
		case "mosin_nagant_mp": return &"WEAPON_MOSINNAGANT";
		case "mosin_nagant_sniper_mp": return &"WEAPON_SCOPEDMOSINNAGANT";
		case "mosin_nagant_sniper_2_mp": return &"WEAPON_SCOPEDMOSINNAGANT_LR";
		case "mp40_mp": return &"WEAPON_MP40";
		case "mp44_mp": return &"WEAPON_MP44";
		case "panzerschreck_allies": return &"WEAPON_BAZOOKA";
		case "panzerschreck_mp": return &"WEAPON_PANZERSCHRECK";
		case "pps42_mp": return &"WEAPON_PPS42";
		case "ppsh_mp": return &"WEAPON_PPSH";
		case "shotgun_mp": return &"WEAPON_SHOTGUN";
		case "springfield_mp": return &"WEAPON_SPRINGFIELD";
		case "springfield_2_mp": return &"WEAPON_SPRINGFIELD_LR";
		case "sten_mp": return &"WEAPON_STEN";
		case "svt40_mp": return &"WEAPON_SVT40";
		case "thompson_mp": return &"WEAPON_THOMPSON";

		// offhand weapons
		case "colt_mp": return &"WEAPON_COLT45";
		case "knife_mp": return &"WEAPON_KNIFE";
		case "luger_mp": return &"WEAPON_LUGER";
		case "tt30_mp": return &"WEAPON_TT30";
		case "webley_mp": return &"WEAPON_WEBLEY";
		case "raygun_mp": return &"WEAPON_RAYGUN";

		// frag grenades
		case "frag_grenade_american_mp":
		case "frag_grenade_british_mp":
		case "frag_grenade_german_mp":
		case "frag_grenade_russian_mp": return &"WEAPON_FRAGGRENADE";

		// gas grenades
		case "smoke_grenade_american_gas_mp":
		case "smoke_grenade_british_gas_mp":
		case "smoke_grenade_german_gas_mp":
		case "smoke_grenade_russian_gas_mp":
		case "gas_mp": return &"WEAPON_GAS";

		// napalm grenades
		case "smoke_grenade_american_fire_mp":
		case "smoke_grenade_british_fire_mp":
		case "smoke_grenade_german_fire_mp":
		case "smoke_grenade_russian_fire_mp":
		case "fire_mp": return &"WEAPON_FIRE";

		// satchel charges
		case "smoke_grenade_american_satchel_mp":
		case "smoke_grenade_british_satchel_mp":
		case "smoke_grenade_german_satchel_mp":
		case "smoke_grenade_russian_satchel_mp":
		case "satchel_mp": return &"WEAPON_SATCHEL";

		// other weapons
		case "mortar_mp": return &"WEAPON_MORTAR";
		case "artillery_mp": return &"WEAPON_ARTILLERY";
		case "planebomb_mp": return &"WEAPON_AIRSTRIKE";
		case "gunship_25mm_mp": return &"WEAPON_GUNSHIP_25MM";
		case "gunship_40mm_mp": return &"WEAPON_GUNSHIP_40MM";
		case "gunship_105mm_mp": return &"WEAPON_GUNSHIP_105MM";
		case "gunship_nuke_mp": return &"WEAPON_GUNSHIP_NUKE";
		case "landmine_mp": return &"WEAPON_LANDMINE";
		case "tripwire_mp": return &"WEAPON_TRIPWIRE";
		case "sentrygun_mp": return &"WEAPON_SENTRYGUN";
		case "heligun_mp": return &"WEAPON_HELIGUN";
		case "helimissile_mp": return &"WEAPON_HELIMISSILE";
		case "helitube_mp": return &"WEAPON_HELITUBE";

		// mobile mg and turrets
		case "30cal_duck_mp":
		case "30cal_prone_mp":
		case "30cal_stand_mp":
		case "mobile_30cal": return &"WEAPON_30CAL";

		case "mg42_bipod_duck_mp":
		case "mg42_bipod_prone_mp":
		case "mg42_bipod_stand_mp":
		case "mobile_mg42": return &"WEAPON_MG42";

		// modern weapons
		case "ak_47_mp": return &"WEAPON_AK_47";
		case "ak_74_mp": return &"WEAPON_AK_74";
		case "ar_10_mp": return &"WEAPON_AR_10";
		case "ar_10_2_mp": return &"WEAPON_AR_10_LR";
		case "aug_a3_mp": return &"WEAPON_AUG_A3";
		case "barrett_mp": return &"WEAPON_BARRETT";
		case "barrett_2_mp": return &"WEAPON_BARRETT_LR";
		case "beretta_mp": return &"WEAPON_BERETTA";
		case "deagle_mp": return &"WEAPON_DEAGLE";
		case "dragunov_mp": return &"WEAPON_DRAGUNOV";
		case "dragunov_2_mp": return &"WEAPON_DRAGUNOV_LR";
		case "famas_mp": return &"WEAPON_FAMAS";
		case "glock_mp": return &"WEAPON_GLOCK";
		case "hk_g36_mp": return &"WEAPON_HK_G36";
		case "hk45_mp": return &"WEAPON_HK45";
		case "m249_mp": return &"WEAPON_M249";
		case "m40a3_mp": return &"WEAPON_M40A3";
		case "m40a3_2_mp": return &"WEAPON_M40A3_LR";
		case "m4a1_mp": return &"WEAPON_M4A1";
		case "m60_mp": return &"WEAPON_M60";
		case "mac10_mp": return &"WEAPON_MAC10";
		case "mp5_mp": return &"WEAPON_MP5";
		case "mp5a4_mp": return &"WEAPON_MP5A4";
		case "p90_mp": return &"WEAPON_P90";
		case "rpg_mp": return &"WEAPON_RPG";
		case "sig_552_mp": return &"WEAPON_SIG_552";
		case "spas_12_mp": return &"WEAPON_SPAS_12";
		case "tmp_mp": return &"WEAPON_TMP";
		case "ump45_mp": return &"WEAPON_UMP45";
		case "uzi_mp": return &"WEAPON_UZI";
		case "xm1014_mp": return &"WEAPON_XM1014";
	}

	// unknown weapon
	return &"WEAPON_UNKNOWNWEAPON";
}

useAn(weapon)
{
	if(!isDefined(weapon)) return false;

	switch(weapon)
	{
		// classic weapons
		case "m1carbine_mp":
		case "m1garand_mp":
		case "mp40_mp":
		case "mp44_mp":
		case "shotgun_mp":

		// modern weapons
		case "ak_47_mp":
		case "ak_74_mp":
		case "ar_10_mp":
		case "ar_10_2_mp":
		case "aug_a3_mp":
		case "hk45_mp":
		case "hk_g36_mp":
		case "m249_mp":
		case "m40a3_mp":
		case "m40a3_2_mp":
		case "m4a1_mp":
		case "m60_mp":
		case "mp5_mp":
		case "mp5a4_mp":
		case "rpg_mp":
		case "uzi_mp":
		case "xm1014_mp":

		// wmd
		case "artillery_mp": return true;
	}

	return false;
}

cycleUpdateAllowed()
{
	level endon("ex_gameover");

	for(;;)
	{
		wait( [[level.ex_fpstime]](1) );
		updateAllowed();
		wait( [[level.ex_fpstime]](4) );
	}
}

updateAllowed()
{
	level endon("ex_gameover");

	classname = undefined;

	switch(level.ex_wepo_class)
	{
		case 1: classname = "pistol"; break;     // pistol only
		case 2: classname = "sniper"; break;     // sniper only
		case 3: classname = "mg"; break;         // mg only
		case 4: classname = "smg"; break;        // smg only
		case 5: classname = "rifle"; break;      // rifle only
		case 6: classname = "boltrifle"; break;  // bolt action rifle only
		case 7: classname = "shotgun"; break;    // shotgun only
		case 8: classname = "rl"; break;         // panzerschreck only
		case 9: classname = "boltsniper"; break; // bolt and sniper only
		case 10: classname = "knife"; break;     // knives only
	}

	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// Do not check LR rifles. They share the same vars as their SR counterparts,
		if(isWeaponType(weaponname, "sniperlr")) continue;

		if(level.ex_wepo_class)
		{
			// check if it matches the class based weapon
			if(isWeaponType(weaponname, classname)) cvarvalue = getCvarInt(level.weapons[weaponname].server_allowcvar);
				else cvarvalue = 0;

			// frag grenade override
			if(level.weapons[weaponname].classname == "nade" && level.ex_wepo_allow_frag) cvarvalue = 1;

			// smoke grenade override
			if(level.weapons[weaponname].classname == "smoke" && level.ex_wepo_allow_smoke) cvarvalue = 1;

			// sidearm override
			if(level.ex_wepo_sidearm)
			{
				if(level.ex_wepo_sidearm_type == 0 && isWeaponType(weaponname, "pistol")) cvarvalue = 1;
				if(level.ex_wepo_sidearm_type == 1 && isWeaponType(weaponname, "knife")) cvarvalue = 1;
			}
		}
		else cvarvalue = getCvarInt(level.weapons[weaponname].server_allowcvar);

		// if weapon limiter enabled (disabled for classes automatically), count the weapons
		if(level.ex_wepo_limiter)
		{
			// only process weapons which do not have the default value 999
			if(level.weapons[weaponname].limit != 999)
			{
				// Set cvarvalue to 1 to force a recount
				cvarvalue = 1;
				cvarvalue_allies = cvarvalue;
				cvarvalue_axis = cvarvalue;

				// unless this weapon's limit is zero, not available
				if(level.weapons[weaponname].limit == 0) cvarvalue = 0;

				// if it is allowed and is game allies and axis, then check if limit reached
				if(cvarvalue && (isWeaponType(weaponname, game["allies"]) || isWeaponType(weaponname, game["axis"])))
				{
					count = 0;
					count_allies = count;
					count_axis = count;

					// get the players array
					players = level.players;

					for(j = 0; j < players.size; j++)
					{
						player = players[j];

						// skip player if no team setting exist
						if(isPlayer(player) && !isDefined(player.pers["team"])) continue;

						// don't count real spectators
						if(isPlayer(player) && player.pers["team"] == "spectator") continue;

						// check players that are not spectator team and have not started playing, i.e. just joined or switched sides
						if(isPlayer(player) && player.sessionstate == "spectator")
						{
							// check for a primary being chosen, primaryb (secondary) is not checked now, cause they will have spawned directly after choosing
							if(isDefined(player.pers["weapon"]) && weaponname == player.pers["weapon"])
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
						}
						else if(isPlayer(player) && isDefined(player.weapon))
						{
							// check for registered primary spawn weapon
							if(isDefined(player.weapon["primary"]) && isDefined(player.weapon["primary"].name) && weaponname == player.weapon["primary"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
							// check for registered secondary spawn weapon
							else if(isDefined(player.weapon["primaryb"]) && isDefined(player.weapon["primaryb"].name) && weaponname == player.weapon["primaryb"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
							// check for registered virtual spawn weapon
							else if(isDefined(player.weapon["virtual"]) && isDefined(player.weapon["virtual"].name) && weaponname == player.weapon["virtual"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}

							// check if player selected new primary weapon
							if(isDefined(player.pers["weapon"]) && weaponname == player.pers["weapon"] &&
							   isDefined(player.weapon["primary"]) && isDefined(player.weapon["primary"].name) && weaponname != player.weapon["primary"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
							// check if player selected new secondary weapon
							else if(isDefined(player.pers["weapon2"]) && weaponname == player.pers["weapon2"] &&
							   isDefined(player.weapon["primaryb"]) && isDefined(player.weapon["primaryb"].name) && weaponname != player.weapon["primaryb"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
						}
					}

					if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
					{
						if(count_allies >= level.weapons[weaponname].limit_allies) cvarvalue_allies = 0;
						if(count_axis >= level.weapons[weaponname].limit_axis) cvarvalue_axis = 0;

						if(level.weapons[weaponname].allow_allies != cvarvalue_allies)
						{
							level.weapons[weaponname].allow_allies = cvarvalue_allies;
							thread updateAllowedAllAllies(weaponname);
						}

						if(level.weapons[weaponname].allow_axis != cvarvalue_axis)
						{
							level.weapons[weaponname].allow_axis = cvarvalue_axis;
							thread updateAllowedAllAxis(weaponname);
						}
					}
					else
					{
						if(count >= level.weapons[weaponname].limit) cvarvalue = 0;

						if(level.weapons[weaponname].allow != cvarvalue)
						{
							level.weapons[weaponname].allow = cvarvalue;
							thread updateAllowedAllClients(weaponname);
						}
					}
				}
			}
		}
		else
		{
			if(level.weapons[weaponname].allow != cvarvalue)
			{
				level.weapons[weaponname].allow = cvarvalue;
				setCvar(level.weapons[weaponname].server_allowcvar, level.weapons[weaponname].allow);
				thread updateAllowedAllClients(weaponname);
			}
		}
	}
}

updateAllowedAllClients(weaponname)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		players[i] updateAllowedSingleClient(weaponname);
}

updateAllowedAllAllies(weaponname)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] == "allies")
			player updateAllowedSingleClientAllies(weaponname);
	}
}

updateAllowedAllAxis(weaponname)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] == "axis")
			player updateAllowedSingleClientAxis(weaponname);
	}
}

updateAllAllowedSingleClient()
{
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// Do not check LR rifles. They share the same vars as their SR counterparts,
		// but their allow status is not updated. This would re-enable the weapon
		if(isWeaponType(weaponname, "sniperlr")) continue;

		if(level.ex_teamplay && level.ex_wepo_limiter && level.ex_wepo_limiter_perteam && isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
		{
			if(self.pers["team"] == "allies") self updateAllowedSingleClientAllies(weaponname);
				else self updateAllowedSingleClientAxis(weaponname);
		}
		else self updateAllowedSingleClient(weaponname);
	}
}

updateAllowedSingleClient(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar(level.weapons[weaponname].client_allowcvar, level.weapons[weaponname].allow);
}

updateAllowedSingleClientAllies(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar(level.weapons[weaponname].client_allowcvar, level.weapons[weaponname].allow_allies);
}

updateAllowedSingleClientAxis(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar(level.weapons[weaponname].client_allowcvar, level.weapons[weaponname].allow_axis);
}

updateDisabledSingleClient(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar(level.weapons[weaponname].client_allowcvar, 0);
}

updateEnabledSingleClient(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar(level.weapons[weaponname].client_allowcvar, 1);
}

createWeaponsArray()
{
	level.weaponnames = [];
	level.weapons = [];

	// default offhand weapons and unfixed mg's
	level.weaponnames[level.weaponnames.size] = "fraggrenade";
	level.weaponnames[level.weaponnames.size] = "smokegrenade";
	level.weaponnames[level.weaponnames.size] = "binoculars_mp";
	level.weaponnames[level.weaponnames.size] = "raygun_mp";
	level.weaponnames[level.weaponnames.size] = "knife_mp";
	level.weaponnames[level.weaponnames.size] = "mobile_30cal";
	level.weaponnames[level.weaponnames.size] = "mobile_mg42";

	level.weapons["fraggrenade"] = spawnstruct();
	level.weapons["fraggrenade"].server_allowcvar = "scr_allow_fraggrenades";
	level.weapons["fraggrenade"].client_allowcvar = "ui_allow_fraggrenades";
	level.weapons["fraggrenade"].allow_default = 1;
	level.weapons["fraggrenade"].classname = "nade";
	level.weapons["fraggrenade"].team = "all";
	level.weapons["fraggrenade"].era = "all";
	level.weapons["fraggrenade"].limit = [[level.ex_drm]]("ex_fraggrenade_limit", 999, 0, 999, "int");
	level.weapons["fraggrenade"].ammo_limit = [[level.ex_drm]]("ex_fraggrenade_ammo_limit", 1, 0, 9, "int");
	level.weapons["fraggrenade"].clip_limit = 9;

	level.weapons["smokegrenade"] = spawnstruct();
	level.weapons["smokegrenade"].server_allowcvar = "scr_allow_smokegrenades";
	level.weapons["smokegrenade"].client_allowcvar = "ui_allow_smokegrenades";
	level.weapons["smokegrenade"].allow_default = 1;
	level.weapons["smokegrenade"].classname = "smoke";
	level.weapons["smokegrenade"].team = "all";
	level.weapons["smokegrenade"].era = "all";
	level.weapons["smokegrenade"].limit = [[level.ex_drm]]("ex_smokegrenade_limit", 999, 0, 999, "int");
	level.weapons["smokegrenade"].ammo_limit = [[level.ex_drm]]("ex_smokegrenade_ammo_limit", 1, 0, 9, "int");
	level.weapons["smokegrenade"].clip_limit = 9;

	level.weapons["binoculars_mp"] = spawnstruct();
	level.weapons["binoculars_mp"].server_allowcvar = "scr_allow_binocular";
	level.weapons["binoculars_mp"].client_allowcvar = "ui_allow_binocular";
	level.weapons["binoculars_mp"].allow_default = 1;
	level.weapons["binoculars_mp"].classname = "binocular";
	level.weapons["binoculars_mp"].team = "all";
	level.weapons["binoculars_mp"].era = "all";
	level.weapons["binoculars_mp"].limit = [[level.ex_drm]]("ex_wmd_binocular_limit", 999, 0, 999, "int");
	level.weapons["binoculars_mp"].ammo_limit = 999;
	level.weapons["binoculars_mp"].clip_limit = 999;

	level.weapons["raygun_mp"] = spawnstruct();
	level.weapons["raygun_mp"].server_allowcvar = "scr_allow_raygun";
	level.weapons["raygun_mp"].client_allowcvar = "ui_allow_raygun";
	level.weapons["raygun_mp"].allow_default = 1;
	level.weapons["raygun_mp"].classname = "pistol";
	level.weapons["raygun_mp"].team = "all";
	level.weapons["raygun_mp"].era = "all";
	level.weapons["raygun_mp"].limit = [[level.ex_drm]]("ex_raygun_limit", 999, 0, 999, "int");
	level.weapons["raygun_mp"].ammo_limit = [[level.ex_drm]]("ex_raygun_ammo_limit", 180, 0, 180, "int");
	level.weapons["raygun_mp"].clip_limit = [[level.ex_drm]]("ex_raygun_clip_limit", 30, 0, 999, "int");

	level.weapons["knife_mp"] = spawnstruct();
	level.weapons["knife_mp"].server_allowcvar = "scr_allow_knife";
	level.weapons["knife_mp"].client_allowcvar = "ui_allow_knife";
	level.weapons["knife_mp"].allow_default = 1;
	level.weapons["knife_mp"].classname = "pistol";
	level.weapons["knife_mp"].team = "all";
	level.weapons["knife_mp"].era = "all";
	level.weapons["knife_mp"].limit = [[level.ex_drm]]("ex_knife_limit", 999, 0, 999, "int");
	if(level.ex_maxammo) level.weapons["knife_mp"].ammo_limit = [[level.ex_drm]]("ex_knife_ammo_limit", 100, 0, 999, "int");
		else level.weapons["knife_mp"].ammo_limit = [[level.ex_drm]]("ex_knife_ammo_limit", 100, 0, 100, "int");
	level.weapons["knife_mp"].clip_limit = [[level.ex_drm]]("ex_knife_clip_limit", 30, 0, 999, "int");

	level.weapons["mobile_30cal"] = spawnstruct();
	level.weapons["mobile_30cal"].server_allowcvar = "scr_allow_mg30cal";
	level.weapons["mobile_30cal"].client_allowcvar = "ui_allow_mg30cal";
	level.weapons["mobile_30cal"].allow_default = 1;
	level.weapons["mobile_30cal"].classname = "mg";
	level.weapons["mobile_30cal"].team = "allies";
	level.weapons["mobile_30cal"].era = "all";
	level.weapons["mobile_30cal"].limit = [[level.ex_drm]]("ex_mg30cal_limit", 999, 0, 999, "int");
	if(level.ex_maxammo) level.weapons["mobile_30cal"].ammo_limit = [[level.ex_drm]]("ex_mg30cal_ammo_limit", 500, 0, 999, "int");
		else level.weapons["mobile_30cal"].ammo_limit = [[level.ex_drm]]("ex_mg30cal_ammo_limit", 500, 0, 500, "int");
	level.weapons["mobile_30cal"].clip_limit = [[level.ex_drm]]("ex_mg30cal_clip_limit", 100, 0, 999, "int");

	level.weapons["mobile_mg42"] = spawnstruct();
	level.weapons["mobile_mg42"].server_allowcvar = "scr_allow_mg42";
	level.weapons["mobile_mg42"].client_allowcvar = "ui_allow_mg42";
	level.weapons["mobile_mg42"].allow_default = 1;
	level.weapons["mobile_mg42"].classname = "mg";
	level.weapons["mobile_mg42"].team = "axis";
	level.weapons["mobile_mg42"].era = "all";
	level.weapons["mobile_mg42"].limit = [[level.ex_drm]]("ex_mg42_limit", 999, 0, 999, "int");
	if(level.ex_maxammo) level.weapons["mobile_mg42"].ammo_limit = [[level.ex_drm]]("ex_mg42_ammo_limit", 500, 0, 999, "int");
		else level.weapons["mobile_mg42"].ammo_limit = [[level.ex_drm]]("ex_mg42_ammo_limit", 500, 0, 500, "int");
	level.weapons["mobile_mg42"].clip_limit = [[level.ex_drm]]("ex_mg42_clip_limit", 100, 0, 999, "int");

	if(!level.ex_modern_weapons)
	{
		// ww2 weapons
		level.weaponnames[level.weaponnames.size] = "bar_mp";
		level.weaponnames[level.weaponnames.size] = "bren_mp";
		level.weaponnames[level.weaponnames.size] = "colt_mp";
		level.weaponnames[level.weaponnames.size] = "enfield_mp";
		level.weaponnames[level.weaponnames.size] = "enfield_scope_2_mp";
		level.weaponnames[level.weaponnames.size] = "enfield_scope_mp";
		level.weaponnames[level.weaponnames.size] = "flamethrower_allies";
		level.weaponnames[level.weaponnames.size] = "flamethrower_axis";
		level.weaponnames[level.weaponnames.size] = "g43_mp";
		level.weaponnames[level.weaponnames.size] = "g43_sniper";
		level.weaponnames[level.weaponnames.size] = "g43_sniper_2";
		level.weaponnames[level.weaponnames.size] = "greasegun_mp";
		level.weaponnames[level.weaponnames.size] = "kar98k_mp";
		level.weaponnames[level.weaponnames.size] = "kar98k_sniper_2_mp";
		level.weaponnames[level.weaponnames.size] = "kar98k_sniper_mp";
		level.weaponnames[level.weaponnames.size] = "luger_mp";
		level.weaponnames[level.weaponnames.size] = "m1carbine_mp";
		level.weaponnames[level.weaponnames.size] = "m1garand_mp";
		level.weaponnames[level.weaponnames.size] = "mosin_nagant_mp";
		level.weaponnames[level.weaponnames.size] = "mosin_nagant_sniper_2_mp";
		level.weaponnames[level.weaponnames.size] = "mosin_nagant_sniper_mp";
		level.weaponnames[level.weaponnames.size] = "mp40_mp";
		level.weaponnames[level.weaponnames.size] = "mp44_mp";
		level.weaponnames[level.weaponnames.size] = "panzerschreck_allies";
		level.weaponnames[level.weaponnames.size] = "panzerschreck_mp";
		level.weaponnames[level.weaponnames.size] = "pps42_mp";
		level.weaponnames[level.weaponnames.size] = "ppsh_mp";
		level.weaponnames[level.weaponnames.size] = "shotgun_mp";
		level.weaponnames[level.weaponnames.size] = "springfield_2_mp";
		level.weaponnames[level.weaponnames.size] = "springfield_mp";
		level.weaponnames[level.weaponnames.size] = "sten_mp";
		level.weaponnames[level.weaponnames.size] = "svt40_mp";
		level.weaponnames[level.weaponnames.size] = "thompson_mp";
		level.weaponnames[level.weaponnames.size] = "tt30_mp";
		level.weaponnames[level.weaponnames.size] = "webley_mp";

		level.weapons["bar_mp"] = spawnstruct();
		level.weapons["bar_mp"].server_allowcvar = "scr_allow_bar";
		level.weapons["bar_mp"].client_allowcvar = "ui_allow_bar";
		level.weapons["bar_mp"].allow_default = 1;
		level.weapons["bar_mp"].classname = "mg";
		level.weapons["bar_mp"].team = "allies";
		level.weapons["bar_mp"].era = "ww2";
		level.weapons["bar_mp"].limit = [[level.ex_drm]]("ex_bar_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["bar_mp"].ammo_limit = [[level.ex_drm]]("ex_bar_ammo_limit", 120, 0, 999, "int");
			else level.weapons["bar_mp"].ammo_limit = [[level.ex_drm]]("ex_bar_ammo_limit", 120, 0, 120, "int");
		level.weapons["bar_mp"].clip_limit = [[level.ex_drm]]("ex_bar_clip_limit", 20, 0, 999, "int");

		level.weapons["bren_mp"] = spawnstruct();
		level.weapons["bren_mp"].server_allowcvar = "scr_allow_bren";
		level.weapons["bren_mp"].client_allowcvar = "ui_allow_bren";
		level.weapons["bren_mp"].allow_default = 1;
		level.weapons["bren_mp"].classname = "mg";
		level.weapons["bren_mp"].team = "allies";
		level.weapons["bren_mp"].era = "ww2";
		level.weapons["bren_mp"].limit = [[level.ex_drm]]("ex_bren_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["bren_mp"].ammo_limit = [[level.ex_drm]]("ex_bren_ammo_limit", 180, 0, 999, "int");
			else level.weapons["bren_mp"].ammo_limit = [[level.ex_drm]]("ex_bren_ammo_limit", 180, 0, 180, "int");
		level.weapons["bren_mp"].clip_limit = [[level.ex_drm]]("ex_bren_clip_limit", 30, 0, 999, "int");

		level.weapons["colt_mp"] = spawnstruct();
		level.weapons["colt_mp"].server_allowcvar = "scr_allow_colt";
		level.weapons["colt_mp"].client_allowcvar = "ui_allow_colt";
		level.weapons["colt_mp"].allow_default = 1;
		level.weapons["colt_mp"].classname = "pistol";
		level.weapons["colt_mp"].team = "allies";
		level.weapons["colt_mp"].era = "all";
		level.weapons["colt_mp"].limit = [[level.ex_drm]]("ex_colt_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["colt_mp"].ammo_limit = [[level.ex_drm]]("ex_colt_ammo_limit", 21, 0, 999, "int");
			else level.weapons["colt_mp"].ammo_limit = [[level.ex_drm]]("ex_colt_ammo_limit", 21, 0, 21, "int");
		level.weapons["colt_mp"].clip_limit = [[level.ex_drm]]("ex_colt_clip_limit", 7, 0, 999, "int");

		level.weapons["enfield_mp"] = spawnstruct();
		level.weapons["enfield_mp"].server_allowcvar = "scr_allow_enfield";
		level.weapons["enfield_mp"].client_allowcvar = "ui_allow_enfield";
		level.weapons["enfield_mp"].allow_default = 1;
		level.weapons["enfield_mp"].classname = "rifle";
		level.weapons["enfield_mp"].team = "allies";
		level.weapons["enfield_mp"].era = "ww2";
		level.weapons["enfield_mp"].limit = [[level.ex_drm]]("ex_enfield_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["enfield_mp"].ammo_limit = [[level.ex_drm]]("ex_enfield_ammo_limit", 60, 0, 999, "int");
			else level.weapons["enfield_mp"].ammo_limit = [[level.ex_drm]]("ex_enfield_ammo_limit", 60, 0, 60, "int");
		level.weapons["enfield_mp"].clip_limit = [[level.ex_drm]]("ex_enfield_clip_limit", 10, 0, 999, "int");

		level.weapons["enfield_scope_mp"] = spawnstruct();
		level.weapons["enfield_scope_mp"].server_allowcvar = "scr_allow_enfieldsniper";
		level.weapons["enfield_scope_mp"].client_allowcvar = "ui_allow_enfieldsniper";
		level.weapons["enfield_scope_mp"].allow_default = 1;
		level.weapons["enfield_scope_mp"].classname = "sniper";
		level.weapons["enfield_scope_mp"].team = "allies";
		level.weapons["enfield_scope_mp"].era = "ww2";
		level.weapons["enfield_scope_mp"].limit = [[level.ex_drm]]("ex_enfield_scope_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["enfield_scope_mp"].ammo_limit = [[level.ex_drm]]("ex_enfield_scope_ammo_limit", 60, 0, 999, "int");
			else level.weapons["enfield_scope_mp"].ammo_limit = [[level.ex_drm]]("ex_enfield_scope_ammo_limit", 60, 0, 60, "int");
		level.weapons["enfield_scope_mp"].clip_limit = [[level.ex_drm]]("ex_enfield_scope_clip_limit", 10, 0, 999, "int");

		level.weapons["enfield_scope_2_mp"] = spawnstruct();
		level.weapons["enfield_scope_2_mp"].server_allowcvar = "scr_allow_enfieldsniper";
		level.weapons["enfield_scope_2_mp"].client_allowcvar = "ui_allow_enfieldsniper";
		level.weapons["enfield_scope_2_mp"].allow_default = 1;
		level.weapons["enfield_scope_2_mp"].classname = "sniperlr";
		level.weapons["enfield_scope_2_mp"].team = "allies";
		level.weapons["enfield_scope_2_mp"].era = "ww2";
		level.weapons["enfield_scope_2_mp"].limit = [[level.ex_drm]]("ex_enfield_scope_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["enfield_scope_2_mp"].ammo_limit = [[level.ex_drm]]("ex_enfield_scope_ammo_limit", 60, 0, 999, "int");
			else level.weapons["enfield_scope_2_mp"].ammo_limit = [[level.ex_drm]]("ex_enfield_scope_ammo_limit", 60, 0, 60, "int");
		level.weapons["enfield_scope_2_mp"].clip_limit = [[level.ex_drm]]("ex_enfield_scope_clip_limit", 10, 0, 999, "int");

		level.weapons["flamethrower_allies"] = spawnstruct();
		level.weapons["flamethrower_allies"].server_allowcvar = "scr_allow_flamethrower";
		level.weapons["flamethrower_allies"].client_allowcvar = "ui_allow_flamethrower";
		level.weapons["flamethrower_allies"].allow_default = 1;
		level.weapons["flamethrower_allies"].classname = "flamethrower";
		level.weapons["flamethrower_allies"].team = "allies";
		level.weapons["flamethrower_allies"].era = "ww2";
		level.weapons["flamethrower_allies"].limit = [[level.ex_drm]]("ex_flamethrower_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["flamethrower_allies"].ammo_limit = [[level.ex_drm]]("ex_flamethrower_ammo_limit", 200, 0, 999, "int");
			else level.weapons["flamethrower_allies"].ammo_limit = [[level.ex_drm]]("ex_flamethrower_ammo_limit", 200, 0, 200, "int");
		level.weapons["flamethrower_allies"].clip_limit = [[level.ex_drm]]("ex_flamethrower_clip_limit", 100, 0, 999, "int");

		level.weapons["flamethrower_axis"] = spawnstruct();
		level.weapons["flamethrower_axis"].server_allowcvar = "scr_allow_flammenwerfer";
		level.weapons["flamethrower_axis"].client_allowcvar = "ui_allow_flammenwerfer";
		level.weapons["flamethrower_axis"].allow_default = 1;
		level.weapons["flamethrower_axis"].classname = "flamethrower";
		level.weapons["flamethrower_axis"].team = "axis";
		level.weapons["flamethrower_axis"].era = "ww2";
		level.weapons["flamethrower_axis"].limit = [[level.ex_drm]]("ex_flammenwerfer_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["flamethrower_axis"].ammo_limit = [[level.ex_drm]]("ex_flammenwerfer_ammo_limit", 200, 0, 999, "int");
			else level.weapons["flamethrower_axis"].ammo_limit = [[level.ex_drm]]("ex_flammenwerfer_ammo_limit", 200, 0, 200, "int");
		level.weapons["flamethrower_axis"].clip_limit = [[level.ex_drm]]("ex_flammenwerfer_clip_limit", 100, 0, 999, "int");

		level.weapons["g43_mp"] = spawnstruct();
		level.weapons["g43_mp"].server_allowcvar = "scr_allow_g43";
		level.weapons["g43_mp"].client_allowcvar = "ui_allow_g43";
		level.weapons["g43_mp"].allow_default = 1;
		level.weapons["g43_mp"].classname = "rifle";
		level.weapons["g43_mp"].team = "axis";
		level.weapons["g43_mp"].era = "ww2";
		level.weapons["g43_mp"].limit = [[level.ex_drm]]("ex_g43_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["g43_mp"].ammo_limit = [[level.ex_drm]]("ex_g43_ammo_limit", 100, 0, 999, "int");
			else level.weapons["g43_mp"].ammo_limit = [[level.ex_drm]]("ex_g43_ammo_limit", 100, 0, 100, "int");
		level.weapons["g43_mp"].clip_limit = [[level.ex_drm]]("ex_g43_clip_limit", 10, 0, 999, "int");

		level.weapons["g43_sniper"] = spawnstruct();
		level.weapons["g43_sniper"].server_allowcvar = "scr_allow_g43sniper";
		level.weapons["g43_sniper"].client_allowcvar = "ui_allow_g43sniper";
		level.weapons["g43_sniper"].allow_default = 1;
		level.weapons["g43_sniper"].classname = "sniper";
		level.weapons["g43_sniper"].team = "axis";
		level.weapons["g43_sniper"].era = "ww2";
		level.weapons["g43_sniper"].limit = [[level.ex_drm]]("ex_g43_sniper_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["g43_sniper"].ammo_limit = [[level.ex_drm]]("ex_g43_sniper_ammo_limit", 100, 0, 999, "int");
			else level.weapons["g43_sniper"].ammo_limit = [[level.ex_drm]]("ex_g43_sniper_ammo_limit", 100, 0, 100, "int");
		level.weapons["g43_sniper"].clip_limit = [[level.ex_drm]]("ex_g43_sniper_clip_limit", 10, 0, 999, "int");

		level.weapons["g43_sniper_2"] = spawnstruct();
		level.weapons["g43_sniper_2"].server_allowcvar = "scr_allow_g43sniper";
		level.weapons["g43_sniper_2"].client_allowcvar = "ui_allow_g43sniper";
		level.weapons["g43_sniper_2"].allow_default = 1;
		level.weapons["g43_sniper_2"].classname = "sniperlr";
		level.weapons["g43_sniper_2"].team = "axis";
		level.weapons["g43_sniper_2"].era = "ww2";
		level.weapons["g43_sniper_2"].limit = [[level.ex_drm]]("ex_g43_sniper_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["g43_sniper_2"].ammo_limit = [[level.ex_drm]]("ex_g43_sniper_ammo_limit", 100, 0, 999, "int");
			else level.weapons["g43_sniper_2"].ammo_limit = [[level.ex_drm]]("ex_g43_sniper_ammo_limit", 100, 0, 100, "int");
		level.weapons["g43_sniper_2"].clip_limit = [[level.ex_drm]]("ex_g43_sniper_clip_limit", 10, 0, 999, "int");

		level.weapons["greasegun_mp"] = spawnstruct();
		level.weapons["greasegun_mp"].server_allowcvar = "scr_allow_greasegun";
		level.weapons["greasegun_mp"].client_allowcvar = "ui_allow_greasegun";
		level.weapons["greasegun_mp"].allow_default = 1;
		level.weapons["greasegun_mp"].classname = "smg";
		level.weapons["greasegun_mp"].team = "allies";
		level.weapons["greasegun_mp"].era = "ww2";
		level.weapons["greasegun_mp"].limit = [[level.ex_drm]]("ex_greasegun_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["greasegun_mp"].ammo_limit = [[level.ex_drm]]("ex_greasegun_ammo_limit", 192, 0, 999, "int");
			else level.weapons["greasegun_mp"].ammo_limit = [[level.ex_drm]]("ex_greasegun_ammo_limit", 192, 0, 192, "int");
		level.weapons["greasegun_mp"].clip_limit = [[level.ex_drm]]("ex_greasegun_clip_limit", 32, 0, 999, "int");

		level.weapons["kar98k_mp"] = spawnstruct();
		level.weapons["kar98k_mp"].server_allowcvar = "scr_allow_kar98k";
		level.weapons["kar98k_mp"].client_allowcvar = "ui_allow_kar98k";
		level.weapons["kar98k_mp"].allow_default = 1;
		level.weapons["kar98k_mp"].classname = "rifle";
		level.weapons["kar98k_mp"].team = "axis";
		level.weapons["kar98k_mp"].era = "ww2";
		level.weapons["kar98k_mp"].limit = [[level.ex_drm]]("ex_kar98k_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["kar98k_mp"].ammo_limit = [[level.ex_drm]]("ex_kar98k_ammo_limit", 60, 0, 999, "int");
			else level.weapons["kar98k_mp"].ammo_limit = [[level.ex_drm]]("ex_kar98k_ammo_limit", 60, 0, 60, "int");
		level.weapons["kar98k_mp"].clip_limit = [[level.ex_drm]]("ex_kar98k_clip_limit", 5, 0, 999, "int");

		level.weapons["kar98k_sniper_mp"] = spawnstruct();
		level.weapons["kar98k_sniper_mp"].server_allowcvar = "scr_allow_kar98ksniper";
		level.weapons["kar98k_sniper_mp"].client_allowcvar = "ui_allow_kar98ksniper";
		level.weapons["kar98k_sniper_mp"].allow_default = 1;
		level.weapons["kar98k_sniper_mp"].classname = "sniper";
		level.weapons["kar98k_sniper_mp"].team = "axis";
		level.weapons["kar98k_sniper_mp"].era = "ww2";
		level.weapons["kar98k_sniper_mp"].limit = [[level.ex_drm]]("ex_kar98k_sniper_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["kar98k_sniper_mp"].ammo_limit = [[level.ex_drm]]("ex_kar98k_sniper_ammo_limit", 60, 0, 999, "int");
			else level.weapons["kar98k_sniper_mp"].ammo_limit = [[level.ex_drm]]("ex_kar98k_sniper_ammo_limit", 60, 0, 60, "int");
		level.weapons["kar98k_sniper_mp"].clip_limit = [[level.ex_drm]]("ex_kar98k_sniper_clip_limit", 5, 0, 999, "int");

		level.weapons["kar98k_sniper_2_mp"] = spawnstruct();
		level.weapons["kar98k_sniper_2_mp"].server_allowcvar = "scr_allow_kar98ksniper";
		level.weapons["kar98k_sniper_2_mp"].client_allowcvar = "ui_allow_kar98ksniper";
		level.weapons["kar98k_sniper_2_mp"].allow_default = 1;
		level.weapons["kar98k_sniper_2_mp"].classname = "sniperlr";
		level.weapons["kar98k_sniper_2_mp"].team = "axis";
		level.weapons["kar98k_sniper_2_mp"].era = "ww2";
		level.weapons["kar98k_sniper_2_mp"].limit = [[level.ex_drm]]("ex_kar98k_sniper_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["kar98k_sniper_2_mp"].ammo_limit = [[level.ex_drm]]("ex_kar98k_sniper_ammo_limit", 60, 0, 999, "int");
			else level.weapons["kar98k_sniper_2_mp"].ammo_limit = [[level.ex_drm]]("ex_kar98k_sniper_ammo_limit", 60, 0, 60, "int");
		level.weapons["kar98k_sniper_2_mp"].clip_limit = [[level.ex_drm]]("ex_kar98k_sniper_clip_limit", 5, 0, 999, "int");

		level.weapons["luger_mp"] = spawnstruct();
		level.weapons["luger_mp"].server_allowcvar = "scr_allow_luger";
		level.weapons["luger_mp"].client_allowcvar = "ui_allow_luger";
		level.weapons["luger_mp"].allow_default = 1;
		level.weapons["luger_mp"].classname = "pistol";
		level.weapons["luger_mp"].team = "axis";
		level.weapons["luger_mp"].era = "all";
		level.weapons["luger_mp"].limit = [[level.ex_drm]]("ex_luger_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["luger_mp"].ammo_limit = [[level.ex_drm]]("ex_luger_ammo_limit", 24, 0, 999, "int");
			else level.weapons["luger_mp"].ammo_limit = [[level.ex_drm]]("ex_luger_ammo_limit", 24, 0, 24, "int");
		level.weapons["luger_mp"].clip_limit = [[level.ex_drm]]("ex_luger_clip_limit", 8, 0, 999, "int");

		level.weapons["m1carbine_mp"] = spawnstruct();
		level.weapons["m1carbine_mp"].server_allowcvar = "scr_allow_m1carbine";
		level.weapons["m1carbine_mp"].client_allowcvar = "ui_allow_m1carbine";
		level.weapons["m1carbine_mp"].allow_default = 1;
		level.weapons["m1carbine_mp"].classname = "rifle";
		level.weapons["m1carbine_mp"].team = "allies";
		level.weapons["m1carbine_mp"].era = "ww2";
		level.weapons["m1carbine_mp"].limit = [[level.ex_drm]]("ex_m1carbine_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m1carbine_mp"].ammo_limit = [[level.ex_drm]]("ex_m1carbine_ammo_limit", 90, 0, 999, "int");
			else level.weapons["m1carbine_mp"].ammo_limit = [[level.ex_drm]]("ex_m1carbine_ammo_limit", 90, 0, 90, "int");
		level.weapons["m1carbine_mp"].clip_limit = [[level.ex_drm]]("ex_m1carbine_clip_limit", 15, 0, 999, "int");

		level.weapons["m1garand_mp"] = spawnstruct();
		level.weapons["m1garand_mp"].server_allowcvar = "scr_allow_m1garand";
		level.weapons["m1garand_mp"].client_allowcvar = "ui_allow_m1garand";
		level.weapons["m1garand_mp"].allow_default = 1;
		level.weapons["m1garand_mp"].classname = "rifle";
		level.weapons["m1garand_mp"].team = "allies";
		level.weapons["m1garand_mp"].era = "ww2";
		level.weapons["m1garand_mp"].limit = [[level.ex_drm]]("ex_m1garand_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m1garand_mp"].ammo_limit = [[level.ex_drm]]("ex_m1garand_ammo_limit", 96, 0, 999, "int");
			else level.weapons["m1garand_mp"].ammo_limit = [[level.ex_drm]]("ex_m1garand_ammo_limit", 96, 0, 96, "int");
		level.weapons["m1garand_mp"].clip_limit = [[level.ex_drm]]("ex_m1garand_clip_limit", 8, 0, 999, "int");

		level.weapons["mosin_nagant_mp"] = spawnstruct();
		level.weapons["mosin_nagant_mp"].server_allowcvar = "scr_allow_nagant";
		level.weapons["mosin_nagant_mp"].client_allowcvar = "ui_allow_nagant";
		level.weapons["mosin_nagant_mp"].allow_default = 1;
		level.weapons["mosin_nagant_mp"].classname = "rifle";
		level.weapons["mosin_nagant_mp"].team = "allies";
		level.weapons["mosin_nagant_mp"].era = "ww2";
		level.weapons["mosin_nagant_mp"].limit = [[level.ex_drm]]("ex_mosin_nagant_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mosin_nagant_mp"].ammo_limit = [[level.ex_drm]]("ex_mosin_nagant_ammo_limit", 60, 0, 999, "int");
			else level.weapons["mosin_nagant_mp"].ammo_limit = [[level.ex_drm]]("ex_mosin_nagant_ammo_limit", 60, 0, 60, "int");
		level.weapons["mosin_nagant_mp"].clip_limit = [[level.ex_drm]]("ex_mosin_nagant_clip_limit", 5, 0, 999, "int");

		level.weapons["mosin_nagant_sniper_mp"] = spawnstruct();
		level.weapons["mosin_nagant_sniper_mp"].server_allowcvar = "scr_allow_nagantsniper";
		level.weapons["mosin_nagant_sniper_mp"].client_allowcvar = "ui_allow_nagantsniper";
		level.weapons["mosin_nagant_sniper_mp"].allow_default = 1;
		level.weapons["mosin_nagant_sniper_mp"].classname = "sniper";
		level.weapons["mosin_nagant_sniper_mp"].team = "allies";
		level.weapons["mosin_nagant_sniper_mp"].era = "ww2";
		level.weapons["mosin_nagant_sniper_mp"].limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mosin_nagant_sniper_mp"].ammo_limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_ammo_limit", 60, 0, 999, "int");
			else level.weapons["mosin_nagant_sniper_mp"].ammo_limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_ammo_limit", 60, 0, 60, "int");
		level.weapons["mosin_nagant_sniper_mp"].clip_limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_clip_limit", 5, 0, 999, "int");

		level.weapons["mosin_nagant_sniper_2_mp"] = spawnstruct();
		level.weapons["mosin_nagant_sniper_2_mp"].server_allowcvar = "scr_allow_nagantsniper";
		level.weapons["mosin_nagant_sniper_2_mp"].client_allowcvar = "ui_allow_nagantsniper";
		level.weapons["mosin_nagant_sniper_2_mp"].allow_default = 1;
		level.weapons["mosin_nagant_sniper_2_mp"].classname = "sniperlr";
		level.weapons["mosin_nagant_sniper_2_mp"].team = "allies";
		level.weapons["mosin_nagant_sniper_2_mp"].era = "ww2";
		level.weapons["mosin_nagant_sniper_2_mp"].limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mosin_nagant_sniper_2_mp"].ammo_limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_ammo_limit", 60, 0, 999, "int");
			else level.weapons["mosin_nagant_sniper_2_mp"].ammo_limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_ammo_limit", 60, 0, 60, "int");
		level.weapons["mosin_nagant_sniper_2_mp"].clip_limit = [[level.ex_drm]]("ex_mosin_nagant_sniper_clip_limit", 5, 0, 999, "int");

		level.weapons["mp40_mp"] = spawnstruct();
		level.weapons["mp40_mp"].server_allowcvar = "scr_allow_mp40";
		level.weapons["mp40_mp"].client_allowcvar = "ui_allow_mp40";
		level.weapons["mp40_mp"].allow_default = 1;
		level.weapons["mp40_mp"].classname = "smg";
		level.weapons["mp40_mp"].team = "axis";
		level.weapons["mp40_mp"].era = "ww2";
		level.weapons["mp40_mp"].limit = [[level.ex_drm]]("ex_mp40_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mp40_mp"].ammo_limit = [[level.ex_drm]]("ex_mp40_ammo_limit", 192, 0, 999, "int");
			else level.weapons["mp40_mp"].ammo_limit = [[level.ex_drm]]("ex_mp40_ammo_limit", 192, 0, 192, "int");
		level.weapons["mp40_mp"].clip_limit = [[level.ex_drm]]("ex_mp40_clip_limit", 32, 0, 999, "int");

		level.weapons["mp44_mp"] = spawnstruct();
		level.weapons["mp44_mp"].server_allowcvar = "scr_allow_mp44";
		level.weapons["mp44_mp"].client_allowcvar = "ui_allow_mp44";
		level.weapons["mp44_mp"].allow_default = 1;
		level.weapons["mp44_mp"].classname = "mg";
		level.weapons["mp44_mp"].team = "axis";
		level.weapons["mp44_mp"].era = "ww2";
		level.weapons["mp44_mp"].limit = [[level.ex_drm]]("ex_mp44_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mp44_mp"].ammo_limit = [[level.ex_drm]]("ex_mp44_ammo_limit", 180, 0, 999, "int");
			else level.weapons["mp44_mp"].ammo_limit = [[level.ex_drm]]("ex_mp44_ammo_limit", 180, 0, 180, "int");
		level.weapons["mp44_mp"].clip_limit = [[level.ex_drm]]("ex_mp44_clip_limit", 30, 0, 999, "int");

		level.weapons["panzerschreck_allies"] = spawnstruct();
		level.weapons["panzerschreck_allies"].server_allowcvar = "scr_allow_bazooka";
		level.weapons["panzerschreck_allies"].client_allowcvar = "ui_allow_bazooka";
		level.weapons["panzerschreck_allies"].allow_default = 1;
		level.weapons["panzerschreck_allies"].classname = "rl";
		level.weapons["panzerschreck_allies"].team = "allies";
		level.weapons["panzerschreck_allies"].era = "ww2";
		level.weapons["panzerschreck_allies"].limit = [[level.ex_drm]]("ex_bazooka_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["panzerschreck_allies"].ammo_limit = [[level.ex_drm]]("ex_bazooka_ammo_limit", 10, 0, 999, "int");
			else level.weapons["panzerschreck_allies"].ammo_limit = [[level.ex_drm]]("ex_bazooka_ammo_limit", 10, 0, 10, "int");
		level.weapons["panzerschreck_allies"].clip_limit = [[level.ex_drm]]("ex_bazooka_clip_limit", 1, 0, 999, "int");

		level.weapons["panzerschreck_mp"] = spawnstruct();
		level.weapons["panzerschreck_mp"].server_allowcvar = "scr_allow_panzerschreck";
		level.weapons["panzerschreck_mp"].client_allowcvar = "ui_allow_panzerschreck";
		level.weapons["panzerschreck_mp"].allow_default = 1;
		level.weapons["panzerschreck_mp"].classname = "rl";
		level.weapons["panzerschreck_mp"].team = "axis";
		level.weapons["panzerschreck_mp"].era = "ww2";
		level.weapons["panzerschreck_mp"].limit = [[level.ex_drm]]("ex_panzer_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["panzerschreck_mp"].ammo_limit = [[level.ex_drm]]("ex_panzer_ammo_limit", 10, 0, 999, "int");
			else level.weapons["panzerschreck_mp"].ammo_limit = [[level.ex_drm]]("ex_panzer_ammo_limit", 10, 0, 10, "int");
		level.weapons["panzerschreck_mp"].clip_limit = [[level.ex_drm]]("ex_panzer_clip_limit", 1, 0, 999, "int");

		level.weapons["ppsh_mp"] = spawnstruct();
		level.weapons["ppsh_mp"].server_allowcvar = "scr_allow_ppsh";
		level.weapons["ppsh_mp"].client_allowcvar = "ui_allow_ppsh";
		level.weapons["ppsh_mp"].allow_default = 1;
		level.weapons["ppsh_mp"].classname = "mg";
		level.weapons["ppsh_mp"].team = "allies";
		level.weapons["ppsh_mp"].era = "ww2";
		level.weapons["ppsh_mp"].limit = [[level.ex_drm]]("ex_ppsh_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["ppsh_mp"].ammo_limit = [[level.ex_drm]]("ex_ppsh_ammo_limit", 213, 0, 999, "int");
			else level.weapons["ppsh_mp"].ammo_limit = [[level.ex_drm]]("ex_ppsh_ammo_limit", 213, 0, 213, "int");
		level.weapons["ppsh_mp"].clip_limit = [[level.ex_drm]]("ex_ppsh_clip_limit", 71, 0, 999, "int");

		level.weapons["pps42_mp"] = spawnstruct();
		level.weapons["pps42_mp"].server_allowcvar = "scr_allow_pps42";
		level.weapons["pps42_mp"].client_allowcvar = "ui_allow_pps42";
		level.weapons["pps42_mp"].allow_default = 1;
		level.weapons["pps42_mp"].classname = "smg";
		level.weapons["pps42_mp"].team = "allies";
		level.weapons["pps42_mp"].era = "ww2";
		level.weapons["pps42_mp"].limit = [[level.ex_drm]]("ex_pps42_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["pps42_mp"].ammo_limit = [[level.ex_drm]]("ex_pps42_ammo_limit", 210, 0, 999, "int");
			else level.weapons["pps42_mp"].ammo_limit = [[level.ex_drm]]("ex_pps42_ammo_limit", 210, 0, 210, "int");
		level.weapons["pps42_mp"].clip_limit = [[level.ex_drm]]("ex_pps42_clip_limit", 35, 0, 999, "int");

		level.weapons["shotgun_mp"] = spawnstruct();
		level.weapons["shotgun_mp"].server_allowcvar = "scr_allow_shotgun";
		level.weapons["shotgun_mp"].client_allowcvar = "ui_allow_shotgun";
		level.weapons["shotgun_mp"].allow_default = 1;
		level.weapons["shotgun_mp"].classname = "shotgun";
		level.weapons["shotgun_mp"].team = "all";
		level.weapons["shotgun_mp"].era = "ww2";
		level.weapons["shotgun_mp"].limit = [[level.ex_drm]]("ex_shotgun_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["shotgun_mp"].ammo_limit = [[level.ex_drm]]("ex_shotgun_ammo_limit", 60, 0, 999, "int");
			else level.weapons["shotgun_mp"].ammo_limit = [[level.ex_drm]]("ex_shotgun_ammo_limit", 60, 0, 60, "int");
		level.weapons["shotgun_mp"].clip_limit = [[level.ex_drm]]("ex_shotgun_clip_limit", 6, 0, 999, "int");

		level.weapons["springfield_mp"] = spawnstruct();
		level.weapons["springfield_mp"].server_allowcvar = "scr_allow_springfield";
		level.weapons["springfield_mp"].client_allowcvar = "ui_allow_springfield";
		level.weapons["springfield_mp"].allow_default = 1;
		level.weapons["springfield_mp"].classname = "sniper";
		level.weapons["springfield_mp"].team = "allies";
		level.weapons["springfield_mp"].era = "ww2";
		level.weapons["springfield_mp"].limit = [[level.ex_drm]]("ex_springfield_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["springfield_mp"].ammo_limit = [[level.ex_drm]]("ex_springfield_ammo_limit", 60, 0, 999, "int");
			else level.weapons["springfield_mp"].ammo_limit = [[level.ex_drm]]("ex_springfield_ammo_limit", 60, 0, 60, "int");
		level.weapons["springfield_mp"].clip_limit = [[level.ex_drm]]("ex_springfield_clip_limit", 5, 0, 999, "int");

		level.weapons["springfield_2_mp"] = spawnstruct();
		level.weapons["springfield_2_mp"].server_allowcvar = "scr_allow_springfield";
		level.weapons["springfield_2_mp"].client_allowcvar = "ui_allow_springfield";
		level.weapons["springfield_2_mp"].allow_default = 1;
		level.weapons["springfield_2_mp"].classname = "sniperlr";
		level.weapons["springfield_2_mp"].team = "allies";
		level.weapons["springfield_2_mp"].era = "ww2";
		level.weapons["springfield_2_mp"].limit = [[level.ex_drm]]("ex_springfield_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["springfield_2_mp"].ammo_limit = [[level.ex_drm]]("ex_springfield_ammo_limit", 60, 0, 999, "int");
			else level.weapons["springfield_2_mp"].ammo_limit = [[level.ex_drm]]("ex_springfield_ammo_limit", 60, 0, 60, "int");
		level.weapons["springfield_2_mp"].clip_limit = [[level.ex_drm]]("ex_springfield_clip_limit", 5, 0, 999, "int");

		level.weapons["sten_mp"] = spawnstruct();
		level.weapons["sten_mp"].server_allowcvar = "scr_allow_sten";
		level.weapons["sten_mp"].client_allowcvar = "ui_allow_sten";
		level.weapons["sten_mp"].allow_default = 1;
		level.weapons["sten_mp"].classname = "smg";
		level.weapons["sten_mp"].team = "allies";
		level.weapons["sten_mp"].era = "ww2";
		level.weapons["sten_mp"].limit = [[level.ex_drm]]("ex_sten_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["sten_mp"].ammo_limit = [[level.ex_drm]]("ex_sten_ammo_limit", 192, 0, 999, "int");
			else level.weapons["sten_mp"].ammo_limit = [[level.ex_drm]]("ex_sten_ammo_limit", 192, 0, 192, "int");
		level.weapons["sten_mp"].clip_limit = [[level.ex_drm]]("ex_sten_clip_limit", 32, 0, 999, "int");

		level.weapons["svt40_mp"] = spawnstruct();
		level.weapons["svt40_mp"].server_allowcvar = "scr_allow_svt40";
		level.weapons["svt40_mp"].client_allowcvar = "ui_allow_svt40";
		level.weapons["svt40_mp"].allow_default = 1;
		level.weapons["svt40_mp"].classname = "rifle";
		level.weapons["svt40_mp"].team = "allies";
		level.weapons["svt40_mp"].era = "ww2";
		level.weapons["svt40_mp"].limit = [[level.ex_drm]]("ex_svt40_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["svt40_mp"].ammo_limit = [[level.ex_drm]]("ex_svt40_ammo_limit", 100, 0, 999, "int");
			else level.weapons["svt40_mp"].ammo_limit = [[level.ex_drm]]("ex_svt40_ammo_limit", 100, 0, 100, "int");
		level.weapons["svt40_mp"].clip_limit = [[level.ex_drm]]("ex_svt40_clip_limit", 10, 0, 999, "int");

		level.weapons["thompson_mp"] = spawnstruct();
		level.weapons["thompson_mp"].server_allowcvar = "scr_allow_thompson";
		level.weapons["thompson_mp"].client_allowcvar = "ui_allow_thompson";
		level.weapons["thompson_mp"].allow_default = 1;
		level.weapons["thompson_mp"].classname = "smg";
		level.weapons["thompson_mp"].team = "allies";
		level.weapons["thompson_mp"].era = "ww2";
		level.weapons["thompson_mp"].limit = [[level.ex_drm]]("ex_thompson_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["thompson_mp"].ammo_limit = [[level.ex_drm]]("ex_thompson_ammo_limit", 180, 0, 999, "int");
			else level.weapons["thompson_mp"].ammo_limit = [[level.ex_drm]]("ex_thompson_ammo_limit", 180, 0, 180, "int");
		level.weapons["thompson_mp"].clip_limit = [[level.ex_drm]]("ex_thompson_clip_limit", 30, 0, 999, "int");

		level.weapons["tt30_mp"] = spawnstruct();
		level.weapons["tt30_mp"].server_allowcvar = "scr_allow_tt30";
		level.weapons["tt30_mp"].client_allowcvar = "ui_allow_tt30";
		level.weapons["tt30_mp"].allow_default = 1;
		level.weapons["tt30_mp"].classname = "pistol";
		level.weapons["tt30_mp"].team = "allies";
		level.weapons["tt30_mp"].era = "all";
		level.weapons["tt30_mp"].limit = [[level.ex_drm]]("ex_tt30_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["tt30_mp"].ammo_limit = [[level.ex_drm]]("ex_tt30_ammo_limit", 24, 0, 999, "int");
			else level.weapons["tt30_mp"].ammo_limit = [[level.ex_drm]]("ex_tt30_ammo_limit", 24, 0, 24, "int");
		level.weapons["tt30_mp"].clip_limit = [[level.ex_drm]]("ex_tt30_clip_limit", 8, 0, 999, "int");

		level.weapons["webley_mp"] = spawnstruct();
		level.weapons["webley_mp"].server_allowcvar = "scr_allow_webley";
		level.weapons["webley_mp"].client_allowcvar = "ui_allow_webley";
		level.weapons["webley_mp"].allow_default = 1;
		level.weapons["webley_mp"].classname = "pistol";
		level.weapons["webley_mp"].team = "allies";
		level.weapons["webley_mp"].era = "all";
		level.weapons["webley_mp"].limit = [[level.ex_drm]]("ex_webley_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["webley_mp"].ammo_limit = [[level.ex_drm]]("ex_webley_ammo_limit", 18, 0, 999, "int");
			else level.weapons["webley_mp"].ammo_limit = [[level.ex_drm]]("ex_webley_ammo_limit", 18, 0, 18, "int");
		level.weapons["webley_mp"].clip_limit = [[level.ex_drm]]("ex_webley_clip_limit", 6, 0, 999, "int");
	}
	else
	{
		// modern weapons
		level.weaponnames[level.weaponnames.size] = "ak_47_mp";
		level.weaponnames[level.weaponnames.size] = "ak_74_mp";
		level.weaponnames[level.weaponnames.size] = "ar_10_mp";
		level.weaponnames[level.weaponnames.size] = "ar_10_2_mp";
		level.weaponnames[level.weaponnames.size] = "aug_a3_mp";
		level.weaponnames[level.weaponnames.size] = "barrett_mp";
		level.weaponnames[level.weaponnames.size] = "barrett_2_mp";
		level.weaponnames[level.weaponnames.size] = "beretta_mp";
		level.weaponnames[level.weaponnames.size] = "deagle_mp";
		level.weaponnames[level.weaponnames.size] = "dragunov_mp";
		level.weaponnames[level.weaponnames.size] = "dragunov_2_mp";
		level.weaponnames[level.weaponnames.size] = "famas_mp";
		level.weaponnames[level.weaponnames.size] = "glock_mp";
		level.weaponnames[level.weaponnames.size] = "hk_g36_mp";
		level.weaponnames[level.weaponnames.size] = "hk45_mp";
		level.weaponnames[level.weaponnames.size] = "m249_mp";
		level.weaponnames[level.weaponnames.size] = "m40a3_mp";
		level.weaponnames[level.weaponnames.size] = "m40a3_2_mp";
 		level.weaponnames[level.weaponnames.size] = "m4a1_mp";
		level.weaponnames[level.weaponnames.size] = "m60_mp";
		level.weaponnames[level.weaponnames.size] = "mac10_mp";
		level.weaponnames[level.weaponnames.size] = "mp5_mp";
		level.weaponnames[level.weaponnames.size] = "mp5a4_mp";
		level.weaponnames[level.weaponnames.size] = "p90_mp";
		level.weaponnames[level.weaponnames.size] = "rpg_mp";
		level.weaponnames[level.weaponnames.size] = "sig_552_mp";
		level.weaponnames[level.weaponnames.size] = "spas_12_mp";
		level.weaponnames[level.weaponnames.size] = "tmp_mp";
		level.weaponnames[level.weaponnames.size] = "ump45_mp";
		level.weaponnames[level.weaponnames.size] = "uzi_mp";
		level.weaponnames[level.weaponnames.size] = "xm1014_mp";

		level.weapons["ak_47_mp"] = spawnstruct();
		level.weapons["ak_47_mp"].server_allowcvar = "scr_allow_ak_47";
		level.weapons["ak_47_mp"].client_allowcvar = "ui_allow_ak_47";
		level.weapons["ak_47_mp"].allow_default = 1;
		level.weapons["ak_47_mp"].classname = "mg";
		level.weapons["ak_47_mp"].team = "all";
		level.weapons["ak_47_mp"].era = "modern";
		level.weapons["ak_47_mp"].limit = [[level.ex_drm]]("ex_ak_47_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["ak_47_mp"].ammo_limit = [[level.ex_drm]]("ex_ak_47_ammo_limit", 300, 0, 999, "int");
			else level.weapons["ak_47_mp"].ammo_limit = [[level.ex_drm]]("ex_ak_47_ammo_limit", 300, 0, 300, "int");
		level.weapons["ak_47_mp"].clip_limit = [[level.ex_drm]]("ex_ak_47_clip_limit", 30, 0, 999, "int");

		level.weapons["ak_74_mp"] = spawnstruct();
		level.weapons["ak_74_mp"].server_allowcvar = "scr_allow_ak_74";
		level.weapons["ak_74_mp"].client_allowcvar = "ui_allow_ak_74";
		level.weapons["ak_74_mp"].allow_default = 1;
		level.weapons["ak_74_mp"].classname = "mg";
		level.weapons["ak_74_mp"].team = "all";
		level.weapons["ak_74_mp"].era = "modern";
		level.weapons["ak_74_mp"].limit = [[level.ex_drm]]("ex_ak_74_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["ak_74_mp"].ammo_limit = [[level.ex_drm]]("ex_ak_74_ammo_limit", 300, 0, 999, "int");
			else level.weapons["ak_74_mp"].ammo_limit = [[level.ex_drm]]("ex_ak_74_ammo_limit", 300, 0, 300, "int");
		level.weapons["ak_74_mp"].clip_limit = [[level.ex_drm]]("ex_ak_74_clip_limit", 30, 0, 999, "int");

		level.weapons["ar_10_mp"] = spawnstruct();
		level.weapons["ar_10_mp"].server_allowcvar = "scr_allow_ar_10";
		level.weapons["ar_10_mp"].client_allowcvar = "ui_allow_ar_10";
		level.weapons["ar_10_mp"].allow_default = 1;
		level.weapons["ar_10_mp"].classname = "sniper";
		level.weapons["ar_10_mp"].team = "all";
		level.weapons["ar_10_mp"].era = "modern";
		level.weapons["ar_10_mp"].limit = [[level.ex_drm]]("ex_ar_10_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["ar_10_mp"].ammo_limit = [[level.ex_drm]]("ex_ar_10_ammo_limit", 60, 0, 999, "int");
			else level.weapons["ar_10_mp"].ammo_limit = [[level.ex_drm]]("ex_ar_10_ammo_limit", 60, 0, 60, "int");
		level.weapons["ar_10_mp"].clip_limit = [[level.ex_drm]]("ex_ar_10_clip_limit", 20, 0, 999, "int");
		
		level.weapons["ar_10_2_mp"] = spawnstruct();
		level.weapons["ar_10_2_mp"].server_allowcvar = "scr_allow_ar_10";
		level.weapons["ar_10_2_mp"].client_allowcvar = "ui_allow_ar_10";
		level.weapons["ar_10_2_mp"].allow_default = 1;
		level.weapons["ar_10_2_mp"].classname = "sniperlr";
		level.weapons["ar_10_2_mp"].team = "all";
		level.weapons["ar_10_2_mp"].era = "modern";
		level.weapons["ar_10_2_mp"].limit = [[level.ex_drm]]("ex_ar_10_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["ar_10_2_mp"].ammo_limit = [[level.ex_drm]]("ex_ar_10_ammo_limit", 60, 0, 999, "int");
			else level.weapons["ar_10_2_mp"].ammo_limit = [[level.ex_drm]]("ex_ar_10_ammo_limit", 60, 0, 60, "int");
		level.weapons["ar_10_2_mp"].clip_limit = [[level.ex_drm]]("ex_ar_10_clip_limit", 20, 0, 999, "int");

		level.weapons["aug_a3_mp"] = spawnstruct();
		level.weapons["aug_a3_mp"].server_allowcvar = "scr_allow_aug_a3";
		level.weapons["aug_a3_mp"].client_allowcvar = "ui_allow_aug_a3";
		level.weapons["aug_a3_mp"].allow_default = 1;
		level.weapons["aug_a3_mp"].classname = "mg";
		level.weapons["aug_a3_mp"].team = "all";
		level.weapons["aug_a3_mp"].era = "modern";
		level.weapons["aug_a3_mp"].limit = [[level.ex_drm]]("ex_aug_a3_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["aug_a3_mp"].ammo_limit = [[level.ex_drm]]("ex_aug_a3_ammo_limit", 300, 0, 999, "int");
			else level.weapons["aug_a3_mp"].ammo_limit = [[level.ex_drm]]("ex_aug_a3_ammo_limit", 300, 0, 300, "int");
		level.weapons["aug_a3_mp"].clip_limit = [[level.ex_drm]]("ex_aug_a3_clip_limit", 30, 0, 999, "int");

		level.weapons["barrett_mp"] = spawnstruct();
		level.weapons["barrett_mp"].server_allowcvar = "scr_allow_barrett";
		level.weapons["barrett_mp"].client_allowcvar = "ui_allow_barrett";
		level.weapons["barrett_mp"].allow_default = 1;
		level.weapons["barrett_mp"].classname = "sniper";
		level.weapons["barrett_mp"].team = "all";
		level.weapons["barrett_mp"].era = "modern";
		level.weapons["barrett_mp"].limit = [[level.ex_drm]]("ex_barrett_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["barrett_mp"].ammo_limit = [[level.ex_drm]]("ex_barrett_ammo_limit", 60, 0, 999, "int");
			else level.weapons["barrett_mp"].ammo_limit = [[level.ex_drm]]("ex_barrett_ammo_limit", 60, 0, 60, "int");
		level.weapons["barrett_mp"].clip_limit = [[level.ex_drm]]("ex_barrett_clip_limit", 10, 0, 999, "int");
		
		level.weapons["barrett_2_mp"] = spawnstruct();
		level.weapons["barrett_2_mp"].server_allowcvar = "scr_allow_barrett";
		level.weapons["barrett_2_mp"].client_allowcvar = "ui_allow_barrett";
		level.weapons["barrett_2_mp"].allow_default = 1;
		level.weapons["barrett_2_mp"].classname = "sniperlr";
		level.weapons["barrett_2_mp"].team = "all";
		level.weapons["barrett_2_mp"].era = "modern";
		level.weapons["barrett_2_mp"].limit = [[level.ex_drm]]("ex_barrett_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["barrett_2_mp"].ammo_limit = [[level.ex_drm]]("ex_barrett_ammo_limit", 60, 0, 999, "int");
			else level.weapons["barrett_2_mp"].ammo_limit = [[level.ex_drm]]("ex_barrett_ammo_limit", 60, 0, 60, "int");
		level.weapons["barrett_2_mp"].clip_limit = [[level.ex_drm]]("ex_barrett_clip_limit", 10, 0, 999, "int");

		level.weapons["beretta_mp"] = spawnstruct();
		level.weapons["beretta_mp"].server_allowcvar = "scr_allow_beretta";
		level.weapons["beretta_mp"].client_allowcvar = "ui_allow_beretta";
		level.weapons["beretta_mp"].allow_default = 1;
		level.weapons["beretta_mp"].classname = "pistol";
		level.weapons["beretta_mp"].team = "all";
		level.weapons["beretta_mp"].era = "modern";
		level.weapons["beretta_mp"].limit = [[level.ex_drm]]("ex_beretta_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["beretta_mp"].ammo_limit = [[level.ex_drm]]("ex_beretta_ammo_limit", 60, 0, 999, "int");
			else level.weapons["beretta_mp"].ammo_limit = [[level.ex_drm]]("ex_beretta_ammo_limit", 60, 0, 60, "int");
		level.weapons["beretta_mp"].clip_limit = [[level.ex_drm]]("ex_beretta_clip_limit", 15, 0, 999, "int");

		level.weapons["deagle_mp"] = spawnstruct();
		level.weapons["deagle_mp"].server_allowcvar = "scr_allow_deagle";
		level.weapons["deagle_mp"].client_allowcvar = "ui_allow_deagle";
		level.weapons["deagle_mp"].allow_default = 1;
		level.weapons["deagle_mp"].classname = "pistol";
		level.weapons["deagle_mp"].team = "all";
		level.weapons["deagle_mp"].era = "modern";
		level.weapons["deagle_mp"].limit = [[level.ex_drm]]("ex_deagle_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["deagle_mp"].ammo_limit = [[level.ex_drm]]("ex_deagle_ammo_limit", 60, 0, 999, "int");
			else level.weapons["deagle_mp"].ammo_limit = [[level.ex_drm]]("ex_deagle_ammo_limit", 60, 0, 60, "int");
		level.weapons["deagle_mp"].clip_limit = [[level.ex_drm]]("ex_deagle_clip_limit", 10, 0, 999, "int");

		level.weapons["dragunov_mp"] = spawnstruct();
		level.weapons["dragunov_mp"].server_allowcvar = "scr_allow_dragunov";
		level.weapons["dragunov_mp"].client_allowcvar = "ui_allow_dragunov";
		level.weapons["dragunov_mp"].allow_default = 1;
		level.weapons["dragunov_mp"].classname = "sniper";
		level.weapons["dragunov_mp"].team = "all";
		level.weapons["dragunov_mp"].era = "modern";
		level.weapons["dragunov_mp"].limit = [[level.ex_drm]]("ex_dragunov_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["dragunov_mp"].ammo_limit = [[level.ex_drm]]("ex_dragunov_ammo_limit", 60, 0, 999, "int");
			else level.weapons["dragunov_mp"].ammo_limit = [[level.ex_drm]]("ex_dragunov_ammo_limit", 60, 0, 60, "int");
		level.weapons["dragunov_mp"].clip_limit = [[level.ex_drm]]("ex_dragunov_clip_limit", 10, 0, 999, "int");
		
		level.weapons["dragunov_2_mp"] = spawnstruct();
		level.weapons["dragunov_2_mp"].server_allowcvar = "scr_allow_dragunov";
		level.weapons["dragunov_2_mp"].client_allowcvar = "ui_allow_dragunov";
		level.weapons["dragunov_2_mp"].allow_default = 1;
		level.weapons["dragunov_2_mp"].classname = "sniperlr";
		level.weapons["dragunov_2_mp"].team = "all";
		level.weapons["dragunov_2_mp"].era = "modern";
		level.weapons["dragunov_2_mp"].limit = [[level.ex_drm]]("ex_dragunov_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["dragunov_2_mp"].ammo_limit = [[level.ex_drm]]("ex_dragunov_ammo_limit", 60, 0, 999, "int");
			else level.weapons["dragunov_2_mp"].ammo_limit = [[level.ex_drm]]("ex_dragunov_ammo_limit", 60, 0, 60, "int");
		level.weapons["dragunov_2_mp"].clip_limit = [[level.ex_drm]]("ex_dragunov_clip_limit", 10, 0, 999, "int");

		level.weapons["famas_mp"] = spawnstruct();
		level.weapons["famas_mp"].server_allowcvar = "scr_allow_famas";
		level.weapons["famas_mp"].client_allowcvar = "ui_allow_famas";
		level.weapons["famas_mp"].allow_default = 1;
		level.weapons["famas_mp"].classname = "mg";
		level.weapons["famas_mp"].team = "all";
		level.weapons["famas_mp"].era = "modern";
		level.weapons["famas_mp"].limit = [[level.ex_drm]]("ex_famas_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["famas_mp"].ammo_limit = [[level.ex_drm]]("ex_famas_ammo_limit", 300, 0, 999, "int");
			else level.weapons["famas_mp"].ammo_limit = [[level.ex_drm]]("ex_famas_ammo_limit", 300, 0, 300, "int");
		level.weapons["famas_mp"].clip_limit = [[level.ex_drm]]("ex_famas_clip_limit", 30, 0, 999, "int");

		level.weapons["glock_mp"] = spawnstruct();
		level.weapons["glock_mp"].server_allowcvar = "scr_allow_glock";
		level.weapons["glock_mp"].client_allowcvar = "ui_allow_glock";
		level.weapons["glock_mp"].allow_default = 1;
		level.weapons["glock_mp"].classname = "pistol";
		level.weapons["glock_mp"].team = "all";
		level.weapons["glock_mp"].era = "modern";
		level.weapons["glock_mp"].limit = [[level.ex_drm]]("ex_glock_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["glock_mp"].ammo_limit = [[level.ex_drm]]("ex_glock_ammo_limit", 60, 0, 999, "int");
			else level.weapons["glock_mp"].ammo_limit = [[level.ex_drm]]("ex_glock_ammo_limit", 60, 0, 60, "int");
		level.weapons["glock_mp"].clip_limit = [[level.ex_drm]]("ex_glock_clip_limit", 15, 0, 999, "int");

		level.weapons["hk_g36_mp"] = spawnstruct();
		level.weapons["hk_g36_mp"].server_allowcvar = "scr_allow_hk_g36";
		level.weapons["hk_g36_mp"].client_allowcvar = "ui_allow_hk_g36";
		level.weapons["hk_g36_mp"].allow_default = 1;
		level.weapons["hk_g36_mp"].classname = "smg";
		level.weapons["hk_g36_mp"].team = "all";
		level.weapons["hk_g36_mp"].era = "modern";
		level.weapons["hk_g36_mp"].limit = [[level.ex_drm]]("ex_hk_g36_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["hk_g36_mp"].ammo_limit = [[level.ex_drm]]("ex_hk_g36_ammo_limit", 300, 0, 999, "int");
			else level.weapons["hk_g36_mp"].ammo_limit = [[level.ex_drm]]("ex_hk_g36_ammo_limit", 300, 0, 300, "int");
		level.weapons["hk_g36_mp"].clip_limit = [[level.ex_drm]]("ex_hk_g36_clip_limit", 30, 0, 999, "int");

		level.weapons["hk45_mp"] = spawnstruct();
		level.weapons["hk45_mp"].server_allowcvar = "scr_allow_hk45";
		level.weapons["hk45_mp"].client_allowcvar = "ui_allow_hk45";
		level.weapons["hk45_mp"].allow_default = 1;
		level.weapons["hk45_mp"].classname = "pistol";
		level.weapons["hk45_mp"].team = "all";
		level.weapons["hk45_mp"].era = "modern";
		level.weapons["hk45_mp"].limit = [[level.ex_drm]]("ex_hk45_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["hk45_mp"].ammo_limit = [[level.ex_drm]]("ex_hk45_ammo_limit", 60, 0, 999, "int");
			else level.weapons["hk45_mp"].ammo_limit = [[level.ex_drm]]("ex_hk45_ammo_limit", 60, 0, 60, "int");
		level.weapons["hk45_mp"].clip_limit = [[level.ex_drm]]("ex_hk45_clip_limit", 15, 0, 999, "int");

		level.weapons["m249_mp"] = spawnstruct();
		level.weapons["m249_mp"].server_allowcvar = "scr_allow_m249";
		level.weapons["m249_mp"].client_allowcvar = "ui_allow_m249";
		level.weapons["m249_mp"].allow_default = 1;
		level.weapons["m249_mp"].classname = "mg";
		level.weapons["m249_mp"].team = "all";
		level.weapons["m249_mp"].era = "modern";
		level.weapons["m249_mp"].limit = [[level.ex_drm]]("ex_m249_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m249_mp"].ammo_limit = [[level.ex_drm]]("ex_m249_ammo_limit", 300, 0, 999, "int");
			else level.weapons["m249_mp"].ammo_limit = [[level.ex_drm]]("ex_m249_ammo_limit", 300, 0, 300, "int");
		level.weapons["m249_mp"].clip_limit = [[level.ex_drm]]("ex_m249_clip_limit", 100, 0, 999, "int");

		level.weapons["m40a3_mp"] = spawnstruct();
		level.weapons["m40a3_mp"].server_allowcvar = "scr_allow_m40a3";
		level.weapons["m40a3_mp"].client_allowcvar = "ui_allow_m40a3";
		level.weapons["m40a3_mp"].allow_default = 1;
		level.weapons["m40a3_mp"].classname = "sniper";
		level.weapons["m40a3_mp"].team = "all";
		level.weapons["m40a3_mp"].era = "modern";
		level.weapons["m40a3_mp"].limit = [[level.ex_drm]]("ex_m40a3_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m40a3_mp"].ammo_limit = [[level.ex_drm]]("ex_m40a3_ammo_limit", 60, 0, 999, "int");
			else level.weapons["m40a3_mp"].ammo_limit = [[level.ex_drm]]("ex_m40a3_ammo_limit", 60, 0, 60, "int");
		level.weapons["m40a3_mp"].clip_limit = [[level.ex_drm]]("ex_m40a3_clip_limit", 10, 0, 999, "int");

		level.weapons["m40a3_2_mp"] = spawnstruct();
		level.weapons["m40a3_2_mp"].server_allowcvar = "scr_allow_m40a3";
		level.weapons["m40a3_2_mp"].client_allowcvar = "ui_allow_m40a3";
		level.weapons["m40a3_2_mp"].allow_default = 1;
		level.weapons["m40a3_2_mp"].classname = "sniperlr";
		level.weapons["m40a3_2_mp"].team = "all";
		level.weapons["m40a3_2_mp"].era = "modern";
		level.weapons["m40a3_2_mp"].limit = [[level.ex_drm]]("ex_m40a3_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m40a3_2_mp"].ammo_limit = [[level.ex_drm]]("ex_m40a3_ammo_limit", 60, 0, 999, "int");
			else level.weapons["m40a3_2_mp"].ammo_limit = [[level.ex_drm]]("ex_m40a3_ammo_limit", 60, 0, 60, "int");
		level.weapons["m40a3_2_mp"].clip_limit = [[level.ex_drm]]("ex_m40a3_clip_limit", 10, 0, 999, "int");

		level.weapons["m4a1_mp"] = spawnstruct();
		level.weapons["m4a1_mp"].server_allowcvar = "scr_allow_m4a1";
		level.weapons["m4a1_mp"].client_allowcvar = "ui_allow_m4a1";
		level.weapons["m4a1_mp"].allow_default = 1;
		level.weapons["m4a1_mp"].classname = "mg";
		level.weapons["m4a1_mp"].team = "all";
		level.weapons["m4a1_mp"].era = "modern";
		level.weapons["m4a1_mp"].limit = [[level.ex_drm]]("ex_m4a1_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m4a1_mp"].ammo_limit = [[level.ex_drm]]("ex_m4a1_ammo_limit", 300, 0, 999, "int");
			else level.weapons["m4a1_mp"].ammo_limit = [[level.ex_drm]]("ex_m4a1_ammo_limit", 300, 0, 300, "int");
		level.weapons["m4a1_mp"].clip_limit = [[level.ex_drm]]("ex_m4a1_clip_limit", 30, 0, 999, "int");

		level.weapons["m60_mp"] = spawnstruct();
		level.weapons["m60_mp"].server_allowcvar = "scr_allow_m60";
		level.weapons["m60_mp"].client_allowcvar = "ui_allow_m60";
		level.weapons["m60_mp"].allow_default = 1;
		level.weapons["m60_mp"].classname = "mg";
		level.weapons["m60_mp"].team = "all";
		level.weapons["m60_mp"].era = "modern";
		level.weapons["m60_mp"].limit = [[level.ex_drm]]("ex_m60_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["m60_mp"].ammo_limit = [[level.ex_drm]]("ex_m60_ammo_limit", 300, 0, 999, "int");
			else level.weapons["m60_mp"].ammo_limit = [[level.ex_drm]]("ex_m60_ammo_limit", 300, 0, 300, "int");
		level.weapons["m60_mp"].clip_limit = [[level.ex_drm]]("ex_m60_clip_limit", 100, 0, 999, "int");

		level.weapons["mac10_mp"] = spawnstruct();
		level.weapons["mac10_mp"].server_allowcvar = "scr_allow_mac10";
		level.weapons["mac10_mp"].client_allowcvar = "ui_allow_mac10";
		level.weapons["mac10_mp"].allow_default = 1;
		level.weapons["mac10_mp"].classname = "smg";
		level.weapons["mac10_mp"].team = "all";
		level.weapons["mac10_mp"].era = "modern";
		level.weapons["mac10_mp"].limit = [[level.ex_drm]]("ex_mac10_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mac10_mp"].ammo_limit = [[level.ex_drm]]("ex_mac10_ammo_limit", 300, 0, 999, "int");
			else level.weapons["mac10_mp"].ammo_limit = [[level.ex_drm]]("ex_mac10_ammo_limit", 300, 0, 300, "int");
		level.weapons["mac10_mp"].clip_limit = [[level.ex_drm]]("ex_mac10_clip_limit", 30, 0, 999, "int");

		level.weapons["mp5_mp"] = spawnstruct();
		level.weapons["mp5_mp"].server_allowcvar = "scr_allow_mp5";
		level.weapons["mp5_mp"].client_allowcvar = "ui_allow_mp5";
		level.weapons["mp5_mp"].allow_default = 1;
		level.weapons["mp5_mp"].classname = "smg";
		level.weapons["mp5_mp"].team = "all";
		level.weapons["mp5_mp"].era = "modern";
		level.weapons["mp5_mp"].limit = [[level.ex_drm]]("ex_mp5_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mp5_mp"].ammo_limit = [[level.ex_drm]]("ex_mp5_ammo_limit", 300, 0, 999, "int");
			else level.weapons["mp5_mp"].ammo_limit = [[level.ex_drm]]("ex_mp5_ammo_limit", 300, 0, 300, "int");
		level.weapons["mp5_mp"].clip_limit = [[level.ex_drm]]("ex_mp5_clip_limit", 30, 0, 999, "int");

		level.weapons["mp5a4_mp"] = spawnstruct();
		level.weapons["mp5a4_mp"].server_allowcvar = "scr_allow_mp5a4";
		level.weapons["mp5a4_mp"].client_allowcvar = "ui_allow_mp5a4";
		level.weapons["mp5a4_mp"].allow_default = 1;
		level.weapons["mp5a4_mp"].classname = "smg";
		level.weapons["mp5a4_mp"].team = "all";
		level.weapons["mp5a4_mp"].era = "modern";
		level.weapons["mp5a4_mp"].limit = [[level.ex_drm]]("ex_mp5a4_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["mp5a4_mp"].ammo_limit = [[level.ex_drm]]("ex_mp5a4_ammo_limit", 300, 0, 999, "int");
			else level.weapons["mp5a4_mp"].ammo_limit = [[level.ex_drm]]("ex_mp5a4_ammo_limit", 300, 0, 300, "int");
		level.weapons["mp5a4_mp"].clip_limit = [[level.ex_drm]]("ex_mp5a4_clip_limit", 30, 0, 999, "int");

		level.weapons["p90_mp"] = spawnstruct();
		level.weapons["p90_mp"].server_allowcvar = "scr_allow_p90";
		level.weapons["p90_mp"].client_allowcvar = "ui_allow_p90";
		level.weapons["p90_mp"].allow_default = 1;
		level.weapons["p90_mp"].classname = "smg";
		level.weapons["p90_mp"].team = "all";
		level.weapons["p90_mp"].era = "modern";
		level.weapons["p90_mp"].limit = [[level.ex_drm]]("ex_p90_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["p90_mp"].ammo_limit = [[level.ex_drm]]("ex_p90_ammo_limit", 300, 0, 999, "int");
			else level.weapons["p90_mp"].ammo_limit = [[level.ex_drm]]("ex_p90_ammo_limit", 300, 0, 300, "int");
		level.weapons["p90_mp"].clip_limit = [[level.ex_drm]]("ex_p90_clip_limit", 30, 0, 999, "int");

		level.weapons["rpg_mp"] = spawnstruct();
		level.weapons["rpg_mp"].server_allowcvar = "scr_allow_rpg";
		level.weapons["rpg_mp"].client_allowcvar = "ui_allow_rpg";
		level.weapons["rpg_mp"].allow_default = 1;
		level.weapons["rpg_mp"].classname = "rl";
		level.weapons["rpg_mp"].team = "all";
		level.weapons["rpg_mp"].era = "modern";
		level.weapons["rpg_mp"].limit = [[level.ex_drm]]("ex_rpg_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["rpg_mp"].ammo_limit = [[level.ex_drm]]("ex_rpg_ammo_limit", 10, 0, 999, "int");
			else level.weapons["rpg_mp"].ammo_limit = [[level.ex_drm]]("ex_rpg_ammo_limit", 10, 0, 10, "int");
		level.weapons["rpg_mp"].clip_limit = [[level.ex_drm]]("ex_rpg_clip_limit", 1, 0, 999, "int");

		level.weapons["sig_552_mp"] = spawnstruct();
		level.weapons["sig_552_mp"].server_allowcvar = "scr_allow_sig_552";
		level.weapons["sig_552_mp"].client_allowcvar = "ui_allow_sig_552";
		level.weapons["sig_552_mp"].allow_default = 1;
		level.weapons["sig_552_mp"].classname = "smg";
		level.weapons["sig_552_mp"].team = "all";
		level.weapons["sig_552_mp"].era = "modern";
		level.weapons["sig_552_mp"].limit = [[level.ex_drm]]("ex_sig_552_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["sig_552_mp"].ammo_limit = [[level.ex_drm]]("ex_sig_552_ammo_limit", 300, 0, 999, "int");
			else level.weapons["sig_552_mp"].ammo_limit = [[level.ex_drm]]("ex_sig_552_ammo_limit", 300, 0, 300, "int");
		level.weapons["sig_552_mp"].clip_limit = [[level.ex_drm]]("ex_sig_552_clip_limit", 30, 0, 999, "int");

		level.weapons["spas_12_mp"] = spawnstruct();
		level.weapons["spas_12_mp"].server_allowcvar = "scr_allow_spas_12";
		level.weapons["spas_12_mp"].client_allowcvar = "ui_allow_spas_12";
		level.weapons["spas_12_mp"].allow_default = 1;
		level.weapons["spas_12_mp"].classname = "shotgun";
		level.weapons["spas_12_mp"].team = "all";
		level.weapons["spas_12_mp"].era = "modern";
		level.weapons["spas_12_mp"].limit = [[level.ex_drm]]("ex_spas_12_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["spas_12_mp"].ammo_limit = [[level.ex_drm]]("ex_spas_12_ammo_limit", 60, 0, 999, "int");
			else level.weapons["spas_12_mp"].ammo_limit = [[level.ex_drm]]("ex_spas_12_ammo_limit", 60, 0, 60, "int");
		level.weapons["spas_12_mp"].clip_limit = [[level.ex_drm]]("ex_spas_12_clip_limit", 6, 0, 999, "int");

		level.weapons["tmp_mp"] = spawnstruct();
		level.weapons["tmp_mp"].server_allowcvar = "scr_allow_tmp";
		level.weapons["tmp_mp"].client_allowcvar = "ui_allow_tmp";
		level.weapons["tmp_mp"].allow_default = 1;
		level.weapons["tmp_mp"].classname = "smg";
		level.weapons["tmp_mp"].team = "all";
		level.weapons["tmp_mp"].era = "modern";
		level.weapons["tmp_mp"].limit = [[level.ex_drm]]("ex_tmp_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["tmp_mp"].ammo_limit = [[level.ex_drm]]("ex_tmp_ammo_limit", 300, 0, 999, "int");
			else level.weapons["tmp_mp"].ammo_limit = [[level.ex_drm]]("ex_tmp_ammo_limit", 300, 0, 300, "int");
		level.weapons["tmp_mp"].clip_limit = [[level.ex_drm]]("ex_tmp_clip_limit", 30, 0, 999, "int");

		level.weapons["ump45_mp"] = spawnstruct();
		level.weapons["ump45_mp"].server_allowcvar = "scr_allow_ump45";
		level.weapons["ump45_mp"].client_allowcvar = "ui_allow_ump45";
		level.weapons["ump45_mp"].allow_default = 1;
		level.weapons["ump45_mp"].classname = "smg";
		level.weapons["ump45_mp"].team = "all";
		level.weapons["ump45_mp"].era = "modern";
		level.weapons["ump45_mp"].limit = [[level.ex_drm]]("ex_ump45_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["ump45_mp"].ammo_limit = [[level.ex_drm]]("ex_ump45_ammo_limit", 300, 0, 999, "int");
			else level.weapons["ump45_mp"].ammo_limit = [[level.ex_drm]]("ex_ump45_ammo_limit", 300, 0, 300, "int");
		level.weapons["ump45_mp"].clip_limit = [[level.ex_drm]]("ex_ump45_clip_limit", 30, 0, 999, "int");

		level.weapons["uzi_mp"] = spawnstruct();
		level.weapons["uzi_mp"].server_allowcvar = "scr_allow_uzi";
		level.weapons["uzi_mp"].client_allowcvar = "ui_allow_uzi";
		level.weapons["uzi_mp"].allow_default = 1;
		level.weapons["uzi_mp"].classname = "smg";
		level.weapons["uzi_mp"].team = "all";
		level.weapons["uzi_mp"].era = "modern";
		level.weapons["uzi_mp"].limit = [[level.ex_drm]]("ex_uzi_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["uzi_mp"].ammo_limit = [[level.ex_drm]]("ex_uzi_ammo_limit", 300, 0, 999, "int");
			else level.weapons["uzi_mp"].ammo_limit = [[level.ex_drm]]("ex_uzi_ammo_limit", 300, 0, 300, "int");
		level.weapons["uzi_mp"].clip_limit = [[level.ex_drm]]("ex_uzi_clip_limit", 30, 0, 999, "int");

		level.weapons["xm1014_mp"] = spawnstruct();
		level.weapons["xm1014_mp"].server_allowcvar = "scr_allow_xm1014";
		level.weapons["xm1014_mp"].client_allowcvar = "ui_allow_xm1014";
		level.weapons["xm1014_mp"].allow_default = 1;
		level.weapons["xm1014_mp"].classname = "shotgun";
		level.weapons["xm1014_mp"].team = "all";
		level.weapons["xm1014_mp"].era = "modern";
		level.weapons["xm1014_mp"].limit = [[level.ex_drm]]("ex_xm1014_limit", 999, 0, 999, "int");
		if(level.ex_maxammo) level.weapons["xm1014_mp"].ammo_limit = [[level.ex_drm]]("ex_xm1014_ammo_limit", 60, 0, 999, "int");
			else level.weapons["xm1014_mp"].ammo_limit = [[level.ex_drm]]("ex_xm1014_ammo_limit", 60, 0, 60, "int");
		level.weapons["xm1014_mp"].clip_limit = [[level.ex_drm]]("ex_xm1014_clip_limit", 6, 0, 999, "int");

		// Keep a list of ww2 weapons, so we can remove them from maps containing weapons
		level.oldweaponnames = [];
		level.oldweaponnames[level.oldweaponnames.size] = "bar_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "bren_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "colt_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "enfield_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "enfield_scope_2_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "enfield_scope_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "flamethrower_allies";
		level.oldweaponnames[level.oldweaponnames.size] = "flamethrower_axis";
		level.oldweaponnames[level.oldweaponnames.size] = "g43_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "g43_sniper";
		level.oldweaponnames[level.oldweaponnames.size] = "g43_sniper_2";
		level.oldweaponnames[level.oldweaponnames.size] = "greasegun_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "kar98k_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "kar98k_sniper_2_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "kar98k_sniper_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "luger_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "m1carbine_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "m1garand_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "mosin_nagant_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "mosin_nagant_sniper_2_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "mosin_nagant_sniper_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "mp40_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "mp44_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "panzerschreck_allies";
		level.oldweaponnames[level.oldweaponnames.size] = "panzerschreck_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "pps42_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "ppsh_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "shotgun_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "springfield_2_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "springfield_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "sten_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "svt40_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "thompson_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "tt30_mp";
		level.oldweaponnames[level.oldweaponnames.size] = "webley_mp";
	}
}

precacheWeapons()
{
	classname = undefined;
	allteamweapons = false;
	allmodernweapons = false;

	if(level.ex_modern_weapons)
	{
		switch(level.ex_wepo_class)
		{
			case 1: classname = "pistol"; break;     // pistol only
			case 2: classname = "sniper"; break;     // sniper only
			case 3: classname = "mg"; break;         // mg only
			case 4: classname = "smg"; break;        // smg only
			case 7: classname = "shotgun"; break;    // shotgun only
			default: allmodernweapons = true; break; // all team weapons
		}
	}
	else if(!level.ex_all_weapons)
	{
		switch(level.ex_wepo_class)
		{
			case 1: classname = "pistol"; break;     // pistol only
			case 2: classname = "sniper"; break;     // sniper only
			case 3: classname = "mg"; break;         // mg only
			case 4: classname = "smg"; break;        // smg only
			case 5: classname = "rifle"; break;      // rifle only
			case 6: classname = "boltrifle"; break;  // bolt action rifle only
			case 7: classname = "shotgun"; break;    // shotgun only
			case 8: classname = "rl"; break;         // panzerschreck/bazooka only
			case 9: classname = "boltsniper"; break; // bolt and sniper only
			case 10: classname = "knife"; break;     // knives only
			default: allteamweapons = true; break;   // all team weapons
		}
	}

	// precache the on hand weapons
	for(i = 0; i < level.weapons.size; i++)
	{
		weaponname = level.weaponnames[i];

		if(weaponname == "fraggrenade" || weaponname == "smokegrenade" || weaponname == "binoculars_mp") continue; // nades and binocs precached later

		if(level.ex_all_weapons) // all ww2 weapons for allies and axis
		{
			if(isWeaponType(weaponname, "sidearm")) continue; // sidearm precached later

			if(level.weapons[weaponname].classname != "sniperlr" || (level.ex_longrange && level.weapons[weaponname].classname == "sniperlr"))
			{
				bridgePrecacheItem(weaponname);
				if(level.ex_mbot) [[level.ex_PrecacheItem]](getMBotWeapon(weaponname));
				if(level.ex_weaponsonback && isValidWeaponOnBack(weaponname))
					[[level.ex_PrecacheModel]]("xmodel/" + weaponname);
			}
		}
		else if(level.ex_modern_weapons) // all modern weapons for allies and axis
		{
			if(!level.ex_wepo_class && isWeaponType(weaponname, "sidearm")) continue; // sidearm precached later

			if(allmodernweapons || (level.ex_wepo_class && isWeaponType(weaponname, classname)))
			{
				if(level.weapons[weaponname].classname != "sniperlr" || (level.ex_longrange && level.weapons[weaponname].classname == "sniperlr"))
					bridgePrecacheItem(weaponname);
				if(level.ex_mbot) [[level.ex_PrecacheItem]](getMBotWeapon(weaponname));
			}
		}
		else if(allteamweapons) // all team weapons for allies and axis
		{
			if(isWeaponType(weaponname, "sidearm")) continue; // sidearm precached later

			if(isWeaponType(weaponname, game["allies"]) || isWeaponType(weaponname, game["axis"]))
			{
				if(level.weapons[weaponname].classname != "sniperlr" || (level.ex_longrange && level.weapons[weaponname].classname == "sniperlr"))
				{
					bridgePrecacheItem(weaponname);
					if(level.ex_mbot) [[level.ex_PrecacheItem]](getMBotWeapon(weaponname));
					if(level.ex_weaponsonback && isValidWeaponOnBack(weaponname))
						[[level.ex_PrecacheModel]]("xmodel/" + weaponname);
				}
			}
		}
		else // weapon class (secondary system disabled)
		{
			if(level.ex_wepo_team_only) // team based, only precache weapons of this type that match the game allies and the game axis
			{
				if(isWeaponType(weaponname, classname) && (isWeaponType(weaponname, game["allies"]) || isWeaponType(weaponname, game["axis"])))
				{
					if(level.weapons[weaponname].classname != "sniperlr" || (level.ex_longrange && level.weapons[weaponname].classname == "sniperlr"))
					{
						bridgePrecacheItem(weaponname);
						if(level.ex_mbot) [[level.ex_PrecacheItem]](getMBotWeapon(weaponname));
						if(level.ex_weaponsonback && isValidWeaponOnBack(weaponname))
							[[level.ex_PrecacheModel]]("xmodel/" + weaponname);
					}
				}
			}
			else // not team based so precache all weapons of this type
			{
				if(isWeaponType(weaponname, classname))
				{
					if(level.weapons[weaponname].classname != "sniperlr" || (level.ex_longrange && level.weapons[weaponname].classname == "sniperlr"))
					{
						bridgePrecacheItem(weaponname);
						if(level.ex_mbot) [[level.ex_PrecacheItem]](getMBotWeapon(weaponname));
						if(level.ex_weaponsonback && isValidWeaponOnBack(weaponname))
							[[level.ex_PrecacheModel]]("xmodel/" + weaponname);
					}
				}
			}
		}
	}

	// if sidearm is allowed precache it
	if(level.ex_wepo_sidearm)
	{
		if(level.ex_currentgt == "ft" && level.ft_raygun)
		{
			// FreezeTag raygun
			[[level.ex_PrecacheItem]]("raygun_mp");
		}
		else
		{
			// pistols
			if(level.ex_wepo_sidearm_type == 0)
			{
				sidearmtype = undefined;

				if(level.ex_modern_weapons)
				{
					switch(game["allies"])
					{
						case "american": sidearmtype = "deagle_mp"; break;
						case "british": sidearmtype = "beretta_mp"; break;
						default: sidearmtype = "glock_mp"; break;
					}

					[[level.ex_PrecacheItem]](sidearmtype);
					[[level.ex_PrecacheItem]]("hk45_mp");
				}
				else
				{
					switch(game["allies"])
					{
						case "american": sidearmtype = "colt_mp"; break;
						case "british": sidearmtype = "webley_mp"; break;
						default: sidearmtype = "tt30_mp"; break;
					}

					[[level.ex_PrecacheItem]](sidearmtype);
					[[level.ex_PrecacheItem]]("luger_mp");
				}
			}
			// knife
			else [[level.ex_PrecacheItem]]("knife_mp");
		}
	}

	// precache the frag grenades (off hand)
	if(!level.ex_wepo_precache_mode || (level.ex_wepo_precache_mode && getcvarint("scr_allow_fraggrenades")))
	{
		if(level.ex_firenades)
			[[level.ex_PrecacheItem]]("fire_mp");
		else if(level.ex_gasnades)
			[[level.ex_PrecacheItem]]("gas_mp");
		else if(level.ex_satchelcharges)
			[[level.ex_PrecacheItem]]("satchel_mp");
		else
		{
			[[level.ex_PrecacheItem]]("frag_grenade_" + game["allies"] + "_mp");
			[[level.ex_PrecacheItem]]("frag_grenade_german_mp");
		}

		if(level.ex_mbot)
		{
			[[level.ex_PrecacheItem]]("frag_grenade_" + game["allies"] + "_bot");
			[[level.ex_PrecacheItem]]("frag_grenade_german_bot");
		}
	}

	// precache the smoke grenades (off hand)
	if(!level.ex_wepo_precache_mode || (level.ex_wepo_precache_mode && getcvarint("scr_allow_smokegrenades")))
	{
		[[level.ex_PrecacheItem]]("smoke_grenade_" + game["allies"] + getSmokeColour(level.ex_smoke[game["allies"]]) + "mp");
		[[level.ex_PrecacheItem]]("smoke_grenade_german" + GetSmokeColour(level.ex_smoke["german"]) + "mp");

		if(level.ex_mbot)
		{
			[[level.ex_PrecacheItem]]("smoke_grenade_" + game["allies"] + "_bot");
			[[level.ex_PrecacheItem]]("smoke_grenade_german_bot");
		}
	}

	// placebo weapons for empty slots
	[[level.ex_PrecacheItem]]("dummy1_mp");
	[[level.ex_PrecacheItem]]("dummy2_mp");
	[[level.ex_PrecacheItem]]("dummy3_mp");

	// sprint system placebo weapon
	game["sprint"] = "sprint_mp";
	if(level.ex_sprint)
	{
		if(level.ex_sprint_level == 1) game["sprint"] = "sprint20_mp";
		else if(level.ex_sprint_level == 2) game["sprint"] = "sprint25_mp";
		else if(level.ex_sprint_level == 3) game["sprint"] = "sprint30_mp";
		else if(level.ex_sprint_level == 4) game["sprint"] = "sprint35_mp";
		[[level.ex_PrecacheItem]](game["sprint"]);
	}

	// mortar placebo weapon
	if(level.ex_ranksystem || level.ex_mortars) [[level.ex_PrecacheItem]]("mortar_mp");

	// artillery placebo weapon
	if(level.ex_ranksystem || level.ex_artillery || level.ex_cmdmonitor) [[level.ex_PrecacheItem]]("artillery_mp");

	// airstrike placebo weapons
	if(level.ex_ranksystem || level.ex_planes)
	{
		[[level.ex_PrecacheItem]]("plane_mp");
		[[level.ex_PrecacheItem]]("planebomb_mp");
	}

	// landmine placebo weapon
	if(level.ex_landmines) [[level.ex_PrecacheItem]]("landmine_mp");

	// tripwire placebo weapon
	if(level.ex_tweapon) [[level.ex_PrecacheItem]]("tripwire_mp");

	// you look through these :)
	[[level.ex_PrecacheItem]]("binoculars_mp");

	// mbot placebo weapons
	if(level.ex_mbot)
	{
		[[level.ex_PrecacheItem]]("mantle_up_bot");
		[[level.ex_PrecacheItem]]("mantle_over_bot");
		[[level.ex_PrecacheItem]]("climb_up_bot");
		[[level.ex_PrecacheItem]]("jump_bot");
	}

	// gunship
	if(level.ex_gunship || level.ex_gunship_special)
	{
		if(level.ex_gunship_25mm) [[level.ex_PrecacheItem]]("gunship_25mm_mp");
		if(level.ex_gunship_40mm) [[level.ex_PrecacheItem]]("gunship_40mm_mp");
		if(level.ex_gunship_105mm) [[level.ex_PrecacheItem]]("gunship_105mm_mp");
		if(level.ex_gunship_nuke) [[level.ex_PrecacheItem]]("gunship_nuke_mp");
	}

	// unfix turrets
	if(level.ex_turrets == 2)
	{	
		[[level.ex_PrecacheItem]]("30cal_duck_mp");
		[[level.ex_PrecacheItem]]("30cal_prone_mp");
		[[level.ex_PrecacheItem]]("30cal_stand_mp");
		[[level.ex_PrecacheItem]]("mg42_bipod_duck_mp");
		[[level.ex_PrecacheItem]]("mg42_bipod_prone_mp");
		[[level.ex_PrecacheItem]]("mg42_bipod_stand_mp");
	}

	// flamethrower tank (not a weapon!)
	if(!level.ex_wepo_precache_mode || (getWeaponStatus("flamethrower_axis") || getWeaponStatus("flamethrower_allies")))
		[[level.ex_PrecacheModel]]("xmodel/ft_tank");

	//logprint("DEBUG: the number of precached items is: " + level.ex_precacheditems.size + "\n");
	//for(i = 0; i < level.ex_precacheditems.size; i++)
	//	logprint("DEBUG: weapon " + (i+1) + ": " + level.ex_precacheditems[i] + "\n");
	//logprint("DEBUG: weapon " + (i+1) + ": defaultweapon_mp\n");
}

bridgePrecacheItem(weapon)
{
	precache = 1;
	if(level.ex_wepo_precache_mode) precache = getWeaponStatus(weapon);
	if(precache) [[level.ex_PrecacheItem]](weapon);
}

isValidWeaponOnBack(weapon)
{
	if(!isDefined(weapon)) return false;

	switch(weapon)
	{
		case "knife_mp":
		case "binoculars_mp":
		case "flamethrower_axis":
		case "flamethrower_allies":
		case "colt_mp":
		case "webley_mp":
		case "tt30_mp":
		case "luger_mp":
		case "springfield_2_mp":
		case "enfield_scope_2_mp":
		case "mosin_nagant_sniper_2_mp":
		case "kar98k_sniper_2_mp":
		case "g43_sniper_2": return false;
	}

	return true;
}

initWeaponDamageModifiers()
{
	// Weapon damage modifiers
	if(level.ex_wdmodon)
	{
		level.ex_wdm = [];

		// Weapons from weapons array
		for(i = 0; i < level.weaponnames.size; i++)
		{
			weaponname = level.weaponnames[i];
			level.ex_wdm[weaponname] = [[level.ex_drm]]("ex_wdm_" + weaponname, 100, 0, 500, "int");
		}

		// Misc weapons
		level.ex_wdm["artillery_mp"] = [[level.ex_drm]]("ex_wdm_artillery_mp", 100, 0, 500, "int");
		level.ex_wdm["gunship_25mm_mp"] = [[level.ex_drm]]("ex_wdm_gunship_25mm_mp", 100, 0, 500, "int");
		level.ex_wdm["gunship_40mm_mp"] = [[level.ex_drm]]("ex_wdm_gunship_40mm_mp", 100, 0, 500, "int");
		level.ex_wdm["gunship_105mm_mp"] = [[level.ex_drm]]("ex_wdm_gunship_105mm_mp", 100, 0, 500, "int");
		level.ex_wdm["gunship_nuke_mp"] = [[level.ex_drm]]("ex_wdm_gunship_nuke_mp", 100, 0, 500, "int");
		level.ex_wdm["landmine_mp"] = [[level.ex_drm]]("ex_wdm_landmine_mp", 100, 0, 500, "int");
		level.ex_wdm["mg30cal_duck_mp"] = [[level.ex_drm]]("ex_wdm_mg30cal_duck_mp", 100, 0, 500, "int");
		level.ex_wdm["mg30cal_stand_mp"] = [[level.ex_drm]]("ex_wdm_mg30cal_stand_mp", 100, 0, 500, "int");
		level.ex_wdm["mg30cal_prone_mp"] = [[level.ex_drm]]("ex_wdm_mg30cal_prone_mp", 100, 0, 500, "int");
		level.ex_wdm["mg42_bipod_duck_mp"] = [[level.ex_drm]]("ex_wdm_mg42_bipod_duck_mp", 100, 0, 500, "int");
		level.ex_wdm["mg42_bipod_prone_mp"] = [[level.ex_drm]]("ex_wdm_mg42_bipod_prone_mp", 100, 0, 500, "int");
		level.ex_wdm["mg42_bipod_stand_mp"] = [[level.ex_drm]]("ex_wdm_mg42_bipod_stand_mp", 100, 0, 500, "int");
		level.ex_wdm["mortar_mp"] = [[level.ex_drm]]("ex_wdm_mortar_mp", 100, 0, 500, "int");
		level.ex_wdm["plane_mp"] = [[level.ex_drm]]("ex_wdm_plane_mp", 100, 0, 500, "int");
		level.ex_wdm["planebomb_mp"] = [[level.ex_drm]]("ex_wdm_planebomb_mp", 100, 0, 500, "int");
		level.ex_wdm["tripwire_mp"] = [[level.ex_drm]]("ex_wdm_tripwire_mp", 100, 0, 500, "int");
	}
}

getMBotWeapon(weapon)
{
	// mbot weapons which are always available
	if(level.ex_modern_weapons)
	{
		switch(weapon)
		{
			case "aug_a3_mp": return "aug_a3_bot";
			case "mp5_mp": return "mp5_bot";
			case "p90_mp": return "p90_bot";
			case "sig_552_mp": return "sig_552_bot";
		}
	}
	else
	{
		switch(weapon)
		{
			case "mp40_mp": return "mp40_bot";
			case "ppsh_mp": return "ppsh_bot";
			case "thompson_mp": return "thompson_bot";
		}
	}

	// Stop here if "all weapons" mode OR not a weapon class AND gunship enabled
	// due to game engine limit for precached weapons (PrecacheItem)
	if(level.ex_all_weapons || (!level.ex_wepo_class && (level.ex_gunship || level.ex_gunship_special)) ) return "dummy1_mp";

	// mbot weapons which are only available for weapon classes
	if(level.ex_modern_weapons)
	{
		switch(weapon)
		{
			case "ak_47_mp": return "ak_47_bot";
			case "ak_74_mp": return "ak_74_bot";
			case "ar_10_mp": return "ar_10_bot"; // sniper
			case "barrett_mp": return "barrett_bot"; // sniper
			case "dragunov_mp": return "dragunov_bot"; // sniper
			case "famas_mp": return "famas_bot";
			case "hk_g36_mp": return "hk_g36_bot";
			case "m249_mp": return "m249_bot";
			case "m40a3_mp": return "m40a3_bot"; // sniper
			case "m4a1_mp": return "m4a1_bot";
			case "m60_mp": return "m60_bot";
			case "mp5a4_mp": return "mp5a4_bot";
			//case "mac10_mp": return "mac10_bot"; // bad grip (weaponClass\pistol to weaponClass\rifle to stop the sliding)
			case "rpg_mp": return "rpg_bot"; // rpg
			case "spas_12_mp": return "spas_12_bot";
			case "tmp_mp": return "tmp_bot"; // silenced weapon
			case "ump45_mp": return "ump45_bot";
			//case "uzi_mp": return "uzi_bot"; // bad grip
			case "xm1014_mp": return "xm1014_bot";
		}
	}
	else
	{
		switch(weapon)
		{
			case "bar_mp": return "bar_bot";
			case "bren_mp": return "bren_bot";
			case "enfield_mp": return "enfield_bot";
			case "enfield_scope_mp": return "enfield_scope_bot";
			case "flamethrower_allies": return "flamethrower_allies_bot";
			case "flamethrower_axis": return "flamethrower_axis_bot";
			case "g43_mp": return "g43_bot";
			case "g43_sniper": return "g43_sniper_bot";
			case "greasegun_mp": return "greasegun_bot";
			case "kar98k_mp": return "kar98k_bot";
			case "kar98k_sniper_mp": return "kar98k_sniper_bot";
			case "m1carbine_mp": return "m1carbine_bot";
			case "m1garand_mp": return "m1garand_bot";
			case "mobile_30cal": return "mobile_30cal_bot";
			case "mobile_mg42": return "mobile_mg42_bot";
			case "mosin_nagant_mp": return "mosin_nagant_bot";
			case "mosin_nagant_sniper_mp": return "mosin_nagant_sniper_bot";
			case "mp44_mp": return "mp44_bot";
			case "panzerschreck_allies": return "panzerschreck_allies_bot";
			case "panzerschreck_mp": return "panzerschreck_bot";
			case "pps42_mp": return "pps42_bot";
			case "shotgun_mp": return "shotgun_bot";
			case "springfield_mp": return "springfield_bot";
			case "sten_mp": return "sten_bot";
			case "svt40_mp": return "svt40_bot";
		}
	}

	// If unknown weapon, return dummy weapon.
	// Dummies are always precached anyway, and the botJoin code will automatically skip it
	return "dummy1_mp";
}
