/*------------------------------------------------------------------------------
	Roundbased CTF - Scripted by Tally 21/4/2007
	This is essentially the UO version of CTF. Original scripts from GMI UO.
	
	Round Objective: To win the set number of flags per round.
	Attackers: Either achieve the round objective, or eliminate the enemy
	Defenders: Either eliminate the enemy, or achieve the round objective
	Defenders win by default if the round objective isnt achieved by attackers

	Script contributions by bell (krister, AWE 2.12), La Truffe (nedgerblansky)
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

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflagmissing_allies = "objpoint_flagmissing_" + game["allies"];
	level.objpointflagmissing_axis = "objpoint_flagmissing_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	
	//Setup the hud icons
	switch(game["allies"])
	{
		case "american":
			game["objecticon_allies"] = "hud_flag_american";
			game["draw_flag"] = "flag_draw_us";
			game["flag_taken"] = "US_mp_flagtaken";
			break;
		case "british":
			game["objecticon_allies"] = "hud_flag_british";
			game["draw_flag"] = "flag_draw_brit";
			game["flag_taken"] = "UK_mp_flagtaken";
			break;
		case "russian":
			game["objecticon_allies"] = "hud_flag_russian";
			game["draw_flag"] = "flag_draw_rus";
			game["flag_taken"] = "RU_mp_flagtaken";
			break;
	}

	game["objecticon_axis"] = "hud_flag_german";

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
			precacheStatusIcon(level.hudflag_allies);
			precacheStatusIcon(level.hudflag_axis);
		}
		precacheShader(level.compassflag_allies);
		precacheShader(level.compassflag_axis);
		precacheShader(level.objpointflag_allies);
		precacheShader(level.objpointflag_axis);
		precacheShader(level.hudflag_allies);
		precacheShader(level.hudflag_axis);
		precacheShader(level.objpointflag_allies);
		precacheShader(level.objpointflag_axis);
		precacheShader(level.objpointflagmissing_allies);
		precacheShader(level.objpointflagmissing_axis);
		precacheShader(game["objecticon_allies"]);
		precacheShader(game["objecticon_axis"]);
		precacheShader(game["draw_flag"]);
		precacheModel("xmodel/prop_flag_" + game["allies"]);
		precacheModel("xmodel/prop_flag_" + game["axis"]);
		precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
		precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
		precacheShader("gfx/custom/flagge_german.tga");
		precacheShader("gfx/custom/flagge_" + game["allies"] + ".tga");
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
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
	setClientNameMode("manual_change");

	spawnpointname = "mp_ctf_spawn_allied";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_ctf_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);	

	level.roundended = false;
	level.mapended = false;
	level.axis_eliminated = undefined;
	level.allied_eliminated = undefined;
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	level.allies_cap_count = 0; // how many times the allies capped in the current round
	level.axis_cap_count = 0; // how many times the axis capped in the current round

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];
	
	if(!isdefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	if(!isdefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);

	if(!isdefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["matchstarted"])) game["matchstarted"] = false;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread initFlags();
		thread startGame();
		thread updateGametypeCvars();
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

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
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
	self dropFlag();
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
	if(!isdefined(vDir))
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
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * level.ex_friendlyfire_reflect);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

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
				if(iDamage < 1)
					iDamage = 1;

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
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
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

	if(self.sessionteam == "spectator")
		return;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();
	
	flagrunner = false;
	if(isdefined(self.flag))
	{
		flagrunner = true;
		self dropFlag();
	}

	self.sessionstate = "dead";
	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams))
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
			if(isdefined(self.switching_teams))
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

			if(isdefined(attacker.friendlydamage))
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;
			
			// Only handle points if game has not ended
			if(!level.roundended)
			{
				// Check if extra points should be given for bash or headshot
				reward_points = 0;
				if(isDefined(sMeansOfDeath))
				{
					if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
						else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
				}

				if(flagrunner) reward_points += level.ex_rbctfpoints_playerkf;

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
					reward_points = 0;
					// if the dead person was close to the flag then give the killer a defense bonus
					if(self isnearFlag() )
					{
						reward_points++;
						lpattacknum = attacker getEntityNumber();
						lpattackguid = attacker getGuid();
						logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + attacker.pers["team"] + ";" + attacker.name + ";" + "rbctf_defended" + "\n");
					}

					// if the dead person was close to the flag carrier then give the killer an assist bonus
					if(self isnearCarrier(attacker) )
					{
						reward_points++;
						lpattacknum = attacker getEntityNumber();
						lpattackguid = attacker getGuid();
						logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + attacker.pers["team"] + ";" + attacker.name + ";" + "rbctf_assist" + "\n");
					}
				}

				points += reward_points;
				attacker.pers["score"] += points;
				attacker.pers["bonus"] += reward_points;
				attacker.score = attacker.pers["score"];
				// added for arcade style HUD points
				attacker notify("update_playerscore_hud");
			}
		}

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

	spawnpoint = undefined;
	spawnpointname = "";

	if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
		else spawnpointname = "mp_ctf_spawn_axis";

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

	if(isdefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
		else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	level updateTeamStatus();

	if(!isdefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isdefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];

	if(!isdefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);
		
	self extreme\_ex_weapons::loadout();

	if(level.scorelimit > 0) self setClientCvar("cg_objectiveText", &"MP_RBCTF_OBJ_TEXT");
		else self setClientCvar("cg_objectiveText", &"MP_RBCTF_OBJ_TEXT_NOSCORE");

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
		if(!isdefined(self.deathcount))
			self.deathcount = 0;
		
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
	thread startHUD();
	thread startRound();
}

clock()
{
	mastertime = level.timelimit - game["timepassed"];
	if(level.show_total_time && mastertime > 0) extreme\_ex_gtcommon::createClock(1, mastertime * 60);
	extreme\_ex_gtcommon::createClock(2, level.roundlength * 60);
}

startRound()
{
	level endon("round_ended");

	game["matchstarted"] = true; // mainly to control UpdateTeamStatus
	game["roundnumber"]++;

	thread clock();

	level.allies_cap_count = 0;
	level.axis_cap_count = 0;
	
	wait( [[level.ex_fpstime]](level.roundlength * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	if(level.allies_cap_count == level.axis_cap_count)
	{
		iprintlnBold(&"MP_ROUNDDRAW");
		level thread endRound("draw");
	}
	else if(level.allies_cap_count > level.axis_cap_count )
	{
		iprintlnBold(&"MP_ALLIEDMISSIONACCOMPLISHED");
		level thread endRound("allies");
	}
	else
	{
		iprintlnBold(&"MP_AXISMISSIONACCOMPLISHED");
		level thread endRound("axis");
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

	if(level.ex_readyup == 2)
	{
		players = level.players;
		for(i = 0; i < players.size; i++) players[i].pers["readyup_spawnticket"] = 1;
	}

	winners = "";
	losers = "";
	
	game["alliedscore"] = getTeamScore("allies");
	game["axisscore"] = getTeamScore("axis");

	if(roundwinner == "allies")
	{	
		if(isdefined(level.axis_eliminated)) game["alliedscore"]+= 5;
		
		points = level.ex_rbctfpoints_roundwin;
		GivePointsToTeam("allies", points);
		
		setTeamScore("allies", game["alliedscore"]);

		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_" + game["allies"] + ".tga",128,128,1,0.9,1,1,1);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			lpselfguid = players[i] getGuid();
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				winners = (winners + ";" + lpselfguid + ";" + players[i].name);
			else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				losers = (losers + ";" + lpselfguid + ";" + players[i].name);
		}
		logPrint("W;allies" + winners + "\n");
		logPrint("L;axis" + losers + "\n");
	}
	else if(roundwinner == "axis")
	{	
		if(isdefined(level.allied_eliminated)) game["axisscore"]+= 5;
		
		points = level.ex_rbctfpoints_roundwin;
		GivePointsToTeam("axis", points);
		
		setTeamScore("axis", game["axisscore"]);
		
		level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_" + game["axis"] + ".tga",128,128,1,0.9,1,1,1);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			lpselfguid = players[i] getGuid();
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				winners = (winners + ";" + lpselfguid + ";" + players[i].name);
			else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				losers = (losers + ";" + lpselfguid + ";" + players[i].name);
		}
		logPrint("W;axis" + winners + "\n");
		logPrint("L;allies" + losers + "\n");
	}
	else if(roundwinner == "draw")
	{
		level createLevelHudElement("flag_draw", 320,110, "center","middle","fullscreen","fullscreen",false,game["draw_flag"],128,70,1,0.9,1,1,1);
	}

	announceWinner(roundwinner, 2);

	if(roundwinner == "allies" || roundwinner == "axis") level thread deleteLevelHudElementByName("flag_winner");
		else level thread deleteLevelHudElementByName("flag_draw");
	wait( [[level.ex_fpstime]](1) );

	checkScoreLimit();
	game["roundsplayed"]++;
	checkRoundLimit();

	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	checkTimeLimit();

	if(level.mapended) return;

	if(level.ex_flag_drop) level thread dropflagUntag();
	iprintlnbold(&"MP_STARTING_NEW_ROUND");
	level notify("restarting");
	wait( [[level.ex_fpstime]](2) );

	if(level.ex_swapteams) extreme\_ex_main::swapTeams();

	map_restart(true);
}

endMap()
{
	level.mapended = true;

	// Give some time to the round winner announcement
	wait( [[level.ex_fpstime]](4) );

	game["alliedscore"] = getTeamScore("allies");
	game["axisscore"] = getTeamScore("axis");

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

	if(winningteam == "allies" || winningteam == "axis") level thread deleteLevelHudElementByName("flag_winner");
		else level thread deleteLevelHudElementByName("flag_draw");
	wait( [[level.ex_fpstime]](1) );

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();
		player extreme\_ex_spawn::spawnIntermission();
		
		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0) return;

	if(game["timepassed"] < level.timelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0) return;

	if(game["alliedscore"] < level.scorelimit && game["axisscore"] < level.scorelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

checkRoundLimit()
{
	if(level.roundlimit <= 0) return;

	if(game["roundsplayed"] < level.roundlimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_ROUND_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_rbctf_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_rbctf_timelimit", "1440");
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

			if(game["matchstarted"])
				checkTimeLimit();
		}

		scorelimit = level.scorelimit;
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			if(game["matchstarted"])
				checkScoreLimit();
		}

		roundlimit = getcvarint("scr_rbctf_roundlimit");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
			setCvar("ui_roundlimit", level.roundlimit);

			if(game["matchstarted"])
				checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateTeamStatus()
{
	wait 0;	// Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

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

		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(level.roundended) return;

	// if both allies and axis were alive and now they are both dead in the same instance
	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{
		iprintlnbold(&"MP_ROUNDDRAW");
		level thread endRound("draw");
		return;
	}

	// if allies were alive and now they are not
	if(oldvalue["allies"] && !level.exist["allies"])
	{
		level.allied_eliminated = true;
		iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread playSoundOnPlayers("mp_announcer_allieselim");
		level thread endRound("axis");
		return;
	}

	// if axis were alive and now they are not
	if(oldvalue["axis"] && !level.exist["axis"])
	{
		level.axis_eliminated = true;
		iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
		level thread playSoundOnPlayers("mp_announcer_axiselim");
		level thread endRound("allies");
		
		return;
	}
}

initFlags()
{
	maperrors = [];

	allied_flags = getentarray("allied_flag", "targetname");
	if(allied_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"allied_flag\"";
	else if(allied_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"allied_flag\"";

	axis_flags = getentarray("axis_flag", "targetname");
	if(axis_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"axis_flag\"";
	else if(axis_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"axis_flag\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
	allied_flag.basemodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.basemodel.angles = allied_flag.home_angles;
	allied_flag.basemodel setmodel("xmodel/prop_flag_base");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;
	allied_flag.objpointflag = level.objpointflag_allies;
	allied_flag.objpointflagmissing = level.objpointflagmissing_allies;
	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
	axis_flag.basemodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.basemodel.angles = axis_flag.home_angles;
	axis_flag.basemodel setmodel("xmodel/prop_flag_base");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;
	axis_flag.objpointflag = level.objpointflag_axis;
	axis_flag.objpointflagmissing = level.objpointflagmissing_axis;
	axis_flag thread flag();
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self createFlagWaypoint();
	
	self.status = "home";
	
	for(;;)
	{
		self waittill("trigger", other);

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator") && !level.roundended)
		{
			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if(isdefined(other.flag)) // Captured flag
					{
						friendlyAlias = "ctf_touchcapture";
						enemyAlias = "ctf_enemy_touchcapture";

						if(self.team == "axis")
						{
							level.axis_cap_count++;
							enemy = "allies";
							if((level.ex_flag_voiceover & 2) == 2) level thread playSoundOnPlayers("GE_mp_flagcap");
						}
						else
						{
							level.allies_cap_count++;
							enemy = "axis";
							if((level.ex_flag_voiceover & 2) == 2) level thread playSoundOnPlayers("mp_announcer_axisflagcap");
						}

						level thread playSoundOnPlayers(friendlyAlias, self.team);
						level thread playSoundOnPlayers(enemyAlias, enemy);

						thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_CAPTURED", self.team, other);
						thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_CAPTURED", enemy, other);

						lpselfnum = other getEntityNumber();
						lpselfguid = other getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "rbctf_captured" + "\n");

						other.flag returnFlag();
						other detachFlag(other.flag);
						other.flag = undefined;
						other.statusicon = "";

						other.pers["score"] += level.ex_rbctfpoints_playercf;
						other.score = other.pers["score"];
						if(level.ex_ranksystem) other.pers["special"] += level.ex_rbctfpoints_playercf;
						// added for arcade style HUD points
						other notify("update_playerscore_hud");

						other.pers["flagcap"]++;
						if(level.ex_statshud) other thread extreme\_ex_statshud::showStatsHUD();

						teamscore = getTeamScore(other.pers["team"]);
						teamscore += level.ex_rbctfpoints_teamcf;
						setTeamScore(other.pers["team"], teamscore);
						level notify("update_teamscore_hud");

						checkScoreLimit();
					}
				}
				else // Returned flag
				{
					if(self.team == "axis")
					{
						enemy = "allies";
						if((level.ex_flag_voiceover & 4) == 4) level thread playSoundOnPlayers("mp_announcer_axisflagret");
					}
					else
					{
						enemy = "axis";
						if((level.ex_flag_voiceover & 4) == 4) level thread playSoundOnPlayers("mp_announcer_alliedflagret");
					}

					level thread playSoundOnPlayers("ctf_touchown", self.team);

					thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_RETURNED", self.team, other);

					self returnFlag();
					
					other.pers["flagret"]++;
					other.pers["score"] += level.ex_rbctfpoints_playerrf;
					other.score = other.pers["score"];
					if(level.ex_ranksystem) other.pers["special"] += level.ex_rbctfpoints_playerrf;
					// added for arcade style HUD points
					other notify("update_playerscore_hud");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "rbctf_returned" + "\n");
				}
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				friendlyAlias = "ctf_touchenemy";
				enemyAlias = "ctf_enemy_touchenemy";

				if(self.team == "axis")
					enemy = "allies";
				else
					enemy = "axis";

				level thread playSoundOnPlayers(enemyAlias, enemy);
				thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_TAKEN", self.team, other);
				thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_TAKEN", enemy, other);

				if(self.atbase) // Stolen flag
				{
					if((level.ex_flag_voiceover & 1) == 1)
					{
						if(self.team == "axis")
							level thread playSoundOnPlayers(game["flag_taken"]);
						else
							level thread playSoundOnPlayers("GE_mp_flagtaken");
					}

					other.score += level.ex_rbctfpoints_playersf;
					if(level.ex_ranksystem) other.pers["special"] += level.ex_rbctfpoints_playersf;
					other notify("update_playerscore_hud");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "rbctf_take" + "\n");
				}
				else // Picked up flag
				{
					if(!isDefined(other.flagDropped))
					{
						other.score += level.ex_rbctfpoints_playertf;
						if(level.ex_ranksystem) other.pers["special"] += level.ex_rbctfpoints_playertf;
						other notify("update_playerscore_hud");
					}

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "rbctf_pickup" + "\n");
				}

				other pickupFlag(self);
			}
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

pickupFlag(flag)
{
	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;

	flag.atbase=false;

	if(self.pers["team"] == "allies" && !level.ex_rank_statusicons)
		self.statusicon = level.hudflag_axis;
	else if(self.pers["team"] == "axis" && !level.ex_rank_statusicons)
		self.statusicon = level.hudflag_allies;

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();
	flag createFlagMissingWaypoint();

	objective_onEntity(self.flag.objective, self);
	objective_team(self.flag.objective, self.pers["team"]);

	self attachFlag();
}

dropFlag()
{
	if(isdefined(self.flag))
	{
		start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		self.statusicon = "";

		objective_position(self.flag.objective, self.flag.origin);
		objective_team(self.flag.objective, "none");

		self.flag createFlagWaypoint();
		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag returnFlag();
				break;
			}
		}

		if((level.ex_flag_voiceover & 8) == 8)
		{
			if(self.flag.team == "axis")
				level thread playSoundOnPlayers("mp_announcer_axisflagdrop");
			else
				level thread playSoundOnPlayers("mp_announcer_alliedflagdrop");
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

returnFlag()
{
	self notify("end_autoreturn");
	
	if(level.ex_flag_drop)
	{
		if(self.team == "axis") enemy = "allies";
			else enemy = "axis";
		level thread dropflagUntag(enemy);
	}

	self.status = "home";
	self.origin = self.home_origin;
	self.flagmodel.origin = self.home_origin;
	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	objective_position(self.objective, self.origin);
	objective_team(self.objective, "none");

	self createFlagWaypoint();
	self deleteFlagMissingWaypoint();
}

autoReturn()
{
	level endon("ex_gameover");
	self endon("end_autoreturn");

	wait( [[level.ex_fpstime]](level.flagautoreturndelay) );

	if(level.ex_gameover) announce_return = false;
		else announce_return = true;

	if(announce_return)
	{
		if(self.team == "axis")
		{
			level thread playSoundOnPlayers("mp_announcer_axisflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_DOWNTEAM");
		}
		else
		{
			level thread playSoundOnPlayers("mp_announcer_alliedflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_UPTEAM");
		}
	}

	self thread returnFlag();
}

attachFlag()
{
	if(isdefined(self.flagAttached))
		return;

	if(self.pers["team"] == "allies")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach(flagModel, "J_Spine4", true);
	self.flagAttached = true;
	
	self thread createHudIcon();
	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

detachFlag(flag)
{
	if(!isdefined(self.flagAttached))
		return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		
	self detach(flagModel, "J_Spine4");
	self.flagAttached = undefined;

	self thread deleteHudIcon();
}

dropFlagMonitor()
{
	level endon("ex_gameover");
	self endon("disconnect");

	while(isAlive(self) && isDefined(self.flagAttached))
	{
		if(self useButtonPressed() && self meleeButtonPressed())
		{
			dropspot = self getDropSpot(100);
			if(isDefined(dropspot))
			{
				self.flagDropped = true;
				self dropFlag(dropspot);
				break;
			}
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

dropflagUntag(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i].flagDropped = undefined;
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i].flagDropped = undefined;
	}
}

getDropSpot(radius)
{
	origin = self.origin + (0, 0, 20);
	dropspot = undefined;

	// scan 360 degrees in 20 degree increments for good spot to drop flag
	for(i = 0; i < 360; i += 20)
	{
		// locate candidate spot in circle
		spot0 = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), radius);
		trace = bulletTrace(origin, spot0, false, undefined);
		spot1 = trace["position"];
		dist1 = int(distance(origin, spot1) + 0.5);
		if(dist1 != radius) continue;

		// check if this spot is in minefield (unfortunately needs entity to check)
		badspot = false;
		model1 = spawn("script_model", spot1);
		model1 setmodel("xmodel/tag_origin");
		for(j = 0; j < level.flag_returners.size; j++)
		{
			if(model1 istouching(level.flag_returners[j]))
			{
				badspot = true;
				break;
			}
		}
		model1 delete();
		if(badspot) continue;

		// find ground level
		trace = bulletTrace(spot1, spot1 + (0, 0, -2000), false, undefined);
		spot2 = trace["position"];
		dist2 = int(distance(spot1, spot2) + 0.5);

		// make sure path is clear 50 units up
		trace = bulletTrace(spot2, spot2 + (0, 0, 50), false, undefined);
		spot3 = trace["position"];
		dist3 = int(distance(spot2, spot3) + 0.5);
		if(dist3 != 50) continue;

		dropspot = spot2;
		break;
	}

	return dropspot;
}

createHudIcon()
{
	iconSize = 40;

	self.hud_flag = newClientHudElem(self);
	self.hud_flag.horzAlign = "left";
	self.hud_flag.vertAlign = "top";
	self.hud_flag.alignX = "center";
	self.hud_flag.alignY = "middle";
	self.hud_flag.x = 30;
	self.hud_flag.y = 95;
	self.hud_flag.alpha = 1;

	if(self.pers["team"] == "allies") self.hud_flag setShader(level.hudflag_axis, iconSize, iconSize);
		else self.hud_flag setShader(level.hudflag_allies, iconSize, iconSize);
}

deleteHudIcon()
{
	if(isdefined(self.hud_flag)) self.hud_flag destroy();
}

createFlagWaypoint()
{
	if(!level.ex_objindicator)
		return;
		
	self deleteFlagWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.origin[0];
	waypoint.y = self.origin[1];
	waypoint.z = self.origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;
	waypoint setShader(self.objpointflag, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint_flag = waypoint;
}

deleteFlagWaypoint()
{
	if(isdefined(self.waypoint_flag))
		self.waypoint_flag destroy();
}

createFlagMissingWaypoint()
{
	if(!level.ex_objindicator)
		return;
		
	self deleteFlagMissingWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.home_origin[0];
	waypoint.y = self.home_origin[1];
	waypoint.z = self.home_origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;
	waypoint setShader(self.objpointflagmissing, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint_base = waypoint;
}

deleteFlagMissingWaypoint()
{
	if(isdefined(self.waypoint_base))
		self.waypoint_base destroy();
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
	level.hud[count].alpha = 0;
	level.hud[count].color = (color_r,color_g,color_b);
	
	level.hud[count] fadeOverTime(2);
	level.hud[count].alpha = .9;
	level.hud[count].name = hud_element_name;
	level.hud[count].shader_name = shader;
	level.hud[count].shader_width = shader_width;
	level.hud[count].shader_height = shader_height;
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

isnearFlag()
{
	// determine the opposite teams flag
	if( self.pers["team"] == "allies" )
		myflag = getent("axis_flag", "targetname");
	else
		myflag = getent("allied_flag", "targetname");

	// if the flag is not at the base then return false
	if(myflag.home_origin != myflag.origin)
		return false;
		
	dist = distance(myflag.home_origin, self.origin);
	
	// if they were close to the flag then return true
	if( dist < 850 )
		return true;
		
	return false;
}

isnearCarrier(attacker)
{
	// determine the teams flag
	if(self.pers["team"] == "allies" )
		myflag = getent("allied_flag", "targetname");
	else
		myflag = getent("axis_flag", "targetname");
		
	// if the flag is at the base then return false
	if(myflag.status == "home")
		return false;
	
	// if the attacker is the carrier then return false
	if(isdefined(attacker.flag))
		return false;
		
	// Find the player with the flag
	dist = 9999;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isdefined(player.flag) )
			continue;

		if(player.pers["team"] != attacker.pers["team"])
			continue;

		dist = distance(self.origin, player.origin);
	}
	
	// if they were close to the flag carrier then return true
	if( dist < 850 )
		return true;
		
	return false;
}

startHUD()
{
	if(!level.showobj_hud) return;

	level endon("ex_gameover");

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
	level thread onUpdateTeamHUD();
}

onPlayerSpawned()
{
	self endon("disconnect");

	if(!isdefined(self.obj_teamhud))
	{
		self.obj_teamhud = newClientHudElem(self);
		self.obj_teamhud.horzAlign = "left";
		self.obj_teamhud.vertAlign = "top";
		self.obj_teamhud.x = 100;
		self.obj_teamhud.y = 26;
		self.obj_teamhud.font = "default";
		self.obj_teamhud.fontscale = 2;
		self.obj_teamhud.archived = false;
		self.obj_teamhud.color = (0.98, 0.827, 0.58);
	}

	if(!isdefined(self.obj_enemyhud))
	{
		self.obj_enemyhud = newClientHudElem(self);
		self.obj_enemyhud.horzAlign = "left";
		self.obj_enemyhud.vertAlign = "top";
		self.obj_enemyhud.x = 100;
		self.obj_enemyhud.y = 48;
		self.obj_enemyhud.font = "default";
		self.obj_enemyhud.fontscale = 2;
		self.obj_enemyhud.archived = false;
		self.obj_enemyhud.color = (0.98, 0.827, 0.58);
	}

	self thread updatePlayerHUD();
}

onJoinedTeam()
{
	self thread removePlayerHUD();
}

onJoinedSpectators()
{
	self thread removePlayerHUD();
}

onUpdateTeamHUD()
{
	while(!level.ex_gameover)
	{
		//self waittill("update_obj_hud");
		wait( [[level.ex_fpstime]](1) );
		level thread updateTeamHUD();
	}
}

updatePlayerHUD()
{
	allied_obj = level.allies_cap_count;
	axis_obj = level.axis_cap_count;

	if(isdefined(self.obj_teamhud) && isdefined(self.obj_enemyhud))
	{
		if(self.pers["team"] == "allies")
		{
			self.obj_teamhud setValue(allied_obj);
			self.obj_enemyhud setValue(axis_obj);
		}
		else if(self.pers["team"] == "axis")
		{
			self.obj_teamhud setValue(axis_obj);
			self.obj_enemyhud setValue(allied_obj);
		}
	}
}

updateTeamHUD()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player thread updatePlayerHUD();
	}
}

removePlayerHUD()
{
	if(isDefined(self.obj_teamhud)) self.obj_teamhud destroy();
	if(isDefined(self.obj_enemyhud)) self.obj_enemyhud destroy();
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

printOnTeam(locstring, team, player)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(locstring, [[level.ex_pname]](player));
	}
}
