#include maps\mp\gametypes\_weapons;
#include extreme\_ex_weapons;

main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("disconnect");

	if(level.ex_deathsound && randomInt(100) < 50) self thread extreme\_ex_utils::playSoundLoc("generic_death",self.origin, "death");

	level.obitlog = 0;

	// Death music override possibility (preventing overlapping sounds)
	self.pers["dth_on"] = true;

	// No death music when jukebox is playing
	if(level.ex_jukebox && isDefined(self.pers["jukebox"]) && self.pers["jukebox"].playing)
		self.pers["dth_on"] = false;

	// do not report command monitor deaths
	if(level.ex_cmdmonitor && isDefined(self.ex_cmdmondeath))
	{
		self thread playDeathMusic();
		self.ex_cmdmondeath = undefined;
		return;
	}

	// do not report forced suicides
	if(isDefined(self.ex_forcedsuicide) && self.ex_forcedsuicide)
	{
		self thread playDeathMusic();
		self.ex_forcedsuicide = undefined;
		return;
	}

	// do not report forced suicide for camping
	if(isDefined(self.ex_iscamper) && self.ex_iscamper)
	{
		self thread playDeathMusic();
		return;
	}
	
	// do not report forced suicide for team switch
	if(isDefined(self.switching_teams) && self.switching_teams)
	{
		self thread playDeathMusic();
		return;
	}

	self.ex_obmonamsg = false;
	self.ex_obmonpmsg = false;
	self.ex_obmonpsound = false;

	// 0 = no obituary       - with stats (---)
	// 1 = stock obituary    - with stats (---)
	// 2 = stock obituary    - with stats and personal sounds (--S)
	// 3 = stock obituary    - with stats and personal messages (-M-)
	// 4 = stock obituary    - with stats, personal messages and personal sounds (-MS)
	// 5 = eXtreme+ obituary - with stats (X--)
	// 6 = eXtreme+ obituary - with stats and personal sounds (X-S)
	// 7 = eXtreme+ obituary - with stats and personal message (XM-)
	// 8 = eXtreme+ obituary - with stats, personal messages and personal sounds (XMS)
	if(level.ex_obituary >= 5) self.ex_obmonamsg = true;
	if(level.ex_obituary == 3 || level.ex_obituary == 4 || level.ex_obituary == 7 || level.ex_obituary == 8) self.ex_obmonpmsg = true;
	if(level.ex_obituary == 2 || level.ex_obituary == 4 || level.ex_obituary == 6 || level.ex_obituary == 8) self.ex_obmonpsound = true;
	if(level.ex_bash_only)
	{
		self.ex_obmonpmsg = false;
		self.ex_obmonpsound = false;
	}

	if(level.ex_obituary >= 1 && level.ex_obituary <= 4) obituary(self, attacker, sWeapon, sMeansOfDeath);
	thread extremeobituary(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);
}

