#include extreme\_ex_weapons;

main(mbot_start)
{
	// only used in mbot development mode to start the mbots right away
	if(!isDefined(mbot_start)) mbot_start = false;

	createBotWeaponsArray();

	// mbots are handled differently
	if(level.ex_mbot)
	{
		level.wp = [];
		level.ex_mbots_allies = 0;
		level.ex_mbots_axis = 0;
		level.ex_botstart = -1;
		level.ex_botend = -1;

		setcvar("mbot_add", "");
		setcvar("mbot_remove", "");
		setcvar("mbot_skill", "");
		setcvar("mbot_speed", "");
		if(level.ex_mbot_dev) extreme\_ex_mbot_dev::init();

		level.wpfile = ("mbot/" + level.ex_currentmap + "_" + level.ex_currentgt + ".wp");
		if(!buildNodeInfo(level.wpfile))
		{
			if(level.ex_mbot_dev)
			{
				level.ex_mbot_dev_autosave_counter = 1;

				for(i = 0; i < level.ex_mbot_spawnpoints.size; i++)
				{
					vec = anglesToForward(level.ex_mbot_spawnpoints[i].angles);
					vec = maps\mp\_utility::vectorScale(vec, 26);
					org = level.ex_mbot_spawnpoints[i].origin + vec;
					extreme\_ex_mbot_dev::spawnNode("w", org, false);
				}

				extreme\_ex_mbot_dev::repositionWaypoints();
				extreme\_ex_mbot_dev::saveWaypoints(level.wpfile);
			}
			else
			{
				logprint("MBOTS: ABORTED. INVALID WAYPOINT FILE FOR MAP " + level.ex_currentmap + "\n");
				return;
			}
		}
		else
		{
			if(level.ex_mbot_dev)
			{
				level.ex_mbot_dev_autosave_counter = 1;

				extreme\_ex_mbot_dev::backupWaypoints();

				for(;;)
				{
					f = openfile(level.wpfile + ".auto" + level.ex_mbot_dev_autosave_counter, "read");
					if(f != -1)
					{
						closefile(f);
						level.ex_mbot_dev_autosave_counter++;
						if(level.ex_mbot_dev_autosave_counter > 20)
						{
							level.ex_mbot_dev_autosave_counter = 1;
							break;
						}
					}
					else break;
				}
			}
		}

		addVel();

		setBotSkill(level.ex_mbot_skill, true);
		setBotSpeed(level.ex_mbot_speed, true);
	}

	// don't add bots again if using the ready-up system
	if(level.ex_readyup && isDefined(game["readyup_done"])) return;

	if(!mbot_start) level waittill("gobots");

	if(level.ex_mbot)
	{
		level.ex_mbot_timer = 0;
		[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
		thread mbotStart();
	}
	else if(level.ex_testclients) thread dbotStart();
}

//******************************************************************************
// mbot restart monitor
//******************************************************************************
onSecond(eventID)
{
	restart = false;
	if(level.ex_mbot_timelimit)
	{
		level.ex_mbot_timer++;
		if(level.ex_mbot_timer == level.ex_mbot_timelimit * 60) restart = true;
	}

	if(level.ex_mbot_scorelimit)
	{
		if(getTeamScore("allies") >= level.ex_mbot_scorelimit || getTeamScore("axis") >= level.ex_mbot_scorelimit) restart = true;
	}

	if(restart)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player) && isDefined(player.pers["isbot"]))
				player thread extreme\_ex_bots::botJoin("spectator");
		}

		wait( [[level.ex_fpstime]](2) );
		game["mbot_restart"] = true;
		map_restart(true);
	}
}

//******************************************************************************
// eXtreme DUMB Bots
//******************************************************************************
dbotStart()
{
	wait( [[level.ex_fpstime]](5) );

	level.adding_dbots = true;

	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isDefined(players[i].pers) && isDefined(players[i].pers["isbot"])) level.ex_testclients--;

	for(i = 0; i < level.ex_testclients; i++)
	{
		wait( [[level.ex_fpstime]](1) );

		if(i & 1) team = "axis";
			else team = "allies";

		bot = undefined;
		players = level.players;
		for(j = 0; j < players.size; j++)
		{
			player = players[j];
			if( isPlayer(player) && !isDefined(player.spawning_bot) &&
			    (isSubStr(player.name, "bot") || (isDefined(player.pers) && isDefined(player.pers["isbot"]))) &&
			    (player.pers["team"] == "spectator" || player.sessionteam == "spectator") )
			{
				bot = player;
				break;
			}
		}

		if(!isDefined(bot)) bot = addtestclient();

		if(isDefined(bot))
		{
			bot.spawning_bot = true;
			bot thread dbotAdd(team);
		}
		else logprint("BOT DEBUG: failed to spawn bot " + i + "\n");
	}

	wait( [[level.ex_fpstime]](5) );
	level.adding_dbots = undefined;
}

dbotAdd(team)
{
	level endon("ex_gameover");
	self endon("disconnect");

	// wait here while the teams are configured
	while(!isDefined(self.pers["team"]) || !isDefined(game["allies"]) || !isDefined(game["axis"])) wait( [[level.ex_fpstime]](0.05) );

	// flag the bot
	self.pers["isbot"] = true;

	// pass server info
	self notify("menuresponse", game["menu_serverinfo"], "team");
	wait( [[level.ex_fpstime]](0.5) ); // DO NOT REMOVE, CHANGE OR DISABLE!

	// choose a team
	while(self.pers["team"] == "spectator")
	{
		self notify("menuresponse", game["menu_team"], team);
		wait( [[level.ex_fpstime]](0.5) );
	}

	//self.spawning_bot = undefined;

	// select weapon(s)
	self thread dbotLoadout();
}

