#include extreme\_ex_weapons;

/*QUAKED mp_tdm_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

/*------------------------------------------------------------------------------
Freeze-Tag Mod version 1.3
	Written by MedicMan
	For information or Questions: james@mayrinckevans.com

Credits:
	Models: UKUFTaFFyTuck
	Sounds: BritishBulldog1, MedicMan
	Additional scripting help: MSJeta1
Special Thanks to:
	The makers of AWE, eXtreme+ and PowerServer
	All the fellow gamers who put up with my testing requests
	My wife for putting up with me when I lock myself in the office
	to play and mod Call of Duty.
Converted for eXtreme+ 2.7 by PatmanSan

Objective:
	Score points for your team by freezing players on the opposing team
Map ends:
	When one team reaches the score limit, or entire team is frozen, or time limit is reached
Respawning:
	No wait / Near teammates

Level requirements
------------------
Spawnpoints:
	classname		mp_tdm_spawn
	All players spawn from these. The spawnpoint chosen is dependent on the current
	locations of teammates and enemies at the time of spawn. Players generally spawn
	behind their teammates relative to the direction of enemies.

Spectator Spawnpoints:
	classname		mp_global_intermission
	Spectators spawn from these and intermission is viewed from these positions.
	Atleast one is required, any more and they are randomly chosen between.

Level script requirements
-------------------------
Team Definitions:
	game["allies"] = "american";
	game["axis"] = "german";
	This sets the nationalities of the teams. Allies can be american, british, or
	russian. Axis can be german.

If using minefields or exploders:
	maps\mp\_load::main();

Optional level script settings
------------------------------
Soldier Type and Variation:
	game["american_soldiertype"] = "normandy";
	game["german_soldiertype"] = "normandy";
	This sets what character models are used for each nationality on a particular map.

Valid settings:
	american_soldiertype	normandy
	british_soldiertype		normandy, africa
	russian_soldiertype		coats, padded
	german_soldiertype		normandy, africa, winterlight, winterdark
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
		precacheRumble("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			precacheStatusIcon("hud_status_dead");
			precacheStatusIcon("hud_status_connecting");
			precachestatusIcon("hud_stat_frozen");
		}
		precacheString(&"MP_TIME_TILL_SPAWN");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");

		precacheString(&"FT_UNFREEZE_HINT");
		precacheString(&"FT_UNFREEZE_YOU");
		precacheString(&"FT_UNFREEZE_ME");
		precacheString(&"FT_YOUAREFROZEN");
		precacheString(&"FT_ROUND_DEAD");
		precacheString(&"FT_NEXT_ROUND");
		precacheString(&"FT_WEAPON_STEAL");
		precacheString(&"FT_WEAPON_CHANGE");
		precacheString(&"FT_WEAPON_KEEP");
		precacheString(&"FT_WEAPON_KEEP_CURRENT");
		precacheString(&"FT_WEAPON_KEEP_SPAWN");

		precacheShader("hudStopwatch");
		precacheShader("hudstopwatchneedle");

		precacheModel("xmodel/icecubeblue1");
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

	// load freezetag fx
	level.ft_laserfx = loadfx("fx/ft/laservision.efx");
	level.ft_smokefx = loadfx("fx/misc/snow_impact_small.efx");

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// set score update flag. Used to remove the double score bug
	level.ft_scoreupdate = 0;
	level.roundended = false;
	level.mapended = false;
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	if(!isdefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	if(!isdefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);

	if(!isdefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isdefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["matchstarted"])) game["matchstarted"] = false;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		level thread debugMonitor();
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

	self.frozenstate = "unfrozen";
	self.frozenstatus = 0;
	self.frozencount = 0;
	self.spawnfrozen = 0;

	// check history for reconnecting players
	if(level.ft_history && !isDefined(self.pers["skiphistory"])) self checkHistory();
	self.pers["skiphistory"] = undefined;

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

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator" && (self.frozenstate == "frozen" || isDefined(self.spawned)) )
	{
		if(self.frozenstate == "frozen")
		{
			if(isDefined(self.icecube)) self.icecube delete();
			number = self getEntityNumber();
			status_cvar = self.name + ",FROZEN";
		}
		else status_cvar = self.name + ",DEAD";

		if(level.ft_history)
		{
			if(!isDefined(game["checknumber"])) game["checknumber"] = 0;
			game["checknumber"]++;
			if(game["checknumber"] > level.ft_history) game["checknumber"] = 1;
			setcvar("ft_history" + game["checknumber"], status_cvar);
			iprintln(&"FT_HISTORY_ADD", [[level.ex_pname]](self));
			//logprint("FREEZETAG disconnect: player added to FT history (" + status_cvar + ")\n");
		}
	}

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies") setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis") setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator") setplayerteamrank(self, 2, 0);
	}
	
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

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= self.health)
				{
					self.frozencount++;
					if(self.frozencount < level.ft_maxfreeze) self thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else self finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					self.deaths++;
				}
				else
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

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= eAttacker.health)
				{
					eAttacker.frozencount++;
					if(eAttacker.frozencount < level.ft_maxfreeze) eAttacker thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else eAttacker finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					eAttacker.deaths++;
					eAttacker.score--;
				}
				else
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

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= self.health)
				{
					self.frozencount++;
					if(self.frozencount < level.ft_maxfreeze) self thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else self finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					self.deaths++;
					eAttacker.score--;
				}
				else
					self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= eAttacker.health)
				{
					eAttacker.frozencount++;
					if(eAttacker.frozencount < level.ft_maxfreeze) eAttacker thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else eAttacker finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					eAttacker.deaths++;
				}
				else
					eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

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

			// check if damage is greater than current health. If it is, freeze the player
			if(iDamage >= self.health)
			{
				self.frozencount++;
				if(self.frozencount < level.ft_maxfreeze) self thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
					else self finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				self.deaths++;

				if(isPlayer(eAttacker) && eAttacker != self)
				{
					eAttacker.score += level.ft_points_freeze;

					// added for arcade style HUD points
					eAttacker notify("update_playerscore_hud");
				}
			}
			else
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

	if(self.frozenstate == "frozen" || (level.ex_logdamage && self.sessionstate != "dead"))
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

		if(self.frozenstate == "frozen")
		{
			if(!isDefined(friendly) || friendly == 2)
				logPrint("F;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

			if(isDefined(friendly) && eAttacker.sessionstate != "dead")
			{
				lpselfnum = lpattacknum;
				lpselfname = lpattackname;
				lpselfGuid = lpattackGuid;
				logPrint("F;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
			}
		}
		else
		{
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
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator") return;

	// save some player info for weapon restore and exchange feature
	if(!isDefined(self.switching_teams) && !self.terminate_reason) self weaponSave();

	level thread updateTeamStatus();

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";

	// make sure this comes after setting sessionstate
	if(self.frozenstate == "frozen")
	{
		self.killedfrozen = 1;
		self thread unfreezePlayer();
	}

	self hudDestroy(true);

	if(!level.ex_rank_statusicons) self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams)) self.deaths++;

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
				if(self.killedfrozen) self.spawnfrozen = 1;

				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1)
						attacker.score--;
				}
			}
			// catch those who blew themselves up
			else if(sWeapon == "none" && sMeansOfDeath == "MOD_SUICIDE")
			{
				if(self.killedfrozen)
				{
					self.frozencount = 999;

					// cheat with /kill when frozen
					if(!self.terminate_reason)
					{
						iprintln(&"FT_ALL_OUT_CHEAT", [[level.ex_pname]](self));
						self iprintlnbold(&"FT_YOU_OUT_CHEAT");
						self.terminate_reason = 1;
					}
					// time-out suicide
					else
					{
						iprintln(&"FT_ALL_OUT_TIME", [[level.ex_pname]](self));
						self iprintlnbold(&"FT_YOU_OUT_TIME");
					}
				}
				// held a nade too long
				else self.spawnfrozen = 2;
			}
			// catch those who were killed in a minefield
			else if(sWeapon == "minefield" && sMeansOfDeath == "MOD_EXPLOSIVE") self.spawnfrozen = 3;

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

			points = level.ft_points_freeze + reward_points;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker.score -= points;
					else attacker.score--;
			}
			else
			{
				attacker.score += points;
				attacker.pers["bonus"] += reward_points;
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

	/*
	logprint("FREEZETAG killed: player " + self.name +
		", killedfrozen = " + self.killedfrozen +
		", spawnfrozen = " + self.spawnfrozen +
		", frozencount " + self.frozencount +
		", terminate_reason " + self.terminate_reason +
		", sWeapon = " + sWeapon +
		", sMeansOfDeath = " + sMeansOfDeath + "\n");
	*/

	if(self.frozencount >= level.ft_maxfreeze && !self.terminate_reason)
	{
		iprintln(&"FT_ALL_OUT_LIMIT", [[level.ex_pname]](self));
		self iprintlnbold(&"FT_YOU_OUT_LIMIT");
	}

	level notify("update_teamscore_hud");

	if(!isdefined(self.switching_teams))
	{
		if(self.spawnfrozen)
			logPrint("F;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
		else
			logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
	else self.ex_team_changed = true;

	// Stop thread if map ended on this death
	if(level.mapended) return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	//body = self cloneplayer(deathAnimDuration);
	//thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);
	
	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	if(self.frozencount >= level.ft_maxfreeze)
	{
		self.spawned = 1;
		self thread respawn_staydead(delay);
	}
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

	self extreme\_ex_main::exprespawn();
	
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(self.spawnfrozen == 2 && isDefined(self.dead_origin) && isDefined(self.dead_angles))
	{
		self spawn(self.dead_origin, self.dead_angles);
	}
	else if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	self.dead_origin = undefined;
	self.dead_angles = undefined;

	level updateTeamStatus();

	if(!isDefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isDefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];

	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(level.scorelimit > 0)
		self setClientCvar("cg_objectiveText", &"FT_OBJECTIVE_SCORE", level.scorelimit);
	else
		self setClientCvar("cg_objectiveText", &"FT_OBJECTIVE");

	self thread updateTimer();

	waittillframeend;

	self.killedfrozen = 0;
	self.terminate_reason = 0;
	self.unfreezing = 0;
	self.beingunfroze = 0;
	self.foundinbinocs = 0;
	self.foundeligible = 0;
	self.foundenemy = 0;

	self extreme\_ex_main::expostspawn();

	if(self.spawnfrozen == 1) self thread freezePlayer(undefined, "empty", "empty");
		else if(self.spawnfrozen > 1) self thread freezePlayer(self, "empty", "empty");

	self thread hudScan();
	self thread frozenTracker();

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

	/*
	if(!level.forcerespawn)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}
	*/

	// wait for callback to end
	wait 0;

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

	// clear history
	if(level.ft_history) thread clearHistory();

	thread clock();

	wait( [[level.ex_fpstime]](level.roundlength * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	level thread checkFrozen();
}

checkFrozen()
{
	level.frozen = [];
	level.frozen["axis"] = 0;
	level.frozen["allies"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isPlayer(player) && isDefined(player.pers["team"]) && player.pers["team"] != "spectator")
		{
			if(player.sessionstate == "spectator") continue;
			if(isDefined(player.spawned) || (player.frozenstatus > 0 && player.frozenstate == "frozen"))
				level.frozen[player.pers["team"]]++;
		}
	}

	if(level.frozen["axis"] > level.frozen["allies"]) level thread endRound("allies");
		else if(level.frozen["axis"] < level.frozen["allies"]) level thread endRound("axis");
			else level thread endRound("draw");
}

endRound(roundwinner)
{
	level endon("intermission");
	level endon("kill_endround");

	if(level.roundended || level.ex_readyup && !isDefined(game["readyup_done"])) return;
	level.roundended = true;

	level notify("round_ended");

	if(roundwinner == "allies")
	{
		oldscore = game["alliedscore"];
		game["alliedscore"] = getTeamScore("allies");
		game["alliedscore"]++;
		setTeamScore("allies", game["alliedscore"]);
		points = game["alliedscore"] - oldscore;

		if(level.mapended) return;

		if(points > 1) iprintlnbold(&"MP_SCORED_ALLIES", points);
			else iprintlnbold(&"FT_SCORED_ALLIES_SINGLE", points);
	}
	else if(roundwinner == "axis")
	{
			oldscore = game["axisscore"];
			game["axisscore"] = getTeamScore("axis");
			game["axisscore"]++;
			setTeamScore("axis", game["axisscore"]);
			points = game["axisscore"] - oldscore;

			if(level.mapended) return;

			if(points > 1) iprintlnbold(&"MP_SCORED_AXIS", points);
				else iprintlnbold(&"FT_SCORED_AXIS_SINGLE", points);
	}
	else if(roundwinner == "draw") iprintlnbold(&"FT_SCORED_NOPOINTS");

	level notify("update_teamscore_hud");

	//checkScoreLimit();
	game["roundsplayed"]++;
	checkRoundLimit();
	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	checkTimeLimit();

	if(level.mapended) return;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player))
		{
			player notify("end_unfreeze");

			// optionally unfreeze frozen players
			//if(player.frozenstate == "frozen") player.frozenstatus = 0;

			// clean the hud
			player hudDestroy(true);
			if(isdefined(player.staydead)) player.staydead destroy();

			// store player scores and status
			player.pers["score"] = player.score;
			player.pers["death"] = player.deaths;

			// make sure this player bypasses history check
			player.pers["skiphistory"] = true;

			// save weapons for new rounds
			if(level.ft_weaponsteal_keep && isDefined(player) && isDefined(player.pers["team"]) && (player.pers["team"] != "spectator") && (player.sessionteam != "spectator"))
				player thread weaponEndRoundSave();

			// disable weapons during delay
			player [[level.ex_dWeapon]]();
		}
	}

	level.nextround_timer = newHudElem();
	level.nextround_timer.archived = false;
	level.nextround_timer.horzAlign = "center_safearea";
	level.nextround_timer.vertAlign = "center_safearea";
	level.nextround_timer.alignX = "center";
	level.nextround_timer.alignY = "middle";
	level.nextround_timer.x = 0;
	level.nextround_timer.y = -50;
	level.nextround_timer.font = "default";
	level.nextround_timer.fontscale = 2;
	level.nextround_timer.color = (1,1,0);
	level.nextround_timer.alpha = 1;
	level.nextround_timer.label = &"FT_NEXT_ROUND";
	level.nextround_timer settimer(level.ft_roundend_delay);

	wait( [[level.ex_fpstime]](level.ft_roundend_delay) );

	level notify("restarting");
	wait( [[level.ex_fpstime]](.05) );

	// restart map
	map_restart(true);
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

	winners = "";
	losers = "";

	if(winningteam == "allies")
		level.ex_resultsound = "MP_announcer_allies_win";
	else if(winningteam == "axis")
		level.ex_resultsound = "MP_announcer_axis_win";
	else
		level.ex_resultsound = "MP_announcer_round_draw";

	extreme\_ex_main::exendmap();

	game["state"] = "intermission";
	level notify("intermission");

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
		timelimit = getCvarFloat("scr_ft_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ft_timelimit", "1440");
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

		/*
		scorelimit = getCvarInt("scr_ft_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);

			checkScoreLimit();
		}
		*/

		wait( [[level.ex_fpstime]](1) );
	}
}

