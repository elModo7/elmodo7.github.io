/*------------------------------------------------------------------------------
	Enhanced S&D
	Scripted by Nedgerblansky
	Edited with new features and ported over to eXtreme+ mod by Tally (16/5/2007)
------------------------------------------------------------------------------*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_clientcontrol::menuAutoAssign;
	level.allies = extreme\_ex_clientcontrol::menuAllies;
	level.axis = extreme\_ex_clientcontrol::menuAxis;
	level.spectator = extreme\_ex_clientcontrol::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.spawnplayer = ::spawnplayer;
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();
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
		if(level.esd_campaign_mode)
		{
			level.esd_lastwinner = getCvar("scr_esd_lastwinner");
			setCvar("scr_esd_lastwinner", "");

			if(level.esd_lastwinner != "")
			{
				if(level.esd_lastwinner == "allies") // Last map winner attacks, loser defends
				{
					game["attackers"] = "allies";
					game["defenders"] = "axis";
				}
				else
				{
					game["attackers"] = "axis";
					game["defenders"] = "allies";
				}
			}
			else //they want campaign, but it's the first map
			{
				game["attackers"] = "allies";
				game["defenders"] = "axis";
			}
		}
		else
		{
			if(!isdefined(game["attackers"])) game["attackers"] = "allies";
			if(!isdefined(game["defenders"])) game["defenders"] = "axis";
		}
	}

	if(level.esd_swap_roundwinner)
	{
		level.esd_roundwinner = getCvar("scr_esd_roundwinner");
		setCvar("scr_esd_roundwinner", "");

		if(level.esd_roundwinner != "")
		{
			if(level.esd_roundwinner == "allies") // Last round winner attacks, loser defends
			{
				game["attackers"] = "allies";
				game["defenders"] = "axis";
			}
			else
			{
				game["attackers"] = "axis";
				game["defenders"] = "allies";
			}
		}
		else //they want to swap, but it's the first round
		{
			if(!isdefined(game["attackers"])) game["attackers"] = "allies";
			if(!isdefined(game["defenders"])) game["defenders"] = "axis";
		}
	}

	switch(game["allies"])
	{
		case "american":
			game["draw_flag"] = "flag_draw_us";
			break;
		case "british":
			game["draw_flag"] = "flag_draw_brit";
			break;
		case "russian":
			game["draw_flag"] = "flag_draw_rus";
			break;
	}

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
		}
		precacheShader("plantbomb");
		precacheShader("defusebomb");
		precacheShader("objective");
		precacheShader("objectiveA");
		precacheShader("objectiveB");
		precacheShader("bombplanted");
		precacheShader("objpoint_bomb");
		precacheShader("objpoint_A");
		precacheShader("objpoint_B");
		precacheShader("objpoint_star");
		precacheShader("hudStopwatch");
		precacheShader("gfx/custom/flagge_german.tga");
		precacheShader("gfx/custom/flagge_" + game["allies"] + ".tga");
		precacheShader("hudstopwatchneedle");
		precacheShader(game["draw_flag"]);
		precacheModel("xmodel/mp_tntbomb");
		precacheModel("xmodel/mp_tntbomb_obj");
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		precacheString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
		precacheString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
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
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("manual_change");

	spawnpointname = "mp_sd_spawn_attacker";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_sd_spawn_defender";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	level._effect["bombexplosion"] = loadfx("fx/props/barrelexp.efx");

	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.defuseback = (level.esd_mode == 3) || (level.esd_mode == 4);
	level.bombplanted = false;
	level.bombexploded = false;
	level.bombdefused = false;
	level.bombmode = 0;
	level.objectives_count = 0;
	level.defused_count = 0;

	level.mapended = false;
	level.roundstarted = false;
	level.roundended = false;
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	if(!isDefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	if(!isDefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);

	if(!isDefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["matchstarted"])) game["matchstarted"] = false;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread bombzones();
		thread startGame();
		thread updateGametypeCvars();
	}

	// launch eXtreme+
	extreme\_ex_main::main();
}

dummy()
{
	waittillframeend;
	if(isDefined(self)) level notify("connecting", self);
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

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	level updateTeamStatus();
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir)) iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

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
		}

		if(isDefined(eAttacker) && eAttacker != self)
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

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isDefined(self.switching_teams))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	lpselfname = self.name;
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// switching teams
			if(isDefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1)
					{
						attacker.pers["score"]--;
						attacker.score = attacker.pers["score"];
					}
					
				}
			}

			if(isDefined(attacker.friendlydamage))
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
				if(level.ex_reward_teamkill)
				{
					attacker.pers["score"] -= points;
					attacker.score = attacker.pers["score"];
				}
				else
				{
					attacker.pers["score"] -= level.ex_points_kill;
					attacker.score = attacker.pers["score"];
				}
			}
			else
			{
				attacker.pers["score"] += points;
				attacker.pers["bonus"] += reward_points;
				attacker.score = attacker.pers["score"];
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

		self.pers["score"]--;
		self.score = self.pers["score"];

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isDefined(self.switching_teams))
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	if(!level.exist[self.pers["team"]]) // If the last player on a team was just killed, don't do killcam
	{
		doKillcam = false;
		self.skip_setspectatepermissions = true;

		if(level.bombplanted && level.planting_team == self.pers["team"])
		{
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(player.pers["team"] == self.pers["team"])
				{
					player allowSpectateTeam("allies", true);
					player allowSpectateTeam("axis", true);
					player allowSpectateTeam("freelook", true);
					player allowSpectateTeam("none", false);
				}
			}
		}
	}

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	if(level.respawndelay) self thread respawn_timer(delay);
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, level.respawndelay);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	// Handle ready-up spawn tickets
	if(level.ex_readyup == 2 && isDefined(game["readyup_done"]))
	{
		if(!isDefined(self.pers["readyup_spawnticket"]))
		{
			if(level.ex_readyup_status == 2 && level.ex_readyup_ticketing == 1)
				self.pers["readyup_spawnticket"] = 1;
			else if(level.ex_readyup_status == 3)
				self.pers["readyup_spawnticket"] = 1;
			else
			{
				self extreme\_ex_readyup::moveToSpectators();
				if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
				self extreme\_ex_readyup::waitForNextRound();
				return;
			}
		}
	}

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
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

	self extreme\_ex_main::exprespawn();
	
	spawnpointname = "";

	if(game["attackers"] == "axis")
	{
		if(self.pers["team"] == "axis") spawnpointname = "mp_sd_spawn_attacker";
			else spawnpointname = "mp_sd_spawn_defender";
	}
	else
	{
		if(self.pers["team"] == "allies") spawnpointname = "mp_sd_spawn_attacker";
			else spawnpointname = "mp_sd_spawn_defender";
	}

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

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

	level updateTeamStatus();

	if(!isDefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isDefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	self extreme\_ex_weapons::loadout();

	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])))
	{
		if(level.scorelimit > 0)
		{
			if(self.pers["team"] == game["attackers"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_ATTACKERS", level.scorelimit);
				else if(self.pers["team"] == game["defenders"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_DEFENDERS", level.scorelimit);
		}
		else
		{
			if(self.pers["team"] == game["attackers"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_ATTACKERS_NOSCORE");
				else if(self.pers["team"] == game["defenders"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_DEFENDERS_NOSCORE");
		}
	}

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "spectator";

	if(isDefined(self.dead_origin) && isDefined(self.dead_angles))
	{
		origin = self.dead_origin + (0, 0, 16);
		angles = self.dead_angles;
	}
	else
	{
		origin = self.origin + (0, 0, 16);
		angles = self.angles;
	}

	self spawn(origin, angles);

	if(!isDefined(updtimer)) updtimer = false;
	if(updtimer) self thread updateTimer();

	while(isdefined(self.WaitingToSpawn)) wait( [[level.ex_fpstime]](0.05) );

	self.spawned = undefined;
	
	for(;;)
	{	
		if(!isdefined(self.deathcount)) self.deathcount = 0;
		self.deathcount++;
		
		if(self.deathcount <= level.spawnlimit)
		{
			if(!level.forcerespawn)
			{
				self thread waitRespawnButton();
				self waittill("respawn");
			}
			
			self thread spawnPlayer();
		}
		else
		{
			level updateTeamStatus();
			self.spawned = true;
			self thread extreme\_ex_spawn::spawnspectator();
		}
	
		wait( [[level.ex_fpstime]](0.05) );
	}
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

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
	thread startRound();
}

startRound()
{
	if(!level.esd_mode) level endon("bomb_planted");
	level endon("round_ended");

	game["matchstarted"] = true; // mainly to control UpdateTeamStatus
	game["roundnumber"]++;

	extreme\_ex_gtcommon::createClock();
	level.clock setTimer(level.roundlength * 60);
	
	level.objectives_count = 0;
	level.defused_count = 0;
	
	wait( [[level.ex_fpstime]](level.roundlength * 60) );

	if(level.roundended) return;

	if(!level.exist[game["attackers"]] || !level.exist[game["defenders"]])
	{
		iprintln(&"MP_TIMEHASEXPIRED");
		level thread endRound("draw");
	}
	else
	{
		iprintln(&"MP_TIMEHASEXPIRED");
		level thread endRound(game["defenders"]);
	}
}

resetScores()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.pers["score"] = 0;
		player.pers["death"] = 0;
	}

	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

endRound(roundwinner)
{
	level endon("intermission");
	level endon("kill_endround");

	if(level.roundended || level.ex_readyup && !isDefined(game["readyup_done"])) return;
	level.roundended = true;

	level notify("round_ended");
	level notify("update_teamscore_hud");
	
	if(level.esd_mode && isdefined(level.clock)) level.clock destroy();

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.progressbackground)) player.progressbackground destroy();
		if(isDefined(player.progressbar)) player.progressbar destroy();

		player unlink();
		player [[level.ex_eWeapon]]();

		if(level.ex_readyup == 2) player.pers["readyup_spawnticket"] = 1;
	}

	objective_delete(0);
	objective_delete(1);

	winners = "";
	losers = "";

	if(roundwinner == "allies")
	{
		points = level.roundwin_points;
		GivePointsToTeam("allies", points);
		
		game["alliedscore"]++;
		setTeamScore("allies", game["alliedscore"]);
		
		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_" + game["allies"] + ".tga",128,128,1,0.9,1,1,1);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			lpselfguid = players[i] getGuid();
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				winners = (winners + ";" + lpselfguid + ";" + players[i].name);
			else if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				losers = (losers + ";" + lpselfguid + ";" + players[i].name);
		}
		logPrint("W;allies" + winners + "\n");
		logPrint("L;axis" + losers + "\n");
	}
	else if(roundwinner == "axis")
	{
		points = level.roundwin_points;
		GivePointsToTeam("axis", points);
		
		game["axisscore"]++;
		setTeamScore("axis", game["axisscore"]);
		
		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_german.tga",128,128,1,0.9,1,1,1);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			lpselfguid = players[i] getGuid();
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				winners = (winners + ";" + lpselfguid + ";" + players[i].name);
			else if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				losers = (losers + ";" + lpselfguid + ";" + players[i].name);
		}
		logPrint("W;axis" + winners + "\n");
		logPrint("L;allies" + losers + "\n");
	}
	else if(roundwinner == "draw")
		level createLevelHudElement("flag_draw", 320,110, "center","middle","fullscreen","fullscreen",false,game["draw_flag"],128,70,1,0.9,1,1,1);

	announceWinner(roundwinner, 2);

	if(roundwinner == "allies" || roundwinner == "axis") level thread deleteLevelHudElementByName("flag_winner");
		else level thread deleteLevelHudElementByName("flag_draw");
	wait( [[level.ex_fpstime]](1) );

	checkScoreLimit();
	game["roundsplayed"]++;
	checkRoundLimit();
		
	if(level.esd_swap_roundwinner)
	{
		if(roundwinner != "draw") setcvar("scr_esd_roundwinner", roundwinner);
			else setcvar("scr_esd_roundwinner", game["attackers"]);
	}

	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	checkTimeLimit();

	if(level.mapended) return;

	iprintlnbold(&"MP_STARTING_NEW_ROUND");
	level notify("restarting");
	wait( [[level.ex_fpstime]](2) );

	if(level.ex_swapteams == 1 && !level.esd_swap_roundwinner) extreme\_ex_main::swapTeams();
	if(level.ex_swapteams == 2 && !level.esd_swap_roundwinner && game["roundnumber"] == level.half_time) extreme\_ex_main::swapTeams();

	map_restart(true);
}

endMap()
{
	level.mapended = true;
	level notify("end_map");

	if(isdefined(level.bombmodel))
	{
		if(isdefined(level.bombmodel[0]))
			level.bombmodel[0] stopLoopSound();
		if(isdefined(level.bombmodel[1]))
			level.bombmodel[1] stopLoopSound();
	}

	// Give some time to the round winner announcement
	wait( [[level.ex_fpstime]](4) );

	if(game["alliedscore"] == game["axisscore"])
	{
		winningteam = "tie";
		losingteam = "tie";
		level createLevelHudElement("flag_draw", 320,110, "center","middle","fullscreen","fullscreen",false,game["draw_flag"],128,70,1,0.9,1,1,1);
	}
	else if(game["alliedscore"] > game["axisscore"])
	{
		winningteam = "allies";
		losingteam = "axis";
		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_" + game["allies"] + ".tga",128,128,1,0.9,1,1,1);
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_german.tga",128,128,1,0.9,1,1,1);
	}
	
	announceWinner(winningteam, 2);
	
	if(winningteam == "allies" || winningteam == "axis")
		level thread deleteLevelHudElementByName("flag_winner");
	else
		level thread deleteLevelHudElementByName("flag_draw");	
	wait( [[level.ex_fpstime]](1) );
	
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
		player extreme\_ex_spawn::spawnIntermission();
		
		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

	if(level.esd_campaign_mode) 
	{
		if(winningteam != "tie") setcvar("scr_esd_lastwinner", winningteam);
			else setcvar("scr_esd_lastwinner", game["attackers"]);
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0) return;

	if(game["timepassed"] < level.timelimit) return;

	if(level.mapended) return;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0) return;

	if(game["alliedscore"] < level.scorelimit && game["axisscore"] < level.scorelimit) return;

	if(level.mapended) return;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

checkRoundLimit()
{
	if(level.roundlimit <= 0) return;

	if(game["roundsplayed"] < level.roundlimit) return;

	if(level.mapended) return;

	iprintln(&"MP_ROUND_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_esd_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_esd_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock)) extreme\_ex_gtcommon::createClock();
				level.clock setTimer(level.timelimit * 60);
			}
			else if(isDefined(level.clock)) level.clock destroy();

			checkTimeLimit();
		}

		scorelimit = getcvarfloat("scr_esd_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			checkScoreLimit();
		}

		roundlimit = getcvarint("scr_esd_roundlimit");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
			setCvar("ui_roundlimit", level.roundlimit);

			checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateTeamStatus()
{
	wait 0; // Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

	if(!game["matchstarted"]) return;

	resettimeout();

	oldvalue["allies"] = level.exist["allies"];
	oldvalue["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(level.roundended) return;

	// if both allies and axis were alive and now they are both dead in the same instance
	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{
		if(level.bombplanted)
		{
			// if allies planted the bomb, allies win
			if(level.planting_team == "allies")
			{
				iprintlnbold(&"MP_ALLIEDMISSIONACCOMPLISHED");
				level thread endRound("allies");
				return;
			}
			else // axis planted the bomb, axis win
			{
				assert(game["attackers"] == "axis");
				iprintlnbold(&"MP_AXISMISSIONACCOMPLISHED");
				level thread endRound("axis");
				return;
			}
		}

		// if there is no bomb planted the round is a draw
		iprintlnbold(&"MP_ROUNDDRAW");
		level thread endRound("draw");
		return;
	}

	// if allies were alive and now they are not
	if(oldvalue["allies"] && !level.exist["allies"])
	{
		// if allies planted the bomb, continue the round
		if(level.bombplanted && level.planting_team == "allies") return;
		iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread extreme\_ex_utils::playSoundOnPlayers("mp_announcer_allieselim");
		level thread endRound("axis");
		return;
	}

	// if axis were alive and now they are not
	if(oldvalue["axis"] && !level.exist["axis"])
	{
		// if axis planted the bomb, continue the round
		if(level.bombplanted && level.planting_team == "axis") return;
		iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
		level thread extreme\_ex_utils::playSoundOnPlayers("mp_announcer_axiselim");
		level thread endRound("allies");
		return;
	}
}

bombzones()
{
	maperrors = [];

	level.barsize = 192;

	wait( [[level.ex_fpstime]](0.2) );

	bombzones = getentarray("bombzone", "targetname");
	array = [];

	if(level.bombmode == 0)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isdefined(bombzone.script_bombmode_original) && isdefined(bombzone.script_label))
				array[array.size] = bombzone;
		}

		if(array.size == 2)
		{
			bombzone0 = array[0];
			bombzone1 = array[1];
			bombzoneA = undefined;
			bombzoneB = undefined;

			if(bombzone0.script_label == "A" || bombzone0.script_label == "a")
		 	{
		 		bombzoneA = bombzone0;
		 		bombzoneB = bombzone1;
		 	}
		 	else if(bombzone0.script_label == "B" || bombzone0.script_label == "b")
		 	{
		 		bombzoneA = bombzone1;
		 		bombzoneB = bombzone0;
		 	}
		 	else
		 		maperrors[maperrors.size] = "^1Bombmode original: Bombzone found with an invalid \"script_label\", must be \"A\" or \"B\"";

	 		objective_add(0, "current", bombzoneA.origin, "objectiveA");
	 		objective_add(1, "current", bombzoneB.origin, "objectiveB");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneA.origin, "0", "allies", "objpoint_A");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneB.origin, "1", "allies", "objpoint_B");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneA.origin, "0", "axis", "objpoint_A");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneB.origin, "1", "axis", "objpoint_B");

	 		bombzoneA thread bombzone_think(bombzoneB, 0);
			bombzoneB thread bombzone_think(bombzoneA, 1);
			
		}
		else if(array.size < 2)
			maperrors[maperrors.size] = "^1Bombmode original: Less than 2 bombzones found with \"script_bombmode_original\" \"1\"";
		else if(array.size > 2)
			maperrors[maperrors.size] = "^1Bombmode original: More than 2 bombzones found with \"script_bombmode_original\" \"1\"";
	}
	else if(level.bombmode == 1)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isdefined(bombzone.script_bombmode_single))
				array[array.size] = bombzone;
		}

		if(array.size == 1)
		{
	 		objective_add(0, "current", array[0].origin, "objective");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(array[0].origin, "single", "allies", "objpoint_star");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(array[0].origin, "single", "axis", "objpoint_star");

	 		array[0] thread bombzone_think();
		}
		else if(array.size < 1)
			maperrors[maperrors.size] = "^1Bombmode single: Less than 1 bombzone found with \"script_bombmode_single\" \"1\"";
		else if(array.size > 1)
			maperrors[maperrors.size] = "^1Bombmode single: More than 1 bombzone found with \"script_bombmode_single\" \"1\"";
	}
	else if(level.bombmode == 2)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isdefined(bombzone.script_bombmode_dual))
		 		array[array.size] = bombzone;
		}

		if(array.size == 2)
		{
	 		bombzone0 = array[0];
	 		bombzone1 = array[1];

	 		objective_add(0, "current", bombzone0.origin, "objective");
	 		objective_add(1, "current", bombzone1.origin, "objective");

	 		if(isdefined(bombzone0.script_team) && isdefined(bombzone1.script_team))
	 		{
	 			if((bombzone0.script_team == "allies" && bombzone1.script_team == "axis") || (bombzone0.script_team == "axis" || bombzone1.script_team == "allies"))
	 			{
	 				objective_team(0, bombzone0.script_team);
	 				objective_team(1, bombzone1.script_team);

					if(bombzone0.script_team == "allies")
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone0.origin, "0", "allies", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone1.origin, "1", "axis", "objpoint_star");
					}
					else
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone0.origin, "0", "axis", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone1.origin, "1", "allies", "objpoint_star");
					}
	 			}
	 			else
	 				maperrors[maperrors.size] = "^1Bombmode dual: One or more bombzones missing \"script_team\" \"allies\" or \"axis\"";
	 		}

	 		bombzone0 thread bombzone_think(bombzone1);
	 		bombzone1 thread bombzone_think(bombzone0);
			
		}
		else if(array.size < 2)
			maperrors[maperrors.size] = "^1Bombmode dual: Less than 2 bombzones found with \"script_bombmode_dual\" \"1\"";
		else if(array.size > 2)
			maperrors[maperrors.size] = "^1Bombmode dual: More than 2 bombzones found with \"script_bombmode_dual\" \"1\"";
	}
	else
		println("^6Unknown bomb mode");

	bombtriggers = getentarray("bombtrigger", "targetname");
	if(bombtriggers.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"bombtrigger\"";
	else if(bombtriggers.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"bombtrigger\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	bombtrigger = getent("bombtrigger", "targetname");
	bombtrigger maps\mp\_utility::triggerOff();

	// Kill unused bombzones and associated script_exploders

	accepted = [];
	for(i = 0; i < array.size; i++)
	{
		if(isdefined(array[i].script_noteworthy))
			accepted[accepted.size] = array[i].script_noteworthy;
	}

	remove = [];
	bombzones = getentarray("bombzone", "targetname");
	for(i = 0; i < bombzones.size; i++)
	{
		bombzone = bombzones[i];

		if(isdefined(bombzone.script_noteworthy))
		{
			addtolist = true;
			for(j = 0; j < accepted.size; j++)
			{
				if(bombzone.script_noteworthy == accepted[j])
				{
					addtolist = false;
					break;
				}
			}

			if(addtolist)
				remove[remove.size] = bombzone.script_noteworthy;
		}
	}

	ents = getentarray();
	for(i = 0; i < ents.size; i++)
	{
		ent = ents[i];

		if(isdefined(ent.script_exploder))
		{
			kill = false;
			for(j = 0; j < remove.size; j++)
			{
				if(ent.script_exploder == int(remove[j]))
				{
					kill = true;
					break;
				}
			}

			if(kill)
				ent delete();
		}
	}
}

bombzone_think(bombzone_other, id)
{
	level endon("round_ended");

	level.barincrement = (level.barsize / (20.0 * level.planttime));

	self setteamfortrigger(game["attackers"]);
	self setHintString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");

	for(;;)
	{
		self waittill("trigger", other);

		if((!level.esd_mode) && isdefined(bombzone_other) && isdefined(bombzone_other.planting))
			continue;

		if(level.roundended) continue;
		
		if(level.bombmode == 2 && isdefined(self.script_team))
			team = self.script_team;
		else
			team = game["attackers"];

		if(isPlayer(other) && (other.pers["team"] == team) && other isOnGround())
		{
			while(isAlive(other) && other istouching(self) && other useButtonPressed() && (!level.roundended))
			{
				other notify("kill_check_bombzone");

				self.planting = true;
				other.ex_planting = true;
				other clientclaimtrigger(self);
				
				if((!level.esd_mode) && isdefined(bombzone_other))
					other clientclaimtrigger(bombzone_other);

				if(!isdefined(other.progressbackground))
				{
					other.progressbackground = newClientHudElem(other);
					other.progressbackground.x = 0;
					other.progressbackground.y = 104;
					other.progressbackground.alignX = "center";
					other.progressbackground.alignY = "middle";
					other.progressbackground.horzAlign = "center_safearea";
					other.progressbackground.vertAlign = "center_safearea";
					other.progressbackground.alpha = 0.5;
				}
				other.progressbackground setShader("black", (level.barsize + 4), 12);

				if(!isdefined(other.progressbar))
				{
					other.progressbar = newClientHudElem(other);
					other.progressbar.x = int(level.barsize / (-2.0));
					other.progressbar.y = 104;
					other.progressbar.alignX = "left";
					other.progressbar.alignY = "middle";
					other.progressbar.horzAlign = "center_safearea";
					other.progressbar.vertAlign = "center_safearea";
				}
				other.progressbar setShader("white", 0, 8);
				other.progressbar scaleOverTime(level.planttime, level.barsize, 8);

				other playsound("MP_bomb_plant");
				other linkTo(self);
				other [[level.ex_dWeapon]]();

				self.progresstime = 0;
				while(isAlive(other) && other useButtonPressed() && self.progresstime < level.planttime)
				{
					self.progresstime += level.ex_fps_frame;
					wait( [[level.ex_fpstime]](level.ex_fps_frame) );
				}

				// TODO: script error if player is disconnected/kicked here
				other clientreleasetrigger(self);
				other.ex_planting = undefined;

				if((!level.esd_mode) && isdefined(bombzone_other))
					other clientreleasetrigger(bombzone_other);

				if(self.progresstime >= level.planttime)
				{
					other.progressbackground destroy();
					other.progressbar destroy();
					
					if(level.esd_mode)
						other unlink();
					
					other [[level.ex_eWeapon]]();

					if(isdefined(self.target))
					{
						exploder = getent(self.target, "targetname");

						if(isdefined(exploder) && isdefined(exploder.script_exploder))
							level.bombexploder[id] = exploder.script_exploder;
					}

					if(!level.esd_mode)
					{
						bombzones = getentarray("bombzone", "targetname");
						for(i = 0; i < bombzones.size; i++)
							bombzones[i] delete();
					}
					
					if(level.bombmode == 1)
					{
						objective_delete(0);
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
					{
						if(!level.esd_mode)
						{
							objective_delete(0);
							objective_delete(1);
							thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
							thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
						}
					}

					plant = other maps\mp\_utility::getPlant();

					level.bombmodel[id] = spawn("script_model", plant.origin);
					level.bombmodel[id].angles = plant.angles;
					level.bombmodel[id] setmodel("xmodel/mp_tntbomb");
					level.bombmodel[id] playSound("Explo_plant_no_tick");
					level.bombglow[id] = spawn("script_model", plant.origin);
					level.bombglow[id].angles = plant.angles;
					level.bombglow[id] setmodel("xmodel/mp_tntbomb_obj");

					if(!level.esd_mode)
					{
						bombtrigger = getent("bombtrigger", "targetname");
						bombtrigger.origin = level.bombmodel[id].origin;
					}
					else
						bombtrigger = self;
					
					if(!level.esd_mode)
					{
						objective_add(0, "current", bombtrigger.origin, "objective");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
						objective_icon(id, "objective");

					if(!level.esd_mode)
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombtrigger.origin, "bomb", "allies", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombtrigger.origin, "bomb", "axis", "objpoint_star");
					}
					else
					{
						name = "" + id;
						thread changeTeamObjpoints(name, "allies", "objpoint_star", true);
						thread changeTeamObjpoints(name, "axis", "objpoint_star", true);
					}
					
					if(!level.esd_mode)
					{
						level.bombplanted = true;
					}
					else
					{
						self.bombplanted[id] = true;
					}
					
					if(level.esd_mode)
					{
						self.lastbombplanted[id] = true;
					}	
					else if(!level.esd_mode) level.lastbombplanted = true;
						
					level.bombtimerstart = gettime();
					level.planting_team = other.pers["team"];
					
					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "bomb_plant" + "\n");

					iprintln(&"MP_EXPLOSIVESPLANTED");
					level thread soundPlanted(other);

					other.pers["score"] += level.plantscore;
					other.score = other.pers["score"];
					if(level.ex_ranksystem) other.pers["special"] += level.plantscore;
					// added for arcade style HUD points
					other notify("update_playerscore_hud");

					bombtrigger thread bomb_think(id);
					bombtrigger thread bomb_countdown(id);

					if(!level.esd_mode)
					{
						level notify("bomb_planted");
						level.clock destroy();
						return;
					}
					else if(level.defuseback)
					{
						self waittill("bomb_defuseback");
						self.bombplanted[id] = false;
						self.bombdefused[id] = false;
						self setteamfortrigger(game["attackers"]);
						self setHintString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
						break;
					}
					else
						return;
				}
				else
				{
					if(isdefined(other.progressbackground))
						other.progressbackground destroy();

					if(isdefined(other.progressbar))
						other.progressbar destroy();

					other unlink();
					other [[level.ex_eWeapon]]();
				}

				wait( [[level.ex_fpstime]](0.05) );
			}

			self.planting = undefined;
			other.ex_planting = undefined;
			other thread check_bombzone(self);
		}
	}
}

check_bombzone(trigger)
{
	self notify("kill_check_bombzone");
	self endon("kill_check_bombzone");
	self endon("disconnect");
	level endon("round_ended");

	while(isDefined(trigger) && !isDefined(trigger.planting) && self istouching(trigger) && isAlive(self))
		wait( [[level.ex_fpstime]](0.05) );
}

bomb_countdown(id)
{
	self endon("bomb_defused");
	level endon("intermission");

	thread showBombTimers(id);
	level.bombmodel[id] playLoopSound("bomb_tick");

	wait( [[level.ex_fpstime]](level.bombtimer) );

	// bomb timer is up
	if(!level.esd_mode)
	{
		objective_delete(0);
		thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
		thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
	}
	else
	{
		objective_delete(id);
		name = "" + id;
		thread changeTeamObjpoints(name, "allies", "", false);
		thread changeTeamObjpoints(name, "axis", "", false);
	}
	
	thread deleteBombTimers(id);
	
	self.bombexploded[id] = true;
	level.bombexploded = self.bombexploded[id];
	
	wait( [[level.ex_fpstime]](0.3) );
	
	self notify("bomb_exploded");

	// trigger exploder if it exists
	if(isdefined(level.bombexploder) && isdefined(level.bombexploder[id]))
	{
		maps\mp\_utility::exploder(level.bombexploder[id]);
	}

	// explode bomb
	origin = self getorigin();
	range = 500;
	maxdamage = 2000;
	mindamage = 1000;

	self delete(); // delete the defuse trigger
	level.bombmodel[id] stopLoopSound();
	level.bombmodel[id] delete();
	level.bombglow[id] delete();

	playfx(level._effect["bombexplosion"], origin);
	radiusDamage(origin, range, maxdamage, mindamage);

	level thread extreme\_ex_utils::playSoundOnPlayers("mp_announcer_objdest");

	if((level.esd_mode == 0) || (level.esd_mode == 1) || (level.esd_mode == 3))
		level thread endRound(level.planting_team);
		
	if((level.esd_mode == 2) || (level.esd_mode == 4))
		level thread Check_objectives_Complete();
}

Check_objectives_Complete()
{
	level.objectives_count++;
	if(level.objectives_count == 2) level thread endRound(level.planting_team);
}

bomb_think(id)
{
	self endon("bomb_exploded");
	level.barincrement = (level.barsize / (20.0 * level.defusetime));

	self setteamfortrigger(game["defenders"]);
	self setHintString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");

	for(;;)
	{
		self waittill("trigger", other);

		if(level.roundended) continue;

		// check for having been triggered by a valid player
		if(isPlayer(other) && (other.pers["team"] != level.planting_team) && other isOnGround())
		{
			while(isAlive(other) && other useButtonPressed() && (!level.roundended) && !level.bombexploded)
			{
				other notify("kill_check_bomb");

				other clientclaimtrigger(self);
				other.ex_defusing = true;

				if(!isdefined(other.progressbackground))
				{
					other.progressbackground = newClientHudElem(other);
					other.progressbackground.x = 0;
					other.progressbackground.y = 104;
					other.progressbackground.alignX = "center";
					other.progressbackground.alignY = "middle";
					other.progressbackground.horzAlign= "center_safearea";
					other.progressbackground.vertAlign = "center_safearea";
					other.progressbackground.alpha = 0.5;
				}
				other.progressbackground setShader("black", (level.barsize + 4), 12);

				if(!isdefined(other.progressbar))
				{
					other.progressbar = newClientHudElem(other);
					other.progressbar.x = int(level.barsize / (-2.0));
					other.progressbar.y = 104;
					other.progressbar.alignX = "left";
					other.progressbar.alignY = "middle";
					other.progressbar.horzAlign = "center_safearea";
					other.progressbar.vertAlign = "center_safearea";
				}
				other.progressbar setShader("white", 0, 8);
				other.progressbar scaleOverTime(level.defusetime, level.barsize, 8);

				other playsound("MP_bomb_defuse");
				other linkTo(self);
				other [[level.ex_dWeapon]]();

				self.progresstime = 0;
				while(isAlive(other) && other useButtonPressed() && self.progresstime < level.defusetime)
				{
					self.progresstime += level.ex_fps_frame;
					wait( [[level.ex_fpstime]](level.ex_fps_frame) );
				}

				other clientreleasetrigger(self);
				other.ex_defusing = undefined;

				if(self.progresstime >= level.defusetime)
				{
					other.progressbackground destroy();
					other.progressbar destroy();

					if(!level.esd_mode)
					{
						objective_delete(0);
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
					{
						other unlink();
						other [[level.ex_eWeapon]]();
						
						if(level.defuseback)
						{
							if(id == 0)
							{
								objective_icon(0, "objectiveA");
								thread changeTeamObjpoints("0", "allies", "objpoint_A", true);
								thread changeTeamObjpoints("0", "axis", "objpoint_A", true);
							}
							else
							{
								objective_icon(1, "objectiveB");
								thread changeTeamObjpoints("1", "allies", "objpoint_B", true);
								thread changeTeamObjpoints("1", "axis", "objpoint_B", true);
							}
						}
						else
						{
							objective_delete(id);
							name = "" + id;
							thread changeTeamObjpoints(name, "allies", "", false);
							thread changeTeamObjpoints(name, "axis", "", false);
						}
					}
					
					thread deleteBombTimers(id);

					self notify("bomb_defused");
					self.bombdefused[id] = true;
					level.bombmodel[id] stopLoopSound();
					level.bombmodel[id] delete();
					level.bombglow[id] delete();
					
					if(!level.defuseback)
						self delete();

					iprintln(&"MP_EXPLOSIVESDEFUSED");
					level thread extreme\_ex_utils::playSoundOnPlayers("MP_announcer_bomb_defused");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "bomb_defuse" + "\n");

					other.pers["score"] += level.defusescore;
					other.score = other.pers["score"];
					if(level.ex_ranksystem) other.pers["special"] += level.defusescore;
					// added for arcade style HUD points
					other notify("update_playerscore_hud");

					if(!level.esd_mode)
					{
						level thread endRound(other.pers["team"]);
						return;
					}

					if((!level.defuseback) && (level.esd_mode == 2))
					{
						level thread endRound(other.pers["team"]);
						return;
					}
					
					if((!level.defuseback) && level.esd_mode == 1)
					{
						level thread Check_objectives_defused();
						return;
					}
					
					if(level.defuseback)
						self notify("bomb_defuseback");
					
					return;
				}
				else
				{
					if(isdefined(other.progressbackground))
						other.progressbackground destroy();

					if(isdefined(other.progressbar))
						other.progressbar destroy();

					other unlink();
					other [[level.ex_eWeapon]]();
				}

				wait( [[level.ex_fpstime]](0.05) );
			}

			self.defusing = undefined;
			other.ex_defusing = undefined;
			other thread check_bomb(self);
		}
	}
}

Check_objectives_defused()
{
	level.defused_count++;
	
	if(level.defused_count == 2)
	{
		if(game["defenders"] == "allies")
			level thread endRound("allies");
		else
			level thread endRound("axis");
	}
}

check_bomb(trigger)
{
	self notify("kill_check_bomb");
	self endon("kill_check_bomb");
	self endon("disconnect");
	level endon("round_ended");

	while(isDefined(trigger) && !isDefined(trigger.defusing) && self istouching(trigger) && isAlive(self))
		wait( [[level.ex_fpstime]](0.05) );
}

sayMoveIn()
{
	wait( [[level.ex_fpstime]](2) );

	alliedsoundalias = game["allies"] + "_move_in";
	axissoundalias = game["axis"] + "_move_in";

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] == "allies") player playLocalSound(alliedsoundalias);
		else if(player.pers["team"] == "axis") player playLocalSound(axissoundalias);
	}
}

showBombTimers(id)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			player showPlayerBombTimer(id);
	}
}

showPlayerBombTimer(id)
{
	timeleft = (level.bombtimer - (getTime() - level.bombtimerstart) / 1000);

	if(timeleft > 0)
	{
		self.bombtimer[id] = newClientHudElem(self);

		if(!level.esd_mode)
		{
			self.bombtimer[id].x = 6;
			self.bombtimer[id].y = 76;
		}
		else
		{
			self.bombtimer[id].x = 6 + 48 * id;
			self.bombtimer[id].y = 76;
		}
		self.bombtimer[id].horzAlign = "left";
		self.bombtimer[id].vertAlign = "top";

		if(!level.esd_mode)
			self.bombtimer[id] setClock(timeleft, level.bombtimer, "hudStopwatch", 48, 48);
		else
			self.bombtimer[id] setClock(timeleft, level.bombtimer, "hudStopwatch", 40, 40);
	}
}

deleteBombTimers(id)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		players[i] deletePlayerBombTimer(id);
}

deletePlayerBombTimer(id)
{
	if(isDefined(self.bombtimer) && isDefined(self.bombtimer[id]))
		self.bombtimer[id] destroy();
}

announceWinner(winner, delay)
{
	if(winner == "allies")
	{
		if(level.mapended) text = &"MP_ALLIES_WIN";
			else text = &"MP_ALLIES_WIN_ROUND";
		iprintlnbold(text);
		level thread extreme\_ex_utils::playSoundOnPlayers("MP_announcer_allies_win");
	}
	else if(winner == "axis")
	{
		if(level.mapended) text = &"MP_AXIS_WIN";
			else text = &"MP_AXIS_WIN_ROUND";
		iprintlnbold(text);
		level thread extreme\_ex_utils::playSoundOnPlayers("MP_announcer_axis_win");
	}
	else
	{
		if(level.mapended) text = &"MP_THE_GAME_IS_A_TIE";
			else text = &"MP_THE_ROUND_IS_A_TIE";
		iprintlnbold(text);
		level thread extreme\_ex_utils::playSoundOnPlayers("MP_announcer_round_draw");
	}

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player setClientCvar("cg_objectiveText", text);
	}

	wait( [[level.ex_fpstime]](delay) );
}

changeTeamObjpoints(name, team, material, drawwaypoint)
{

	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if(isdefined(player.pers["team"]) && (player.pers["team"] == team) && (player.sessionstate == "playing"))
		{
			objpoints = player.objpoints;
			for(j = 0; j < objpoints.size; j ++)
			{
				if(objpoints[j].name == name)
				{
					objpoints[j] setShader(material, level.objpoint_scale, level.objpoint_scale);
					objpoints[j] setwaypoint(drawwaypoint);
				}
			}
		}
		
		objpoints = level.objpoints_allies.array;
		for(j = 0; j < objpoints.size; j ++)
		{
			if(objpoints[j].name == name)
				objpoints[j].material = material;
		}
		
		objpoints = level.objpoints_axis.array;
		for(j = 0; j < objpoints.size; j ++)
		{
			if(objpoints[j].name == name)
				objpoints[j].material = material;
		}
	}
}

soundPlanted(player)
{
	if(game["allies"] == "british") alliedsound = "UK_mp_explosivesplanted";
	else if(game["allies"] == "russian") alliedsound = "RU_mp_explosivesplanted";
	else alliedsound = "US_mp_explosivesplanted";

	axissound = "GE_mp_explosivesplanted";

	level extreme\_ex_utils::playSoundOnPlayers(alliedsound, "allies");
	level extreme\_ex_utils::playSoundOnPlayers(axissound, "axis");

	wait( [[level.ex_fpstime]](1.5) );

	if(level.planting_team == "allies")
	{
		if(game["allies"] == "british") alliedsound = "UK_mp_defendbomb";
		else if(game["allies"] == "russian") alliedsound = "RU_mp_defendbomb";
		else alliedsound = "US_mp_defendbomb";

		level extreme\_ex_utils::playSoundOnPlayers(alliedsound, "allies");
		level extreme\_ex_utils::playSoundOnPlayers("GE_mp_defusebomb", "axis");
	}
	else if(level.planting_team == "axis")
	{
		if(game["allies"] == "british") alliedsound = "UK_mp_defusebomb";
		else if(game["allies"] == "russian") alliedsound = "RU_mp_defusebomb";
		else alliedsound = "US_mp_defusebomb";

		level extreme\_ex_utils::playSoundOnPlayers(alliedsound, "allies");
		level extreme\_ex_utils::playSoundOnPlayers("GE_mp_defendbomb", "axis");
	}
}

createLevelHudElement(hud_element_name, x,y,xAlign,yAlign,horzAlign,vertAlign,foreground,shader,shader_width,shader_height,sort,alpha,color_r,color_g,color_b) 
{
	if(!isDefined(level.hud)) level.hud = [];
	
	count = level.hud.size;

	level.hud[count] = newHudElem();
	level.hud[count].x = x;
	level.hud[count].y = y;
	level.hud[count].alignX = xAlign;
	level.hud[count].alignY = yAlign;
	level.hud[count].horzAlign = horzAlign;
	level.hud[count].vertAlign = vertAlign;
	level.hud[count].foreground = foreground;
	level.hud[count] setShader(shader, shader_width, shader_height);	
	level.hud[count].sort = sort;
	level.hud[count].alpha = alpha;
	level.hud[count].color = (color_r,color_g,color_b);
	
	level.hud[count].name 			= hud_element_name;
	level.hud[count].shader_name 	= shader;
	level.hud[count].shader_width 	= shader_width;
	level.hud[count].shader_height 	= shader_height;
}

deleteLevelHudElementByName(hud_element_name) 
{
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
		for(i=0;i<level.hud.size;i++)
		{
			if(isDefined(level.hud[i].name) && level.hud[i].name == hud_element_name) 
			{
				level.hud[i] destroy();
				level.hud[i].name = undefined;
			}
		}
		
		new_ar = [];
		for(i=0;i<level.hud.size;i++)
			if(isDefined(level.hud[i].name)) new_ar[new_ar.size] = level.hud[i];			
		
		level.hud = new_ar;
	}
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

GivePointsToTeam(team, points)
{
	players = level.players;
	
	// count up the people in the flag area
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isAlive(player) && player.pers["team"] == team)
		{
			player.pers["score"] += points;
			player.score = player.pers["score"];
			// added for arcade style HUD points
			player notify("update_playerscore_hud");
		}
	}
}
