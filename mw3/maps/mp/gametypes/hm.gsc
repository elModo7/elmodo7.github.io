/*------------------------------------------------------------------------------
Original: Ravir's "Assassin" gametype for COD and UO
Revised: Artful_Dodger's "Espionage Agent" gametype for COD and UO
         revised from Assassin.
COD2 1.3 version: Tally. Ported over Artful_Dodger's ESP gametype and added
         extra features, and changed scoring and respawning patterns.
------------------------------------------------------------------------------*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_clientcontrol::menuAutoAssignDM;
	level.allies = extreme\_ex_clientcontrol::menuAllies;
	level.axis = extreme\_ex_clientcontrol::menuAxis;
	level.spectator = extreme\_ex_clientcontrol::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.spawnplayer = ::spawnplayer;
	level.updatetimer = ::blank;
	level.endgameconfirmed = ::endMap;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();	
}

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
{
	wait(0);
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	game["headicon_commander"] = "headicon_commander";
	game["headicon_guard"] = "headicon_guard";
	game["headicon_hitman"] = "headicon_hitman";

	game["statusicon_commander"] = "statusicon_commander";
	game["statusicon_guard"] = "statusicon_guard";
	game["statusicon_hitman"] = "statusicon_hitman";

	if(!isDefined(game["precachedone"]))
	{
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
			precacheStatusIcon(game["statusicon_commander"]);
			precacheStatusIcon(game["statusicon_guard"]);
			precacheStatusIcon(game["statusicon_hitman"]);
		}
		precacheHeadIcon(game["headicon_commander"]);
		precacheHeadIcon(game["headicon_guard"]);
		precacheHeadIcon(game["headicon_hitman"]);
		precacheShader("objpoint_star");
		precacheShader(game["statusicon_commander"]);
		precacheShader(game["statusicon_guard"]);
		precacheShader(game["statusicon_hitman"]);
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		precacheString(&"HM_HITMAN");
		precacheString(&"HM_KILL_COMMANDER");
		precacheString(&"HM_NEW_HITMAN");
		precacheString(&"HM_NEW_GUARD");
		precacheString(&"HM_NEW_COMMANDER");
		precacheString(&"HM_HITMAN_VS_HITMAN");
		precacheString(&"HM_OTHER_HITMANS");
		precacheString(&"HM_AVOID_GUARDS");
		precacheString(&"HM_HITMAN_KILL_COMMANDER");
		precacheString(&"HM_COMMANDER_EVADE_HITMAN");
		precacheString(&"HM_GUARD_STOP_HITMAN");
		precacheString(&"HM_GUARD_PROTECT_COMMANDER");
		precacheString(&"HM_DONT_KILL_GUARDS");
		precacheString(&"HM_AVOID_GUARDS");
		precacheString(&"HM_RESPAWN_HITMAN");
		precacheString(&"HM_GUARD_KILLED_HITMAN");
		precacheString(&"HM_GUARD_CHOSEN_COMMANDER");
		precacheString(&"HM_GUARD_CHOSEN_HITMAN");
		precacheString(&"HM_RESPAWN_GUARD");
		precacheString(&"HM_HITMAN_KILLEDBY_GUARD");
		precacheString(&"HM_COMMANDER_KILLEDBY_HITMAN");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_playerscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++) spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.QuickMessageToAll = true;
	level.mapended = false;

	level.hitmans = 0;
	level.guards = 0;
	level.commander = undefined;
	
	if(!isdefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
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

	self.hm_status = "";
	self.hm_lockstatus = false;
	self.hm_nodamage = false;
	self.hm_wasCommander = false;

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
		self.sessionteam = "none";

		if(isdefined(self.pers["weapon"]))
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

	if(isdefined(self.clientid))
		setplayerteamrank(self, self.clientid, 0);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	players = level.players;

	guards = [];
	untappedguards = [];
	newcommander = undefined;

	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i]) && isdefined(players[i].hm_status) && players[i].hm_status == "guard")
		{
			guards[guards.size] = players[i];
			if(!players[i].hm_wasCommander) // hasn't been commander
				untappedguards[untappedguards.size] = players[i];
		}
	}

	if(!isdefined(self.hm_status)) 
		return;

	if(self.hm_status == "commander")
	{
		objective_delete(0);

		if(untappedguards.size > 0)
		{
			i = randomInt(untappedguards.size);
			newCommander = untappedguards[i];
		}
		else
		{
			if(guards.size > 0)
			{
				i = randomInt(guards.size);
				newCommander = guards[i];
			}
		}

		if(isdefined(newCommander))
		{
			newCommander thread hud_announce(&"HM_GUARD_CHOSEN_COMMANDER", 0);
			newCommander thread newStatus("commander");
		}
	}

	if(self.hm_status == "hitman")
	{
		level.hitmans--;
		if(level.hitmans == 0) // there are no more hitmen
		{
			if(guards.size > 0 && level.guards > 0) // pick a guard to become an hitman
			{
				i = randomInt(guards.size);
				newHitman = guards[i];
				newHitman thread hud_announce(&"HM_GUARD_CHOSEN_HITMAN", 0);
				newHitman thread newStatus("hitman");
			}
		}
	}
}

Headicon_Restore()
{
	switch(self.hm_status)
	{
		case "commander": self.headicon = game["headicon_commander"]; break;
		case "guard": self.headicon = game["headicon_guard"]; break;
		case "hitman": self.headicon = game["headicon_hitman"]; break;
	}
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
		// Make sure at least one point of damage is done
		if(iDamage < 1) iDamage = 1;

		// guards and commanders share friendly fire damage
		if((self.hm_status == "guard" || self.hm_status == "commander") && isdefined(eAttacker) && isdefined(eAttacker.hm_status) && (eAttacker.hm_status == "guard" || eAttacker.hm_status == "commander"))
		{
			eAttacker.friendlydamage = true;

			iDamage = int(iDamage * .5);
		
			// Make sure at least one point of damage is done
			if(iDamage < 1) iDamage = 1;

			eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			eAttacker.friendlydamage = undefined;
			eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			eAttacker playrumble("damage_heavy");

			friendly = 2;
		}
	
		// Apply the damage to the player
		self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
		self playrumble("damage_heavy");
	
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

	if(!isdefined(self.switching_teams)) 
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfteam = "";
	lpselfguid = self getGuid();
	lpattackerteam = "";

	attackerNum = -1;
	oldStatus = self.hm_status;
	nextStatus = "";

	if(self.hm_status == "commander") 
		self thread delete_commander_marker();

	penalty = 0;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;
			self.hm_lockstatus = true; // killing yourself keeps your status
			attacker.score--;
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// give points to commander killing hitman
			if(attacker.hm_status == "commander" && self.hm_status == "hitman")
			{
				attacker.score += level.ex_hmpoints_cmd_hitman;
				attacker checkScoreLimit();
			}

			// give points to guard killing hitman
			if(attacker.hm_status == "guard" && self.hm_status == "hitman")
			{
				attacker.score += level.ex_hmpoints_guard_hitman;
				attacker checkScoreLimit();
			}

			// give points to hitman
			if(attacker.hm_status == "hitman")
			{
				// give points to hitman killing commander
				if(self.hm_status == "commander")
				{
					attacker.score += level.ex_hmpoints_hitman_cmd;
					attacker checkScoreLimit();
				}

				// give points to hitman killing guard
				if(self.hm_status == "guard")
				{
					attacker.score += level.ex_hmpoints_hitman_guard;
					attacker checkScoreLimit();
				}

				// give points to hitman killing another hitman
				if(self.hm_status == "hitman")
				{
					attacker.score += level.ex_hmpoints_hitman_hitman;
					attacker checkScoreLimit();
					// additional respawn delay for killed hitman (optional)
					penalty = level.penalty_time;
					self.hm_lockstatus = true;
				}
			}

			if(self.hm_status == "hitman" && attacker.hm_status == "guard") // a guard killed an hitman
			{
				self thread hud_announce(&"HM_HITMAN_KILLEDBY_GUARD", 0);
				self thread hud_announce(&"HM_RESPAWN_GUARD", 2);
				// see if the guard should become an hitman
				if(level.hitmans > 1) // more than one hitman, may need to lose one
				{
					if(level.guards + 1 > (level.hitmans-1) * 2) // losing an hitman would produce more than 2 guards per hitman
						attackerNewStatus = "hitman";
					else 
						attackerNewStatus = "guard";
				}
				else
				{
					attackerNewStatus = "hitman";
				}
				
				self thread newStatus("guard");

				attacker thread hud_announce(&"HM_GUARD_KILLED_HITMAN", 0);
				if(attackerNewStatus == "hitman")
				{
					attacker thread hud_announce(&"HM_RESPAWN_HITMAN", 2);
					attacker thread newStatus("hitman");
				}
			}

			if(self.hm_status == "hitman" && attacker.hm_status == "commander") // the commander killed an hitman
			{
				self.hm_lockstatus = true;
			}
			
			if(self.hm_status == "commander") // the commander was killed by the hitman
			{
				level.commander = undefined;
				players = level.players;
				guards = [];
				untappedguards = [];
				for(i = 0; i < players.size; i++)
				{
					if(isdefined(players[i]) && isdefined(players[i].hm_status) && players[i].hm_status == "guard")
					{
						guards[guards.size] = players[i]; // all guards
						if(!players[i].hm_wasCommander)
							untappedguards[untappedguards.size] = players[i]; // guards that haven't been the commander yet
					}
				}

				if(level.guards == 0) // the hitman and commander are alone on the server, exchange them
				{
					attacker thread hud_announce(&"HM_GUARD_CHOSEN_COMMANDER", 0);
					attacker thread newStatus("commander");
					self thread hud_announce(&"HM_GUARD_CHOSEN_HITMAN", 0);
					self thread newStatus("hitman");
				}
				else // there are guards on the server
				{
					if(untappedguards.size > 0)
					{
						j = randomint(untappedguards.size);
						newCommander = untappedguards[j];
					}
					else
					{
						j = randomint(guards.size);
						for(i = 0; i < guards.size; i++)
							guards[i].hm_wasCommander = false;
						newCommander = guards[j];
					}
					if(!isdefined(level.commander)) // in case someone else already got the spot
					{
						newCommander thread hud_announce(&"HM_GUARD_CHOSEN_COMMANDER", 0);
						newCommander thread newStatus("commander");
					}
					self thread hud_announce(&"HM_COMMANDER_KILLEDBY_HITMAN", 0);
					self thread hud_announce(&"HM_RESPAWN_GUARD", 2);
					self thread newStatus("guard"); // the commander is now a guard
				}
			}
		}
		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		
		attacker notify("update_playerscore_hud");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;
		self.hm_lockstatus = true;
		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";

		self notify("update_playerscore_hud");
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
	//thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2 + penalty;	// Delay the player becoming a spectator till after he's done dying
	if(penalty > 0) self thread hud_announce(&"HM_HITMAN_VS_HITMAN", 0);
	wait( [[level.ex_fpstime]](delay) );	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	// no killcam for the commander if he needs to respawn
	if(self.hm_status == "commander") doKillcam = false;

	if(doKillcam && level.killcam) 
	{
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);
		self thread respawn();
	}
	else // if you're still the commander, you can't wait to respawn
	{
		if(self.hm_status == "commander") self thread spawnPlayer();
			else self thread respawn();
	}
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

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;

	self extreme\_ex_main::exprespawn();

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_DM(spawnpoints);

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

	if(!isdefined(self.pers["savedmodel"])) maps\mp\gametypes\_teams::model();
		else maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(!self.hm_lockstatus) // enable auto-selection of role
	{
		nextStatus = "";

		if(level.hitmans == 0) // the first player to spawn is an hitman
		{
			nextStatus = "hitman";
		}
		if(level.hitmans >= 1 && !isdefined(level.commander) && (self.hm_status == "" || self.hm_status == "guard")) // there is an hitman, but no commander, this player is the commander
		{
			nextStatus = "commander";
			level.commander = self;
		}

		if(level.hitmans > 0 && isdefined(level.commander) && self.hm_status != "commander" && nextStatus != "commander" && nextStatus != "hitman") // this player should be either an hitman or guard
		{
			if(level.guards <= level.hitmans * 2) // there aren't enough guards, should be at least 2 to 1 odds
			{
				if(self.hm_status == "hitman") // is currently an hitman, may have to change
				{
					if((level.guards+1 <= (level.hitmans-1) * 2) && level.hitmans > 1) // one more guard and one less hitman is still good odds
						nextStatus = "guard";
					else
						nextStatus = "hitman";
				}
				else // they're not an hitman, make them a guard
				{
					nextStatus = "guard";
				}
			}
			else // might need another hitman, too many guards
			{
				if(self.hm_status == "") // not set yet, make an hitman
					nextStatus = "hitman";

				if(self.hm_status == "guard") // player is currently a guard
				{
					if((level.guards - 1) <= (level.hitmans+1) * 2) // cannot afford to convert guard to hitman
						nextStatus = "guard";
					else
						nextStatus = "hitman";
				}
			}
		}
	}
	else
	{
		nextStatus = self.hm_status; // players status was locked by another function
	}

	self.maxhealth = 100;
	self.health = self.maxhealth;

	self.hm_nodamage = false;
	self newStatus(nextStatus);

	waittillframeend;
	self extreme\_ex_main::expostspawn();
	self notify("spawned_player");
}

respawn()
{
	self endon("end_respawn");

	if(!isdefined(self.pers["weapon"])) return;

	if(!level.forcerespawn)
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

	if(isdefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

// a player's status has changed, inform them
newStatus(status)
{
	self endon("disconnect");

	if(!isdefined(status))
		status = self.hm_status;
	if(self.hm_status == "guard")
		level.guards--;	
	if(self.hm_status == "hitman") 
		level.hitmans--;

	myHeadIcon = undefined;
	myStatusIcon = undefined;
	myHud1Text = undefined;
	myHud1Icon = undefined;
	myHud2Text = undefined;
	myHud2Icon = undefined;
	myHud3Text = undefined;
	myHud3Icon = undefined;
	myStatus = undefined;

	switch(status)
	{
		case "guard":
			myHeadIcon = "headicon_guard";
			myStatusIcon = "statusicon_guard";
			myHud1Text = &"HM_GUARD_STOP_HITMAN";
			myHud1Icon = "statusicon_hitman";
			myHud2Text = &"HM_DONT_KILL_GUARDS";
			myHud2Icon = "statusicon_guard";
			myHud3Text = &"HM_GUARD_PROTECT_COMMANDER";
			myHud3Icon = "statusicon_commander";
			myStatus = &"HM_NEW_GUARD";
			level.guards++;
			break;

		case "commander":
			myHeadIcon = "headicon_commander";
			myStatusIcon = "statusicon_commander";
			myHud1Text = &"HM_NEW_COMMANDER";
			myHud1Icon = "statusicon_commander";
			myHud2Text = &"HM_DONT_KILL_GUARDS";
			myHud2Icon = "statusicon_guard";
			myHud3Text = &"HM_COMMANDER_EVADE_HITMAN";
			myHud3Icon = "statusicon_hitman";
			myStatus = &"HM_NEW_COMMANDER";
			level.commander = self;
			self.hm_wasCommander = true;
			break;

		case "hitman":
			myHeadIcon = "headicon_hitman";
			myStatusIcon = "statusicon_hitman";
			myHud1Text = &"HM_OTHER_HITMANS";
			myHud1Icon = "statusicon_hitman";
			myHud2Text = &"HM_AVOID_GUARDS";
			myHud2Icon = "statusicon_guard";
			myHud3Text = &"HM_HITMAN_KILL_COMMANDER";
			myHud3Icon = "statusicon_commander";
			myStatus = &"HM_NEW_HITMAN";
			level.hitmans++;
			break;
	}

	respawnNow = undefined;

	if((self.hm_status == "guard" || self.hm_status == "hitman") && status == "commander" && self.sessionstate == "playing") // a player has been chosen to respawn as the commander
	{
		self.hm_status = "commander";
		respawnNow = 1;
	}

	if((self.hm_status == "guard" || self.hm_status == "commander") && status == "hitman" && self.sessionstate == "playing") // a player has been chosen to be an hitman
	{
		self.hm_status = "hitman";
		respawnNow = 1;
	}

	if(isdefined(respawnNow)) // do the forced respawn
	{
		self.hm_lockstatus = true;
		// take away their weapons and mark them as undamageable
		self.hm_nodamage = true;

		wait( [[level.ex_fpstime]](2) );
		self.sessionstate = "dead"; // hide the player from the world

		self thread clearHud();

		wait( [[level.ex_fpstime]](3) );
		self thread spawnplayer(); // respawn this player
		return;
	}

	self.hm_status = status;

	if(self.sessionstate == "playing")
	{
		self.hm_lockstatus = false;

		if(!level.ex_rank_statusicons) self.statusicon = game[myStatusIcon];
		self.headicon = game[myHeadIcon];

		if(!isdefined(self.statusHUDicon))
		{
			self.statusHUDicon = newClientHudElem(self);
			self.statusHUDicon.horzAlign = "fullscreen";
			self.statusHUDicon.vertAlign = "fullscreen";
			self.statusHUDicon.alignX = "left";
			self.statusHUDicon.alignY = "middle";
			self.statusHUDicon.x = 180;
			self.statusHUDicon.y = 420;
		}
		self.statusHUDicon setShader(game[myStatusIcon], 24, 24);

		if(isdefined(self.oldhmst) && self.oldhmst != myStatusIcon)
			self thread explostatus(myStatusIcon);

		if(!isdefined(self.hud1text))
		{
			self.hud1text = newClientHudElem(self);				
			self.hud1text.alignX = "center";
			self.hud1text.alignY = "middle";
			self.hud1text.x = 575;
			self.hud1text.y = 140;
			self.hud1text.alpha = 0.7;
			self.hud1text.fontscale = 1.0;
		}
		self.hud1text settext(myHud1Text);			

		if(!isdefined(self.hud1icon))
		{
			self.hud1icon = newClientHudElem(self);				
			self.hud1icon.alignX = "center";
			self.hud1icon.alignY = "middle";
			self.hud1icon.x = 575;
			self.hud1icon.y = 165;
		}
		self.hud1icon setShader(game[myHud1Icon], 24, 24);

		if(!isdefined(self.hud2text))
		{
			self.hud2text = newClientHudElem(self);				
			self.hud2text.alignX = "center";
			self.hud2text.alignY = "middle";
			self.hud2text.x = 575;
			self.hud2text.y = 190;
			self.hud2text.alpha = 0.7;
			self.hud2text.fontscale = 1.0;
		}
		self.hud2text settext(myHud2Text);			

		if(!isdefined(self.hud2icon))
		{
			self.hud2icon = newClientHudElem(self);				
			self.hud2icon.alignX = "center";
			self.hud2icon.alignY = "middle";
			self.hud2icon.x = 575;
			self.hud2icon.y = 215;
		}
		self.hud2icon setShader(game[myHud2Icon], 24, 24);

		if(!isdefined(self.hud3text))
		{
			self.hud3text = newClientHudElem(self);				
			self.hud3text.alignX = "center";
			self.hud3text.alignY = "middle";
			self.hud3text.x = 575;
			self.hud3text.y = 235;
			self.hud3text.alpha = 0.7;
			self.hud3text.fontscale = 1.0;
		}
		self.hud3text settext(myHud3Text);			

		if(!isdefined(self.hud3icon))
		{
			self.hud3icon = newClientHudElem(self);				
			self.hud3icon.alignX = "center";
			self.hud3icon.alignY = "middle";
			self.hud3icon.x = 575;
			self.hud3icon.y = 260;
		}
		self.hud3icon setShader(game[myHud3Icon], 24, 24);

		self thread hud_announce(myStatus, 0);
		self thread hud_announce(myHud3Text, 2.5);

		self setClientCvar("cg_objectiveText", myHud3Text);

		if(self.hm_status == "commander") 
			self thread make_commander_marker();
	}
	else self.hm_lockstatus = true; // lock this status in place for the next spawn

	self thread fadehudinfo();
	self.oldhmst = myStatusIcon;
}

explostatus(myStatusIcon)
{
	if(isdefined(self.statusHUDicon))
	{
		self.statusHUDicon setShader(game[myStatusIcon], 96, 96);
		self.statusHUDicon scaleOverTime(2, 24, 24);
	}
}

fadehudinfo()
{
	self endon("death");
	self endon("respawn");
	
	wait( [[level.ex_fpstime]](10) );

	if(isdefined(self.hud1text))
	{
		self.hud1text fadeOverTime(2);
		self.hud1text.alpha = 0;
	}

	if(isdefined(self.hud1icon))
	{
		self.hud1icon fadeOverTime(2);
		self.hud1icon.alpha = 0;
	}

	if(isdefined(self.hud2text))
	{
		self.hud2text fadeOverTime(2);
		self.hud2text.alpha = 0;
	}

	if(isdefined(self.hud2icon))
	{
		self.hud2icon fadeOverTime(2);
		self.hud2icon.alpha = 0;
	}

	if(isdefined(self.hud3text))
	{
		self.hud3text fadeOverTime(2);
		self.hud3text.alpha = 0;
	}	

	if(isdefined(self.hud3icon))
	{
		self.hud3icon fadeOverTime(2);
		self.hud3icon.alpha = 0;
	}

	wait( [[level.ex_fpstime]](2) );

	if(isdefined(self.hud1text)) self.hud1text destroy();
	if(isdefined(self.hud1icon)) self.hud1icon destroy();
	if(isdefined(self.hud2text)) self.hud2text destroy();
	if(isdefined(self.hud2icon)) self.hud2icon destroy();
	if(isdefined(self.hud3text)) self.hud3text destroy();
	if(isdefined(self.hud3icon)) self.hud3icon destroy();
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
	players = level.players;
	highscore = undefined;
	tied = undefined;
	playername = undefined;
	name = undefined;
	guid = undefined;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] == "spectator")
			continue;

		if(!isdefined(highscore))
		{
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
			continue;
		}

		if(player.score == highscore)
			tied = true;
		else if(player.score > highscore)
		{
			tied = false;
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
		}
	}

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();

		if(isdefined(tied) && tied) player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
		else if(isdefined(playername)) player setClientCvar("cg_objectiveText", &"MP_WINS", playername);

		player extreme\_ex_spawn::spawnIntermission();

		if(level.ex_rank_statusicons)
			player.statusicon = player thread extreme\_ex_ranksystem::getStatusIcon();
	}

	if(isdefined(name))
		logPrint("W;;" + guid + ";" + name + "\n");

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
	waittillframeend;

	if(level.scorelimit <= 0) return;

	if(self.score < level.scorelimit) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_hm_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_hm_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isdefined(level.clock)) extreme\_ex_gtcommon::createClock();
				level.clock setTimer(level.timelimit * 60);
			}
			else if(isdefined(level.clock)) level.clock destroy();

			checkTimeLimit();
		}

		scorelimit = getcvarint("scr_hm_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			players = level.players;
			for(i = 0; i < players.size; i++)
				players[i] checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

hud_announce(message, predelay)
{
	self endon("kill_thread");
	self endon("kill_hud_announce");

	if(!isDefined(message)) return;

	if(!isDefined(self.hud_announce))
	{
		self.hud_announce = [];
		self.hudwait = 1;
	}

	if(self.hudwait < 1) self.hudwait = 1;

	self.hudwait++;
	
	wait( [[level.ex_fpstime]](self.hudwait) );

	for(i = 0; i < self.hud_announce.size; i++)
	{
		if(isDefined(self.hud_announce[i]))
		{
			self.hud_announce[i] moveOverTime(0.25);
			self.hud_announce[i].y = self.hud_announce[i].y - 20;
		}
	}

	i = 0;
	while(isDefined(self.hud_announce[i])) i++;

	self.hud_announce[i] = newClientHudElem(self);
	self.hud_announce[i].alignX = "center";
	self.hud_announce[i].alignY = "middle";
	self.hud_announce[i].x = 320;
	self.hud_announce[i].y = 100;
	self.hud_announce[i].alpha = 0;
	self.hud_announce[i].fontscale = 1.5;

	self.hud_announce[i] settext(message);
	self.hud_announce[i] fadeOverTime(0.5);
	self.hud_announce[i].alpha = 1;
	wait( [[level.ex_fpstime]](2.5) );
	if(isDefined(self.hud_announce[i]))
	{
		self.hud_announce[i] fadeOverTime(0.5);
		self.hud_announce[i].alpha = 0;
		wait( [[level.ex_fpstime]](0.5) );
		self.hud_announce[i] destroy();
	}
	self.hudwait--;
}

make_commander_marker()
{
	self endon("disconnect");
	self endon("commanderblip");
	wait( [[level.ex_fpstime]](level.tposuptime) );

	while((isPlayer(self)) && (isAlive(self)))
	{
		if(level.showcommander)
		{
			objective_add(0, "current", self.origin, "objpoint_star");
			objective_icon(0, "objpoint_star");
			objective_team(0, "none");
			objective_position(1, self.origin);
			lastobjpos = self.origin;
			newobjpos = self.origin;
			lastobjpos = newobjpos;
			newobjpos = (((lastobjpos[0] + self.origin[0]) * 0.5), ((lastobjpos[1] + self.origin[1]) * 0.5), 0);
			objective_position(0, newobjpos);
		}
		wait( [[level.ex_fpstime]](level.tposuptime) );
		objective_delete(0);
	}
}

delete_commander_marker()
{
	self notify("commanderblip");
	objective_delete(0);
}

clearHUD()
{
	if(isdefined(self.hud1text)) self.hud1text destroy();
	if(isdefined(self.hud1icon)) self.hud1icon destroy();
	if(isdefined(self.hud2text)) self.hud2text destroy();
	if(isdefined(self.hud2icon)) self.hud2icon destroy();
	if(isdefined(self.hud3text)) self.hud3text destroy();
	if(isdefined(self.hud3icon)) self.hud3icon destroy();
	if(isdefined(self.statusHUDicon)) self.statusHUDicon destroy();
}