updateTeamStatus()
{
	wait 0; // Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

	if(!game["matchstarted"]) return;

	resettimeout();

	level.existed["allies"] = level.exist["allies"];
	level.existed["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing" && player.frozenstate != "frozen")
			level.exist[player.pers["team"]]++;
	}

	if(level.roundended) return;

	playercount = maps\mp\gametypes\_teams::CountPlayers();
	if(playercount["allies"] > 0 && playercount["axis"] > 0)
	{
		// if both allies and axis were there and now they are both frozen in the same instance
		if(level.existed["allies"] && !level.exist["allies"] && level.existed["axis"] && !level.exist["axis"])
		{
			iprintlnbold(&"MP_ROUNDDRAW");
			level thread endRound("draw");
			return;
		}

		// if allies were there and now they are not
		if(level.existed["allies"] && !level.exist["allies"])
		{
			level.allied_eliminated = true;
			iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
			level thread playSoundOnPlayers("mp_announcer_allieselim");
			level thread endRound("axis");
			return;
		}

		// if axis were there and now they are not
		if(level.existed["axis"] && !level.exist["axis"])
		{
			level.axis_eliminated = true;
			iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
			level thread playSoundOnPlayers("mp_announcer_axiselim");
			level thread endRound("allies");
			return;
		}
	}
	else
	{
		// one team forfeited. No points to be scored, just start new round
		if(playercount["allies"] == 0 && level.existed["allies"] > 0)
		{
			iprintlnbold(&"FT_ALLIES_FORFEITED");
			level thread endRound("draw");
		}

		if(playercount["axis"] == 0 && level.existed["axis"] > 0)
		{
			iprintlnbold(&"FT_AXIS_FORFEITED");
			level thread endRound("draw");
		}
	}
}