dbotLoadout()
{
	// set the weapon variable
	weapon = undefined;
	if(level.ex_testclients_diag) logprint(self.name + " selecting weapons...\n");

	// keep looping here until all the weapons have been selected
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );

		if(self.pers["team"] == "allies") weapon = level.ex_botweapons_allies[randomInt(level.ex_botweapons_allies.size)];
			else weapon = level.ex_botweapons_axis[randomInt(level.ex_botweapons_axis.size)];

		if(!isDefined(weapon))
		{
			logprint("BOT DEBUG: bot weapons array contains an undefined slot. Fix that!\n");
			continue;
		}

		// check for weapon class only
		if(level.ex_wepo_class)
		{
			switch(level.ex_wepo_class)
			{
				case 1: classname = "pistol"; break;      // pistol only
				case 2: classname = "sniper"; break;      // sniper only
				case 3: classname = "mg"; break;          // mg only
				case 4: classname = "smg"; break;         // smg only
				case 5: classname = "rifle"; break;       // rifle only
				case 6: classname = "boltrifle"; break;   // bolt action rifle only
				case 7: classname = "shotgun"; break;     // shotgun only
				case 8: classname = "rl"; break;          // panzerschreck only
				case 9: classname = "boltsniper"; break;  // bolt and sniper only
				case 10: classname = "knife"; break;      // knives only
				default: classname = "boltsniper"; break; // boltsniper fallback
			}

			// if the weapon is not part of this class, shouldn't happen, but just in case!
			if(!isWeaponType(weapon, classname)) continue;
		}

		// force secondary weapon to "none" if secondary system is on
		if(level.ex_wepo_secondary && isDefined(self.pers["weapon"]))
		{
			self.sweapon = "none";
			self notify("menuresponse", game["menu_weapon_" + self.pers["team"] +"_sec"], "none");
			break;
		}

		// only allow pistol as primary on pistol-only class
		if(isWeaponType(weapon, "pistol") && level.ex_wepo_class != 1) continue;

		// only allow knife as primary on knife-only class
		if(isWeaponType(weapon, "knife") && level.ex_wepo_class != 10) continue;

		// if the weapon limiter is on, and this weapon is not allowed, get another one!
		if(level.ex_wepo_limiter)
		{
			if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
			{
				if(self.pers["team"] == "allies")
				{
					if(isDefined(level.weapons[weapon].allow_allies) && level.weapons[weapon].allow_allies == 0) continue;
				}
				else
				{
					if(isDefined(level.weapons[weapon].allow_axis) && level.weapons[weapon].allow_axis == 0) continue;
				}
			}
			else
			{
				if(isDefined(level.weapons[weapon].allow) && level.weapons[weapon].allow == 0) continue;
			}
		}

		// choose a primary weapon
		if(!isDefined(self.pers["weapon"]))
		{
			self notify("menuresponse", game["menu_weapon_" + self.pers["team"]], weapon);
			wait( [[level.ex_fpstime]](1) );
			if(level.ex_testclients_diag && isDefined(self.pers["weapon"]))
				logprint(self.name + " (" + self.pers["team"] + ") selected primary weapon " + weapon + "\n");

			if(!level.ex_wepo_secondary && isDefined(self.pers["weapon"])) break;
		}
	}
}

//******************************************************************************
// eXtreme AI Bots
// Based on MBot v0.7 by Maks Deryabin aka Spec; modifications by Cepe7a
// Adapted to eXtreme+ by PatmanSan
//******************************************************************************
mbotStart()
{
	level.ex_mbot_init = true;
	if(isDefined(game["mbot_restart"]))
	{
		level.ex_mbot_init = false;
		game["mbot_restart"] = undefined;
	}

	mbot_allies = level.ex_mbot_allies;
	if(mbot_allies > 32) mbot_allies = 32;
	mbot_maxaxis = 32 - mbot_allies;
	mbot_axis = level.ex_mbot_axis;
	if(mbot_axis > mbot_maxaxis) mbot_axis = mbot_maxaxis;
	mbot_onteam = mbot_allies + mbot_axis;
	if(mbot_onteam >= 32) level.ex_mbot_spec = 0;

	mbot_selector = 1;
	while(mbot_allies > 0 || mbot_axis > 0)
	{
		wait( [[level.ex_fpstime]](3) );

		if( (mbot_selector&1) && (mbot_axis > 0) )
		{
			mbot_axis--;
			addBot("axis");
		}
		else if(mbot_allies > 0)
		{
			mbot_allies--;
			addBot("allies");
		}

		mbot_selector++;
	}

	for(i = 0; i < level.ex_mbot_spec; i++)
	{
		wait( [[level.ex_fpstime]](1) );
		addBot("spectator");
	}

	wait( [[level.ex_fpstime]](5) );
	level.ex_mbot_init = false;

	level thread dvarCheck();
}