extremeobituary(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("disconnect");

	// Mbot weapon conversions
	if(level.ex_mbot && isDefined(attacker) && isDefined(attacker.pers["isbot"]))
		sWeapon = botToNormalWeapon(attacker, sWeapon);

	if(level.ex_currentgt == "vip")
		sWeapon = vipToNormalPistol(sWeapon);

	// sMeansOfDeath conversions
	if(sMeansOfDeath == "MOD_EXPLOSIVE")
	{
		switch(sWeapon)
		{
			case "artillery_mp": sMeansOfDeath = "MOD_ARTILLERY"; break;
			case "tripwire_mp": sMeansOfDeath = "MOD_TRIPWIRE"; break;
			case "landmine_mp": sMeansOfDeath = "MOD_LANDMINE"; break;
			case "dummy2_mp": sWeapon = "helimissile_mp"; sMeansOfDeath = "MOD_HELIMISSILE"; break;
		}
	}
	else if(sMeansOfDeath == "MOD_GRENADE")
	{
		switch(sWeapon)
		{
			case "mortar_mp": sMeansOfDeath = "MOD_MORTAR"; break;
			case "planebomb_mp": sMeansOfDeath = "MOD_AIRSTRIKE"; break;
			case "dummy2_mp": sWeapon = "helitube_mp"; sMeansOfDeath = "MOD_HELITUBE"; break;
		}
	}
	else if(sMeansOfDeath == "MOD_PROJECTILE")
	{
		switch(sWeapon)
		{
			case "flamethrower_allies": sMeansOfDeath = "MOD_FLAMETHROWER"; break;
			case "flamethrower_axis": sMeansOfDeath = "MOD_FLAMETHROWER"; break;
			case "gunship_25mm_mp": sMeansOfDeath = "MOD_GUNSHIP_25MM"; break;
			case "gunship_40mm_mp": sMeansOfDeath = "MOD_GUNSHIP_40MM"; break;
			case "gunship_105mm_mp": sMeansOfDeath = "MOD_GUNSHIP_105MM"; break;
			case "gunship_nuke_mp": sMeansOfDeath = "MOD_GUNSHIP_NUKE"; break;
			case "panzerschreck_mp": sMeansOfDeath = "MOD_RPG"; break;
			case "panzerschreck_allies": sMeansOfDeath = "MOD_RPG"; break;
			case "rpg_mp": sMeansOfDeath = "MOD_RPG"; break;
			case "planebomb_mp": sMeansOfDeath = "MOD_NAPALM"; break;
			case "dummy1_mp": sWeapon = "sentrygun_mp"; sMeansOfDeath = "MOD_SENTRYGUN"; break;
			case "dummy2_mp": sWeapon = "heligun_mp"; sMeansOfDeath = "MOD_HELIGUN"; break;
		}
	}
	else if(sMeansOfDeath == "MOD_GRENADE_SPLASH")
	{
		switch(sWeapon)
		{
			case "smoke_grenade_american_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_british_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_german_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_russian_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_american_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_british_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_german_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_russian_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_american_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_british_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_german_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_russian_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
		}
	}
	else if(sMeansOfDeath == "MOD_PROJECTILE_SPLASH")
	{
		switch(sWeapon)
		{
			case "gunship_25mm_mp": sMeansOfDeath = "MOD_GUNSHIP_25MM"; break;
			case "gunship_40mm_mp": sMeansOfDeath = "MOD_GUNSHIP_40MM"; break;
			case "gunship_105mm_mp": sMeansOfDeath = "MOD_GUNSHIP_105MM"; break;
			case "gunship_nuke_mp": sMeansOfDeath = "MOD_GUNSHIP_NUKE"; break;
			case "panzerschreck_mp": sMeansOfDeath = "MOD_RPG"; break;
			case "panzerschreck_allies": sMeansOfDeath = "MOD_RPG"; break;
			case "rpg_mp": sMeansOfDeath = "MOD_RPG"; break;
		}
	}
	else if(sMeansOfDeath == "MOD_HEAD_SHOT")
	{
		if(sWeapon == "knife_mp") sMeansOfDeath = "MOD_KNIFE";
	}
	else if(sMeansOfDeath == "MOD_PISTOL_BULLET")
	{
		if(sWeapon == "knife_mp") sMeansOfDeath = "MOD_KNIFE";
	}
	else if(sMeansOfDeath == "MOD_SUICIDE")
	{
		if(sWeapon == "dummy1_mp") sMeansOfDeath = "MOD_DROWNING";
	}

	// obituary handling
	if(level.obitlog) logprint("OBITUARY LOG: " + sMeansOfDeath + ", Weapon: " + sWeapon + ", Hitloc: " + sHitLoc + "\n");

	if(sMeansOfDeath == "MOD_TRIGGER_HURT") // unknown death
	{
		obitnad("", "unknown", false);
	}
	else if(sMeansOfDeath == "MOD_FALLING")	// falling
	{
		obitnad("fallingdeath", "falling", true);
	}
	else if(isDefined(attacker) && !isPlayer(attacker)) // ambient fx deaths
	{
		switch(sMeansOfDeath)
		{
			case "MOD_EXPLOSIVE":
			{
				switch(sWeapon)
				{
					case "mortar_mp":
					obitnad("mortardeath", "mortar", false);
					break;
					
					case "artillery_mp":
					obitnad("artillerydeath", "artillery", false);
					break;
					
					case "planebomb_mp":
					obitnad("airstrikedeath", "airstrike", false);
					break;

					case "plane_mp":
					obitnad("planedeath", "plane", false);
					break;

					default:
					obitnad("", "ambient", false);
					break;
				}
			}
		}
	}
	else if(isDefined(attacker) && isPlayer(attacker)) // real player kills/deaths
	{
		if(attacker == self) // killed themself
		{
			switch(sMeansOfDeath)
			{
				case "MOD_EXPLOSIVE":
				obitnad("minefielddeath", "minefield", true);
				break;

				case "MOD_DROWNING":
				obitnad("", "drowning", true);
				break;

				case "MOD_GRENADE_SPLASH":
				if(isWeaponType(sWeapon, "fraggrenade"))
					obitnad("grenadedeath", "selfnade", false);
				break;

				case "MOD_FIRENADE":
				obitnad("firenadedeath", "selffirenade", false);
				break;

				case "MOD_GASNADE":
				obitnad("gasnadedeath", "selfgasnade", false);
				break;
				
				case "MOD_SATCHELCHARGE":
				obitnad("satchelchargedeath", "selfsatchelcharge", false);
				break;

				case "MOD_MORTAR":
				obitnad("mortardeath", "selfmortar", false);
				break;

				case "MOD_ARTILLERY":
				obitnad("artillerydeath", "selfartillery", false);
				break;

				case "MOD_AIRSTRIKE":
				obitnad("airstrikedeath", "selfairstrike", false);
				break;

				case "MOD_NAPALM":
				obitnad("napalmdeath", "selfnapalm", false);
				break;

				case "MOD_RPG":
				obitnad("panzerdeath", "selfrpg", false);
				break;

				case "MOD_TRIPWIRE":
				obitnad("tripwiredeath", "selftripwire", false);
				break;

				case "MOD_LANDMINE":
				obitnad("landminedeath", "selflandmine", false);
				break;

				case "MOD_FLAMETHROWER":
				obitnad("flamethrowerdeath", "selfflamethrower", false);
				break;

				case "MOD_SUICIDE":
				if(level.ex_kamikaze && isWeaponType(self.ex_lastoffhand, "suicidebomb"))
					obitnad("grenadedeath", "selfkamikaze", true);
				else
					obitnad("grenadedeath", "selfnades", true);
				break;

				case "MOD_KNIFE":
				obitnad("knifedeath", "selfknife", false);
				break;
			}
		}
		else if(attacker.pers["team"] != self.pers["team"] && level.ex_teamplay || !level.ex_teamplay) // did not kill themself
		{
			if(isSpecialMeansOfDeath(sMeansOfDeath)) // special sMOD
			{
				switch(sMeansOfDeath)
				{
					case "MOD_MELEE":
					{
						if(sWeapon == "knife_mp") // register knife bash as normal kill
						{
							obitad(attacker, "knifekill", "knifedeath", "knifewhip", sMeansOfDeath, sWeapon);
						}
						else
						{
							if(sHitLoc == "head")
								obitad(attacker, "bashkill", "bashdeath", "bashkill_head", sMeansOfDeath, sWeapon);
							else
								obitad(attacker, "bashkill", "bashdeath", "bashkill", sMeansOfDeath, sWeapon);

							if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_humiliation", level.ex_arcade_shaders_special);
								else if(self.ex_obmonpmsg) self iprintlnbold(&"OBITUARY_HUMILIATION");
							if(self.ex_obmonpsound) self playLocalSound("humiliation");
						}
						break;
					}

					case "MOD_HEAD_SHOT":
					{
						obitad(attacker, "headshotkill", "headshotdeath", "", sMeansOfDeath, sWeapon);
						if(isWeaponType(sWeapon, "sniper")) obitstat(attacker, "sniperkill", "sniperdeath");
						obitmain(attacker, sWeapon, sHitLoc, false);
						if(level.ex_arcade_shaders) attacker thread extreme\_ex_arcade::showArcadeShader("x2_headshot", level.ex_arcade_shaders_special);
							else if(self.ex_obmonpmsg) attacker iprintlnbold(&"OBITUARY_HEADSHOT");
						if(self.ex_obmonpsound) attacker playLocalSound("headshot");
						break;
					}

					case "MOD_GRENADE_SPLASH":
					{
						if(isWeaponType(sWeapon, "fraggrenade"))
							obitad(attacker, "grenadekill", "grenadedeath", "explosive", sMeansOfDeath, sWeapon);
						break;
					}

					case "MOD_KNIFE":
					obitad(attacker, "knifekill", "knifedeath", "knife", sMeansOfDeath, sWeapon);
					break;

					case "MOD_MORTAR":
					obitad(attacker, "mortarkill", "mortardeath", "explosive", sMeansOfDeath, sWeapon);
					break;

					case "MOD_ARTILLERY":
					obitad(attacker, "artillerykill", "artillerydeath", "explosive", sMeansOfDeath, sWeapon);
					break;

					case "MOD_AIRSTRIKE":
					obitad(attacker, "airstrikekill", "airstrikedeath", "explosive", sMeansOfDeath, sWeapon);
					break;

					case "MOD_NAPALM":
					obitad(attacker, "napalmkill", "napalmdeath", "napalm", sMeansOfDeath, sWeapon); // will show Artillery Shell!
					break;

					case "MOD_FIRENADE":
					obitad(attacker, "firenadekill", "firenadedeath", "firenade", sMeansOfDeath, sWeapon);
					break;

					case "MOD_GASNADE":
					obitad(attacker, "gasnadekill", "gasnadedeath", "gasnade", sMeansOfDeath, sWeapon);
					break;
					
					case "MOD_SATCHELCHARGE":
					obitad(attacker, "satchelchargekill", "satchelchargedeath", "satchelcharge", sMeansOfDeath, sWeapon);
					break;

					case "MOD_TRIPWIRE":
					obitad(attacker, "tripwirekill", "tripwiredeath", "explosive", sMeansOfDeath, sWeapon);
					break;

					case "MOD_LANDMINE":
					obitad(attacker, "landminekill", "landminedeath", "explosive", sMeansOfDeath, sWeapon);
					break;

					case "MOD_GUNSHIP_25MM":
					case "MOD_GUNSHIP_40MM":
					case "MOD_GUNSHIP_105MM":
					case "MOD_GUNSHIP_NUKE":
					obitad(attacker, "gunshipkill", "gunshipdeath", "explosive", sMeansOfDeath, sWeapon);
					break;

					case "MOD_RPG":
					obitad(attacker, "panzerkill", "panzerdeath", "rpg", sMeansOfDeath, sWeapon);
					break;

					case "MOD_FLAMETHROWER":
					obitad(attacker, "flamethrowerkill", "flamethrowerdeath", "flamethrower", sMeansOfDeath, sWeapon);
					break;

					case "MOD_SENTRYGUN":
					obitad(attacker, "", "", "sentrygun", sMeansOfDeath, sWeapon);
					break;

					case "MOD_HELIGUN":
					obitad(attacker, "", "", "heligun", sMeansOfDeath, sWeapon);
					break;

					case "MOD_HELITUBE":
					obitad(attacker, "", "", "helitube", sMeansOfDeath, sWeapon);
					break;

					case "MOD_HELIMISSILE":
					obitad(attacker, "", "", "helimissile", sMeansOfDeath, sWeapon);
					break;
				}
			}
			else // not special sMOD
			{
				// sniper kills
				if(isWeaponType(sWeapon, "sniper"))
				{
					obitad(attacker, "sniperkill", "sniperdeath", "", sMeansOfDeath, sWeapon);
					obitmain(attacker, sWeapon, sHitLoc, false);
					sMeansOfDeath = "MOD_IGNORE";
				}
			}
		}
		else if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) // team kills
		{
			if(isSpecialMeansOfDeath(sMeansOfDeath)) // special sMOD
			{
				switch(sMeansOfDeath)
				{
					case "MOD_MELEE":
					{
						if(sWeapon == "knife_mp")
							obitteam(attacker, "knifewhiptk", sMeansOfDeath, sWeapon);
						else
							obitteam(attacker, "bashtk", sMeansOfDeath, sWeapon);
						break;
					}

					case "MOD_HEAD_SHOT":
					obitteam(attacker, "headshottk", sMeansOfDeath, sWeapon);
					break;

					case "MOD_KNIFE":
					obitteam(attacker, "knifetk", sMeansOfDeath, sWeapon);
					break;
					
					case "MOD_GRENADE_SPLASH":
					case "MOD_MORTAR":
					case "MOD_ARTILLERY":
					case "MOD_AIRSTRIKE":
					case "MOD_TRIPWIRE":
					case "MOD_LANDMINE":
					case "MOD_GUNSHIP_25MM":
					case "MOD_GUNSHIP_40MM":
					case "MOD_GUNSHIP_105MM":
					case "MOD_GUNSHIP_NUKE":
					obitteam(attacker, "explosivetk", sMeansOfDeath, sWeapon);
					break;

					case "MOD_NAPALM":
					obitteam(attacker, "napalmtk", sMeansOfDeath, sWeapon);
					break;

					case "MOD_FIRENADE":
					obitteam(attacker, "firenadetk", sMeansOfDeath, sWeapon);
					break;

					case "MOD_GASNADE":
					obitteam(attacker, "gasnadetk", sMeansOfDeath, sWeapon);
					break;
					
					case "MOD_SATCHELCHARGE":
					obitteam(attacker, "satchelchargetk", sMeansOfDeath, sWeapon);
					break;

					case "MOD_RPG":
					obitteam(attacker, "rpgtk", sMeansOfDeath, sWeapon);
					break;

					case "MOD_FLAMETHROWER":
					obitteam(attacker, "flamethrowertk", sMeansOfDeath, sWeapon);
					break;
				}
			}
			else // not special sMOD
			{
				if(isWeaponType(sWeapon, "sniper"))
				{
					obitteam(attacker, "snipertk", sMeansOfDeath, sWeapon);
					sMeansOfDeath = "MOD_IGNORE";
				}
			}
		}
	}

	// standard deaths
	if(isPlayer(attacker) && sHitLoc != "none" && !isSpecialMeansOfDeath(sMeansOfDeath))
	{
		if(attacker.pers["team"] != self.pers["team"] && level.ex_teamplay || !level.ex_teamplay) obitmain(attacker, sWeapon, sHitLoc, true);
			else if(attacker.pers["team"] == self.pers["team"] && attacker != self && level.ex_teamplay) obitteam(attacker, "teamkill", sMeansOfDeath, sWeapon);
	}

	// gunship weapon unlock
	if(level.ex_gunship && getsubstr(sMeansOfDeath, 0, 11) == "MOD_GUNSHIP")
		level thread extreme\_ex_gunship::gunshipWeaponUnlock(attacker);

	self thread killspree(attacker);

	if(level.ex_obituary_streakinfo)
	{
		weapon_mg = isWeaponType(sWeapon, "mg");
		weapon_smg = isWeaponType(sWeapon, "smg");
		if(weapon_mg || weapon_smg) self thread noobstreak(attacker, sWeapon);
		if(!weapon_mg && !weapon_smg) self thread weaponstreak(attacker, sWeapon);
	}
	
	self thread consecdeath(attacker);

	if(level.ex_fbannounce && level.ex_firstblood)
	{
		if(isDefined(attacker) && isPlayer(attacker))
		{
			if(level.ex_arcade_shaders && attacker != self) attacker thread extreme\_ex_arcade::showArcadeShader("x2_firstblood", level.ex_arcade_shaders_special);

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				if(players[i] != self)
				{
					players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_ALL", [[level.ex_pname]](attacker));
					if(!level.ex_teamplay || attacker.pers["team"] != self.pers["team"]) players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_VICTIM", [[level.ex_pname]](self));
					else if(level.ex_teamplay && attacker != self && attacker.pers["team"] == self.pers["team"]) players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_VICTIM_TEAM", [[level.ex_pname]](self));
						else if(attacker == self) players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_VICTIM_SELF");

					players[i] playLocalSound("firstblood");
				}
			}

			self iprintlnbold(&"OBITUARY_FIRSTBLOOD_SELF");
			self playlocalsound("whyami");
			self.pers["dth_on"] = false;
		}
		level.ex_fbannounce = false;
	}

	self thread playDeathMusic();

	if(level.ex_statshud && isDefined(attacker) && isPlayer(attacker))
		attacker thread extreme\_ex_statshud::showStatsHUD();
}