respawn_staydead(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	if(isDefined(self.icecube))
	{
		self unlink();
		self.icecube delete();
	}
	number = self getEntityNumber();

	if(!isdefined(self.staydead))
	{
		self.staydead = newClientHudElem(self);
		self.staydead.x = 0;
		self.staydead.y = -50;
		self.staydead.alignX = "center";
		self.staydead.alignY = "middle";
		self.staydead.horzAlign = "center_safearea";
		self.staydead.vertAlign = "center_safearea";
		self.staydead.alpha = 0;
		self.staydead.archived = false;
		self.staydead.font = "default";
		self.staydead.fontscale = 2;
		self.staydead setText(&"FT_ROUND_DEAD");
	}

	wait( [[level.ex_fpstime]](delay) );
	self thread updateTimer();

	level waittill("finish_staydead");

	if(isdefined(self.staydead))
		self.staydead destroy();

	self.spawned = undefined;
	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isdefined(self.staydead))
	{
		if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
			self.staydead.alpha = 1;
		else
			self.staydead.alpha = 0;
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

// *****************************************************************************

freezePlayer(eAttacker, sWeapon, sMeansOfDeath)
{
	// sometimes a suicide nade triggers a freeze through ft::Callback_PlayerDamage
	// even though it is handled by ft::Callback_PlayerKilled as well.
	// 4:29 K;0;10;axis;CLAN|PatmanSan;0;10;axis;CLAN|PatmanSan;none;100000;MOD_SUICIDE;none
	// 4:29 F;0;10;axis;CLAN|PatmanSan;0;10;axis;CLAN|PatmanSan;frag_grenade_british_mp;174;MOD_GRENADE_SPLASH;none
	if(self.spawnfrozen == 2 && isDefined(eAttacker) && eAttacker == self && isWeaponType(sWeapon, "fraggrenade") && sMeansOfDeath == "MOD_GRENADE_SPLASH") return;

	if(self.spawnfrozen != 3 && self.frozenstate == "frozen") return;
	self.frozenstate = "frozen";
	self.frozenstatus = 100;

	// let ft::Callback_PlayerDamage finish first
	wait(0);

	self.unfreezing = 0;
	self.beingunfroze = 0;

	self stopShellshock();
	self stoprumble("damage_heavy");

	if(!isDefined(sWeapon)) sWeapon = "empty";
	if(!isDefined(sMeansOfDeath)) sMeansOfDeath = "empty";

	/*
	logprint("FREEZETAG freeze: player " + self.name +
		", killedfrozen = " + self.killedfrozen +
		", spawnfrozen = " + self.spawnfrozen +
		", frozencount " + self.frozencount +
		", terminate_reason " + self.terminate_reason +
		", sWeapon = " + sWeapon +
		", sMeansOfDeath = " + sMeansOfDeath + "\n");
	*/

	// release the fire button to stop firing, and press the use button to get off the turret
	if(isDefined(self.onturret)) self.forceoffturret = true;

	// save some player info for weapon restore and exchange feature
	if(sWeapon != "empty") self weaponSave();

	// self kill by minefield when handled by ft::Callback_PlayerDamage
	if(sWeapon == "minefield" && sMeansOfDeath == "MOD_EXPLOSIVE")
	{
		self iprintlnbold(&"FT_FROZEN_BY_MINE");

		// kill running player threads
		self notify("kill_thread");
		self notify("killed_player");
		wait(0);

		// respawn the player away from minefield
		self.spawnfrozen = 3;
		self spawnPlayer();
		// quit because this procedure will be called again by spawnPlayer()
		return;
	}

	// self.spawnfrozen:
	// 0 = disabled
	// 1 = switching teams manually or auto-balanced (set by ft::Callback_PlayerKilled)
	// 2 = suicide nade (set by ft::Callback_PlayerKilled)
	// 3 = minefield (set by ft::Callback_PlayerKilled or section above)
	// 4 = reconnect when frozen (set by freezetag::checkHistory)
	// 5 = reconnect when waiting for next round (set by freezetag::checkHistory)

	if(self.spawnfrozen > 1)
	{
		// suicide nade or minefield
		if(self.spawnfrozen == 2 || self.spawnfrozen == 3) self weaponRestore();
		// reconnect when frozen
		else if(self.spawnfrozen == 4)
		{
			iprintln(&"FT_ALL_RECON_FROZEN", [[level.ex_pname]](self));
			self iprintlnbold(&"FT_YOU_RECON_FROZEN");
		}
		// reconnect when waiting for next round
		else if(self.spawnfrozen == 5) self thread frozenTermination(5);
	}

	if(isDefined(eAttacker) && isPlayer(eAttacker))
	{
		if(eAttacker == self) iprintln(&"FT_FROZEN_HIMSELF", [[level.ex_pname]](self));
			else if(eAttacker.pers["team"] == self.pers["team"]) iprintln(self.name, &"FT_FROZEN_BY_FRIEND", [[level.ex_pname]](eAttacker));
				else iprintln(self.name, &"FT_FROZEN_BY", [[level.ex_pname]](eAttacker));
	}

	// force the player to stand on normal freeze, i.e. if not forced to spawn frozen
	if(!self.spawnfrozen) self extreme\_ex_utils::forceto("stand");
	self.spawnfrozen = 0;

	// put up the icecube, and lock the players in place
	if(!isDefined(self.icecube)) self.icecube = spawn("script_model", self.origin);
	self.icecube setmodel("xmodel/icecubeblue1");
	self.icecube.origin = self.origin;
	self.icecube.angles = self.angles;
	self.icecube rotateto((0,0,90),.01);
	self linkTo(self.icecube);

	if(!level.ft_balance_frozen) self.dont_auto_balance = 1;

	if(!level.ex_rank_statusicons) self.statusicon = "hud_stat_frozen";

	// add "you are frozen" hud element
	if(!isDefined(self.hud_frozen))
	{
		self.hud_frozen = newClientHudElem(self);
		self.hud_frozen.x = 325;
		self.hud_frozen.y = 415;
		self.hud_frozen.alignX = "center";
		self.hud_frozen.alignY = "middle";
		self.hud_frozen.archived = false;
		self.hud_frozen.font = "default";
		self.hud_frozen.fontscale = 2;
		self.hud_frozen setText(&"FT_YOUAREFROZEN");

		// add frozen status bar
		self.hud_frozen_bar = newClientHudElem(self);
		self.hud_frozen_bar.x = 225;
		self.hud_frozen_bar.y = 430;
		self.hud_frozen_bar.alignX = "left";
		self.hud_frozen_bar.alignY = "top";
		self.hud_frozen_bar.alpha = 1;
		freezebar = int(self.frozenstatus * 2);
		self.hud_frozen_bar.color = (0,0,1);
		self.hud_frozen_bar setshader("white", freezebar, 10);
	}

	// show optional clock
	if(level.ft_unfreeze_mode) self thread frozenWindowClock(level.ft_unfreeze_mode_window);

	// play freezing sound
	self thread playFreezeFX("freeze", undefined);

	// force them to throw a nade if holding it
	self freezecontrols(true);
	wait(0);
	self freezecontrols(false);

	// disable the frozen player's weapons
	self [[level.ex_dWeapon]]();
	if(level.ex_ranksystem) self thread extreme\_ex_ranksystem::wmdStop();

	self thread playBreathFX();

	level updateTeamStatus();
}

frozenWindowClock(time)
{
	self endon("kill_thread");

	if(!isDefined(self.hud_frozen_clock))
	{
		self.hud_frozen_clock = newClientHudElem(self);
		self.hud_frozen_clock.horzAlign = "fullscreen";
		self.hud_frozen_clock.vertAlign = "fullscreen";
		self.hud_frozen_clock.horzAlign = "left";
		self.hud_frozen_clock.vertAlign = "top";
		self.hud_frozen_clock.x = 6;
		self.hud_frozen_clock.y = 76;
		self.hud_frozen_clock setClock(time, time, "hudStopwatch", 48, 48);
	}

	timer = time;
	while(timer)
	{
		wait( [[level.ex_fpstime]](1) );
		if(self.frozenstatus == 0)
		{
			if(isDefined(self.hud_frozen_clock)) self.hud_frozen_clock destroy();
			return;
		}

		timer--;
	}

	if(level.roundended || level.mapended) return;

	switch(level.ft_unfreeze_mode)
	{
		case 1:
			self.terminate_reason = 2;
			self suicide();
			break;
		case 2:
			if(self.frozenstate == "frozen") self.frozenstatus = 0;
			break;
	}
}

frozenTermination(time)
{
	self endon("kill_thread");

	iprintln(&"FT_ALL_RECON_DEAD", [[level.ex_pname]](self));
	self iprintlnbold(&"FT_YOU_RECON_DEAD");

	wait( [[level.ex_fpstime]](time) );

	if(level.roundended || level.mapended) return;

	self.frozencount = 999;
	self.terminate_reason = 3;
	self suicide();
}

unfreezePlayer()
{
	self endon("disconnect");

	self.dont_auto_balance = 0;
	self.health = 100;
	self.maxhealth = 100;
	self hudDestroy(false);
	self notify("unfrozen");

	if(isDefined(self.icecube))
	{
		self unlink();
		self.icecube delete();
	}

	self.frozenstate = "unfrozen";
	self.frozenstatus = 0;
	self.unfreeze_pending = undefined;

	// spawn at another location
	if(self.sessionstate != "dead")
	{
		if(level.ft_unfreeze_respawn)
		{
			spawnpointname = "mp_tdm_spawn";
			spawnpoints = getentarray(spawnpointname, "classname");
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_Unfrozen(spawnpoints);
			if(isDefined(spawnpoint))
			{
				self setOrigin(spawnpoint.origin);
				self setplayerangles(spawnpoint.angles);
			}
		}
		self [[level.ex_eWeapon]]();
		if(!level.ex_rank_statusicons) self.statusicon = "";
	}
}

hudScan()
{
	self endon("kill_thread");
	self endon("spawned");

	// randomize execution, so the thread won't run at the same time for all players.
	// Especially needed to spread the load after a map_restart (round based games)
	wait( [[level.ex_fpstime]](randomFloat(.5)) );

	while(1)
	{
		wait( [[level.ex_fpstime]](.5) );

		if(self.foundeligible || self.foundinbinocs)
		{
			if(!isDefined(self.hud_unfreeze_hint))
			{
				self.hud_unfreeze_hint = newClientHudElem(self);
				self.hud_unfreeze_hint.x = 0;
				self.hud_unfreeze_hint.y = 160;
				self.hud_unfreeze_hint.alignX = "center";
				self.hud_unfreeze_hint.alignY = "middle";
				self.hud_unfreeze_hint.horzAlign = "center_safearea";
				self.hud_unfreeze_hint.vertAlign = "center_safearea";
				self.hud_unfreeze_hint.alpha = 1;
				self.hud_unfreeze_hint.archived = false;
				self.hud_unfreeze_hint.font = "default";
				self.hud_unfreeze_hint.fontscale = 1.5;
				self.hud_unfreeze_hint.color = (0.980,0.996,0.388);
				self.hud_unfreeze_hint setText(&"FT_UNFREEZE_HINT");
			}
		}
		else if(isDefined(self.hud_unfreeze_hint)) self.hud_unfreeze_hint destroy();

		if(self.unfreezing || self.beingunfroze)
		{
			if(!isDefined(self.hud_unfreeze))
			{
				self.hud_unfreeze = newClientHudElem(self);
				self.hud_unfreeze.x = 580;
				self.hud_unfreeze.y = 130;
				self.hud_unfreeze.alignX = "center";
				self.hud_unfreeze.alignY = "middle";
				self.hud_unfreeze.fontScale = 1.2;
				self.hud_unfreeze.color = (1, 1, 1);
				self.hud_unfreeze.alpha = 1;
			}

			if(self.unfreezing) self.hud_unfreeze setText(&"FT_UNFREEZE_YOU");
				else self.hud_unfreeze setText(&"FT_UNFREEZE_ME");
		}
		else if(isDefined(self.hud_unfreeze)) self.hud_unfreeze destroy();

		if(level.ft_weaponsteal && self.foundenemy)
		{
			if(!isDefined(self.hud_steal))
			{
				self.hud_steal = newClientHudElem(self);
				self.hud_steal.x = 0;
				self.hud_steal.y = 200;
				self.hud_steal.alignX = "center";
				self.hud_steal.alignY = "middle";
				self.hud_steal.horzAlign = "center_safearea";
				self.hud_steal.vertAlign = "center_safearea";
				self.hud_steal.alpha = 1;
				self.hud_steal.archived = false;
				self.hud_steal.font = "default";
				self.hud_steal.fontscale = 1.5;
				self.hud_steal.color = (0.980,0.996,0.388);
				self.hud_steal setText(&"FT_WEAPON_STEAL");
			}
		}
		else if(isDefined(self.hud_steal)) self.hud_steal destroy();
	}
}

hudDestroy(all)
{
	self endon("disconnect");

	if(isDefined(self.hud_frozen)) self.hud_frozen destroy();
	if(isDefined(self.hud_frozen_bar)) self.hud_frozen_bar destroy();
	if(isDefined(self.hud_frozen_clock)) self.hud_frozen_clock destroy();
	if(all)
	{
		if(isDefined(self.hud_unfreeze)) self.hud_unfreeze destroy();
		if(isDefined(self.hud_unfreeze_bar)) self.hud_unfreeze_bar destroy();
		if(isDefined(self.hud_unfreeze_hint)) self.hud_unfreeze_hint destroy();
		if(isDefined(self.hud_steal)) self.hud_steal destroy();
	}
}

frozenTracker()
{
	self endon("kill_thread");
	self endon("spawned");

	// randomize execution, so the thread won't run at the same time for all players.
	// Especially needed to spread the load after a map_restart (round based games)
	wait( [[level.ex_fpstime]](randomFloat(.5)) );

	while(isDefined(self) && isAlive(self))
	{
		wait( [[level.ex_fpstime]](.5) );

		// if frozen, only check for unfreeze
		if(self.frozenstate == "frozen")
		{
			self.foundinbinocs = 0;
			self.foundeligible = 0;
			self.foundenemy = 0;

			// unfreeze player if frozenstatus drops to zero
			if(self.frozenstatus == 0) self unfreezePlayer();
		}
		// if binocs are up, check for laservision unfreeze targets
		else if(level.ft_unfreeze_laser && self.ex_binocuse)
		{
			frozen_player = self checkFrozenPlayers("laser", false, level.ft_unfreeze_laser_dist);

			if(frozen_player != self && self.frozenstate != "frozen")
			{
				self.foundinbinocs = 1;

				if(self usebuttonpressed()) self unfreezePlayerStatus(frozen_player); // do not thread
			}
			else self.foundinbinocs = 0;
		}
		// check for close proximity unfreezes and weapon exchanges
		else
		{
			self.foundinbinocs = 0;
			frozen_player = self checkFrozenPlayers("prox", false, level.ft_unfreeze_prox_dist);

			if(frozen_player != self && self.frozenstate != "frozen")
			{
				self.foundeligible = 1;

				if(self useButtonPressed()) self unfreezePlayerStatus(frozen_player); // do not thread
			}
			else self.foundeligible = 0;

			// check for weapon exchange targets if no frozen teammate is nearby
			if(!self.foundeligible && level.ft_weaponsteal)
			{
				frozen_player = self checkFrozenPlayers("prox", true, level.ft_unfreeze_prox_dist);

				if(frozen_player != self && self.frozenstate != "frozen")
				{
					self.foundenemy = 1;

					if(!isDefined(self.pers["isbot"]))
					{
						if(self useButtonPressed()) self weaponExchange(frozen_player);
						if(self meleeButtonPressed()) self grenadeSteal(frozen_player);
					}
				}
				else self.foundenemy = 0;
			}
		}
	}
}

checkFrozenPlayers(mode, check_enemy, check_dist)
{
	self endon("kill_thread");
	self endon("spawned");

	eligible_player = self;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isDefined(player) || !isAlive(player) || player == self) continue;
		if(isDefined(player.pers["team"]) && (player.pers["team"] == "spectator" || player.sessionteam == "spectator")) continue;
		if(check_enemy && player.pers["team"] == self.pers["team"]) continue;
		if(!check_enemy && player.pers["team"] != self.pers["team"]) continue;
		if(check_dist)
		{
			if(mode == "prox" && distance(player.origin, self.origin) > check_dist) continue;
			if(mode == "laser" && distance(player.origin, self.origin) > check_dist) continue;
		}
		if(self islookingat(player) && player.frozenstatus > 0 && player.frozenstate == "frozen")
		{
			eligible_player = player;
			break;
		}
	}

	return eligible_player;
}