//------------------------------------------------------------------------------
// Level functions
//------------------------------------------------------------------------------
dvarCheck()
{
	level endon("ex_gameover");

	for(;;)
	{
		tmp = getCvar("mbot_add");
		if(tmp != "")
		{
			setCvar("mbot_add", "");
			addbot(tmp);
		}

		tmp = getCvar("mbot_remove");
		if(tmp != "")
		{
			setCvar("mbot_remove", "");
			removeBot(tmp);
		}

		tmp = getCvar("mbot_skill");
		if(tmp != "")
		{
			tmp = getCvarInt("mbot_skill");
			setCvar("mbot_skill", "");
			if(tmp != level.ex_mbot_skill) setBotSkill(tmp);
		}

		tmp = getCvar("mbot_speed");
		if(tmp != "")
		{
			tmp = getCvarInt("mbot_speed");
			setCvar("mbot_speed", "");
			if(tmp != level.ex_mbot_speed) setBotSpeed(tmp);
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

addBot(team)
{
	if(!isDefined(team)) team = "autoassign";

	bot = undefined;
	players = level.players;
	if(!level.ex_mbot_init && team != "spectator")
	{
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["isbot"]) && (players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator"))
			{
				bot = players[i];
				break;
			}
		}
	}

	if(!isDefined(bot)) bot = addtestclient();

	if(isDefined(bot))
	{
		bot.pers["isbot"] = true;
		bot.pers["dontkick"] = true; // exclude from kick monitor
		if(level.ex_diana && (randomInt(100) < 25)) bot.pers["diana"] = true;
		iprintlnbold(&"MBOT_BOTADDED", [[level.ex_pname]](bot));

		switch(team)
		{
			case "axis": bot thread botJoin(team); break;
			case "allies": bot thread botJoin(team); break;
			case "spectator": bot thread botJoin(team); break;
			default: bot thread botJoin("autoassign"); break;
		}
	}
	else iprintln(&"MBOT_MAXBOTS");
}

removeBot(team)
{
	players = level.players;

	switch(team)
	{
		case "allies":
			for(i = 0; i < players.size; i++)
			{
				if(!isDefined(players[i].pers["isbot"])) continue;
				if(players[i].pers["team"] == team)
				{
					players[i] notify("kill_thread");
					players[i] notify("killed_player");
					level.ex_mbots_allies--;
					players[i] thread botJoin("spectator");
					iprintlnbold(&"MBOT_BOTREMOVED", [[level.ex_pname]](players[i]));
				}
			}
			break;
		case "axis":
			for(i = 0; i < players.size; i++)
			{
				if(!isDefined(players[i].pers["isbot"])) continue;
				if(players[i].pers["team"] == team)
				{
					players[i] notify("kill_thread");
					players[i] notify("killed_player");
					level.ex_mbots_axis--;
					players[i] thread botJoin("spectator");
					iprintlnbold(&"MBOT_BOTREMOVED", [[level.ex_pname]](players[i]));
				}
			}
			break;
		case "all":
			for(i = 0; i < players.size; i++)
			{
				if(!isDefined(players[i].pers["isbot"])) continue;
				players[i] notify("kill_thread");
				players[i] notify("killed_player");
				players[i] thread botJoin("spectator");
				iprintlnbold(&"MBOT_BOTREMOVED", [[level.ex_pname]](players[i]));
			}

			level.ex_mbots_allies = 0;
			level.ex_mbots_axis = 0;
			break;
		default:
			for(i = 0; i < players.size; i++)
			{
				if(players[i].name == team)
				{
					if(!isDefined(players[i].pers["isbot"]))
					{
						iprintln(&"MBOT_NOTABOT", [[level.ex_pname]](players[i]));
						continue;
					}

					if(players[i].pers["team"] == "allies")
						level.ex_mbots_allies--;
					else if(players[i].pers["team"] == "axis")
						level.ex_mbots_axis--;

					players[i] notify("kill_thread");
					players[i] notify("killed_player");
					players[i] thread botJoin("spectator");
					iprintlnbold(&"MBOT_BOTREMOVED", [[level.ex_pname]](players[i]));
					break;
				}
			}
			break;
	}
}

setBotSkill(num, force)
{
	if(!isDefined(force)) force = false;

	if(num > 10) num = 10;
		else if(num < 0) num = 0;

	if(force || level.ex_mbot_skill != num)
	{
		level.ex_mbot_skill = num;
		level.botwaittime = 0.55 - (level.ex_mbot_skill / 20);
		iprintlnbold(&"MBOT_SKILL", level.ex_mbot_skill);
	}
}

setBotSpeed(num, force)
{
	if(!isDefined(force)) force = false;

	if(num > 220) num = 220;
		else if(num < 50) num = 50;

	if(force || level.ex_mbot_speed != num)
	{
		level.ex_mbot_speed = num;
		iprintlnbold(&"MBOT_SPEED", level.ex_mbot_speed);
	}
}

//------------------------------------------------------------------------------
// Bot weapon functions
//------------------------------------------------------------------------------
botJoin(team)
{
	self endon("disconnect");
	self endon("joined_spectators");

	// wait here while the teams are configured
	while(!isDefined(self.pers["team"]) || !isDefined(game["allies"]) || !isDefined(game["axis"])) wait( [[level.ex_fpstime]](0.05) );

	// pass server info
	if(!isDefined(self.pers["skipserverinfo"]))
	{
		self notify("menuresponse", game["menu_serverinfo"], "team");
		wait( [[level.ex_fpstime]](0.5) ); // DO NOT REMOVE, CHANGE OR DISABLE!
	}

	// choose a team
	self notify("menuresponse", game["menu_team"], team);
	self waittill("joined_team");
	if(self.pers["team"] == "allies") level.ex_mbots_allies++;
		else if(self.pers["team"] == "axis") level.ex_mbots_axis++;

	// start monitoring the bot. That thread terminates if bot joins spectators
	self thread botStart();

	// keep looping here until all the weapons have been selected
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );
		if(self.pers["team"] == "allies") weapon = level.ex_botweapons_allies[randomInt(level.ex_botweapons_allies.size)];
			else weapon = level.ex_botweapons_axis[randomInt(level.ex_botweapons_axis.size)];

		// check for weapon class only
		if(level.ex_wepo_class)
		{
			switch(level.ex_wepo_class)
			{
				case 1: classname = "pistol"; break;       // pistol only
				case 2: classname = "sniper"; break;       // sniper only
				case 3: classname = "mg"; break;           // mg only
				case 4: classname = "smg"; break;          // smg only
				case 5: classname = "rifle"; break;        // rifle only
				case 6: classname = "boltrifle"; break;    // bolt action rifle only
				case 7: classname = "shotgun"; break;      // shotgun only
				case 8: classname = "rl"; break;           // panzerschreck only
				case 9: classname = "boltsniper"; break;   // bolt and sniper only
				case 10: classname = "knife"; break;       // knives only
				default: classname = "boltsniper"; break;  // boltsniper fallback
			}

			// if the weapon is not part of this class, shouldn't happen, but just in case!
			if(!isWeaponType(weapon, classname)) continue;
		}

		// check if this is also a valid bot weapon
		bweapon = maps\mp\gametypes\_weapons::getMBotWeapon(weapon);
		if(level.ex_testclients_diag) logprint(self.name + " (" + self.pers["team"] + ") trying to select weapon " + weapon + " (" + bweapon + ")\n");
		if(bweapon == "dummy1_mp") continue;

		// force secondary weapon to "none" if secondary system is on
		if(level.ex_wepo_secondary && isDefined(self.pers["weapon"]))
		{
			self.sweapon = "none";
			self notify("menuresponse", game["menu_weapon_" + self.pers["team"] +"_sec"], "none");
			break;
		}

		// only allow pistol as primary on pistol-only class
		if(isWeaponType(weapon, "pistol") && level.ex_wepo_class != 1) continue;

		// if the weapon limiter is on, and this weapon is not allowed, get another one!
		if(!level.ex_wepo_class && level.ex_wepo_limiter && !level.weapons[weapon].allow) continue;

		// choose a primary weapon
		if(!isDefined(self.pers["weapon"]))
		{
			self.oweapon = weapon;
			self.pweapon = bweapon;
			self notify("menuresponse", game["menu_weapon_" + self.pers["team"]], weapon);
			wait( [[level.ex_fpstime]](1) );
			if(level.ex_testclients_diag && isDefined(self.pers["weapon"]))
				logprint(self.name + " (" + self.pers["team"] + ") selected primary weapon " + weapon + "\n");

			if(!level.ex_wepo_secondary && isDefined(self.pers["weapon"])) break;
		}
	}
}

botLoadout()
{
	currpweapon = self getweaponslotweapon("primary");
	self takeweapon(currpweapon);
	self.pers["weapon"] = self.pweapon;
	self setWeaponSlotWeapon("primary", self.pers["weapon"]);
	self setweaponslotammo("primary", 999);
	self setweaponslotclipammo("primary", 999);
	self setspawnweapon(self.pers["weapon"]);
	self.pclipammo = self getWeaponSlotClipAmmo("primary");
}

addBotWeapon(weapon, ammo, clipammo)
{
	if(isDefined(self.pers["weapon"]))
	{
		currpweapon = self getweaponslotweapon("primary");
		self takeweapon(currpweapon);
		self giveweapon(weapon);
		self setweaponslotammo("primary", ammo);
		self setweaponslotclipammo("primary", clipammo);
		self setspawnweapon(weapon);
		self switchtoweapon(weapon);
	}
}

//------------------------------------------------------------------------------
// Bot main logic
//------------------------------------------------------------------------------
botStart()
{
	self endon("disconnect");
	self endon("joined_spectators");

	for(;;)
	{
		self waittill("spawned_player");
		wait( [[level.ex_fpstime]](0.2) );
		self thread botMainLoop();
	}
}