playDeathMusic()
{
	if(level.ex_deathmusic && self.pers["dth_on"] && !self.pers["spec_on"] && !level.ex_roundbased)
		self playLocalSound("death_music");
}

isSpecialMeansOfDeath(sMeansOfDeath)
{
	switch(sMeansOfDeath)
	{
		case "MOD_FALLING":
		case "MOD_MELEE":
		case "MOD_KNIFE":
		case "MOD_GRENADE":
		case "MOD_GRENADE_SPLASH":
		case "MOD_EXPLOSIVE":
		case "MOD_SUICIDE":
		case "MOD_IGNORE":
		case "MOD_ARTILLERY":
		case "MOD_MORTAR":
		case "MOD_AIRSTRIKE":
		case "MOD_NAPALM":
		case "MOD_TRIPWIRE":
		case "MOD_LANDMINE":
		case "MOD_HEAD_SHOT":
		case "MOD_PROJECTILE":
		case "MOD_GUNSHIP_25MM":
		case "MOD_GUNSHIP_40MM":
		case "MOD_GUNSHIP_105MM":
		case "MOD_GUNSHIP_NUKE":
		case "MOD_RPG":
		case "MOD_FIRENADE":
		case "MOD_GASNADE":
		case "MOD_FLAMETHROWER":
		case "MOD_SATCHELCHARGE":
		case "MOD_SENTRYGUN":
		case "MOD_HELIGUN":
		case "MOD_HELITUBE":
		case "MOD_HELIMISSILE":
		case "MOD_DROWNING": return true;
	}

	return false;
}

// special detection - no attacker defined
obitnad(vartype, amsg, issuicide)
{
	self endon("disconnect");

	self.pers["death"]++;
	if(vartype != "") self.pers[vartype]++;
	if(issuicide)
	{
		self.pers["kill"]--;
		self.pers["suicide"]++;
	}

	if(level.obitlog) logprint("OBITNAD: self skd(" + self.score + ":" + self.pers["kill"] + ":" + self.pers["death"] + ")\n");

	if(amsg != "")
	{
		if(self.ex_obmonpmsg) self showpmsg(amsg);
		if(self.ex_obmonamsg) self showamsg(amsg);
	}
}