unfreezePlayerStatus(frozen_player)
{
	self endon("kill_thread");
	self endon("spawned");

	self.unfreezing = 1;
	frozen_player.beingunfroze = 1;

	// unfreeze loops every half a sec, so divide by 2 to get correct unfreeze amount
	if(self.foundinbinocs) unfreeze_amount = int( (100 / level.ft_unfreeze_laser_time) / 2);
		else unfreeze_amount = int( (100 / level.ft_unfreeze_prox_time) / 2);
	if(unfreeze_amount == 0) unfreeze_amount = 1;

	// add unfreezing status bar
	if(!isDefined(self.hud_unfreeze_bar))
	{
		self.hud_unfreeze_bar = newClientHudElem(self);
		self.hud_unfreeze_bar.x = 530;
		self.hud_unfreeze_bar.y = 150;
		self.hud_unfreeze_bar.alignX = "left";
		self.hud_unfreeze_bar.alignY = "middle";
		self.hud_unfreeze_bar.alpha = 1;
	}

	// play unfreeze fx
	if(!self.foundinbinocs)
		self thread playFreezeFX("unfreeze", frozen_player);

	timer = 0;

	while(isDefined(self) && isDefined(frozen_player) && self useButtonPressed() && frozen_player.frozenstatus > 0)
	{
		if(!self.foundinbinocs && level.ft_unfreeze_prox_dist && distance(self.origin, frozen_player.origin) > level.ft_unfreeze_prox_dist) break;

		if(self.foundinbinocs && (!self.ex_binocuse || !(self islookingat(frozen_player))) ) break;

		if(!self useButtonPressed()
		|| !isAlive(self)
		|| !isAlive(frozen_player)
		|| self.sessionstate != "playing"
		|| frozen_player.sessionstate != "playing"
		|| self.frozenstate == "frozen") break;

		if(!timer)
		{
			// shoot laser
			if(self.foundinbinocs)
			{
				self thread playLaserFX(frozen_player);
				wait( [[level.ex_fpstime]](.05) );
			}

			// play unfreeze smoke efx
			if(!self.foundinbinocs)
			{
				playereye = frozen_player geteye();
				playfx(level.ft_smokefx, playereye);
			}

			timer = 2;
		}

		frozen_player.frozenstatus = frozen_player.frozenstatus - unfreeze_amount;
		if(frozen_player.frozenstatus < 0) frozen_player.frozenstatus = 0;

		// update unfreezing status bar
		freezebar = int(frozen_player.frozenstatus);
		self.hud_unfreeze_bar setshader("white", freezebar, 10);

		// update status bar for frozen player
		if(isDefined(frozen_player.hud_frozen_bar))
		{
			freezebar = int(frozen_player.frozenstatus * 2);
			frozen_player.hud_frozen_bar setshader("white", freezebar, 10);
		}

		if(frozen_player.frozenstatus == 0)
		{
			self thread finishUnfreeze(frozen_player, false);
			break;
		}

		wait( [[level.ex_fpstime]](.5) );
		timer--;
	}

	if(isDefined(self))
	{
		self.unfreezing = 0;
		if(self.foundinbinocs)
		{
			self thread playFreezeFX("binocs", frozen_player);
			self.foundinbinocs = 0;
		}
	}

	if(isDefined(frozen_player))
		frozen_player.beingunfroze = 0;

	if(isDefined(self.hud_unfreeze_bar))
		self.hud_unfreeze_bar destroy();
}