botMainLoop()
{
	self endon("kill_thread");

	self freezecontrols(true);
	wait( [[level.ex_fpstime]](1) );
	self.botorg = spawn("script_origin", self.origin);
	self linkto(self.botorg);

	self.state = "start";
	self.alert = false;
	self.facetarget = undefined;
	self.next = undefined;
	self.skiprotate = undefined;
	self.collisions = 0;

	self thread checkEnemy();

	while(isAlive(self))
	{
		switch(self.state)
		{
			case "freeze":
				self.state = "camp";
				self thread makeCamp(0);
				break;

			case "idle":
				if(!self.alert)
				{
					if(self.next.type != "w")
						self mbotStopLoopSound();

					switch(self.next.type)
					{
						case "w":
							self.state = "move";
							self.next = self getNextNode();
							self thread goToNode(self.next.origin);
							break;

						case "g":
							if(randomInt(100) < 50)
							{
								self.state = "throw";
								self thread throwFragGrenade();
							}
							else if(randomInt(100) < 10)
							{
								self.state = "throw";
								self thread throwSmokeGrenade();
							}
							else self.state = "done";
							break;

						case "f":
							self.state = "fall";
							self thread fallGravity();
							break;

						case "c":
							if(randomInt(3))
							{
								self.state = "camp";
								time = randomInt(5) + 2;
								self thread makeCamp(time);
							}
							else self.state = "done";
							break;

						case "j":
							self.state = "jump";
							self thread jumpGravity();
							break;

						case "m":
							self.state = "mantle";
							self thread doMantle();
							break;

						case "l":
							self.state = "climb";
							self thread climbUp();
							break;
					}
				}
				else wait( [[level.ex_fpstime]](0.1) );
				break;

			case "move":
				if(checkBotCollision())
				{
					self stopMoving();
					self.pclipammo = self getweaponslotclipammo("primary");
					self setweaponslotammo("primary", 0);
					self setweaponslotclipammo("primary", 0);
					self freezecontrols(false);

					while(checkBotCollision())
					{
						self.collisions++;
						wait( [[level.ex_fpstime]](0.1) );
						if(self.collisions > 100)
						{
							self.ex_forcedsuicide = true;
							self suicide();
							return;
						}
					}
					self.collisions = 0;

					self freezecontrols(true);
					self givemaxammo(self.pers["weapon"]);
					self setweaponslotclipammo("primary", self.pclipammo);
					wait( [[level.ex_fpstime]](1) );
					self thread goToNode(self.next.origin);
					break;
				}

				if(self.alert)
				{
					if(!isDefined(self.facetarget)) self stopMoving();
					while(self.alert) wait( [[level.ex_fpstime]](0.1) );
					self thread goToNode(self.next.origin);
					break;
				}

				wait( [[level.ex_fpstime]](0.01) );
				break;

			case "done":
				self.state = "move";
				self.next = self getNextNode();
				self thread goToNode(self.next.origin);
				break;

			case "start":
				self.state = "move";
				self.next = self getNextNode();
				self thread goToNode(self.next.origin);
				// unhide mbots (hidden in _ex_main::exprespawn)
				self show();
				break;

			default:
				wait( [[level.ex_fpstime]](0.01) );
				break;
		}
	}
}

checkEnemy()
{
	self endon("kill_thread");

	self.alert = false;
	self.enemy = undefined;
	target = undefined;
	target_face = undefined;
	waittarget = 0;
	waitanim = 0;

	self.pclipammo = self getweaponslotclipammo("primary");

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](level.botwaittime + waitanim) );

		if(!isAlive(self) || !isDefined(self.mark)) return;

		waitanim = 0;
		eye = self.mark[0].origin;
		newtarget = undefined;
		target_mark = undefined;

		if(!level.ex_mbot_dev || level.ex_mbot_dev_killmode)
		{
			if(isDefined(self.facetarget) && isAlive(self.facetarget))
			{
				if(!self.alert && (self.state == "idle" || self.state == "move" || self.state == "camp"))
				{
					target_face = self.facetarget;
					target = target_face;
					self.facetarget = undefined;
					waittarget = 2;

					self stopMoving();
					self doRotateOrg(target.origin, randomFloat(1-(level.ex_mbot_skill*0.1))+0.1);
					self thread blockRotate(1);

					self.pclipammo = self getweaponslotclipammo("primary");
					self setweaponslotammo("primary", 0);
					self setweaponslotclipammo("primary", 0);
					self freezecontrols(false);
				}
			}

			if(isDefined(target) && target.pers["team"] != self.pers["team"])
				target_mark = self visibleMark(target, true);

			if(isDefined(target_mark))
			{
				newtarget = target;
			}
			else
			{
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(isPlayer(player) && isDefined(player.pers["team"]) && player.pers["team"] != self.pers["team"])
					{
						target_mark = self visibleMark(player, true);
						if(isDefined(target_mark))
						{
							newtarget = player;
							break;
						}
					}
				}
			}
		}

		target = newtarget;
		if(isDefined(target))
		{
			if(self.state != "idle" && self.state != "move" && self.state != "camp")
			{
				waitanim = 2;
				continue;
			}

			if(!isDefined(self.enemy) || self.enemy != target)
			{
				self.skiprotate = undefined;
				stopRotate();
				rotwait = randomFloat(1-(level.ex_mbot_skill*0.1))+0.1;
				self doRotateOrg(target_mark, rotwait);
				wait( [[level.ex_fpstime]](rotwait) );
			}
			self.enemy = target;

			if(!self.alert)
			{
				if(self.state == "camp" || isDefined(target_face))
				{
					self givemaxammo(self.pers["weapon"]);
					self setweaponslotclipammo("primary", self.pclipammo);
				}
				self.alert = true;
			}

			if(self.state == "idle" || self.state == "move" || self.state == "camp")
			{
				vtarget = vectorNormalize(target_mark - eye);
				self.pclipammo = self getweaponslotclipammo("primary");
				self setPlayerAngles(vectorToAngles(vtarget));
				self freezecontrols(false);
			}

			waittarget = randomInt(2)+5;
		}
		else
		{
			if(self.alert || isDefined(target_face))
			{
				if(!waittarget || (isDefined(self.enemy) && !isAlive(self.enemy)))
				{
					self.enemy = undefined;
					waittarget = 0;
				}
				else
				{
					waittarget--;
					continue;
				}

				if(self.state != "camp")
				{
					self freezecontrols(true);
					wait( [[level.ex_fpstime]](1) );
				}
				else
				{
					self setweaponslotammo("primary", 0);
					self setweaponslotclipammo("primary", 0);
				}

				self.pclipammo = self getweaponslotclipammo("primary");
				if(!self.alert) self thread goToNode(self.next.origin);
					else self.alert = false;
				target_face = undefined;
			}
		}
	}
}

visibleMark(player, checkallsurface)
{
	self endon("kill_thread");

	if(!isDefined(player))
		return undefined;

	if(!isalive(player) || !isDefined(player.mark))
		return undefined;

	if(!level.ex_mbot_dev_killdev && level.ex_mbot_dev && (player.name == level.ex_mbot_devname))
		return undefined;

	bot_maxdist = level.ex_mbot_maxdist;
	if(bot_maxdist < 100) bot_maxdist = 100;

	eye = self.mark[0].origin;
	dist = distance(eye, player.mark[0].origin);
	if(dist > bot_maxdist)
		return undefined;

	dist = vectornormalize(player.origin - eye);
	angles = self getplayerangles();
	vfwd = anglestoforward(angles);
	dot = vectordot(vfwd, dist);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(isDefined(self.enemy))
	{
		if(viewangle > 45)
			return undefined;
	}
	else
	{
		if(viewangle > level.ex_mbot_viewangle)
			return undefined;
	}

	for(j = 0; j < player.mark.size; j++)
	{
		if(j == 0 && level.ex_mbot_skill <= 5) continue;

		if(sighttracepassed(eye, player.mark[j].origin, false, self))
		{
			trace = bullettrace(eye, player.mark[j].origin, true, self);
			if(checkallsurface && trace["surfacetype"] != "default" && trace["surfacetype"] != "none")
				return undefined;

			accuracy = (randomFloat(10-(level.ex_mbot_skill*1)), 0, 0);
			return player.mark[j].origin + accuracy;
		}
	}
	return undefined;
}