// special detection - attacker defined
obitad(attacker, atvt, vivt, amsg, sMeansOfDeath, sWeapon)
{
	self endon("disconnect");

	attacker.pers["kill"]++;
	self.pers["death"]++;
	if(atvt != "") attacker.pers[atvt]++;
	if(vivt != "") self.pers[vivt]++;

	if(level.obitlog) logprint("OBITAD: attacker " + attacker.name + " skd(" + (attacker.score+1) + ":" + attacker.pers["kill"] + ":" + attacker.pers["death"] + "), self " + self.name + " skd(" + self.score + ":" + self.pers["kill"] + ":" + self.pers["death"] + ")\n");

	if(amsg != "")
	{
		attacker_weapon = getWeaponName(sWeapon);
		
		if(sMeansOfDeath == "MOD_MELEE")
		{
			if(isWeaponType(sWeapon, "pistol"))
			{
				if(self.ex_obmonpmsg) self showpmsg("pistolwhip");
				if(self.ex_obmonamsg)
				{
					self showamsg("pistolwhip");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else if(isWeaponType(sWeapon, "knife"))
			{
				if(self.ex_obmonpmsg) self showpmsg("knifewhip");
				if(self.ex_obmonamsg)
				{
					self showamsg("knifewhip");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else
			{
				if(self.ex_obmonpmsg) self showpmsg(amsg);
				if(self.ex_obmonamsg)
				{
					self showamsg(amsg);
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_BUTT_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_BUTT_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
		}
		else
		{
			if(self.ex_obmonpmsg) self showpmsg(amsg);
			if(self.ex_obmonamsg)
			{
				self showamsg(amsg);
				if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
					else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
			}
		}
	}
}

// killed by teammate
obitteam(attacker, amsg, sMeansOfDeath, sWeapon)
{
	self endon("disconnect");

	if(!level.ex_sinbin) attacker.pers["teamkill"]++; // If enabled, sinbin in _ex_main::exPlayerKilled will handle it
	attacker.pers["kill"]--;

	if(level.obitlog) logprint("OBITTEAM: attacker " + attacker.name + " skd(" + (attacker.score-1) + ":" + attacker.pers["kill"] + ":" + attacker.pers["death"] + "), self " + self.name + " skd(" + self.score + ":" + self.pers["kill"] + ":" + self.pers["death"] + ")\n");

	if(amsg != "")
	{
		attacker_weapon = getWeaponName(sWeapon);
	
		if(sMeansOfDeath == "MOD_MELEE")
		{
			if(isWeaponType(sWeapon, "pistol"))
			{
				if(self.ex_obmonpmsg) self showpmsg("pistolwhiptk");
				if(self.ex_obmonamsg)
				{
					self showamsg("pistolwhiptk");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else if(isWeaponType(sWeapon, "knife"))
			{
				if(self.ex_obmonpmsg) self showpmsg("knifewhiptk");
				if(self.ex_obmonamsg)
				{
					self showamsg("knifewhiptk");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else
			{
				if(self.ex_obmonpmsg) self showpmsg(amsg);
				if(self.ex_obmonamsg)
				{
					self showamsg(amsg);
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_BUTT_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_BUTT_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
		}
		else
		{
			if(self.ex_obmonpmsg) self showpmsg(amsg);
			if(self.ex_obmonamsg)
			{
				self showamsg(amsg);
				if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
					else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
			}
		}
	}
}

// standard weapons
obitmain(attacker, sWeapon, sHitLoc, updstat)
{
	self endon("disconnect");

	if(updstat)
	{
		attacker.pers["kill"]++;
		self.pers["death"]++;
	}

	if(level.obitlog) logprint("OBITMAIN: attacker " + attacker.name + " skd(" + (attacker.score+1) + ":" + attacker.pers["kill"] + ":" + attacker.pers["death"] + "), self " + self.name + " skd(" + self.score + ":" + self.pers["kill"] + ":" + self.pers["death"] + ")\n");

	showdist = false;
	calcdist = 0;

	range = int(distance(attacker.origin, self.origin));
	if(isDefined(range))
	{
		if(level.ex_obitunit == 1)
		{
			calcdist = int(range * 0.02778); // Range in Yards
			if(calcdist > 9) showdist = true;
		}
		else
		{
			calcdist = int(range * 0.0254); // Range in Metres
			if(calcdist > 3) showdist = true;
		}

		attacker thread obitlongstat("longdist", calcdist);
		if(sHitloc == "head") attacker thread obitlongstat("longhead", calcdist);
	}

	if(!self.ex_obmonamsg) return;

	hitloc = gethitlocstringname(sHitLoc);
	iprintln(&"OBITUARY_KILLED_HITLOC", [[level.ex_pname]](self), hitloc);

	attacker_weapon = getWeaponName(sWeapon);

	if(showdist)
	{
		if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
			else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);

		if(level.ex_obitrange == 1 || (level.ex_obitrange == 2 && isWeaponType(sWeapon, "sniper")) )
		{
			if(level.ex_obitunit == 1) iprintln(&"OBITUARY_YARDS", calcdist);
				else iprintln(&"OBITUARY_METRES", calcdist);
		}
	}
	else
	{
		if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_CLOSE_AN", [[level.ex_pname]](attacker), attacker_weapon);
			else iprintln(&"OBITUARY_BY_USING_CLOSE_A", [[level.ex_pname]](attacker), attacker_weapon);
	}
}

// special stat update
obitstat(attacker, atvt, vivt)
{
	self endon("disconnect");

	if(atvt != "") attacker.pers[atvt]++;
	if(vivt != "") self.pers[vivt]++;
}

obitlongstat(stat, value)
{
	self endon("disconnect");

	if(value > self.pers[stat])
	  self.pers[stat] = value;
}

killspree(attacker)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(level.ex_teamplay && attacker.pers["team"] == self.pers["team"])
	{
		attacker.pers["conseckill"]--;
		return;
	}

	if(attacker != self)
	{
		// check for end of a players killing spree	
		if(self.pers["conseckill"] >= 5)
		{
			if(self.ex_obmonamsg)
			{
				amsg1 = undefined;
				amsg2 = undefined;

				if(self.pers["conseckill"] >= 30)
				{
					amsg1 = &"KILLSPREE_HAS_SAVED_ALL_OUR_ASSES_FROM";
					amsg2 = &"KILLSPREE_ANAL_RAPE";
				}
				else if(self.pers["conseckill"] >= 25)
				{
					amsg1 = &"KILLSPREE_HAS_SAVED_US_ALL_FROM";
					amsg2 = &"KILLSPREE_UNHOLY";
				}
				else if(self.pers["conseckill"] >= 20)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED_THE_UNSTOPPABLE";
					amsg2 = &"KILLSPREE_CRUSADE";
				}
				else if(self.pers["conseckill"] >= 15)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED_THE_UNSTOPPABLE";
					amsg2 = &"KILLSPREE_UNREAL";
				}
				else if(self.pers["conseckill"] >= 10)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED";
					amsg2 = &"KILLSPREE_FLUKISH";
				}
				else if(self.pers["conseckill"] >= 5)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED";
					amsg2 = &"KILLSPREE_PLURAL";
				}

				if(isDefined(amsg1)) iprintln(amsg1, [[level.ex_pname]](attacker));
				if(isDefined(amsg2)) iprintln(amsg2, [[level.ex_pname]](self));
			}

			self.pers["conseckill"] = 0;

			if(self.ex_obmonpsound)
			{
				attacker playLocalSound("nailedhim");

				players = level.players;
				for(i = 0; i < players.size; i++) if(players[i] != self) players[i] playlocalsound("hallelujah");
				//self playlocalsound("hallelujah");
				//self.ex_deathmusic = false;
			}
		}

		// check multi kill ladder
		if(level.ex_obitladder) attacker thread multiKillLadder();

		// check for a player's killing spree
		if(attacker.pers["conseckill"] < 0) attacker.pers["conseckill"] = 0;

		attacker.pers["conseckill"]++;
		attacker thread obitlongstat("longspree", attacker.pers["conseckill"]);

		reward_points = 0;
		pmsg = undefined;
		amsg = undefined;
		psnd = undefined;
		pshd = undefined;

		if(attacker.pers["conseckill"] >= 5)
		{
			if(level.ex_gunship == 1 && (attacker.pers["conseckill"] % level.ex_gunship_killspree == 0))
				attacker thread extreme\_ex_gunship::gunshipPerk();

			if(attacker.pers["conseckill"] == 5)
			{

				reward_points = pow(1 * level.ex_reward_killspree, level.ex_reward_killspree_power);
				amsg = &"KILLSPREE_MSG_5";
				pmsg = &"KILLSPREE_KILLSPREE_PMSG";
				psnd = "killingspree";
				pshd = "x2_killingspree";
			}
			else if(attacker.pers["conseckill"] == 6)
			{
			if(level.ex_specials_vest == 1 && (attacker.pers["conseckill"] % level.ex_specials_vest_killspree == 0))
				attacker thread extreme\_ex_specials_vest::vestPerk();

				reward_points = pow(2 * level.ex_reward_killspree, level.ex_reward_killspree_power);
				amsg = &"KILLSPREE_MSG_10";
				pmsg = &"KILLSPREE_DOMINATING_PMSG";
				psnd = "dominating";
				pshd = "x2_dominating";
			}
			else if(attacker.pers["conseckill"] == 9)
			{
			if(level.ex_specials_sentrygun == 1 && (attacker.pers["conseckill"] % level.ex_specials_sentrygun_killspree == 0))
				attacker thread extreme\_ex_specials_sentrygun::sentrygunPerk();

				reward_points = pow(3 * level.ex_reward_killspree, level.ex_reward_killspree_power);
				amsg = &"KILLSPREE_MSG_15";
				pmsg = &"KILLSPREE_RAMPAGE_PMSG";
				psnd = "rampage";
				pshd = "x2_rampage";
			}
			else if(attacker.pers["conseckill"] == 13)
			{
			if(level.ex_specials_helicopter == 1 && (attacker.pers["conseckill"] % level.ex_specials_helicopter_killspree == 0))
				attacker thread extreme\_ex_specials_helicopter::heliPerk();

				reward_points = pow(4 * level.ex_reward_killspree, level.ex_reward_killspree_power);
				amsg = &"KILLSPREE_MSG_20";
				pmsg = &"KILLSPREE_UNSTOPPABLE_PMSG";
				psnd = "unstoppable";
				pshd = "x2_unstoppable";
			}
			else if(attacker.pers["conseckill"] == 20)
			{

				reward_points = pow(5 * level.ex_reward_killspree, level.ex_reward_killspree_power);
				amsg = &"KILLSPREE_MSG_25";
				pmsg = &"KILLSPREE_WICKED_SICK_PMSG";
				psnd = "wickedsick";
				pshd = "x2_wickedsick";
			}
			else if(attacker.pers["conseckill"] >= 30)
			{
			if(level.ex_specials_insertion == 1 && (attacker.pers["conseckill"] % level.ex_specials_insertion_killspree == 0))
				attacker thread extreme\_ex_specials_insertion::insertionPerk();

				if(attacker.pers["conseckill"] == 30)
					reward_points = pow(6 * level.ex_reward_killspree, level.ex_reward_killspree_power);

				if(attacker.pers["conseckill"]%5 == 0)
				{
					amsg = &"KILLSPREE_MSG_30";
					ps = randomInt(100);
					if(ps <= 33)
					{
						psnd = "godlike";
						pmsg = &"KILLSPREE_GODLIKE_PMSG";
						pshd = "x2_godlike";
					}
					else if(ps <= 66)
					{
						psnd = "holyshit";
						pmsg = &"KILLSPREE_HOLY_SHIT_PMSG";
						pshd = "x2_holyshit";
					}
					else
					{
						psnd = "slaughter";
						pmsg = &"KILLSPREE_SLAUGHTER_PMSG";
						pshd = "x2_slaughter";
					}
				}
			}

			if( (reward_points > 0) && (level.ex_currentgt != "lms")  && (level.ex_currentgt != "ihtf") )
			{
				attacker.score += reward_points;
				attacker.pers["bonus"] += reward_points;
			}

			if(self.ex_obmonamsg && isDefined(amsg)) iprintln(amsg, [[level.ex_pname]](attacker));
			if(level.ex_arcade_shaders && isDefined(pshd)) attacker thread extreme\_ex_arcade::showArcadeShader(pshd, level.ex_arcade_shaders_spree);
				else if(self.ex_obmonpmsg && isDefined(pmsg)) attacker iprintlnbold(pmsg);
			if(self.ex_obmonpsound && isDefined(psnd)) attacker playLocalSound(psnd);
		}
	}
}

multiKillLadder()
{
	self endon("disconnect");

	self.pers["conskillnumb"]++;
	thiskilltime = getTime();
	prevkilltime = self.pers["conskillprev"];
	self.pers["conskillprev"] = thiskilltime;
	if(prevkilltime == 0) prevkilltime = thiskilltime;
	self.pers["conskilltime"] = self.pers["conskilltime"] + (thiskilltime - prevkilltime) / 1000;
	//logprint("DEBUG KILLTIME: kill " + self.pers["conskillnumb"] + " in " + self.pers["conskilltime"] + "\n");

	if(self.pers["conskillnumb"] < 2) return;

	if(self.pers["conskillnumb"] == 9 && self.pers["conskilltime"] <= level.ex_obitladder_9)
	{
		ladder_max = 9;
		ladder_snd = "topgun";
		ladder_shd = "x2_topgun";
	}
	else if(self.pers["conskillnumb"] == 8 && self.pers["conskilltime"] <= level.ex_obitladder_8)
	{
		ladder_max = 8;
		ladder_snd = "ludicrouskill";
		ladder_shd = "x2_ludicrouskill";
	}
	else if(self.pers["conskillnumb"] == 7 && self.pers["conskilltime"] <= level.ex_obitladder_7)
	{
		ladder_max = 7;
		ladder_snd = "monsterkill";
		ladder_shd = "x2_monsterkill";
	}
	else if(self.pers["conskillnumb"] == 6 && self.pers["conskilltime"] <= level.ex_obitladder_6)
	{
		ladder_max = 6;
		ladder_snd = "ultrakill";
		ladder_shd = "x2_ultrakill";
	}
	else if(self.pers["conskillnumb"] == 5 && self.pers["conskilltime"] <= level.ex_obitladder_5)
	{
		ladder_max = 5;
		ladder_snd = "megakill";
		ladder_shd = "x2_megakill";
	}
	else if(self.pers["conskillnumb"] == 4 && self.pers["conskilltime"] <= level.ex_obitladder_4)
	{
		ladder_max = 4;
		ladder_snd = "multikill";
		ladder_shd = "x2_multikill";
	}
	else if(self.pers["conskillnumb"] == 3 && self.pers["conskilltime"] <= level.ex_obitladder_3)
	{
		ladder_max = 3;
		ladder_snd = "triplekill";
		ladder_shd = "x2_triplekill";
	}
	else if(self.pers["conskillnumb"] == 2 && self.pers["conskilltime"] <= level.ex_obitladder_2)
	{
		ladder_max = 2;
		ladder_snd = "doublekill";
		ladder_shd = "x2_doublekill";
	}
	else
	{
		ladder_max = 1;
		ladder_snd = undefined;
		ladder_shd = undefined;
		self.pers["conskillnumb"] = 1;
		self.pers["conskilltime"] = 0;
	}

	if(ladder_max > 1)
	{
		// check for gunship perk
		if(level.ex_gunship == 3 && ladder_max >= level.ex_gunship_obitladder) self thread extreme\_ex_gunship::gunshipPerk();

		self notify("killspree_update");
		waittillframeend;
		self endon("killspree_update");

		// wait a brief moment to let quick consecutive kills come through
		wait( [[level.ex_fpstime]](0.5) );

		if(level.ex_arcade_shaders == 2) self thread extreme\_ex_arcade::showArcadeShader(ladder_shd, level.ex_arcade_shaders_ladder);
		wait( [[level.ex_fpstime]](0.01) );
		self playLocalSound(ladder_snd);
	}
}

weaponstreak(attacker, sWeapon)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) return;

	if(isDefined(attacker.pers["weaponname"]) && sWeapon == attacker.pers["weaponname"]) attacker.pers["weaponstreak"]++;
	else
	{
		attacker.pers["weaponstreak"] = 1;
		attacker.pers["weaponname"] = sWeapon;
	}

	if(attacker.pers["weaponstreak"] >= 5 && self.ex_obmonamsg)
	{
		amsg1 = undefined;
		amsg2 = undefined;

		if(attacker.pers["weaponstreak"] == 5) amsg1 = &"WEAPONSTREAK_MSG_5";
		else if(attacker.pers["weaponstreak"] == 10) amsg1 = &"WEAPONSTREAK_MSG_10";
		else if(attacker.pers["weaponstreak"] == 15) amsg1 = &"WEAPONSTREAK_MSG_15";
		else if(attacker.pers["weaponstreak"] == 20) amsg1 = &"WEAPONSTREAK_MSG_20";
		else if(attacker.pers["weaponstreak"] == 25) amsg1 = &"WEAPONSTREAK_MSG_25";
		else if(attacker.pers["weaponstreak"] == 30) amsg1 = &"WEAPONSTREAK_MSG_30";
		else if(attacker.pers["weaponstreak"] >= 35)
		{
			amsg1 = &"WEAPONSTREAK_MSG_35A";
			amsg2 = &"WEAPONSTREAK_MSG_35B";
		}

		if(isDefined(amsg1))
		{
			iprintln(amsg1, [[level.ex_pname]](attacker));
			if(level.ex_obituary_streakinfo == 2)
			{
				attacker_weapon = getWeaponName(sWeapon);

				if(UseAn(sWeapon)) iprintln(&"WEAPONSTREAK_USING_AN", attacker_weapon);
					else iprintln(&"WEAPONSTREAK_USING_A", attacker_weapon);
			}

			if(isDefined(amsg2)) iprintln(amsg2, attacker.pers["weaponstreak"]);
		}
	}
}

noobstreak(attacker, sWeapon)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) return;

	if(isDefined(attacker.pers["weaponname"]) && sWeapon == attacker.pers["weaponname"]) attacker.pers["noobstreak"]++;
	else
	{
		attacker.pers["noobstreak"] = 1;
		attacker.pers["weaponname"] = sWeapon;
	}

	if(attacker.pers["noobstreak"]%5==0) attacker.pers["spamkill"]++;

	if(attacker.pers["noobstreak"] >= 5 && self.ex_obmonamsg)
	{
		amsg1 = undefined;
		amsg2 = undefined;

		if(attacker.pers["noobstreak"] == 5) amsg1 = &"NOOBSTREAK_MSG_5";
		else if(attacker.pers["noobstreak"] == 10) amsg1 = &"NOOBSTREAK_MSG_10";
		else if(attacker.pers["noobstreak"] == 15) amsg1 = &"NOOBSTREAK_MSG_15";
		else if(attacker.pers["noobstreak"] == 20) amsg1 = &"NOOBSTREAK_MSG_20";
		else if(attacker.pers["noobstreak"] == 25) amsg1 = &"NOOBSTREAK_MSG_25";
		else if(attacker.pers["noobstreak"] == 30) amsg1 = &"NOOBSTREAK_MSG_30";
		else if(attacker.pers["noobstreak"] >= 35)
		{
			amsg1 = &"NOOBSTREAK_MSG_35A";
			amsg2 = &"NOOBSTREAK_MSG_35B";
		}

		if(isDefined(amsg1))
		{
			iprintln(amsg1, [[level.ex_pname]](attacker));
			if(level.ex_obituary_streakinfo == 2)
			{
				attacker_weapon = getWeaponName(sWeapon);

				if(UseAn(sWeapon)) iprintln(&"NOOBSTREAK_USING_AN", attacker_weapon);
					else iprintln(&"NOOBSTREAK_USING_A", attacker_weapon);
			}

			if(isDefined(amsg2)) iprintln(amsg2, attacker.pers["noobstreak"]);
		}
	}
}

consecdeath(attacker)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) return;

	if(self.pers["conseckill"] > 0) self.pers["conseckill"] = 0;
	self.pers["conseckill"]--;

	if(self.pers["conseckill"] <= -5 && self.ex_obmonamsg)
	{
		amsg = undefined;

		if(self.pers["conseckill"] == -5) amsg = &"CONSECDEATHS_MSG_5";
		else if(self.pers["conseckill"] == -8) amsg = &"CONSECDEATHS_MSG_8";
		else if(self.pers["conseckill"] == -10) amsg = &"CONSECDEATHS_MSG_10";
		else if(self.pers["conseckill"] == -13) amsg = &"CONSECDEATHS_MSG_13";
		else if(self.pers["conseckill"] <= -16) amsg = &"CONSECDEATHS_MSG_16";

		if(isDefined(amsg)) iprintln(amsg, [[level.ex_pname]](self));
	}
}