finishUnfreeze(frozen_player, raygun)
{
	// no need to unfreeze here; this is done by frozenTracker!
	iprintln(frozen_player.name, &"FT_UNFROZEN_BY", [[level.ex_pname]](self));

	// record it in the logs
	ft_selfnum = self getEntityNumber();
	ft_woundnum = frozen_player getEntityNumber();
	ft_selfGuid = self getGuid();
	ft_woundGuid = frozen_player getGuid();
	if(raygun) type = "MP_RAYGUN";
		else if(self.foundinbinocs) type = "MP_LASERVISION";
			else type = "MP_STANDNEAR";
	logprint("U;" + ft_selfGuid + ";" + ft_selfnum + ";" + self.name + ";" + ft_woundGuid + ";" + ft_woundnum + ";" + frozen_player.name + ";" + type + "\n");

	// give unfreezing player 2 points
	self.score += level.ft_points_unfreeze;

	// added for arcade style HUD points
	self notify("update_playerscore_hud");
}

playLaserFX(frozen_player)
{
	self endon("kill_thread");
	self endon("spawned");

	playereye = frozen_player geteye();
	vectortoplayer = vectornormalize(playereye - self.ex_eyemarker.origin);
	fx_origin = self.ex_eyemarker.origin;

	level thread extreme\_ex_utils::playSoundLoc("ft_laser", self.origin);
	playfx(level.ft_laserfx, fx_origin, vectortoplayer);

	if(frozen_player.frozenstate == "frozen")
	{
		playfx(level.ft_smokefx, playereye);
		frozen_player playLocalSound("ft_sandbag_snow");
		wait( [[level.ex_fpstime]](1) );
		if(isPlayer(frozen_player)) frozen_player playlocalSound("ft_melt");
	}
}