checkBotCollision()
{
	self endon("kill_thread");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		dist = distance(self.origin, player.origin);

		if(player == self || !isalive(player) || dist > 96)
			continue;

		if(dist < 32)
			return false;
		else if(dist < 64)
		{
			if(isDefined(player.next) && self.next.origin == player.next.origin && closer(self.next.origin, player.origin, self.origin))
				return true;
		}

		if(self.next.next.size)
		{
			next = level.wp[self.next.next[0]];
			if(isDefined(player.next) && next.origin == player.next.origin)
				return true;
		}
	}

	return false;
}

getNextNode()
{
	self endon("kill_thread");

	next = undefined;

	if(isDefined(self.goto))
	{
		next = moveToNode(self.goto);
		self.goto = undefined;
		return next;
	}

	if(level.ex_botstart != -1)
	{
		if(!isDefined(self.next) || !isDefined(self.next.next) || self.next.next.size == 0 ||
		  (level.ex_botend != -1 && self.next == level.wp[level.ex_botend] && self.next != level.wp[level.ex_botstart]))
		{
			next = moveToNode(level.ex_botstart);
			return next;
		}
	}

	if(isDefined(self.next))
	{
		next = self.next;
		if(isDefined(self.next.next) && self.next.next.size != 0)
		{
			n = randomInt(self.next.next.size);
			next = level.wp[self.next.next[n]];
		}
		else self.freezeme = true;
	}
	else next = self findStartNode();

	return next;
}

moveToNode(node)
{
	self.next = level.wp[node];
	self.botorg moveto(self.next.origin, 0.01, 0, 0);
	self.botorg waittill("movedone");
	next = self.next;
	if(isDefined(self.next.next) && self.next.next.size != 0)
	{
		n = randomInt(self.next.next.size);
		next = level.wp[self.next.next[n]];
	}
	else self.freezeme = true;
	return(next);
}

findStartNode()
{
	if(isDefined(level.ex_mbot_spawnpoints))
	{
		for(i = 0; i < level.ex_mbot_spawnpoints.size; i++)
		{
			if(distance(self.origin, level.ex_mbot_spawnpoints[i].origin) < 16)
				return level.wp[i];
		}
	}

	next = undefined;
	for (;;)
	{
		next = level.wp[randomInt(level.ex_mbot_spawnpoints.size)];
		if(!isDefined(self.next) || self.next != next)
			break;
	}

	return next;
}

goToNode(nodeOrg)
{
	self endon("kill_thread");
	self endon("stopmove");

	if(isDefined(self.freezeme))
	{
		self.state = "freeze";
		return;
	}

	if(!isDefined(nodeOrg) || nodeOrg == self.botorg.origin)
	{
		self.state = "idle";
		return;
	}

	dist = distance(self.botorg.origin, nodeOrg);
	moveTime = dist / level.ex_mbot_speed;
	target = vectorNormalize(nodeOrg - self.origin);
	angles = vectorToAngles(target);

	self stopRotate();
	self thread doRotateOrg(nodeOrg, randomFloat(2-(level.ex_mbot_skill*0.2))+0.1);
	self thread mbotPlayLoopSound("step_bot_run", .43);
	self.botorg moveto(nodeOrg, moveTime, 0, 0);

	while(1)
	{
		if(distance(self.origin, nodeOrg) < 32)
		{
			self.state = "idle";
			return;
		}
		wait( [[level.ex_fpstime]](0.1) );
	}
}

stopMoving()
{
	self endon("kill_thread");

	self notify("stopmove");

	self.skiprotate = undefined;
	self stopRotate();
	self mbotStopLoopSound();
	if(isAlive(self)) self.botorg moveto((self.origin + (1, 1, 0)), 0.01, 0, 0);
	wait( [[level.ex_fpstime]](0.1) );
}

throwFragGrenade()
{
	self endon("kill_thread");

	if(self.botgrenadecount > 0)
	{
		self.skiprotate = undefined;
		self stopRotate();
		self doRotateAng(self.next.angles, 0.1);
		wait( [[level.ex_fpstime]](0.1) );

		self addBotWeapon(self.botgrenade, 999, 999);
		self thread extreme\_ex_utils::execClientCommand("-attack; +frag; -frag");
		self switchtooffhand(self.pers["fragtype"]);

		for(i = 0; i < 20; i++)
		{
			self freezecontrols(false);
			wait( [[level.ex_fpstime]](0.05) );
		}

		self.botgrenadecount--;
		self freezecontrols(true);
		self setWeaponClipAmmo(self.pers["fragtype"], self.botgrenadecount);
		self addBotWeapon(self.pers["weapon"], 999, self.pclipammo);
	}

	self.state = "done";
}

throwSmokeGrenade()
{
	self endon("kill_thread");

	if(self.botsmokecount > 0)
	{
		self.skiprotate = undefined;
		self stopRotate();
		self doRotateAng(self.next.angles, 0.1);
		wait( [[level.ex_fpstime]](0.1) );

		self addBotWeapon(self.botsmoke, 999, 999);
		self thread extreme\_ex_utils::execClientCommand("-attack; +smoke; -smoke");
		self switchtooffhand(self.pers["smoketype"]);

		for(i = 0; i < 20; i++)
		{
			self freezecontrols(false);
			wait( [[level.ex_fpstime]](0.05) );
		}

		self.botsmokecount--;
		self freezecontrols(true);
		self setWeaponClipAmmo(self.pers["smoketype"], self.botsmokecount);
		self addBotWeapon(self.pers["weapon"], 999, self.pclipammo);
	}

	self.state = "done";
}

fallGravity()
{
	self endon("kill_thread");

	if(isDefined(self.next.next[0]))
	{
		destOrg = level.wp[self.next.next[0]].origin;

		ang = vectorToAngles((vectorNormalize(destOrg - self.next.origin)));
		vel = anglesToForward((0.0, ang[1], 0.0));

		dst = distance((self.next.origin[0], self.next.origin[1], 0), (destOrg[0], destOrg[1], 0));
		height = self.next.origin[2] - destOrg[2];
		sqr = getVelSqr(height);
		dst = (dst) / sqr;
		
		if(dst > 240) dst = 240;
		vel = (vel[0]*dst, vel[1]*dst, 0);
		
		self stopRotate();
		self thread doRotateAng((30.0, ang[1], 0.0), 0.1);

		self.botorg movegravity(vel, sqr);
		self.botorg waittill("movedone");
		self thread mbotPlaySurface("Land_");
		self.botorg moveto(destOrg, 0.01, 0, 0);
		self.botorg waittill("movedone");
	}

	self.state = "done";
}