showamsg(message)
{
	self endon("disconnect");

	if(!isDefined(message)) return undefined;

	msg = [];

	switch(message)
	{
		case "unknown":
			msg[0] = &"OBITUARY_UNKNOWN_MSG_0";
			msg[1] = &"OBITUARY_UNKNOWN_MSG_1";
			msg[2] = &"OBITUARY_UNKNOWN_MSG_2";
			break;

		case "falling":
			msg[0] = &"OBITUARY_FALLING_MSG_0";
			msg[1] = &"OBITUARY_FALLING_MSG_1";
			msg[2] = &"OBITUARY_FALLING_MSG_2";
			break;

		case "ambient":
			msg[0] = &"OBITUARY_AMBIENT_MSG_0";
			break;

		// pistol
		case "pistolwhip":
			msg[0] = &"OBITUARY_PISTOL_WHIP";
			break;

		case "pistolwhiptk":
			msg[0] = &"OBITUARY_PISTOL_WHIP_TK";
			break;

		// knife
		case "knife":
			msg[0] = &"OBITUARY_KNIFE_MSG_0";
			msg[1] = &"OBITUARY_KNIFE_MSG_1";
			break;

		case "knifetk":
			msg[0] = &"OBITUARY_KNIFETK_MSG_0";
			msg[1] = &"OBITUARY_KNIFETK_MSG_1";
			break;

		case "knifewhip":
			msg[0] = &"OBITUARY_KNIFE_WHIP";
			break;

		case "knifewhiptk":
			msg[0] = &"OBITUARY_KNIFE_WHIP_TK";
			break;

		case "selfknife":
			msg[0] = &"OBITUARY_KNIFESELF_MSG_0";
			break;

		// grenade
		case "selfnade":
			msg[0] = &"OBITUARY_SELFNADE_MSG_0";
			msg[1] = &"OBITUARY_SELFNADE_MSG_1";
			break;

		case "selfnades":
			msg[0] = &"OBITUARY_SELFNADES_MSG_0";
			msg[1] = &"OBITUARY_SELFNADES_MSG_1";
			break;

		case "selfkamikaze":
			msg[0] = &"OBITUARY_SELFKAMIKAZE_MSG_0";
			msg[1] = &"OBITUARY_SELFKAMIKAZE_MSG_1";
			break;

		// fire grenades
		case "firenade":
			msg[0] = &"OBITUARY_FIRENADE_MSG_0";
			msg[1] = &"OBITUARY_FIRENADE_MSG_1";
			break;

		case "firenadetk":
			msg[0] = &"OBITUARY_FIRENADETK_MSG_0";
			msg[1] = &"OBITUARY_FIRENADETK_MSG_1";
			break;

		case "selffirenade":
			msg[0] = &"OBITUARY_FIRENADESELF_MSG_0";
			break;

		// gas grenades
		case "gasnade":
			msg[0] = &"OBITUARY_GASNADE_MSG_0";
			msg[1] = &"OBITUARY_GASNADE_MSG_1";
			break;

		case "gasnadetk":
			msg[0] = &"OBITUARY_GASNADETK_MSG_0";
			msg[1] = &"OBITUARY_GASNADETK_MSG_1";
			break;

		case "selfgasnade":
			msg[0] = &"OBITUARY_GASNADESELF_MSG_0";
			break;

		// satchel charges
		case "satchelcharge":
			msg[0] = &"OBITUARY_SATCHEL_MSG_0";
			msg[1] = &"OBITUARY_SATCHEL_MSG_1";
			break;

		case "satchelchargetk":
			msg[0] = &"OBITUARY_SATCHELTK_MSG_0";
			msg[1] = &"OBITUARY_SATCHELTK_MSG_1";
			break;

		case "selfsatchelcharge":
			msg[0] = &"OBITUARY_SATCHELSELF_MSG_0";
			break;

		// mine
		case "minefield":
			msg[0] = &"OBITUARY_MINEFIELD_MSG_0";
			msg[1] = &"OBITUARY_MINEFIELD_MSG_1";
			msg[2] = &"OBITUARY_MINEFIELD_MSG_2";
			break;

		// tripwire
		case "selftripwire":
			msg[0] = &"OBITUARY_TRIPWIRESELF_MSG_0";
			break;

		// landmine
		case "selflandmine":
			msg[0] = &"OBITUARY_LANDMINESELF_MSG_0";
			break;

		// rpg
		case "rpg":
			msg[0] = &"OBITUARY_RPG_MSG_0";
			msg[1] = &"OBITUARY_RPG_MSG_1";
			break;

		case "rpgtk":
			msg[0] = &"OBITUARY_RPGTK_MSG_0";
			msg[1] = &"OBITUARY_RPGTK_MSG_1";
			break;

		case "selfrpg":
			msg[0] = &"OBITUARY_RPGSELF_MSG_0";
			break;

		// flamethrower
		case "flamethrower":
			msg[0] = &"OBITUARY_FLAMETHROWER_MSG_0";
			msg[1] = &"OBITUARY_FLAMETHROWER_MSG_1";
			break;

		case "flamethrowertk":
			msg[0] = &"OBITUARY_FLAMETHROWERTK_MSG_0";
			msg[1] = &"OBITUARY_FLAMETHROWERTK_MSG_1";
			break;

		case "selfflamethrower":
			msg[0] = &"OBITUARY_FLAMETHROWERSELF_MSG_0";
			break;

		// mortar
		case "mortar":
			msg[0] = &"OBITUARY_MORTAR_MSG_0";
			msg[1] = &"OBITUARY_MORTAR_MSG_1";
			break;

		case "selfmortar":
			msg[0] = &"OBITUARY_MORTARSELF_MSG_0";
			break;

		// artillery
		case "artillery":
			msg[0] = &"OBITUARY_ARTILLERY_MSG_0";
			msg[1] = &"OBITUARY_ARTILLERY_MSG_1";
			break;

		case "selfartillery":
			msg[0] = &"OBITUARY_ARTILLERYSELF_MSG_0";
			break;

		// airstrike
		case "airstrike":
			msg[0] = &"OBITUARY_AIRSTRIKE_MSG_0";
			msg[1] = &"OBITUARY_AIRSTRIKE_MSG_1";
			break;

		case "selfairstrike":
			msg[0] = &"OBITUARY_AIRSTRIKESELF_MSG_0";
			break;

		// napalm
		case "napalm":
			msg[0] = &"OBITUARY_NAPALM_MSG_0";
			msg[1] = &"OBITUARY_NAPALM_MSG_1";
			break;

		case "napalmtk":
			msg[0] = &"OBITUARY_NAPALMTK_MSG_0";
			msg[1] = &"OBITUARY_NAPALMTK_MSG_1";
			break;

		case "selfnapalm":
			msg[0] = &"OBITUARY_NAPALMSELF_MSG_0";
			break;

		// plane
		case "plane":
			msg[0] = &"OBITUARY_PLANE_MSG_0";
			msg[1] = &"OBITUARY_PLANE_MSG_1";
			break;

		// explosive
		case "explosive":
			msg[0] = &"OBITUARY_EXPLOSIVE_MSG_0";
			msg[1] = &"OBITUARY_EXPLOSIVE_MSG_1";
			break;

		case "explosivetk":
			msg[0] = &"OBITUARY_EXPLOSIVETK_MSG_0";
			msg[1] = &"OBITUARY_EXPLOSIVETK_MSG_1";
			break;

		// drowning
		case "drowning":
			msg[0] = &"OBITUARY_DROWNING_MSG_0";
			break;

		// misc
		case "headshottk":
			msg[0] = &"OBITUARY_HEADSHOT_TK_MSG_0";
			msg[1] = &"OBITUARY_HEADSHOT_TK_MSG_1";
			break;

		case "sniper":
			msg[0] = &"OBITUARY_SNIPER_MSG_0";
			msg[1] = &"OBITUARY_SNIPER_MSG_1";
			break;

		case "snipertk":
			msg[0] = &"OBITUARY_SNIPER_TK_MSG_0";
			msg[1] = &"OBITUARY_SNIPER_TK_MSG_1";
			break;

		// general bash
		case "bashkill_head":
			msg[0] = &"OBITUARY_BASHKILL_HEAD_MSG";
			break;

		case "bashkill":
			msg[0] = &"OBITUARY_BASHKILL_MSG_0";
			msg[1] = &"OBITUARY_BASHKILL_MSG_1";
			break;

		case "bashtk":
			msg[0] = &"OBITUARY_BASHTK_MSG_0";
			msg[1] = &"OBITUARY_BASHTK_MSG_1";
			break;

		// general teamkill
		case "teamkill":
			msg[0] = &"OBITUARY_TEAMKILL_MSG";
			break;

		default:
			msg[0] = &"OBITUARY_KILLED_BY";
			break;
	}

	if(msg.size)
	{
		amsg = randomInt(msg.size);
		iprintln(msg[amsg], [[level.ex_pname]](self));
	}
}