playFreezeFX(condition, frozen_player)
{
	self endon("kill_thread");
	self endon("spawned");

	if(condition == "freeze")
		self playLocalSound("ft_freeze");

	if(condition == "unfreeze" && isDefined(frozen_player) && !self.foundinbinocs)
	{
		wait( [[level.ex_fpstime]](.75) );
		if(isDefined(self)) self playLocalSound("ft_sandbag_snow");
		if(isDefined(frozen_player)) frozen_player playLocalSound("ft_sandbag_snow");

		wait( [[level.ex_fpstime]](.2) );
		if(isDefined(self)) self playLocalSound("ft_melt");
		if(isDefined(frozen_player)) frozen_player playLocalSound("ft_melt");

		while(isDefined(frozen_player) && frozen_player.beingunfroze)
		{
			chance = randomint(100);

			if(chance <= level.ft_soundchance)
			{
				if(isDefined(self)) self playLocalSound("ft_sandbag_snow");
				if(isDefined(frozen_player)) frozen_player playLocalSound("ft_sandbag_snow");

				wait( [[level.ex_fpstime]](.2) );
				if(isDefined(self)) self playLocalSound("ft_melt");
				if(isDefined(frozen_player)) frozen_player playLocalSound("ft_melt");
			}

			wait( [[level.ex_fpstime]](1) );
		}

		if(isDefined(self)) self playLocalSound("breathing_better");
		if(isDefined(frozen_player)) frozen_player playLocalSound("breathing_better");
	}

	if(condition == "binocs" && isDefined(frozen_player) && self.foundinbinocs)
	{
		wait( [[level.ex_fpstime]](.5) );
		if(isDefined(self)) self playLocalSound("breathing_better");
		if(isDefined(frozen_player)) frozen_player playLocalSound("breathing_better");
	}
}

playBreathFX()
{
	self endon("kill_thread");
	self endon("unfrozen");

	while(isDefined(self) && isAlive(self) && self.frozenstate == "frozen")
	{
		self pingplayer();

		// make sure the player's weapons are disabled until unfrozen!
		// don't do a self [[level.ex_dWeapon]]() here!
		if(!isDefined(self.pers["isbot"])) self disableWeapon();

		if(isDefined(self.ex_eyemarker))
		{
			angle = self getplayerangles();
			forwardvec = anglestoforward(angle);
			forward = vectornormalize(forwardvec);

			playfx(level.ex_effect["coldbreathfx"], self.ex_eyemarker.origin, forward);
		}

		wait( [[level.ex_fpstime]](3) );
	}
}

grenadeSteal(enemy)
{
	self endon("kill_thread");
	self endon("spawned");

	enemy endon("kill_thread");

	if(self.ex_sprinting) return;
	if(self.ex_binocuse) return;
	if(level.roundended || level.mapended) return;

	if(level.ft_weaponsteal_frag)
	{
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) self_currentfrags = self getammocount(self.pers["fragtype"]);
			else self_currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
		if(!isDefined(self_currentfrags)) self_currentfrags = 0;

		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) enemy_currentfrags = enemy getammocount(enemy.pers["fragtype"]);
			else enemy_currentfrags = enemy getammocount(enemy.pers["fragtype"]) + enemy getammocount(enemy.pers["enemy_fragtype"]);
		if(!isDefined(enemy_currentfrags)) enemy_currentfrags = 0;

		if(enemy_currentfrags && self_currentfrags < 9)
		{
			self_stealfrags = level.ft_weaponsteal_frag;
			if(enemy_currentfrags < self_stealfrags) self_stealfrags = enemy_currentfrags;
			if(self_currentfrags + self_stealfrags > 9) self_stealfrags = 9 - self_currentfrags;
			self_totalfrags = self_currentfrags + self_stealfrags;

			if(self_stealfrags)
			{
				self setWeaponClipAmmo(self.pers["fragtype"], self_totalfrags);
				enemy_totalfrags = enemy_currentfrags - self_stealfrags;
				enemy setWeaponClipAmmo(enemy.pers["fragtype"], enemy_totalfrags);

				if(self_stealfrags > 1)
				{
					enemy iprintlnbold(&"FT_YOUR_NADES_STOLEN", self_stealfrags);
					self iprintln(&"FT_NADES_STOLEN", self_stealfrags);
				}
				else
				{
					enemy iprintlnbold(&"FT_YOUR_NADE_STOLEN", self_stealfrags);
					self iprintln(&"FT_NADE_STOLEN", self_stealfrags);
				}
			}
		}
	}

	if(level.ft_weaponsteal_smoke)
	{
		self_currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
		if(!isDefined(self_currentsmokes)) self_currentsmokes = 0;

		enemy_currentsmokes = enemy getammocount(enemy.pers["smoketype"]) + enemy getammocount(enemy.pers["enemy_smoketype"]);
		if(!isDefined(enemy_currentsmokes)) enemy_currentsmokes = 0;

		if(enemy_currentsmokes && self_currentsmokes < 9)
		{
			self_stealsmokes = level.ft_weaponsteal_smoke;
			if(enemy_currentsmokes < self_stealsmokes) self_stealsmokes = enemy_currentsmokes;
			if(self_currentsmokes + self_stealsmokes > 9) self_stealsmokes = 9 - self_currentsmokes;
			self_totalsmokes = self_currentsmokes + self_stealsmokes;

			if(self_stealsmokes)
			{
				self setWeaponClipAmmo(self.pers["smoketype"], self_totalsmokes);
				enemy_totalsmokes = enemy_currentsmokes - self_stealsmokes;
				enemy setWeaponClipAmmo(enemy.pers["smoketype"], enemy_totalsmokes);

				if(self_stealsmokes > 1)
				{
					enemy iprintlnbold(&"FT_YOUR_SMOKES_STOLEN", self_stealsmokes);
					self iprintln(&"FT_SMOKES_STOLEN", self_stealsmokes);
				}
				else
				{
					enemy iprintlnbold(&"FT_YOUR_SMOKE_STOLEN", self_stealsmokes);
					self iprintln(&"FT_SMOKE_STOLEN", self_stealsmokes);
				}
			}
		}
	}
}