jumpGravity()
{
	self endon("kill_thread");

	if(isDefined(self.next.next[0]))
	{
		destOrg = level.wp[self.next.next[0]].origin;

		vmax = 240;
		ang = vectorToAngles((vectorNormalize(destOrg - self.next.origin)));
		ang = (0, ang[1], 0);
		vel = anglesToForward(ang);
		vel = (vel[0], vel[1], 1);

		dst = distance(destOrg, self.next.origin);
		if(destOrg[2] >= self.next.origin[2])
		{
			dst = dst * 1.6;
			if(dst > vmax)
				dst = vmax;
			vel = (dst*vel[0], dst*vel[1], vmax);
		}
		else
		{
			h = self.next.origin[2] - destOrg[2];
			dst = dst*1.6 - h*(1.25+h/(vmax*10));
			if(dst > vmax)
				dst = vmax;
			vel = (dst*vel[0], dst*vel[1], vmax);
		}

		self.skiprotate = undefined;
		self stopRotate();
		self thread doRotateAng(ang, 0.5);

		self.botorg movegravity(vel, 10);
		
		if(destOrg[2] >= self.next.origin[2])
		{
			wait( [[level.ex_fpstime]](0.5) );
			while(self.botorg.origin[2] > destOrg[2]) wait( [[level.ex_fpstime]](0.01) );
		}
		else
		{
			wait( [[level.ex_fpstime]](0.5) );
			while(self.botorg.origin[2] > destOrg[2]+32 ) wait( [[level.ex_fpstime]](0.01) );
		}

		self thread mbotPlaySurface("Land_");
		self.botorg moveto(destOrg, 0.1, 0, 0);
		self.botorg waittill("movedone");
	}

	self.state = "done";
}

doMantle()
{
	self endon("kill_thread");

	if(isDefined(self.next.next[0]))
	{
		self.skiprotate = undefined;
		self stopRotate();
		wait( [[level.ex_fpstime]](0.1) );
	
		next = level.wp[self.next.next[0]];
		dist = distance(self.next.origin, next.origin);
		ang = vectorToAngles((vectorNormalize(next.origin - self.next.origin)));
		vec = anglesToForward((-80.0, ang[1], 0.0));
		vec = maps\mp\_utility::vectorScale(vec, dist);
		destOrg = self.next.origin + vec;
		self setplayerangles((20, ang[1], 0));

		self addBotWeapon("mantle_up_bot", 0, 0);
		self.botorg playSound("bot_raise_weap");
		wait( [[level.ex_fpstime]](0.1) );

		moveTime = distance(self.next.origin, destOrg)/100;
		self.botorg moveto(destOrg, moveTime, 0, 0);
		self.botorg waittill("movedone");

		if(isDefined(self.next.mode) && self.next.mode == 1 && isDefined(next.next[0]))
		{
			self.next = next;

			vec = anglesToForward((10, ang[1], 0));
			vec = maps\mp\_utility::vectorScale(vec, 32);
			destOrg = self.next.origin + vec;
			moveTime = distance(self.botorg.origin, destOrg)/100;

			self addBotWeapon("mantle_over_bot", 0, 0);
			wait( [[level.ex_fpstime]](0.1) );

			self.botorg moveto(destOrg, moveTime, 0, 0);
			self.botorg waittill("movedone");

			self addBotWeapon(self.pers["weapon"], 999, self.pclipammo);
			self.state = "fall";

			destOrg = level.wp[self.next.next[0]].origin + (0, 0, 20);
			self.botorg movegravity((0.0, 0.0, 0.0), 10);
			while(self.botorg.origin[2] > destOrg[2]) wait( [[level.ex_fpstime]](0.01) );

			self.botorg moveto((destOrg - (0, 0, 20)), .075, 0, 0);
			self.botorg playsound("bot_land");
			self.botorg waittill("movedone");
		}
		else
		{
			self addBotWeapon(self.pers["weapon"], 999, self.pclipammo);
		}
	}

	self.state = "done";
}

climbUp()
{
	self endon("kill_thread");

	if(isDefined(self.next.next[0]))
	{
		next = level.wp[self.next.next[0]];

		height = next.origin[2] - self.next.origin[2] - 10;
		if(height < 10)
		{
			self.state = "done";
			return;
		}

		destOrg = self.next.origin + (0.0, 0.0, height);
		moveTime = distance(self.next.origin, destOrg)/100;

		self.skiprotate = undefined;
		self stopRotate();
		wait( [[level.ex_fpstime]](0.1) );

		ang = vectorToAngles((vectorNormalize(next.origin - self.next.origin)));
		self setplayerangles((-50, ang[1], 0));

		self.botorg playSound("bot_raise_weap");
		self addBotWeapon("climb_up_bot", 0, 0);
		wait( [[level.ex_fpstime]](0.1) );

		self thread mbotPlayLoopSound("step_bot_climb", .4);
		self.botorg moveto(destOrg, moveTime, 0, 0);
		self.botorg waittill("movedone");

		self mbotStopLoopSound();

		if(next.type != "m") self addBotWeapon(self.pers["weapon"], 999, self.pclipammo);
	}

	self.state = "done";
}

makeCamp(time)
{
	self endon("kill_thread");

	if(isDefined(self.next.angles))
	{
		self stopRotate();
		self doRotateAng(self.next.angles, 0.5);
	}

	self.pclipammo = self getweaponslotclipammo("primary");
	self setweaponslotammo("primary", 0);
	self setweaponslotclipammo("primary", 0);
	self freezecontrols(false);

	if(!isDefined(self.freezeme)) wait( [[level.ex_fpstime]](time) );
		else while(isDefined(self.freezeme)) wait( [[level.ex_fpstime]](1) );

	if(!self.alert)
	{
		self freezecontrols(true);
		self givemaxammo(self.pers["weapon"]);
		self setweaponslotclipammo("primary", self.pclipammo);
		wait( [[level.ex_fpstime]](1) );
	}

	self.state = "done";
}

mbotPlayLoopSound(alias, interval)
{
	self endon("stoploopsound");

	if(!isDefined(self.isPlayingLoopSound) || !self.isPlayingLoopSound)
	{
		self.isPlayingLoopSound = true;

		if(alias == "step_bot_run")
		{
			while(isDefined(self.botorg))
			{
				self thread mbotPlaySurface("step_walk_");
				wait( [[level.ex_fpstime]](interval) );
			}
		}
		else
		{
			while(isDefined(self.botorg))
			{
				self.botorg playSound(alias);
				wait( [[level.ex_fpstime]](interval) );
			}
		}
	}
}

mbotPlaySurface(alias)
{
	trace=bulletTrace(self.origin, self.origin-(0,0,512), false, self);
	if(trace["surfacetype"] == "none")
		self playsound(alias + "default");
	else
		self playsound(alias + trace["surfacetype"]);
}

mbotStopLoopSound()
{
	self.isPlayingLoopSound = false;
	self notify("stoploopsound");
}