showpmsg(message)
{
	self endon("disconnect");

	if(!isDefined(message)) return undefined;
	
	pmsg = undefined;

	switch(message)
	{
		case "unknown":
			pmsg = &"OBITUARY_UNKNOWN_PMSG";
			break;

		case "falling":
			pmsg = &"OBITUARY_FALLING_PMSG";
			break;

		case "ambient":
			pmsg = &"OBITUARY_AMBIENT_PMSG";
			break;

		// pistol
		case "pistolwhip":
			pmsg = &"OBITUARY_PISTOL_WHIP_PMSG";
			break;

		case "pistolwhiptk":
			pmsg = &"OBITUARY_PISTOL_WHIP_TK_PMSG";
			break;

		// knife
		case "knife":
			pmsg = &"OBITUARY_KNIFE_PMSG";
			break;

		case "knifetk":
			pmsg = &"OBITUARY_KNIFETK_PMSG";
			break;

		case "knifewhip":
			pmsg = &"OBITUARY_KNIFE_WHIP_PMSG";
			break;

		case "knifewhiptk":
			pmsg = &"OBITUARY_KNIFE_WHIP_TK_PMSG";
			break;

		case "selfknife":
			pmsg = &"OBITUARY_KNIFESELF_PMSG";
			break;

		// grenade
		case "selfnade":
			pmsg = &"OBITUARY_SELFNADE_PMSG";
			break;

		case "selfnades":
			pmsg = &"OBITUARY_SELFNADES_PMSG";
			break;

		case "selfkamikaze":
			pmsg = &"OBITUARY_SELFKAMIKAZE_PMSG";
			break;

		// fire grenades
		case "firenade":
			pmsg = &"OBITUARY_FIRENADE_PMSG";
			break;

		case "firenadetk":
			pmsg = &"OBITUARY_FIRENADETK_PMSG";
			break;

		case "selffirenade":
			pmsg = &"OBITUARY_FIRENADESELF_PMSG";
			break;

		// gas grenades
		case "gasnade":
			pmsg = &"OBITUARY_GASNADE_PMSG";
			break;

		case "gasnadetk":
			pmsg = &"OBITUARY_GASNADETK_PMSG";
			break;

		case "selfgasnade":
			pmsg = &"OBITUARY_GASNADESELF_PMSG";
			break;

		// satchel charge
		case "satchelcharge":
			pmsg = &"OBITUARY_SATCHEL_PMSG";
			break;

		case "satchelchargetk":
			pmsg = &"OBITUARY_SATCHELTK_PMSG";
			break;

		case "selfsatchelcharge":
			pmsg = &"OBITUARY_SATCHELSELF_PMSG";
			break;

		// mine
		case "minefield":
			pmsg = &"OBITUARY_MINEFIELD_PMSG";
			break;

		// tripwire
		case "selftripwire":
			pmsg = &"OBITUARY_TRIPWIRESELF_PMSG";
			break;

		// landmine
		case "selflandmine":
			pmsg = &"OBITUARY_LANDMINESELF_PMSG";
			break;

		// rpg
		case "rpg":
			pmsg = &"OBITUARY_RPG_PMSG";
			break;

		case "rpgtk":
			pmsg = &"OBITUARY_RPGTK_PMSG";
			break;

		case "selfrpg":
			pmsg = &"OBITUARY_RPGSELF_PMSG";
			break;

		// flamethrower
		case "flamethrower":
			pmsg = &"OBITUARY_FLAMETHROWER_PMSG";
			break;

		case "flamethrowertk":
			pmsg = &"OBITUARY_FLAMETHROWERTK_PMSG";
			break;

		case "selfflamethrower":
			pmsg = &"OBITUARY_FLAMETHROWERSELF_PMSG";
			break;

		// mortars
		case "mortar":
			pmsg = &"OBITUARY_MORTAR_PMSG";
			break;

		case "mortartk":
			pmsg = &"OBITUARY_MORTARTK_PMSG";
			break;

		case "selfmortar":
			pmsg = &"OBITUARY_MORTARSELF_PMSG";
			break;

		// artillery
		case "artillery":
			pmsg = &"OBITUARY_ARTILLERY_PMSG";
			break;

		case "artillerytk":
			pmsg = &"OBITUARY_ARTILLERYTK_PMSG";
			break;

		case "selfartillery":
			pmsg = &"OBITUARY_ARTILLERYSELF_PMSG";
			break;

		// airstrike
		case "airstrike":
			pmsg = &"OBITUARY_AIRSTRIKE_PMSG";
			break;

		case "airstriketk":
			pmsg = &"OBITUARY_AIRSTRIKETK_PMSG";
			break;

		case "selfairstrike":
			pmsg = &"OBITUARY_AIRSTRIKESELF_PMSG";
			break;

		// napalm
		case "napalm":
			pmsg = &"OBITUARY_NAPALM_PMSG";
			break;

		case "napalmtk":
			pmsg = &"OBITUARY_NAPALMTK_PMSG";
			break;

		case "selfnapalm":
			pmsg = &"OBITUARY_NAPALMSELF_PMSG";
			break;

		// plane
		case "plane":
			pmsg = &"OBITUARY_PLANE_PMSG";
			break;

		// explosive
		case "explosive":
			pmsg = &"OBITUARY_EXPLOSIVE_PMSG";
			break;
			
		case "explosivetk":
			pmsg = &"OBITUARY_EXPLOSIVETK_PMSG";
			break;

		// drowning
		case "drowning":
			pmsg = &"OBITUARY_DROWNING_PMSG";
			break;

		// specials
		case "sentrygun":
			pmsg = &"OBITUARY_SENTRYGUN_PMSG";
			break;

		case "heligun":
			pmsg = &"OBITUARY_HELIGUN_PMSG";
			break;

		case "helitube":
			pmsg = &"OBITUARY_HELITUBE_PMSG";
			break;

		case "helimissile":
			pmsg = &"OBITUARY_HELIMISSILE_PMSG";
			break;

		// misc
		case "headshottk":
			pmsg = &"OBITUARY_HEADSHOT_TK_PMSG";
			break;

		case "sniper":
			pmsg = &"OBITUARY_SNIPER_PMSG";
			break;

		case "snipertk":
			pmsg = &"OBITUARY_SNIPER_TK_PMSG";
			break;

		// general bashes
		case "bashkill":
			pmsg = &"OBITUARY_BASHKILL_PMSG";
			break;
		
		case "bashkill_head":
			pmsg = &"OBITUARY_BASHKILL_HEAD_PMSG";
			break;

		case "bashtk":
			pmsg = &"OBITUARY_BASHTK_PMSG";
			break;

		// general teamkill
		case "teamkill":
			pmsg = &"OBITUARY_TEAMKILL_PMSG";
			break;

		default:
			return;
	}

	self iprintlnbold(pmsg);
}