weaponExchange(enemy)
{
	self endon("kill_thread");
	self endon("spawned");

	enemy endon("kill_thread");

	if(self.ex_sprinting) return;
	if(self.ex_binocuse) return;
	if(level.roundended || level.mapended) return;

	my_current = self getcurrentweapon();
	my_primary = self getWeaponSlotWeapon("primary");
	my_primaryb = self getWeaponSlotWeapon("primaryb");
	if(isValidWeapon(my_current) && !isDummy(my_current))
	{
		if(my_current == my_primary) my_slot = "primary";
			else if(my_current == my_primaryb) my_slot = "primaryb";
				else my_slot = "virtual"; // should not get here

		my_current_clip = self.weapon[ self.weaponin[ my_slot ].slot ].clip;
		my_current_reserve = self.weapon[ self.weaponin[ my_slot ].slot ].reserve;
	}
	else
	{
		my_slot = "invalid";
		my_current_clip = 0;
		my_current_reserve = 0;
	}

	// if stealing of primary is allowed
	if(my_slot != "invalid" && !isWeaponType(my_current, "sidearm"))
	{
		if(!isDefined(enemy) || !isDefined(enemy.weapon) || !isDefined(enemy.weaponin)) return;

		enemy_current = enemy.weapon["primary"].name; // not really his current, but his saved primary
		enemy_primary = enemy getWeaponSlotWeapon("primary");
		enemy_primaryb = enemy getWeaponSlotWeapon("primaryb");
		if(isValidWeapon(enemy_current) && !isDummy(enemy_current))
		{
			if(enemy_current == enemy_primary) enemy_slot = "primary";
				else if(enemy_current == enemy_primaryb) enemy_slot = "primaryb";
					else enemy_slot = "virtual";

			enemy_primary_clip = enemy.weapon[ enemy.weaponin[ enemy_slot ].slot ].clip;
			enemy_primary_reserve = enemy.weapon[ enemy.weaponin[ enemy_slot ].slot ].reserve;
		}
		else
		{
			enemy_slot = "invalid";
			enemy_primary_clip = 0;
			enemy_primary_reserve = 0;
		}

		// if enemy has primary, try to take it
		if(enemy_slot != "invalid" && !isWeaponType(enemy_current, "sidearm") && enemy_primary_reserve)
		{
			// if you already have this weapon, skip to stealing ammo only
			if(enemy_current != self.weapon["primary"].name && enemy_current != self.weapon["primaryb"].name && enemy_current != self.weapon["virtual"].name)
			{
				// get weapon names, tells the player which weapon was stolen
				my_current_name = maps\mp\gametypes\_weapons::getWeaponName(my_current);
				enemy_current_name = maps\mp\gametypes\_weapons::getWeaponName(enemy_current);

				self takeWeapon(my_current);
				self setWeaponSlotWeapon(my_slot, enemy_current);
				self setWeaponSlotClipAmmo(my_slot, enemy_primary_clip);
				self setWeaponSlotAmmo(my_slot, enemy_primary_reserve);
				self switchtoweapon(enemy_current);

				enemy takeWeapon(enemy_current);
				if(enemy_slot != "virtual")
				{
					enemy setWeaponSlotWeapon(enemy_slot, my_current);
					enemy setWeaponSlotClipAmmo(enemy_slot, my_current_clip);
					enemy setWeaponSlotAmmo(enemy_slot, my_current_reserve);
					enemy switchtoweapon(my_current);
				}
				else
				{
					enemy.weapon["virtual"].name = my_current;
					enemy.weapon["virtual"].clip = my_current_clip;
					enemy.weapon["virtual"].reserve = my_current_reserve;
				}

				// tell the players about the weapon exchange
				self iprintlnbold(&"FT_WEAPON_EXCHANGED", enemy_current_name);
				enemy iprintlnbold(&"FT_WEAPON_PRI_STOLEN", my_current_name);
			}
			else
			{
				// reuse my_slot to save slot for ammo exchange
				if(enemy_current == my_primary) my_slot = "primary";
					else if(enemy_current == my_primaryb) my_slot = "primaryb";
						else my_slot = "virtual"; //if(enemy_current == self.weapon["virtual"].name)

				if(my_slot != "virtual")
				{
					if(self.weapon[ self.weaponin[my_slot].slot ].reserve < level.weapons[my_primary].ammo_limit)
						self setWeaponSlotAmmo(my_slot, self.weapon[ self.weaponin[my_slot].slot ].reserve + enemy_primary_reserve);
				}
				else
				{
					if(self.weapon[ self.weapon[my_slot]].reserve < level.weapons[my_primary].ammo_limit)
						self.weapon[my_slot].reserve += enemy_primary_reserve;
				}

				if(enemy_slot != "virtual") enemy setWeaponSlotAmmo(enemy_slot, 0);
					else enemy.weapon["virtual"].reserve = 0;

				// tell the players about the ammo exchange
				self iprintlnbold(&"FT_AMMO_ONLY_RESERVE");
				enemy iprintlnbold(&"FT_AMMO_RESERVE_STOLEN");
			}
		}
		else self iprintlnbold(&"FT_WEAPON_NOTHING");
	}
	else self iprintlnbold(&"FT_WEAPON_INVALID");

	wait( [[level.ex_fpstime]](.01) );
	while(self useButtonPressed()) wait( [[level.ex_fpstime]](.05) );
}