playerDamage(eAttacker, iDamage)
{
	self endon("kill_thread");

	if(!isDefined(self.pers["isbot"]) || !isPlayer(eAttacker) || self == eAttacker) return;

	if(!isDefined(self.state) || self.state == "jump" || self.state == "mantle" || self.state == "climb") return;

	if(isDefined(self.alert) && !self.alert)
	{
		dist = distance(self.origin, eAttacker.origin);
		if(dist <= level.ex_mbot_maxdist && (self.state == "move" || self.state == "idle"))
			self.facetarget = eAttacker;
	}
}

playerKilled()
{
	if(isDefined(self.pers["isbot"]))
	{
		self.skiprotate = undefined;
		self stopRotate();
		self mbotStopLoopSound();
		self unlink();
		if(isDefined(self.botorg)) self.botorg delete();
	}

	if(isDefined(self.mark))
	{
		for(i = 0; i < self.mark.size; i++) 
		{
			if(isDefined(self.mark[i]))
			{
				self.mark[i] unlink();
				self.mark[i] delete();
			}
		}

		self.mark = undefined;
	}
}

doRotateOrg(target, roundsec)
{
	self endon("kill_thread");
	self endon("stoprotate");

	if(isDefined(self.skiprotate)) return;

	newangles = vectorToAngles(vectorNormalize(target - self.origin));
	self thread doRotateAng(newangles, roundsec);
}

doRotateAng(newangles, roundsec)
{
	self endon("kill_thread");
	self endon("stoprotate");

	if(!isDefined(newangles)) return;
	if(isDefined(self.skiprotate)) return;

	iter = 20;

	iterinc = 360/iter;
	iterwait = roundsec/iter;

	angles = vectorToAngles(anglestoforward(self getplayerangles()));
	newangles = vectorToAngles(anglestoforward(newangles));

	yaw = angleSubtract(newangles[1], angles[1]);
	pitch = angleSubtract(newangles[0], angles[0]);

	if(yaw < 0)
		dyaw = iterinc * (-1);
	else
		dyaw = iterinc;

	if(pitch < 0)
		dpitch = iterinc * (-1);
	else
		dpitch = iterinc;

	iyaw = abs(yaw) / iterinc;
	ipitch = abs(pitch) / iterinc;

	while(1)
	{
		if(iyaw > 1)
			angles = anglesAdd(angles, (0, dyaw, 0));
		if(ipitch > 1)
			angles = anglesAdd(angles, (dpitch, 0, 0));

		self setplayerangles(angles);

		if(iyaw > 1)
			iyaw -= 1;
		if(ipitch > 1)
			ipitch -= 1;

		if(iyaw <= 1 && ipitch <= 1) break;
		wait( [[level.ex_fpstime]](iterwait) );
	}
	self setplayerangles(newangles);
}

stopRotate()
{
	if(isDefined(self.skiprotate)) return;
	self notify("stoprotate");
	wait( [[level.ex_fpstime]](0.01) );
}

blockRotate(time)
{
	self endon("kill_thread");
	self notify("stopblockrotate");
	self endon("stopblockrotate");

	self.skiprotate = true;
	wait( [[level.ex_fpstime]](time) );
	self.skiprotate = undefined;
}

//------------------------------------------------------------------------------
// Utils
//------------------------------------------------------------------------------
createBotWeaponsArray()
{
	classname = undefined;
	allteamweapons = false;
	allmodernweapons = false;

	level.ex_botweapons_allies = [];
	level.ex_botweapons_axis = [];

	// build the botweapon arrays
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		if(level.weapons[weaponname].classname == "sniperlr") continue;
		if(weaponname == "raygun_mp") continue;

		addtoteam = false;
		addtobothteams = false;

		if(weaponname != "fraggrenade" && weaponname != "smokegrenade" && weaponname != "binoculars_mp")
		{
			if(level.ex_all_weapons)
			{
				addtobothteams = true;
			}
			else if(level.ex_modern_weapons)
			{
				switch(level.ex_wepo_class)
				{
					case 1: classname = "pistol"; break; // pistol only
					case 2: classname = "sniper"; break; // sniper only
					case 3: classname = "mg"; break; // mg only
					case 4: classname = "smg"; break; // smg only
					case 7: classname = "shotgun"; break; // shotgun only
					default: allmodernweapons = true; break; // all modern menus
				}

				if(allmodernweapons || isWeaponType(weaponname, classname)) // all modern weapons, or matching class weapon
				{
					addtobothteams = true;
				}
			}
			else
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

				if(allteamweapons) // all team weapons for allies and axis
				{
					addtoteam = true;
				}
				else // weapon class (secondary system disabled)
				{
					if(level.ex_wepo_team_only) // team based, only add weapons of this type that match the game allies and the game axis
					{
						if(isWeaponType(weaponname, classname)) addtoteam = true;
					}
					else // not team based so add all weapons of this type
					{
						if(isWeaponType(weaponname, classname))
						{
							addtobothteams = true;
						}
					}

					if(level.ex_wepo_sidearm && isWeaponType(weaponname, "pistol")) // if sidearm (pistol) is allowed add it
					{
						if(level.ex_wepo_team_only) // only add pistols that match the game allies and the game axis
						{
							if(isWeaponType(weaponname, classname)) addtoteam = true;
						}
						else // not team based so add all pistols
						{
							addtobothteams = true;
						}
					}
				}
			}

			if(addtobothteams || (addtoteam && isWeaponType(weaponname, game["allies"]))) level.ex_botweapons_allies[level.ex_botweapons_allies.size] = weaponname;
			if(addtobothteams || (addtoteam && isWeaponType(weaponname, game["axis"]))) level.ex_botweapons_axis[level.ex_botweapons_axis.size] = weaponname;
		}
	}

	if(level.ex_testclients_diag)
	{
		logprint("*********************************\n");
		logprint("* Bot weapons debug begin       *\n");
		logprint("*********************************\n");

		for(i = 0; i < level.ex_botweapons_allies.size; i++)
			logprint("Allied bot weapon [" + i + "] = " + level.ex_botweapons_allies[i] + " \n");

		logprint("\n");

		for(i = 0; i < level.ex_botweapons_axis.size; i++)
			logprint("Axis bot weapon [" + i + "] = " + level.ex_botweapons_axis[i] + " \n");

		logprint("********************************\n");
		logprint("* BOT weapon debug end         *\n");
		logprint("********************************\n");

		logprint("\n");
	}
}

