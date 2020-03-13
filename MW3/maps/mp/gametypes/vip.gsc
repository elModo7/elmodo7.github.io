/*------------------------------------------------------------------------------
	V.I.P. - eXtreme+ mod compatible version, Version 1.2
	Author : La Truffe
	Credits : Astoroth (eXtreme+ mod), Ravir (cvardef function)

	Objective : Kill the VIP of the other team while protecting yours.
	A team scores when the enemy VIP has been killed.
	Map ends : When one team reaches the score limit, or time limit is reached.
	Respawning : After a configurable delay / Near teammates.
------------------------------------------------------------------------------*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.spawnplayer = ::spawnplayer;
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();

	// Over-override Callback_PlayerDamage
	level.vip_callbackPlayerDamage = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::VIP_Callback_PlayerDamage;
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
			precacheStatusIcon("hudicon_" + game["allies"]);
			precacheStatusIcon("hudicon_" + game["axis"]);
		}
		precacheHeadIcon("objective_" + game["allies"] + "_down");
		precacheHeadIcon("objective_" + game["axis"] + "_down");
		precacheShader("objective_" + game["allies"]);
		precacheShader("objective_" + game["axis"]);
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		precacheString(&"MP_VIP_SPOTTED");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.alive_time_record = 0;
	level.objnumber = [];
	level.objnumber["allies"] = 0;
	level.objnumber["axis"] = 1;
	level.vip_player = [];
	level.vip_player["allies"] = undefined;
	level.vip_player["axis"] = undefined;

	// Define properties of default ww2 VIP pistols
	// Cannot use level.weapon[] because ww2 pistols are not in there when modern
	// weapons are enabled
	level.def_pistol["american"] = spawnstruct();
	level.def_pistol["american"].name = "colt_mp";
	level.def_pistol["american"].ammo_limit = 21;
	level.def_pistol["american"].clip_limit = 7;

	level.def_pistol["british"] = spawnstruct();
	level.def_pistol["british"].name = "webley_mp";
	level.def_pistol["british"].ammo_limit = 18;
	level.def_pistol["british"].clip_limit = 6;

	level.def_pistol["russian"] = spawnstruct();
	level.def_pistol["russian"].name = "tt30_mp";
	level.def_pistol["russian"].ammo_limit = 24;
	level.def_pistol["russian"].clip_limit = 8;

	level.def_pistol["german"] = spawnstruct();
	level.def_pistol["german"].name = "luger_mp";
	level.def_pistol["german"].ammo_limit = 24;
	level.def_pistol["german"].clip_limit = 8;

	level.vip_pistol["american"] = "colt_vip_mp";
	level.vip_pistol["british"] = "webley_vip_mp";
	level.vip_pistol["russian"] = "tt30_vip_mp";
	level.vip_pistol["german"] = "luger_vip_mp";

	level._effect["vip_fx"] = loadfx("fx/misc/flare_smoke_9sec.efx");

	if(level.vippistol)
	{
		precacheItem(level.vip_pistol[game["allies"]]);
		precacheItem(level.vip_pistol[game["axis"]]);

		normal_pistol = level.def_pistol[game["allies"]].name;
		level.weapons[level.vip_pistol[game["allies"]]] = spawnstruct();
		level.weapons[level.vip_pistol[game["allies"]]].server_allowcvar = "";
		level.weapons[level.vip_pistol[game["allies"]]].client_allowcvar = "";
		level.weapons[level.vip_pistol[game["allies"]]].allow_default = 0;
		level.weapons[level.vip_pistol[game["allies"]]].classname = "pistol";
		level.weapons[level.vip_pistol[game["allies"]]].team = "allies";
		level.weapons[level.vip_pistol[game["allies"]]].limit = 0;
		level.weapons[level.vip_pistol[game["allies"]]].ammo_limit = level.def_pistol[game["allies"]].ammo_limit;
		level.weapons[level.vip_pistol[game["allies"]]].clip_limit = level.def_pistol[game["allies"]].clip_limit;

		normal_pistol = level.def_pistol[game["axis"]].name;
		level.weapons[level.vip_pistol[game["axis"]]] = spawnstruct();
		level.weapons[level.vip_pistol[game["axis"]]].server_allowcvar = "";
		level.weapons[level.vip_pistol[game["axis"]]].client_allowcvar = "";
		level.weapons[level.vip_pistol[game["axis"]]].allow_default = 0;
		level.weapons[level.vip_pistol[game["axis"]]].classname = "pistol";
		level.weapons[level.vip_pistol[game["axis"]]].team = "axis";
		level.weapons[level.vip_pistol[game["axis"]]].limit = 0;
		level.weapons[level.vip_pistol[game["axis"]]].ammo_limit = level.def_pistol[game["axis"]].ammo_limit;
		level.weapons[level.vip_pistol[game["axis"]]].clip_limit = level.def_pistol[game["axis"]].clip_limit;
	}

	level.vip_smokenade["american"] = "smoke_grenade_american_vip_mp";
	level.vip_smokenade["british"] = "smoke_grenade_british_vip_mp";
	level.vip_smokenade["russian"] = "smoke_grenade_russian_vip_mp";
	level.vip_smokenade["german"] = "smoke_grenade_german_vip_mp";

	if(level.vipsmokenades)
	{
		precacheItem(level.vip_smokenade[game["allies"]]);
		precacheItem(level.vip_smokenade[game["axis"]]);
	}

	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread startGame();
		thread updateGametypeCvars();
		level thread SelectVIP("allies");
		level thread SelectVIP("axis");
	}

	// launch eXtreme+
	extreme\_ex_main::main();
}

dummy()
{
	waittillframeend;
	if(isdefined(self)) level notify("connecting", self);
}

Callback_PlayerConnect()
{
	thread dummy();

	thread extreme\_ex_clientcontrol::explayerconnect();

	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_connecting";
	self waittill("begin");
	self.statusicon = "";

	level notify("connected", self);

	thread extreme\_ex_clientcontrol::explayerjoinedserver();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		extreme\_ex_spawn::spawnIntermission();
		return;
	}

	level endon("intermission");

	scriptMainMenu = game["menu_ingame"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

		// Fix for spectate problem
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

		if(isDefined(self.pers["weapon"]))
		{
			spawnPlayer();
		}
		else
		{
			extreme\_ex_spawn::spawnspectator();

			if(self.pers["team"] == "allies")
			{
				self openMenu(game["menu_weapon_allies"]);
				scriptMainMenu = game["menu_weapon_allies"];
			}
			else
			{
				self openMenu(game["menu_weapon_axis"]);
				scriptMainMenu = game["menu_weapon_axis"];
			}
		}
	}
	else
	{
		self setClientCvar("ui_allow_weaponchange", "0");

		if(!isDefined(self.pers["skipserverinfo"]))
		{
			extreme\_ex_clientcontrol::exPlayerPreServerInfo();
			self openMenu(game["menu_serverinfo"]);
			self.pers["skipserverinfo"] = true;
		}

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		extreme\_ex_spawn::spawnspectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

Callback_PlayerDisconnect()
{
	self extreme\_ex_clientcontrol::explayerdisconnect();

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies")
			setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis")
			setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator")
			setplayerteamrank(self, 2, 0);
	}

	if(self IsVIP())
	{
		iprintln(&"MP_VIP_DISCONNECTED", [[level.ex_pname]](self));
		RemoveVIPFromTeam(self.pers["team"]);
	}

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

VIP_Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(level.vipsmokenades && isdefined(sWeapon) && ((sWeapon == level.vip_smokenade[game["allies"]]) || (sWeapon == level.vip_smokenade[game["axis"]])))
	{
		// Damage caused by a VIP smoke nade : not a real damage

		if(isdefined(self) && isPlayer(self) && (self IsVIP()) && (isdefined(self.pers["team"])) && (sWeapon == level.vip_smokenade[game[self.pers["team"]]]))
			self thread VIPSmoke(vPoint);

		return;
	}

	[[level.vip_callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * level.ex_friendlyfire_reflect);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 1;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 2;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1) iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");

			// Damage caused to the enemy VIP: record the time
			if((self IsVIP()) && isdefined(eAttacker) && isPlayer(eAttacker))
				eAttacker.last_VIP_damage_time = getTime();
		}

		if(isdefined(eAttacker) && eAttacker != self)
			eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(level.ex_logdamage && self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfGuid = self getGuid();
		lpselfteam = self.pers["team"];

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackname = eAttacker.name;
			lpattackGuid = eAttacker getGuid();
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackname = "";
			lpattackGuid = "";
			lpattackerteam = "world";
		}

		if(!isDefined(friendly) || friendly == 2)
			logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

		if(isDefined(friendly) && eAttacker.sessionstate != "dead")
		{
			lpselfnum = lpattacknum;
			lpselfname = lpattackname;
			lpselfGuid = lpattackGuid;
			logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
		}
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator") return;

		if(isdefined(self.switching_vip))
			self notify("kill_thread");
		else
			self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	if(!isdefined(self.switching_vip))
	{
		// If the player was killed by a head shot, let players know it was a head shot kill
		if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
			sMeansOfDeath = "MOD_HEAD_SHOT";

		// send out an obituary message to all clients about the kill
		self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

		self maps\mp\gametypes\_weapons::dropWeapon();
		self maps\mp\gametypes\_weapons::dropOffhand();
	}

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";

	if((!isdefined(self.switching_teams)) && (!isdefined(self.switching_vip)))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// switching teams
			if(isdefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;
				
					if((players[self.joining_team] - players[self.leaving_team]) > 1)
						attacker.score--;
				}
			}

			if(isdefined(attacker.friendlydamage))
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// Check if extra points should be given for bash or headshot
			reward_points = 0;
			if(isDefined(sMeansOfDeath))
			{
				if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
					else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
			}

			points = level.ex_points_kill + reward_points;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker.score -= points;
					else attacker.score -= level.ex_points_kill;
			}
			else
			{
				attacker.score += points;
				attacker.pers["bonus"] += reward_points;
				attacker thread CheckProtectedVIP(self);
			}
		}

		// added for arcade style HUD points
		attacker notify("update_playerscore_hud");

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	if(self isVIP())
		self thread VIPkilledBy(attacker);

	if(!isdefined(self.switching_vip))
		level notify("update_teamscore_hud");

	checkScoreLimit();

	if(!isdefined(self.switching_vip))
		logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isdefined(self.switching_teams))
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	if(level.respawndelay) self thread respawn_timer(delay);
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, level.respawndelay);

	if(isdefined(self.switching_vip))
	{
		self.switching_vip = undefined;
		self.isvip = true;
	}

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");
	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	self extreme\_ex_main::exprespawn();

	team = self.pers["team"];

	if(self IsVIP() && !level.ex_rank_statusicons) self.statusicon = "hudicon_" + game[team];
		else self.statusicon = "";

	self.last_VIP_damage_time = undefined;	

	if(self IsVIP()) self.maxhealth = level.viphealth;
		else self.maxhealth = 100;
	self.health = self.maxhealth;

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(level.ex_specials && level.ex_insertion)
	{
		insertion_info = extreme\_ex_specials_insertion::insertionGetFrom(self);
		if(insertion_info["exists"])
		{
			spawnpoint.origin = insertion_info["origin"];
			spawnpoint.angles = insertion_info["angles"];
		}
	}

	if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
		else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	self extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"MP_VIP_OBJ_TEXT_NOSCORE");

	if(self IsVIP())
	{
		// Change the VIP weapons a posteriori
		if(level.vippistol)
		{
			self takeWeapon(self getWeaponSlotWeapon("primary"));
			self takeWeapon(self getWeaponSlotWeapon("primaryb"));

			pistol = level.vip_pistol[game[team]];
			self giveWeapon(pistol);
			self giveMaxAmmo(pistol);
			self switchToWeapon(pistol);

			self.pers["sidearm"] = pistol;

			self.weapon["virtual"].name = "ignore";
			self.weapon["virtual"].clip = 0;
			self.weapon["virtual"].reserve = 0;
			self.weapon["virtual"].maxammo = 0;

			self notify("primary_changed");
			self notify("primaryb_changed");
		}

		if(level.vipsmokenades)
		{
			self RemoveRegularSmokeNades();

			smokenade = level.vip_smokenade[game[team]];
			self giveWeapon(smokenade);
			self setWeaponClipAmmo(smokenade, level.vipsmokenades);
		}

		if(level.vipfragnades)
		{
			fragnade = "frag_grenade_" + game[team] + "_mp";
			self giveWeapon(fragnade);
			self setWeaponClipAmmo(fragnade, level.vipfragnades);
		}

		// VIP attributes
		self.vip_credit = 0;
		self.vip_alive_time = getTime();
		self.vip_alive_time_cycle = self.vip_alive_time;

		// Add the objective on compass
		if(level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		{
			if(level.vipvisiblebyteammates && level.vipvisiblebyenemies) objteam = "none";
				else if(level.vipvisiblebyteammates) objteam = team;
					else objteam = EnemyTeam(team);

			objective_add(level.objnumber[team], "current", self.origin, "objective_" + game[team]);
			objective_team(level.objnumber[team], objteam);
		}

		// Follow VIP until he's no longer a VIP
		self thread FollowVIP();
	}

	self thread updateTimer();

	if(level.vipbinoculars) self thread CheckBinoculars();

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(!isDefined(updtimer)) updtimer = false;
	if(updtimer) self thread updateTimer();

	while(isdefined(self.WaitingToSpawn)) wait( [[level.ex_fpstime]](0.05) );

	// VIP is forced to respawn
	if(!level.forcerespawn && !self IsVIP())
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	if(!isdefined(self.respawntext))
	{
		self.respawntext = newClientHudElem(self);
		self.respawntext.horzAlign = "center_safearea";
		self.respawntext.vertAlign = "center_safearea";
		self.respawntext.alignX = "center";
		self.respawntext.alignY = "middle";
		self.respawntext.x = 0;
		self.respawntext.y = -50;
		self.respawntext.archived = false;
		self.respawntext.font = "default";
		self.respawntext.fontscale = 2;
		self.respawntext setText(&"PLATFORM_PRESS_TO_SPAWN");
	}

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true) wait( [[level.ex_fpstime]](0.05) );

	self notify("remove_respawntext");
	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

startGame()
{
	if(level.timelimit > 0)
	{
		extreme\_ex_gtcommon::createClock();
		level.clock setTimer(level.timelimit * 60);
	}

	for(;;)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MP_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MP_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MP_AXIS_WIN";
	}

	if(winningteam == "allies")
		level.ex_resultsound = "MP_announcer_allies_win";
	else if(winningteam == "axis")
		level.ex_resultsound = "MP_announcer_axis_win";
	else
		level.ex_resultsound = "MP_announcer_round_draw";

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	winners = "";
	losers = "";
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if((winningteam == "allies") || (winningteam == "axis"))
		{
			lpselfguid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
					winners = (winners + ";" + lpselfguid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
					losers = (losers + ";" + lpselfguid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();
		player setClientCvar("cg_objectiveText", text);
		player extreme\_ex_spawn::spawnIntermission();

		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0) return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < level.timelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0) return;

	if(getTeamScore("allies") < level.scorelimit && getTeamScore("axis") < level.scorelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_vip_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_vip_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock))
				extreme\_ex_gtcommon::createClock();
				level.clock setTimer(level.timelimit * 60);
			}
			else if(isDefined(level.clock)) level.clock destroy();

			checkTimeLimit();
		}

		scorelimit = getcvarint("scr_vip_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

menuAutoAssign()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_CHANGE_TEAM");
		return;
	}

	self extreme\_ex_clientcontrol::menuAutoAssign();
}

menuAllies()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_CHANGE_TEAM");
		return;
	}

	self extreme\_ex_clientcontrol::menuAllies();
}

menuAxis()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_CHANGE_TEAM");
		return;
	}

	self extreme\_ex_clientcontrol::menuAxis();
}

menuSpectator()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_SPECTATOR");
		return;
	}

	self extreme\_ex_clientcontrol::menuSpectator();
}

respawn_timer(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	respawndelay = level.respawndelay;
	if(level.ex_respawndelay_subzero && self.score < 0) respawndelay += level.ex_respawndelay_subzero;
	if(level.ex_respawndelay_class && isDefined(self.pers["weapon"]))
	{
		weapon = self.pers["weapon"];
		weapon_hit = 0;
		if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) weapon_hit = level.ex_respawndelay_sniper;
		else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) weapon_hit = level.ex_respawndelay_rifle;
		else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) weapon_hit = level.ex_respawndelay_mg;
		else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) weapon_hit = level.ex_respawndelay_smg;
		else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) weapon_hit = level.ex_respawndelay_shot;
		else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) weapon_hit = level.ex_respawndelay_rl;

		if(!weapon_hit && level.ex_respawndelay_class == 2 && level.ex_wepo_secondary && isDefined(self.pers["weapon2"]))
		{
			weapon = self.pers["weapon2"];
			if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) weapon_hit = level.ex_respawndelay_sniper;
			else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) weapon_hit = level.ex_respawndelay_rifle;
			else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) weapon_hit = level.ex_respawndelay_mg;
			else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) weapon_hit = level.ex_respawndelay_smg;
			else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) weapon_hit = level.ex_respawndelay_shot;
			else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) weapon_hit = level.ex_respawndelay_rl;
		}

		if(weapon_hit) respawndelay += weapon_hit;
	}

	if(!isdefined(self.respawntimer))
	{
		self.respawntimer = newClientHudElem(self);
		self.respawntimer.x = 0;
		self.respawntimer.y = -50;
		self.respawntimer.alignX = "center";
		self.respawntimer.alignY = "middle";
		self.respawntimer.horzAlign = "center_safearea";
		self.respawntimer.vertAlign = "center_safearea";
		self.respawntimer.alpha = 0;
		self.respawntimer.archived = false;
		self.respawntimer.font = "default";
		self.respawntimer.fontscale = 2;
		self.respawntimer.label = (&"MP_TIME_TILL_SPAWN");
		self.respawntimer setTimer(respawndelay + delay);
	}

	wait( [[level.ex_fpstime]](delay) );
	self thread updateTimer();

	wait( [[level.ex_fpstime]](respawndelay) );

	if(isdefined(self.respawntimer))
		self.respawntimer destroy();

	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isdefined(self.respawntimer))
	{
		if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
			self.respawntimer.alpha = 1;
		else
			self.respawntimer.alpha = 0;
	}
}

playSoundOnPlayers(sound, team)
{
	players = level.players;

	if(isdefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i] playLocalSound(sound);
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound(sound);
	}
}

IsVIP()
{
	if(!isdefined(self.isvip))
		self.isvip = false;

	return self.isvip;
}

SetVIP()
{
	// We shouldn't be here...
	if(self IsVIP()) return;

	self extreme\_ex_hud::cleanplayer();

	// VIP attributes
	self.in_smoke = spawnstruct();
	self.in_smoke.status = false;
	self.in_smoke.nextnade = 0;
	self.in_smoke.statusbynade = [];
	for(i = 0; i < level.vipmaxsmokenades; i ++)
		self.in_smoke.statusbynade[i] = false;

	vipteam = self.pers["team"];

	// Already a VIP in the team ?! (should not happen)
	if(isdefined(level.vip_player[vipteam])) return;

	level.vip_player[vipteam] = self;
	self.dont_auto_balance = true;

	// Notify the change to the player himself
	self iprintlnbold(&"MP_VIP_BECOME_VIP1");
	self iprintlnbold(&"MP_VIP_BECOME_VIP2");
	self playLocalSound("ctf_touchenemy");

	// Notify the change to other players
	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if((!isdefined(player.pers["team"])) || (player == self))
			continue;

		if(vipteam == "allies")
			player iprintlnbold(&"MP_VIP_NEW_VIP_ALLIES", [[level.ex_pname]](self));
		else
			player iprintlnbold(&"MP_VIP_NEW_VIP_AXIS", [[level.ex_pname]](self));
	}

	// Suicide the player with a little effect
	self.switching_vip = true;
	self suicide();
	playfx(level._effect["vip_fx"], self.origin);
}

ForceVIPpistol()
{
	if(level.ex_spwn_time && self.ex_invulnerable && level.ex_spwn_wepdisable) return;

	weaponb = self getWeaponSlotWeapon("primaryb");
	current = self getCurrentWeapon();
	pistol = level.vip_pistol[game[self.pers["team"]]];

	if(current == game["sprint"]) return;

	if(extreme\_ex_weapons::isDummy(current) || (current == "none"))
		self switchToWeapon(pistol);
	else if((extreme\_ex_weapons::isValidWeapon(current)) && (current != pistol))
	{
		self dropItem(current);

		normal_pistol = level.def_pistol[game[self.pers["team"]]].name;
		pistolname = maps\mp\gametypes\_weapons::getWeaponName(normal_pistol);
		self iprintlnbold(&"CUSTOM_ADMIN_NAME", &"WEAPON_PISTOL_SWAP_NO_MSG1");
		self iprintlnbold(&"WEAPON_PISTOL_SWAP_NO_MSG2", pistolname);
	}
}

RemoveRegularSmokeNades()
{
	team = self.pers["team"];

	self takeWeapon("smoke_grenade_" + game["allies"] + extreme\_ex_weapons::getSmokeColour(level.ex_smoke[game["allies"]]) + "mp");
	self takeWeapon("smoke_grenade_" + game["axis"] + extreme\_ex_weapons::getSmokeColour(level.ex_smoke[game["axis"]]) + "mp");
}

FollowVIP()
{
	vipteam = self.pers["team"];

	self LoopOnVIP();

	level thread SelectVIP(vipteam);
}

LoopOnVIP()
{
	self endon("disconnect");
	self endon("killed_vip");

	while((isdefined(self)) && (isPlayer(self)) && (isdefined(self.pers["team"])) && (self IsVIP()))
	{
		wait( [[level.ex_fpstime]](0.05) );

		vipteam = self.pers["team"];

		// Force head icon
		self SetVIPIcon();

		// Update icon position and visibility on compass
		if(level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		{
			objective_position(level.objnumber[vipteam], self.origin);

			self.in_smoke.status = false;
			for(i = 0; i < level.vipmaxsmokenades; i ++)
				self.in_smoke.status = self.in_smoke.status || self.in_smoke.statusbynade[i];

			if(self.in_smoke.status)
				objective_state(level.objnumber[vipteam], "invisible");
			else
				objective_state(level.objnumber[vipteam], "current");
		}

		// Make sure VIP pistol is used
		if(level.vippistol) self ForceVIPpistol();

		// Make sure VIP has no regular smoke nade
		if(level.vipsmokenades)
			self RemoveRegularSmokeNades();

		// Reward VIP for staying alive if enemy team is populated
		timepassed = (getTime() - self.vip_alive_time_cycle) / 1000;
		if(timepassed > level.vippointscycle * 60)
		{
			self.vip_alive_time_cycle = getTime();
			playerscount = maps\mp\gametypes\_teams::CountPlayers();
			if(playerscount[EnemyTeam(vipteam)] > 0)
			{
				self.score += level.vippoints;
				// added for arcade style HUD points
				self notify("update_playerscore_hud");
			}
		}
	}
}

VIPSmoke(location)
{
	if((!level.vipvisiblebyteammates) && (!level.vipvisiblebyenemies)) return;

	self endon("killed_vip");
	self endon("disconnect");

	nade = self.in_smoke.nextnade;
	self.in_smoke.nextnade ++;

	vipteam = self.pers["team"];
	endtime = getTime() + level.vipsmokeduration * 1000;

	while(getTime() < endtime)
	{
		self.in_smoke.statusbynade[nade] = (distance(self.origin, location) <= level.vipsmokeradius);
		wait( [[level.ex_fpstime]](0.1) );
	}

	self.in_smoke.statusbynade[nade] = false;
}

RemoveVIPFromTeam(team)
{
	// Team has no more VIP
	level.vip_player[team] = undefined;

	// Remove the objective on compass
	if(level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		objective_delete(level.objnumber[team]);
}

UnsetVIP()
{
	// We shouldn't be here...
	if(!self IsVIP()) return;

	RemoveVIPFromTeam(self.pers["team"]);

	self.isvip = false;
	self.dont_auto_balance = undefined;
	self.in_smoke = undefined;
	self UnsetVIPIcon();

	// Notify the change to the player himself only
	self iprintlnbold(&"MP_VIP_NO_LONGER_VIP");
}

SetVIPIcon()
{
	if(!level.drawfriend) return;

	if(self.ex_invulnerable) return;

	headicon_vip = "objective_" + game[self.pers["team"]] + "_down";
	headicon_notvip = game["headicon_" + self.pers["team"]];

	if(self.headicon == headicon_notvip)
		self.headicon = headicon_vip;
}

UnsetVIPIcon()
{
	if(!level.drawfriend) return;

	headicon_notvip = game["headicon_" + self.pers["team"]];
	self.headicon = headicon_notvip;
}

SelectVIP(team)
{
	wait( [[level.ex_fpstime]](level.vipdelay) );
	
	candidate = undefined;
	candidate_credit = 0;

	for(;;)
	{
		players = level.players;

		// Increase randomly the credit of all living players of the team
		for(i = 0; i < players.size; i ++)
		{
			player = players[i];

			if((!isdefined(player.pers["team"])) || (player.pers["team"] != team)) continue;

			if(!isdefined(player.vip_credit))
				player.vip_credit = 0;

			if(player.sessionstate == "playing")
				player.vip_credit += randomInt(100);
		}

		// Choose the new VIP = the alive player with the highest credit
		for(i = 0; i < players.size; i ++)
		{
			player = players[i];
		
			if((!isdefined(player.pers["team"])) || (player.pers["team"] != team)) continue;
		
			if(player.vip_credit > candidate_credit)
			{
				candidate = player;
				candidate_credit = player.vip_credit;
			}
		}

		playerscount = maps\mp\gametypes\_teams::CountPlayers();

		if(isdefined(candidate) && (candidate.sessionstate == "playing") && (playerscount[EnemyTeam(team)] > 0)) break;

		wait( [[level.ex_fpstime]](1) );
	}

	candidate SetVIP();
}

VIPkilledBy(killer)
{
	vipteam = self.pers["team"];
	enemyteam = EnemyTeam(vipteam);

	if(isPlayer(killer))
		killerteam = killer.pers["team"];
	else
		killerteam = undefined;

	if(!isdefined(killerteam))
	{
		iprintlnbold(&"MP_VIP_KILLED", [[level.ex_pname]](self));
		teamscoring	= enemyteam;
	}
	else if(killer == self)
	{
		if(isdefined(self.switching_teams))
			return;

		iprintlnbold(&"MP_VIP_KILLED_HIMSELF", [[level.ex_pname]](killer));
		teamscoring = enemyteam;
	}
	else if(killerteam == vipteam)
	{
		iprintlnbold(&"MP_VIP_TEAMKILLED_BY", [[level.ex_pname]](killer));
		teamscoring = enemyteam;
	}
	else
	{
		iprintlnbold(&"MP_VIP_KILLED_BY", [[level.ex_pname]](killer));
		teamscoring = killerteam;
		killer.score += level.pointsforkillingvip;
		// added for arcade style HUD points
		killer notify("update_playerscore_hud");
	}

	alive_time = getTime() - self.vip_alive_time;
	alive_sec_total = int(alive_time / 1000);
	alive_min = int(alive_sec_total / 60);
	alive_sec = alive_sec_total - alive_min * 60;
	if(alive_sec >= 10)
		alive_str = alive_min + "'" + alive_sec + "''";
	else
		alive_str = alive_min + "'0" + alive_sec + "''";

	if(alive_time > level.alive_time_record)
	{
		iprintln(&"MP_VIP_ALIVE_RECORD", alive_str);
		level.alive_time_record = alive_time;
	}
	else
		iprintln(&"MP_VIP_ALIVE", alive_str);

	setTeamScore(teamscoring, getTeamScore(teamscoring) + 1);

	wait( [[level.ex_fpstime]](1) );

	playSoundOnPlayers("ctf_touchcapture", teamscoring);
	playSoundOnPlayers("ctf_enemy_touchcapture", vipteam);

	self notify("killed_vip");

	self UnsetVIP();
}

EnemyTeam(team)
{
	if(team == "axis") enemyteam = "allies";
		else enemyteam = "axis";
	return (enemyteam);
}

CheckBinoculars()
{
	self endon("disconnect");
	self endon("killed_player");

	for( ; ; )
	{
		if(isdefined(self.vip_hudvipspotted))
			self.vip_hudvipspotted destroy();

		self waittill("binocular_enter");
		self thread CheckVIPspotted();
		self waittill("binocular_exit");

		if(isdefined(self.vip_hudvipspotted))
			self.vip_hudvipspotted destroy();

		wait( [[level.ex_fpstime]](0.2) );
	}	
}

CheckVIPspotted()
{
	self endon("disconnect");
	self endon("killed_player");
	self endon("binocular_exit");

	wait( [[level.ex_fpstime]](0.5) );

	team = self.pers["team"];
	vipteam = EnemyTeam(team);

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.1) );

		// No VIP on team yet
		if(!isdefined(level.vip_player[vipteam])) continue;

		vip = level.vip_player[vipteam];

		// Condition on alive state
		cond_state = (vip.sessionstate == "playing");

		// Condition on invisibility in smoke
		cond_smoke = (isdefined(vip.in_smoke)) && (isdefined(vip.in_smoke.status)) && (!vip.in_smoke.status);

		self_eyepos = self getEye();
		vip_eyepos = vip getEye();
		self_angles = self getplayerangles();

		trace = bulletTrace(self_eyepos, vip_eyepos, false, undefined);
		virtualpoint = trace["position"];
		virtual_dist = distance(vip_eyepos, virtualpoint);

		// Condition on direct visibility
		cond_visible = (virtual_dist < 5);

		virtual_angles = vectortoangles(vectornormalize(trace["normal"]));

		delta_angles_v = virtual_angles[0] - self_angles[0];
		if(delta_angles_v < 0) delta_angles_v += 360;
		else if(delta_angles_v > 360) delta_angles_v -= 360;

		delta_angles_h = virtual_angles[1] - self_angles[1];
		if(delta_angles_h < 0) delta_angles_h += 360;
		else if(delta_angles_h > 360) delta_angles_h -= 360;

		// Condition on view angles : less than 4 degrees vertically and horizontally
		cond_angle = ((delta_angles_v < 4) || (delta_angles_v > 356)) && ((delta_angles_h < 4) || (delta_angles_h > 356));

		// Resulting condition for spotting enemy VIP
		cond = cond_state && cond_smoke && cond_visible && cond_angle;

		if(cond)
		{
			if(!isdefined(self.vip_hudvipspotted))
			{
				self.vip_hudvipspotted = newClientHudElem(self);
				self.vip_hudvipspotted.x = 320;
				self.vip_hudvipspotted.y = 20;
				self.vip_hudvipspotted.alignX = "center";
				self.vip_hudvipspotted.alignY = "middle";
				self.vip_hudvipspotted.color = (1, 1, 1);
				self.vip_hudvipspotted.alpha = 1;
				self.vip_hudvipspotted.fontScale = 1.6;
				self.vip_hudvipspotted.archived = true;
				self.vip_hudvipspotted setText(&"MP_VIP_SPOTTED");
			}
		}
		else
			if(isdefined(self.vip_hudvipspotted)) self.vip_hudvipspotted destroy();
	}
}

CheckProtectedVIP(victim)
{
	// No "self protection" for VIPs
	if(self IsVIP()) return;

	team = self.pers["team"];
	vip = level.vip_player[team];

	// Condition on distance to VIP
	if(isdefined(vip) && isPlayer(vip) && (vip.sessionstate == "playing"))
		cond_dist = (distance(victim.origin, vip.origin) <= level.vipprotectiondistance);
	else
		cond_dist = false;

	// Condition on time since last damage to VIP
	if(isdefined(vip) && isPlayer(vip) && (vip.sessionstate == "playing") && isdefined(victim.last_VIP_damage_time))
		cond_time = ((getTime() - victim.last_VIP_damage_time) < level.vipprotectiontime * 1000);
	else cond_time = false;

	if(cond_dist || cond_time)
	{
		iprintln(&"MP_VIP_PROTECTED_VIP", [[level.ex_pname]](self));
		self.score += level.pointsforprotectingvip - 1;	// 1 point already given in Callback_PlayerKilled
		// added for arcade style HUD points
		self notify("update_playerscore_hud");
	}
}