weaponEndRoundSave()
{
	self endon("disconnect");

	spawn_primary = self.pers["weapon1"];
	if(!isDefined(spawn_primary)) spawn_primary = "none";
	spawn_secondary = self.pers["weapon2"];
	if(!isDefined(spawn_secondary)) spawn_secondary = "none";

	new_primary = self.pers["weapon1"];
	new_secondary = self.pers["weapon2"];

	weapon = self.weapon["primary"].name; //self getWeaponSlotWeapon("primary");
	if(isValidWeapon(weapon) && !isDummy(weapon) && !isWeaponType(weapon, "sidearm")) new_primary = weapon;
	if(!isDefined(new_primary)) new_primary = "none";
	weapon = self.weapon["primaryb"].name; //self getWeaponSlotWeapon("primaryb");
	if(isValidWeapon(weapon) && !isDummy(weapon) && !isWeaponType(weapon, "sidearm")) new_secondary = weapon;
	if(!isDefined(new_secondary)) new_secondary = "none";

	self.nextround_weapon = newClientHudElem(self);
	self.nextround_weapon.archived = false;
	self.nextround_weapon.horzAlign = "center_safearea";
	self.nextround_weapon.vertAlign = "center_safearea";
	self.nextround_weapon.alignX = "center";
	self.nextround_weapon.alignY = "middle";
	self.nextround_weapon.x = 0;
	self.nextround_weapon.y = -30;
	self.nextround_weapon.font = "default";
	self.nextround_weapon.fontscale = 1.3;
	self.nextround_weapon.alpha = 1;

	// if no new weapons, return
	if( (new_primary == spawn_primary || new_primary == spawn_secondary) && (new_secondary == spawn_primary || new_secondary == spawn_secondary) )
	{
		self.nextround_weapon.label = &"FT_WEAPON_CHANGE";
		return;
	}
	else self.nextround_weapon.label = &"FT_WEAPON_KEEP";

	weapons_current = 0;

	while(isPlayer(self))
	{
		wait( [[level.ex_fpstime]](.05) );

		if(isplayer(self) && self attackButtonPressed())
		{
			if(!weapons_current)
			{
				self.pers["weapon"] = new_primary;
				self.pers["weapon1"] = self.pers["weapon"];
				self.pers["weapon2"] = new_secondary;
				self.nextround_weapon.label = &"FT_WEAPON_KEEP_CURRENT";
				weapons_current = 1;
			}
			else
			{
				self.pers["weapon"] = spawn_primary;
				self.pers["weapon1"] = self.pers["weapon"];
				self.pers["weapon2"] = spawn_secondary;
				self.nextround_weapon.label = &"FT_WEAPON_KEEP_SPAWN";
				weapons_current = 0;
			}

			while(isPlayer(self) && self attackButtonPressed())
				wait( [[level.ex_fpstime]](.05) );
		}
	}
}

weaponSave()
{
	self endon("disconnect");

	debugLog(false, "ft::weaponSave() started"); // DEBUG

	// save primary weapon
	if(!isDefined(self.weapon["save_primary"])) self.weapon["save_primary"] = spawnstruct();
	self.weapon["save_primary"].name = self.weapon["primary"].name;
	self.weapon["save_primary"].clip = self.weapon["primary"].clip;
	self.weapon["save_primary"].reserve = self.weapon["primary"].reserve;

	// save secondary weapon
	if(!isDefined(self.weapon["save_primaryb"])) self.weapon["save_primaryb"] = spawnstruct();
	self.weapon["save_primaryb"].name = self.weapon["primaryb"].name;
	self.weapon["save_primaryb"].clip = self.weapon["primaryb"].clip;
	self.weapon["save_primaryb"].reserve = self.weapon["primaryb"].reserve;

	// save virtual weapon
	if(!isDefined(self.weapon["save_virtual"])) self.weapon["save_virtual"] = spawnstruct();
	self.weapon["save_virtual"].name = self.weapon["virtual"].name;
	self.weapon["save_virtual"].clip = self.weapon["virtual"].clip;
	self.weapon["save_virtual"].reserve = self.weapon["virtual"].reserve;

	// save nades
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) self.weapon["save_frags"] = self getammocount(self.pers["fragtype"]);
		else self.weapon["save_frags"] = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(self.weapon["save_frags"])) self.weapon["save_frags"] = 0;
	self.weapon["save_smoke"] = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(self.weapon["save_smoke"])) self.weapon["save_smoke"] = 0;

	debugLog(false, "ft::weaponSave() finished"); // DEBUG
}

weaponRestore()
{
	self endon("disconnect");

	debugLog(false, "ft::weaponRestore() called"); // DEBUG

	self takeAllWeapons();

	wait 0;

	// restore primary weapon
	if(isValidWeapon(self.weapon["save_primary"].name))
	{
		self setWeaponSlotWeapon("primary", self.weapon["save_primary"].name);
		self setWeaponSlotClipAmmo("primary", self.weapon["save_primary"].clip);
		self setWeaponSlotAmmo("primary", self.weapon["save_primary"].reserve);
	}
	else self setWeaponSlotWeapon("primary", "none");

	// restore secondary weapon
	if(isValidWeapon(self.weapon["save_primaryb"].name))
	{
		self setWeaponSlotWeapon("primaryb", self.weapon["save_primaryb"].name);
		self setWeaponSlotClipAmmo("primaryb", self.weapon["save_primaryb"].clip);
		self setWeaponSlotAmmo("primaryb", self.weapon["save_primaryb"].reserve);
	}
	else self setWeaponSlotWeapon("primaryb", "none");

	// restore virtual weapon
	self.weapon["virtual"].name = self.weapon["save_virtual"].name;
	self.weapon["virtual"].clip = self.weapon["save_virtual"].clip;
	self.weapon["virtual"].reserve = self.weapon["save_virtual"].reserve;

	// restore nades
	self giveWeapon(self.pers["fragtype"]);
	self setWeaponClipAmmo(self.pers["fragtype"], self.weapon["save_frags"]);
	self giveWeapon(self.pers["smoketype"]);
	self setWeaponClipAmmo(self.pers["smoketype"], self.weapon["save_smoke"]);

	debugLog(true, "ft::weaponRestore() finished"); // DEBUG
}

checkHistory()
{
	for(i = level.ft_history; i > 0 ; i--)
	{
		status_cvar = getcvar("ft_history" + i);
		if(isDefined(status_cvar))
		{
			token_array = strtok(status_cvar, ",");
			if(token_array.size != 2) continue;
			if(token_array[0] != self.name) continue;
			if(token_array[1] == "DEAD")
			{
				//logprint("FREEZETAG connect: player " + self.name + " found in FT history (reconnect DEAD)\n");
				iprintln(&"FT_HISTORY_HIT_DEAD", [[level.ex_pname]](self));
				self.spawnfrozen = 5;
				return;
			}
			else if(token_array[1] == "FROZEN")
			{
				//logprint("FREEZETAG connect: player " + self.name + " found in FT history (reconnect FROZEN)\n");
				iprintln(&"FT_HISTORY_HIT_FROZEN", [[level.ex_pname]](self));
				self.spawnfrozen = 4;
				return;
			}
		}
	}
}

clearHistory()
{
	for(i = 1; i <= level.ft_history; i++)
		setcvar("ft_history" + i, "*");
}

debugMonitor()
{
	level endon("round_ended");

	// debug script to end the round or to unfreeze all frozen players
	while(1)
	{
		if(getcvarint("ft_endround") == 1)
		{
			setcvar("ft_endround", 0);

			level notify("finish_staydead");
			wait( [[level.ex_fpstime]](.1) );

			endRound("draw");
		}

		if(getcvarint("ft_unfreeze") == 1)
		{
			setcvar("ft_unfreeze", 0);

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player) && isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && (player.frozenstate == "frozen" || isDefined(player.spawned)))
				{
					if(player.frozenstate == "frozen") player.frozenstatus = 0;
					player.spawned = undefined;
					player.frozencount = 0;
					player.spawnfrozen = 0;
					player.killedfrozen = 0;
					player.terminate_reason = 0;
				}
			}

			level notify("finish_staydead");
			wait( [[level.ex_fpstime]](.1) );
		}

		wait( [[level.ex_fpstime]](1) );
	}
}