buildNodeInfo(file)
{
	logprint("MBOT: Loading bot waypoints from ", file, ".\n");
	f = openfile(file, "read");
	if(f == -1)
	{
		logprint("MBOT ERROR: File ", file, " not found.\n");
		return false;
	}

	freadln(f);
	s = fgetarg(f, 0);
	if(!isDefined(s) || s != "mbotwp")
	{
		closefile(f);
		logprint("MBOT ERROR: Unknown file format.\n");
		return false;
	}

	i = 0;
	while(freadln(f) != -1)
	{
		s = fgetarg(f, 0);
		t = strtok(s, " ,");

		level.wp[i] = spawnstruct();
		level.wp[i].origin = (strToFlt(t[0]), strToFlt(t[1]), strToFlt(t[2]));

		switch(t[3])
		{
			case "w":
				level.wp[i].type = "w";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);
				break;

			case "g":
				level.wp[i].type = "g";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				k = 0;
				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);

				k += 6;
				level.wp[i].angles = (strToFlt(t[k]), strToFlt(t[k+1]), 0);
				break;

			case "f":
				level.wp[i].type = "f";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);
				break;

			case "c":
				level.wp[i].type = "c";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				k = 0;
				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);

				k += 6;
				level.wp[i].angles = (strToFlt(t[k]), strToFlt(t[k+1]), 0);
				break;

			case "j":
				level.wp[i].type = "j";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);
				break;

			case "m":
				level.wp[i].type = "m";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);

				k += 6;
				level.wp[i].mode = int(t[k]);
				break;

			case "l":
				level.wp[i].type = "l";
				level.wp[i].next = [];
				level.wp[i].stance = int(t[4]);

				for(k = 0; k < int(t[5]); k++)
					level.wp[i].next[k] = int(t[6+k]);
				break;

			default:
				closefile(f);
				logprint("MBOT ERROR: ", file, " has invalid waypoint #" + i + " (unknown type).\n");
				return false;
		}
		i++;
	}
	closefile(f);

	if(i == 0)
	{
		logprint("MBOT ERROR: ", file, " has not data.\n");
		return false;
	}

	for(k = 0; k < level.wp.size; k++)
	{
		if(level.wp[k].next.size == 0)
			logprint("MBOT WARNING: ", file, " has waypoint #" + k + " with no next waypoint.\n");

		if((level.wp[k].type == "f" || level.wp[k].type == "j" || level.wp[k].type == "m" || level.wp[k].type == "l") && level.wp[k].next.size > 1)
			logprint("MBOT WARNING: ", file, " has waypoint #" + k + " of type \"" + level.wp[k].type + "\" with more than one next waypoints.\n");
	}

	logprint("MBOT: Loaded.\n");
	return true;
}

strToFlt(str)
{
	if((!isDefined(str)) || (!str.size)) return(0);

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	str2 = getsubstr(str, offset);
	parts = strtok(str2, ".");

	intpart = strToInt(parts[0]);
	decpart = strToInt(parts[1]);

	if(decpart < 0) return(0);

	if(decpart)
		for(i = 0; i < parts[1].size; i ++)
			decpart = decpart / 10;

	return((intpart + decpart) * sign);
}

strToInt(str)
{
	if((!isDefined(str)) || (!str.size)) return(0);

	ctoi = [];
	ctoi["0"] = 0;
	ctoi["1"] = 1;
	ctoi["2"] = 2;
	ctoi["3"] = 3;
	ctoi["4"] = 4;
	ctoi["5"] = 5;
	ctoi["6"] = 6;
	ctoi["7"] = 7;
	ctoi["8"] = 8;
	ctoi["9"] = 9;

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	val = 0;

	for(i = offset; i < str.size; i ++)
	{
		switch(str[i])
		{
			case "0" :
			case "1" :
			case "2" :
			case "3" :
			case "4" :
			case "5" :
			case "6" :
			case "7" :
			case "8" :
			case "9" :
				val = val * 10 + ctoi[str[i]];
				break;
			default :
				return(0);
		}
	}

	return(val * sign);
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return var;
}

angleSubtract(a1, a2)
{
	a = a1-a2;
	if(abs(a) > 180)
	{
		if(a < -180)
			a += 360;
		else if(a > 180)
			a -= 360;
	}
	return a;
}

anglesAdd(a1, a2)
{
	v = [];
	v[0] = a1[0] + a2[0];
	v[1] = a1[1] + a2[1];
	v[2] = a1[2] + a2[2];

	for (i=0; i<3; i++)
	{
		while (v[i] > 360)
			v[i] -= 360;
		while (v[i] < -360)
			v[i] += 360;
	}
	return (v[0], v[1], v[2]);
}

addVel()
{
	level.velsqr = [];
	addVelSqr(12, 0.17);
	addVelSqr(25, 0.25);
	addVelSqr(37, 0.31);
	addVelSqr(50, 0.36);
	addVelSqr(75, 0.44);
	addVelSqr(100, 0.51);
	addVelSqr(125, 0.56);
	addVelSqr(150, 0.62);
	addVelSqr(175, 0.67);
	addVelSqr(200, 0.71);
	addVelSqr(250, 0.8);
	addVelSqr(300, 0.88);
	addVelSqr(350, 0.94);
	addVelSqr(400, 1.01);
	addVelSqr(450, 1.07);
	addVelSqr(500, 1.13);
	addVelSqr(600, 1.21);
	addVelSqr(650, 1.29);
	addVelSqr(700, 1.34);
	addVelSqr(750, 1.38);
	addVelSqr(800, 1.43);
	addVelSqr(850, 1.5);
	addVelSqr(900, 1.51);
	addVelSqr(1000, 1.6);
}

addVelSqr(h, sqr)
{
	i = level.velsqr.size;
	level.velsqr[i] = spawnstruct();
	level.velsqr[i].h = h;
	level.velsqr[i].sqr = sqr;
}

getVelSqr(h)
{
	hprev = level.velsqr[0].h;
	for (i=1; i<level.velsqr.size; i++)
	{
		hcur = level.velsqr[i].h;
		if(h > hcur)
		{
			hprev = hcur;
			continue;
		}
		hcur = hprev + ((hcur - hprev) / 2);
		if(h < hcur)
			sqr = level.velsqr[i-1].sqr;
		else
			sqr = level.velsqr[i].sqr;
		return sqr;
	}

	return level.velsqr[i-1].sqr;
}

mapSupportsMBots(map, type)
{
	f = openfile(("mbot/" + map + "_" + type + ".wp"), "read");
	if(f != -1)
	{
		closefile(f);
		return true;
	}

	return false;
}

debugBot(logweap, procname)
{
	if(!isDefined(level.debugbotweapons)) return;
	//if(self.name != "bot1") return;

	logproc = true;
	if(!isDefined(procname)) logproc = false;

	if(logproc) logprint("\nWEAPON DEBUG: " + self.name + ", procedure " +  procname + "\n");
		else logprint("\nWEAPON DEBUG: " + self.name + "\n");

	if(logweap)
	{
		primary = self getWeaponSlotWeapon("primary");
		secondary = self getWeaponSlotWeapon("primaryb");
		current = self getCurrentWeapon();

		if(level.ex_wepo_secondary)
		{
			logprint("WEAPON DEBUG: self.pers[\"weapon1\"]: " + self.pers["weapon1"] + " -- actual primary " + primary + "\n");
			logprint("WEAPON DEBUG: self.pers[\"weapon2\"]: " + self.pers["weapon2"] + " -- actual secondary " + secondary + "\n");
		}
		else
			logprint("WEAPON DEBUG:  self.pers[\"weapon\"]: " + self.pers["weapon"] + " -- actual primary " + primary + " (secondary: " + secondary + ")\n");

		logprint("WEAPON DEBUG:       current weapon: " + current + "\n");
	}
}