gethitlocstringname(location)
{
	if(location == "helmet") location = "head";

	switch(location)
	{
		case "right_hand":      return &"HITLOC_RIGHT_HAND";
		case "left_hand":       return &"HITLOC_LEFT_HAND";
		case "right_arm_upper": return &"HITLOC_RIGHT_UPPER_ARM";
		case "right_arm_lower": return &"HITLOC_RIGHT_FOREARM";
		case "left_arm_upper":  return &"HITLOC_LEFT_UPPER_ARM";
		case "left_arm_lower":  return &"HITLOC_LEFT_FOREARM";
		case "head":            return &"HITLOC_HEAD";
		case "neck":            return &"HITLOC_NECK";
		case "right_foot":      return &"HITLOC_RIGHT_FOOT";
		case "left_foot":       return &"HITLOC_LEFT_FOOT";
		case "right_leg_lower": return &"HITLOC_RIGHT_LOWER_LEG";
		case "left_leg_lower":  return &"HITLOC_LEFT_LOWER_LEG";
		case "right_leg_upper": return &"HITLOC_RIGHT_UPPER_LEG";
		case "left_leg_upper":  return &"HITLOC_LEFT_UPPER_LEG";
		case "torso_upper":     return &"HITLOC_UPPER_TORSO";
		case "torso_lower":     return &"HITLOC_LOWER_TORSO";
		case "none":            
		default:                return &"HITLOC_UNKNOWN";
	}
}

pow(numb, power)
{
	result = 1;
	for(i = 0; i < power; i++)
		result = result * numb;
	return result;
}

vipToNormalPistol(sWeapon)
{
	switch(sWeapon)
	{
		case "colt_vip_mp": return "colt_mp";
		case "luger_vip_mp": return "luger_mp";
		case "tt30_vip_mp": return "tt30_mp";
		case "webley_vip_mp": return "webley_mp";
	}
	return sWeapon;
}

botToNormalWeapon(attacker, sWeapon)
{
	if(isWeaponType(sWeapon, "fraggrenade")) return sWeapon;

	switch(sWeapon)
	{
		case "frag_grenade_american_bot": return "frag_grenade_american_mp";
		case "frag_grenade_british_bot": return "frag_grenade_british_mp";
		case "frag_grenade_russian_bot": return "frag_grenade_russian_mp";
		case "frag_grenade_german_bot": return "frag_grenade_german_mp";
	}
	return attacker.oweapon;
}
