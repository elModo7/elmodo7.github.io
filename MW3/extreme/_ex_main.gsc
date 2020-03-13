#include extreme\_ex_weapons;

//******************************************************************************
// eXtreme+ launch main threads
//******************************************************************************
main()
{
	// call init in 0.iwd to get the iwd in the list of referenced iwd's (to force download)
	//maps\mp\gametypes\_gt0::init();

	// dump entities after the level script has completed
	if((level.ex_entities & 2) == 2) extreme\_ex_entities::dumpMapEntities("AFTER");

	// we only need to initialize the mbots in mbot development mode
	if(level.ex_mbot && level.ex_mbot_dev)
	{
		// initialize spawnpoint markers array
		level.ex_spawnmarkers = [];

		// initialize mbots
		thread extreme\_ex_bots::main(true);

		// Tell DRM to stop processing "small", "medium" and "large" extensions
		game["ex_modstate"] = "initialized";

		return;
	}

	// reposition flags to fix placement bug on linux
	if(level.ex_flagbased)
	{
		axis_flag = getent("axis_flag", "targetname");
		if(isDefined(axis_flag))
		{
			//axis_flag placeSpawnpoint();
			trace = bulletTrace(axis_flag.origin + (0,0,50), axis_flag.origin - (0,0,100), true, axis_flag);
			axis_flag.origin = trace["position"];
			axis_flag.home_origin = axis_flag.origin;
			if(isDefined(axis_flag.flagmodel)) axis_flag.flagmodel.origin = axis_flag.home_origin;
			if(isDefined(axis_flag.basemodel)) axis_flag.basemodel.origin = axis_flag.home_origin;
		}

		allied_flag = getent("allied_flag", "targetname");
		if(isDefined(allied_flag))
		{
			//allied_flag placeSpawnpoint();
			trace = bulletTrace(allied_flag.origin + (0,0,50), allied_flag.origin - (0,0,100), true, allied_flag);
			allied_flag.origin = trace["position"];
			allied_flag.home_origin = allied_flag.origin;
			if(isDefined(allied_flag.flagmodel)) allied_flag.flagmodel.origin = allied_flag.home_origin;
			if(isDefined(allied_flag.basemodel)) allied_flag.basemodel.origin = allied_flag.home_origin;
		}

		/*
		if(isDefined(level.flag))
		{
			//level.flag placeSpawnpoint();
			trace = bulletTrace(level.flag.origin + (0,0,50), level.flag.origin - (0,0,100), true, level.flag);
			level.flag.origin = trace["position"];
			level.flag.home_origin = level.flag.origin;
			if(isDefined(level.flag.flagmodel)) level.flag.flagmodel.origin = level.flag.home_origin;
			if(isDefined(level.flag.basemodel)) level.flag.basemodel.origin = level.flag.home_origin;
		}
		*/
	}

	// get the map dimensions and playing field dimensions
	if(!isDefined(game["mapArea_Centre"])) extreme\_ex_utils::GetMapDim(false);

	// update spawnpoints in designer mode
	if(level.ex_designer) thread extreme\_ex_spawnpoints::markSpawnpoints();

	// initialize bots (dumb or meat)
	if(level.ex_testclients || level.ex_mbot) thread extreme\_ex_bots::main();

	// setup weather FX
	if(level.ex_weather) thread extreme\_ex_weather::main();

	// set up map rotation
	if(getCvar("ex_maprotdone") == "")
	{
		// set up player based rotation
		if(level.ex_pbrotate) extreme\_ex_maprotation::pbRotation();
		// save rotation for rotation stacker
		setCvar("ex_maprotation", getCvar("sv_maprotation"));
		setCvar("ex_maprotdone","1");
	}

	// fix the map rotation (executed only once)
	if(level.ex_fixmaprotation) level extreme\_ex_maprotation::fixMapRotation();

	// set a random map rotation (executed only once)
	if(level.ex_randommaprotation) level thread extreme\_ex_maprotation::randomMapRotation();

	// rotation stacker
	if(!level.ex_pbrotate)
	{
		ex_maprotation = getCvar("ex_maprotation");
		maprotcur = getcvar("sv_maprotationcurrent");
		if(maprotcur == "")
		{
			maprotno = getCvar("ex_maprotno");
			if(maprotno == "") maprotno = 0;
				else maprotno = getCvarInt("ex_maprotno");
			maprotno++;
			maprot = getcvar("sv_maprotation" + maprotno);
			if(maprot != "")
			{
				setCvar("sv_maprotation", maprot);
				setCvar("ex_maprotno", maprotno);
			}
			else if(maprotno != 1)
			{
				maprotno = 0;
				setCvar("sv_maprotation", ex_maprotation);
				setCvar("ex_maprotno", maprotno);
			}
			else setCvar("ex_maprotno", maprotno);
		}
	}

	// clear any camping players
	if(level.ex_campwarntime || level.ex_campsniper_warntime) level thread extreme\_ex_camper::removeCampers();

	// Bash-mode level announcement
	if( (level.ex_bash_only && level.ex_bash_only_msg > 1) ||
	    (level.ex_frag_fest && level.ex_frag_fest_msg > 1) ) level thread modeAnnounceLevel();

	// Clan-mode level announcement
	if(level.ex_clanvsnonclan && level.ex_clanvsnonclan_msg > 1) level thread clanAnnounceLevel();

	// ----- READYUP: Stop here when in ready-up mode ----------------------------
	if(level.ex_readyup && !isDefined(game["readyup_done"]))
	{
		// Tell DRM to stop processing "small", "medium" and "large" extensions
		game["ex_modstate"] = "initialized";

		// Start bot system
		level notify("gobots");

		return;
	}
	// ----- READYUP -------------------------------------------------------------

	// monitor the world for potatoes
	[[level.ex_registerLevelEvent]]("onSecond", ::potatoMonitor);

	// ammo crates
	if(level.ex_amc_perteam) level thread extreme\_ex_ammocrates::main();

	// turrets monitor
	if(level.ex_turrets) level thread extreme\_ex_turrets::main();

	// retreat monitor
	if(level.ex_flag_retreat) level thread retreatMonitor();

	// Start gunship
	if(level.ex_gunship || level.ex_gunship_special) level thread extreme\_ex_gunship::main();

	// Tell DRM to stop processing "small", "medium" and "large" extensions
	game["ex_modstate"] = "initialized";

	// Start bot system
	level notify("gobots");
}

//******************************************************************************
// eXtreme+ launch player threads
//******************************************************************************
playerOnFrame()
{
	wait(0);

	selfnum = self getEntityNumber();
	if(selfnum >= 60) selfframe = selfnum - 60;
	else if(selfnum >= 40) selfframe = selfnum - 40;
	else if(selfnum >= 20) selfframe = selfnum - 20;
	else selfframe = selfnum;
	//logprint("FPS: player " + self.name + " (entity " + selfnum + ") waiting for launch on frame " + selfframe + " (now " + level.ex_frame + ")\n");

	selftick = 0;
	while(level.ex_frame != selfframe)
	{
		wait(0.01);
		selftick++;
	}

	self notify("ready_to_launch");
	//logprint("FPS: player " + self.name + " (entity " + selfnum + ") launching (" + selftick + " ticks)\n");
}

playerThreads()
{
	self endon("kill_thread");

	// make sure the level scripts are started before starting player threads
	while(!isDefined(game["ex_modstate"])) wait( [[level.ex_fpstime]](0.05) );

	// check just to be sure
	if(level.ex_gameover) return;

	// parachutes (prep has been done in exPreSpawn() )
	if(level.ex_parachutes && isDefined(self.ex_willparachute)) self thread extreme\_ex_parachute::main();

	// randomize execution of threads, so they won't run all at the same time for all players.
	// Especially needed to spread the load after a map_restart (round based games)
	if(level.ex_spawncontrol)
	{
		self thread playerOnFrame();
		self waittill("ready_to_launch");
	}
	else wait( [[level.ex_fpstime]](randomFloat(.5)) );

	// check again... can't be sure enough
	if(level.ex_gameover) return;

	// start toolbox procedures
	self thread extreme\_ex_toolbox::main();

	// turn off intro, spec and death music
	if( (level.ex_intromusic && self.pers["intro_on"]) || (level.ex_specmusic && self.pers["spec_on"]) || (level.ex_deathmusic && self.pers["dth_on"]) )
	{
		self.pers["intro_on"] = false;
		self.pers["spec_on"] = false;
		self.pers["dth_on"] = false;
		self playLocalSound("spec_music_null");
		self playLocalSound("spec_music_stop");
	}

	// remove team switching flag (re-allow spawn delay if enabled)
	self.ex_team_changed = undefined;

	// init move monitor vars
	self.ex_lastorigin = self.origin;
	self.ex_stance = 0;
	self.ex_pace = false;
	self.ex_moving = false;

	// init stance-shoot monitor vars
	if(level.ex_stanceshoot)
	{
		self.ex_laststance = 2;
		self.ex_lastjump = 3;
		self.ex_jumpcheck = false;
		self.ex_jumpsensor = 0;
	}

	// init sniper anti-run monitor vars
	if(level.ex_antirun)
	{
		self.antirun_puninprog = false;
		self.antirun_mark = undefined;
		if(!isDefined(self.pers["antirun"])) self.pers["antirun"] = 0;
	}

	// init weapon usage monitor vars
	self.ex_lastoffhand = "none";
	self.ex_oldoffhand = self getCurrentOffHand();
	if(self.ex_oldoffhand != "none") self.ex_oldoffhand_ammo = self getAmmoCount(self.ex_oldoffhand);
		else self.ex_oldoffhand_ammo = 0;

	// init grenade warning monitor vars
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) self.ex_oldfrags = self getammocount(self.pers["fragtype"]);
		else self.ex_oldfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	self.ex_oldsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);

	// init call for medic monitor vars
	self.ex_calledformedic = 0;

	// init cold breath monitor vars
	self.ex_coldbreathdelay = 0;

	// init burst monitor vars
	self.ex_bursttrigger = 0;

	// init health bar
	if(level.ex_healthsystem)
	{
		if(!isDefined(self.ex_healthcross))
		{
			self.ex_healthcross = newClientHudElem(self);
			self.ex_healthcross.archived = true;
			self.ex_healthcross.horzAlign = "fullscreen";
			self.ex_healthcross.vertAlign = "fullscreen";
			self.ex_healthcross.alignX = "right";
			self.ex_healthcross.alignY = "top";
			self.ex_healthcross.x = 535; //543;
			self.ex_healthcross.y = 455;
		}
		self.ex_healthcross setShader("gfx/hud/hud@health_cross.tga", 10, 10);

		if(!isDefined(self.ex_healthback))
		{
			self.ex_healthback = newClientHudElem(self);
			self.ex_healthback.archived = true;
			self.ex_healthback.horzAlign = "fullscreen";
			self.ex_healthback.vertAlign = "fullscreen";
			self.ex_healthback.alignX = "left";
			self.ex_healthback.alignY = "top";
			self.ex_healthback.x = 539; //547;
			self.ex_healthback.y = 455;
		}
		self.ex_healthback setShader("gfx/hud/hud@health_back.tga", 90, 10);

		if(!isDefined(self.ex_healthbar))
		{
			self.ex_healthbar = newClientHudElem(self);
			self.ex_healthbar.archived = true;
			self.ex_healthbar.horzAlign = "fullscreen";
			self.ex_healthbar.vertAlign = "fullscreen";
			self.ex_healthbar.alignX = "left";
			self.ex_healthbar.alignY = "top";
			self.ex_healthbar.x = 540; //548;
			self.ex_healthbar.y = 456;
			self.ex_healthbar.color = ( 0, 1, 0);
		}
		self.ex_healthbar setShader("gfx/hud/hud@health_bar.tga", 88, 8);

		self.ex_oldhealth = self.health;
	}

	// ----- MBOTS: stop here if you are an mbot ---------------------------------
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return;
	// ----- MBOTS ---------------------------------------------------------------

	[[level.ex_registerPlayerEvent]]("onFrame", ::multiMonitorFrame, true);
	[[level.ex_registerPlayerEvent]]("onTenthSecond", ::multiMonitorTenthSecond, true);
	[[level.ex_registerPlayerEvent]]("onHalfSecond", ::multiMonitorHalfSecond, true);
	if(level.ex_heli && level.ex_heli_candamage) extreme\_ex_specials_helicopter::onFrameInit();

	// monitor laser dot
	if(level.ex_laserdot) self thread extreme\_ex_laserdot::main();

	// monitor sniper zoom level
	if(level.ex_zoom) self thread extreme\_ex_zoom::main();

	// monitor for knife
	self thread extreme\_ex_knife::main();

	// monitor for flamethrower
	self thread extreme\_ex_flamethrower::main();

	// monitor sprint
	if(level.ex_sprint) self thread extreme\_ex_sprintsystem::main();

	// check names and show welcome messages
	self thread handleWelcome();

	// ----- READYUP: stop here when in ready-up mode ----------------------------
	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;
	// ----- READYUP -------------------------------------------------------------

	// spawn protection
	if(level.ex_spwn_time) self thread extreme\_ex_spawnpro::main();

	// parachute release
	if(level.ex_parachutes && isDefined(self.ex_willparachute)) self notify("parachute_release");

	// monitor for anti-run forced crouch
	if(level.ex_antirun_spawncrouched) self thread antirunSpawnCrouched();

	// monitor points for arcade style HUD element
	if(level.ex_arcade) self thread extreme\_ex_arcade::main();

	// monitor mobile MGs
	if(level.ex_turrets == 2) self thread extreme\_ex_turrets::monitorMobileMG();

	// monitor camper
	if(level.ex_campwarntime || level.ex_campsniper_warntime) self thread extreme\_ex_camper::main();

	// ----- BOT: stop here if you are a bot -------------------------------------
	if(isDefined(self.pers["isbot"]) && self.pers["isbot"])
	{
		if(level.ex_testclients_freeze) self extreme\_ex_utils::punishment("enable", "freeze");
		return;
	}
	// ----- BOT -----------------------------------------------------------------

	// start the rank hud system
	if(level.ex_ranksystem && level.ex_rankhud) self thread extreme\_ex_ranksystem::rankhud();

	// monitor first aid system
	if(level.ex_medicsystem >= 1) self thread extreme\_ex_firstaid::main();

	// monitor binoculars
	self thread binocularMonitor();

	// monitor tripwires
	if(level.ex_tweapon) self thread extreme\_ex_tripwires::main();

	// start jukebox
	if(level.ex_jukebox) self thread extreme\_ex_jukebox::main();

	// good luck message
	if(level.ex_goodluck)
	{
		if(isDefined(self.ex_team_changed)) self.ex_glplay = undefined;
		if(!isDefined(self.ex_glplay)) self thread extreme\_ex_messages::goodluckMsg();
	}

	// display call vote delay status
	if(level.ex_callvote_mode) self thread extreme\_ex_callvote::voteShowStatus();

	// display round number at spawn for roundbased gametypes
	self thread roundDisplay();

	// display bash mode message
	if( (level.ex_bash_only && level.ex_bash_only_msg > 1) ||
	    (level.ex_frag_fest && level.ex_frag_fest_msg > 1) ) self thread modeAnnouncePlayer();

	// display clan mode message
	if(level.ex_clanvsnonclan && level.ex_clanvsnonclan_msg > 1) self thread clanAnnouncePlayer();
}

//******************************************************************************
// eXtreme+ monitors
//******************************************************************************
retreatMonitor()
{
	level endon("ex_gameover");

	axis_flag = getent("axis_flag", "targetname");
	allied_flag = getent("allied_flag", "targetname");

	// distance between axis and allies base divided by 2 to mark hypothetical middle of map
	flag_dist = int(distance(axis_flag.basemodel.origin, allied_flag.basemodel.origin) / 2);

	// loop delay initialization (regular checks each second; after announcements 5 seconds)
	loop_delay = 1;

	while(1)
	{
		wait( [[level.ex_fpstime]](loop_delay) );

		// loop delay reset
		loop_delay = 1;

		// are flags on base? if both flags are, no need to do additional checking
		axis_flag_onbase = (axis_flag.origin == axis_flag.home_origin);
		allies_flag_onbase = (allied_flag.origin == allied_flag.home_origin);
		if(!axis_flag_onbase || !allies_flag_onbase)
		{
			// are flags on the move?
			flag["axis"] = "none";
			flag["allies"] = "none";

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isPlayer(player) && player.sessionstate == "playing" && isDefined(player.flag))
				{
					if(level.ex_currentgt == "ctfb")
					{
						if(isDefined(player.ownflagAttached)) flag[player.pers["team"]] = player.pers["team"];
						if(isDefined(player.enemyflagAttached)) flag[getEnemyTeam(player.pers["team"])] = player.pers["team"];
					}
					else flag[getEnemyTeam(player.pers["team"])] = player.pers["team"];
				}
				if(flag["axis"] != "none" && flag["allies"] != "none") break;
			}

			// check if axis have both flags
			if( flag["allies"] == "axis" && (axis_flag_onbase || flag["axis"] == "axis") )
			{
				retreat_team = "axis";
				retreat_origin = axis_flag.home_origin;
			}
			// check if allies have both flags
			else if( flag["axis"] == "allies" && (allies_flag_onbase || flag["allies"] == "allies") )
			{
				retreat_team = "allies";
				retreat_origin = allied_flag.home_origin;
			}
			// no retreat_team (only reset retreatwarning flags)
			else
			{
				retreat_team = "none";
				retreat_origin = undefined;
			}
		}
		// no retreat_team (only reset retreatwarning flags)
		else
		{
			retreat_team = "none";
			retreat_origin = undefined;
		}

		// warn players on retreat_team to retreat when in warning range
		// if retreat_team is "none" only reset retreatwarning flag for all players
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player) && player.sessionstate == "playing")
			{
				// 3 warnings until flag status changes; decrement if on retreat_team, reset to 3 if not
				if(player.pers["team"] == retreat_team )
				{
					if(!isDefined(player.retreatwarning)) player.retreatwarning = 3;
					retreat_dist = int(distance(retreat_origin, player.origin));
					if(!isDefined(player.flag))
					{
						if( (retreat_dist < (flag_dist + (flag_dist * 0.25))) && (retreat_dist > (flag_dist * 0.1)) )
						{
							if(player.retreatwarning)
							{
								player.retreatwarning--;
								if((level.ex_flag_retreat & 1) == 1) player iprintln(&"MISC_FLAG_RETREAT");
									else if((level.ex_flag_retreat & 2) == 2) player iprintlnbold(&"MISC_FLAG_RETREAT");
										else if((level.ex_flag_retreat & 4) == 4) player thread extreme\_ex_utils::ex_hud_announce(&"MISC_FLAG_RETREAT");
								if((level.ex_flag_retreat & 8) == 8) player playlocalsound("US_mcc_order_move_back");
							}
						}
					}
					else if((level.ex_flag_retreat & 16) == 16)
					{
						if( retreat_dist < (flag_dist + (flag_dist * 0.5)) )
						{
							if(player.retreatwarning)
							{
								player.retreatwarning--;
								if((level.ex_flag_retreat & 1) == 1) player iprintln(&"MISC_FLAG_BRINGIN");
									else if((level.ex_flag_retreat & 2) == 2) player iprintlnbold(&"MISC_FLAG_BRINGIN");
										else if((level.ex_flag_retreat & 4) == 4) player thread extreme\_ex_utils::ex_hud_announce(&"MISC_FLAG_BRINGIN");
								if((level.ex_flag_retreat & 8) == 8) player playlocalsound("US_mcc_order_move_back");
							}
						}
					}
				}
				else player.retreatwarning = 3;
			}
		}

		// 5 seconds delay after announcements
		if(retreat_team != "none") loop_delay = 5;
	}
}

getEnemyTeam(ownteam)
{
	if(ownteam == "axis") return("allies");
		else if(ownteam == "allies") return("axis");
			else return("none");
}

binocularMonitor()
{
	self endon("kill_thread");

	while(isPlayer(self) && self.sessionstate == "playing")
	{
		self waittill("binocular_enter");
		self.ex_binocuse = true;
		self waittill("binocular_exit");
		self.ex_binocuse = false;
	}
}

multiMonitorFrame(eventID)
{
	self endon("kill_thread");

	// stance-shoot monitor
	if(level.ex_stanceshoot)
	{
		stanceshoot_check = true;
		if(self.ex_plantwire || self.ex_defusewire || self.handling_mine || isDefined(self.ex_isparachuting)) stanceshoot_check = false;
			else if(isDefined(self.ex_planting) || isDefined(self.ex_defusing)) stanceshoot_check = false;

		if(stanceshoot_check)
		{
			jump = [[level.ex_getStance]](true);
			doit = false;

			switch(level.ex_stanceshoot)
			{
				case 1:
					if(self.ex_stance == 2 && self.ex_laststance != 2) doit = true;
					break;
				case 2:
					if(jump == 3 && self.ex_lastjump != 3) self.ex_jumpcheck = true;
					break;
				default:
					if(self.ex_stance == 2 && self.ex_laststance != 2) doit = true;
						else if(jump == 3 && self.ex_lastjump != 3) self.ex_jumpcheck = true;
					break;
			}

			if(self.ex_jumpcheck)
			{
				self.ex_jumpsensor++;
				if(self.ex_jumpsensor > level.ex_jump_sensitivity)
				{
					self.ex_jumpsensor = 0;
					doit = true;
				}
				self.ex_jumpcheck = false;
			}
			else self.ex_jumpsensor = 0;

			self.ex_laststance = self.ex_stance;
			if(self.ex_jumpsensor == 0) self.ex_lastjump = jump;

			if(doit)
			{
				if(!level.ex_stanceshoot_action) self thread extreme\_ex_utils::weaponPause(0.6);
					else self thread extreme\_ex_utils::weaponWeaken(1);
			}
		}
	}

	// burst monitor
	if(level.ex_burst_mode && !isDefined(self.onturret))
	{
		bursttime = 1.5;
		burstweapon = false;
		sWeapon = self getCurrentWeapon();
		if((level.ex_burst_mode == 1 || level.ex_burst_mode == 3) && isWeaponType(sWeapon, "mg"))
		{
			burstweapon = true;
			bursttime = level.ex_burst_mg;
		}
		else if((level.ex_burst_mode == 2 || level.ex_burst_mode == 3) && isWeaponType(sWeapon, "smg"))
		{
			burstweapon = true;
			bursttime = level.ex_burst_smg;
		}

		if(self playerADS() && !level.ex_burst_ads) burstweapon = false;

		if(burstweapon && self attackButtonPressed())
		{
			self.ex_bursttrigger++;
			if(self.ex_bursttrigger > 10)
			{
				self.ex_bursttrigger = 0;
				self thread extreme\_ex_utils::execClientCommand("+attack; -attack; +attack; -attack; +attack; -attack");
			}
		}
		else self.ex_bursttrigger = 0;
	}

	[[level.ex_enablePlayerEvent]]("onFrame", eventID);
}

multiMonitorTenthSecond(eventID)
{
	self endon("kill_thread");

	// move monitor
	self.ex_stance = [[level.ex_getStance]](false);

	dist = distance(self.ex_lastorigin, self.origin);
	if(dist > 1) self.ex_moving = true;
		else self.ex_moving = false;
	if(dist > 10) self.ex_pace = true;
		else self.ex_pace = false;

	self.ex_lastorigin = self.origin;

	// sniper anti-run monitor
	if(level.ex_antirun && !self.ex_invulnerable && !isDefined(self.ex_isparachuting))
	{
		if( (!self playerads() || !level.ex_antirun_ads) && !self.antirun_puninprog && self.ex_stance == 0 && self.ex_moving)
		{
			chkorigin = (self.origin[0], self.origin[1], 0);
			if(isdefined(self.antirun_mark))
			{
				switch(level.ex_antirun)
				{
					case 1:
						if(distance(self.antirun_mark, chkorigin) > level.ex_antirun_distance)
						{
							self thread antirunPunish();
							self.antirun_mark = undefined;
						}
						break;
					case 2:
						if(distance(self.antirun_mark, chkorigin) > 50)
						{
							self thread antirunBlackout();
							self.antirun_mark = undefined;
						}
						break;
				}
			}
			else self.antirun_mark = chkorigin;
		}
		else
		{
			self.antirun_mark = undefined;
			if(level.ex_antirun == 2 && !self.antirun_puninprog && self.pers["antirun"]) self thread antirunBlackoutFade();
		}
	}

	// weapon usage monitor
	if(!self.usedweapons || level.ex_kamikaze)
	{
		newoffhand = self getCurrentOffHand();
		if(newoffhand != "none")
		{
			newoffhand_ammo = self getAmmoCount(newoffhand);
			if(newoffhand != self.ex_lastoffhand) self.ex_lastoffhand = newoffhand;
		}
		else newoffhand_ammo = 0;

		if(!self.usedweapons)
		{
			if(self.ex_oldoffhand_ammo > newoffhand_ammo || (!self.ex_disabledWeapon && self attackButtonPressed()) )
				self.usedweapons = true;
		}
	}

	// healthbar
	if(level.ex_healthsystem)
	{
		if(self.health != self.ex_oldhealth)
		{
			health = self.health / self.maxhealth;
			width = int(health * 88);
			if(width < 1) width = 1;

			if(isDefined(self.ex_healthbar))
			{
				self.ex_healthbar setShader("gfx/hud/hud@health_bar.tga", width, 8);
				self.ex_healthbar.color = ( 1.0 - health, health, 0);
			}

			self.ex_oldhealth = self.health;
		}
	}

	// scoped-on monitor
	if(level.ex_scopedon)
	{
		if(self playerads())
		{
			if(isDefined(self.ex_eyemarker.origin)) startOrigin = self.ex_eyemarker.origin;
				else startOrigin = undefined;

			if(isDefined(startOrigin))
			{
				forward = anglesToForward(self getplayerangles());
				forward = [[level.ex_vectorscale]](forward, 100000);
				endOrigin = startOrigin + forward;

				scopedon = undefined;
				trace = bulletTrace(startOrigin, endOrigin, true, self);
				if(trace["fraction"] != 1 && isDefined(trace["entity"]))
					if(isPlayer(trace["entity"])) scopedon = trace["entity"];

				if(isDefined(scopedon) && (!level.ex_teamplay || scopedon.pers["team"] != self.pers["team"]))
				{
					if(!isDefined(self.ex_scopedon))
					{
						self.ex_scopedon = newClientHudElem(self);
						self.ex_scopedon.archived = false;
						self.ex_scopedon.horzAlign = "fullscreen";
						self.ex_scopedon.vertAlign = "fullscreen";
						self.ex_scopedon.alignx = "center";
						self.ex_scopedon.aligny = "middle";
						self.ex_scopedon.x = 320;
						self.ex_scopedon.y = 200;
						self.ex_scopedon.alpha = 1;
						self.ex_scopedon.color = (1,0,0);
						self.ex_scopedon.fontScale = 1.2;
					}
					self.ex_scopedon setPlayerNameString(scopedon);
				}
				else if(isDefined(self.ex_scopedon)) self.ex_scopedon destroy();
			}
			else if(isDefined(self.ex_scopedon)) self.ex_scopedon destroy();
		}
		else if(isDefined(self.ex_scopedon)) self.ex_scopedon destroy();
	}

	[[level.ex_enablePlayerEvent]]("onTenthSecond", eventID);
}

multiMonitorHalfSecond(eventID)
{
	self endon("kill_thread");

	// range finder
	if(level.ex_rangefinder)
	{
		if(self.ex_binocuse || (self playerads() && extreme\_ex_weapons::isWeaponType(self getcurrentweapon(),"sniper")))
		{
			if(isDefined(self.ex_eyemarker.origin)) startOrigin = self.ex_eyemarker.origin;
				else startOrigin = undefined;

			if(isDefined(startOrigin))
			{
				forward = anglesToForward(self getplayerangles());
				forward = [[level.ex_vectorscale]](forward, 100000);
				endOrigin = startOrigin + forward;

				rangedist = undefined;
				trace = bulletTrace(startOrigin, endOrigin, true, self);
				range = int(distance(startOrigin, trace["position"]));

				if(level.ex_rangefinder_units == 1) rangedist = int(range * 0.02778); // Range in Yards
					else rangedist = int(range * 0.0254);	// Range in Metres

				if(!isDefined(self.ex_rangehud))
				{
					self.ex_rangehud = newClientHudElem(self);
					self.ex_rangehud.archived = false;
					self.ex_rangehud.horzAlign = "fullscreen";
					self.ex_rangehud.vertAlign = "fullscreen";
					self.ex_rangehud.alignx = "center";
					self.ex_rangehud.aligny = "middle";
					self.ex_rangehud.x = 320;
					self.ex_rangehud.y = 360;
					self.ex_rangehud.alpha =0.8;
					self.ex_rangehud.fontScale = 1;
				}

				if(level.ex_rangefinder_units == 1)
				{
					self.ex_rangehud.label = &"MISC_RANGE";
					self.ex_rangehud setvalue(rangedist);
				}
				else
				{
					self.ex_rangehud.label = &"MISC_RANGE2";
					self.ex_rangehud setvalue(rangedist);
				}
			}
			else if(isDefined(self.ex_rangehud)) self.ex_rangehud destroy();
		}
		else if(isDefined(self.ex_rangehud)) self.ex_rangehud destroy();
	}

	// call for medic monitor
	if(level.ex_medicsystem == 1)
	{
		if(!self.ex_calledformedic)
		{
			if(self.health < level.ex_medic_callout)
			{
				self thread extreme\_ex_firstaid::callformedic();
				self.ex_calledformedic = 60;
			}
		}
		else self.ex_calledformedic--;
	}

	// cold breath monitor
	if(level.ex_wintermap && level.ex_coldbreathfx)
	{
		if(!self.ex_coldbreathdelay)
		{
			playfxontag (level.ex_effect["coldbreathfx"], self, "TAG_EYE");
			if(self.ex_playsprint || self.ex_sprintreco) self.ex_coldbreathdelay = (randomInt(1) + 1) * 2;
				else self.ex_coldbreathdelay = (randomInt(2) + 3) * 2;
		}
		else self.ex_coldbreathdelay--;
	}

	// grenade warning monitor
	if(level.ex_grenadewarn && level.ex_teamplay)
	{
		if(self.usedweapons && !self.ex_plantwire)
		{
			if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
				else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
			currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);

			if(currentfrags < self.ex_oldfrags && !self.ex_plantwire)
				self thread maps\mp\gametypes\_quickmessages::quickwarning("frag", 480, true, true);

			if(currentsmokes < self.ex_oldsmokes && !self.ex_plantwire)
				self thread maps\mp\gametypes\_quickmessages::quickwarning("smoke", 480, true, true);

			self.ex_oldfrags = currentfrags;
			self.ex_oldsmokes = currentsmokes;
		}
		else
		{
			if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) self.ex_oldfrags = self getammocount(self.pers["fragtype"]);
				else self.ex_oldfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
			self.ex_oldsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
		}
	}

	// weather fx modifier
	if(level.ex_weather && !level.ex_wintermap && level.ex_weather_level)
	{
		z = 650;
		z_max = game["mapArea_Max"][2] - 100;
		if((self.origin[2] + z) > z_max) z = z_max - self.origin[2];
		playfx(level.ex_effect["weather"], self.origin + (0, 0, z), self.origin + (0, 0, z+30) );
	}

	[[level.ex_enablePlayerEvent]]("onHalfSecond", eventID);
}

potatoMonitor(eventID)
{
	if(level.ex_sprint) thread maps\mp\_utility::deletePlacedEntity("weapon_" + game["sprint"]);
	thread maps\mp\_utility::deletePlacedEntity("weapon_dummy1_mp");
	thread maps\mp\_utility::deletePlacedEntity("weapon_dummy2_mp");
	thread maps\mp\_utility::deletePlacedEntity("weapon_dummy3_mp");
}

//******************************************************************************
// bash mode or nade fest announcement
//******************************************************************************
modeAnnounceLevel()
{
	if(level.ex_bash_only && level.ex_bash_only_msg != 1 && level.ex_bash_only_msg != 4 && level.ex_bash_only_msg != 5) return;
	if(level.ex_frag_fest && level.ex_frag_fest_msg != 1 && level.ex_frag_fest_msg != 4 && level.ex_frag_fest_msg != 5) return;

	if(!isDefined(level.ex_modeannouncer))
	{
		level.ex_modeannouncer = newHudElem();
		level.ex_modeannouncer.archived = false;
		level.ex_modeannouncer.horzAlign = "fullscreen";
		level.ex_modeannouncer.vertAlign = "fullscreen";
		level.ex_modeannouncer.alignX = "right";
		level.ex_modeannouncer.alignY = "middle";
		level.ex_modeannouncer.x = 632;
		level.ex_modeannouncer.y = 461;
		level.ex_modeannouncer.fontScale = 1.3;
		level.ex_modeannouncer setText(level.ex_specialmodemsg);
	}
}

modeAnnouncePlayer()
{
	self endon("kill_thread");

	if(level.ex_bash_only && (level.ex_bash_only_msg == 2 || level.ex_bash_only_msg == 4) && isDefined(self.ex_modeann)) return;
	if(level.ex_frag_fest && (level.ex_frag_fest_msg == 2 || level.ex_frag_fest_msg == 4) && isDefined(self.ex_modeann)) return;
	self.ex_modeann = true;

	if(!isDefined(self.ex_modeannouncer))
	{
		self.ex_modeannouncer = newClientHudElem(self);
		self.ex_modeannouncer.archived = false;
		self.ex_modeannouncer.horzAlign = "fullscreen";
		self.ex_modeannouncer.vertAlign = "fullscreen";
		self.ex_modeannouncer.alignX = "center";
		self.ex_modeannouncer.alignY = "top";
		self.ex_modeannouncer.x = 320;
		self.ex_modeannouncer.y = 90;
		self.ex_modeannouncer.fontscale = 3;
		self.ex_modeannouncer setText(level.ex_specialmodemsg);
	}

	wait( [[level.ex_fpstime]](1.5) );

	if(isDefined(self.ex_modeannouncer))
	{
		self.ex_modeannouncer fadeOverTime(.5);
		self.ex_modeannouncer.alpha = 0;
		wait( [[level.ex_fpstime]](0.5) );
	}

	if(isDefined(self.ex_modeannouncer)) self.ex_modeannouncer destroy();
}

//******************************************************************************
// clan mode annoucement
//******************************************************************************
clanAnnounceLevel()
{
	if(level.ex_clanvsnonclan_msg != 1 && level.ex_clanvsnonclan_msg != 4 && level.ex_clanvsnonclan_msg != 5) return;

	if(!isDefined(level.ex_clanannouncer))
	{
		level.ex_clanannouncer = newHudElem();
		level.ex_clanannouncer.archived = false;
		level.ex_clanannouncer.horzAlign = "fullscreen";
		level.ex_clanannouncer.vertAlign = "fullscreen";
		level.ex_clanannouncer.alignX = "left";
		level.ex_clanannouncer.alignY = "middle";
		level.ex_clanannouncer.x = 8;
		level.ex_clanannouncer.y = 80;
		level.ex_clanannouncer.fontScale = 1.0;
		level.ex_clanannouncer setText(level.ex_clanmodemsg);
	}
}

clanAnnouncePlayer()
{
	self endon("kill_thread");

 	if( (level.ex_clanvsnonclan_msg == 2 || level.ex_clanvsnonclan_msg == 4) && isDefined(self.ex_clanann) ) return;
	self.ex_clanann = true;

	if(!isDefined(self.ex_clanannouncer))
	{
		self.ex_clanannouncer = newClientHudElem(self);
		self.ex_clanannouncer.archived = false;
		self.ex_clanannouncer.horzAlign = "fullscreen";
		self.ex_clanannouncer.vertAlign = "fullscreen";
		self.ex_clanannouncer.alignX = "center";
		self.ex_clanannouncer.alignY = "top";
		self.ex_clanannouncer.x = 320;
		self.ex_clanannouncer.y = 120;
		self.ex_clanannouncer.fontscale = 3;
		self.ex_clanannouncer setText(level.ex_clanmodemsg);
	}

	wait( [[level.ex_fpstime]](1.5) );

	if(isDefined(self.ex_clanannouncer))
	{
		self.ex_clanannouncer fadeOverTime(.5);
		self.ex_clanannouncer.alpha = 0;
		wait( [[level.ex_fpstime]](0.5) );
	}

	if(isDefined(self.ex_clanannouncer)) self.ex_clanannouncer destroy();
}

//******************************************************************************
// eXtreme+ anti-run
//******************************************************************************
antirunSpawnCrouched()
{
	self endon("kill_thread");

	while(isDefined(self.ex_isparachuting)) wait( [[level.ex_fpstime]](.5) );
	extreme\_ex_utils::forceto("crouch");
}

antirunPunish()
{
	self endon("kill_thread");

	if(self.antirun_puninprog) return;
	self.antirun_puninprog = true;

	self iprintlnbold(&"SPRINT_RUNWARNINGA");
	self iprintlnbold(&"SPRINT_RUNWARNINGB");

	switch(self.pers["antirun"])
	{
		case 0:
			self.pers["antirun"]++;
			self iprintlnbold(&"SPRINT_FIRST_PLAYER");
			iprintln(&"SPRINT_FIRST_ALL", [[level.ex_pname]](self));
			extreme\_ex_utils::forceto("crouch");
			self [[level.ex_dWeapon]]();
			self shellshock("default", 5);
			wait( [[level.ex_fpstime]](5) );
			if(isDefined(self)) self [[level.ex_eWeapon]]();
			break;

		case 1:
			self.pers["antirun"]++;
			self iprintlnbold(&"SPRINT_SECOND_PLAYER");
			iprintln(&"SPRINT_SECOND_ALL", [[level.ex_pname]](self));
			extreme\_ex_utils::forceto("crouch");
			self.health = int(self.health / 2);
			self [[level.ex_dWeapon]]();
			self shellshock("default", 10);
			wait( [[level.ex_fpstime]](10) );
			if(isDefined(self)) self [[level.ex_eWeapon]]();
			break;

		case 2:
			self.pers["antirun"]++;
			self iprintlnbold(&"SPRINT_THIRD_PLAYER");
			iprintln(&"SPRINT_THIRD_ALL", [[level.ex_pname]](self));
			extreme\_ex_utils::forceto("crouch");
			self thread extreme\_ex_punishments::doWarp(true);
			wait( [[level.ex_fpstime]](30) );
			break;

		case 3:
			self thread antirunPunishKick();
 			// this keeps self.antirun_puninprog set to true, so we don't end up here again
			return;
	}

	self.antirun_puninprog = false;
}

antirunPunishKick()
{
	self endon("disconnect");

	self iprintlnbold(&"SPRINT_FOURTH_PLAYERA");
	extreme\_ex_utils::forceto("crouch");
	self [[level.ex_dWeapon]]();
	self shellshock("default", 5);
	wait( [[level.ex_fpstime]](5) );
	if(isDefined(self)) self iprintlnbold(&"SPRINT_FOURTH_PLAYERB");
	wait( [[level.ex_fpstime]](3) );
	if(isDefined(self))
	{
		iprintln(&"SPRINT_FOURTH_ALL", [[level.ex_pname]](self));
		kick(self getEntityNumber());
	}
}

antirunBlackout()
{
	self endon("kill_thread");

	if(self.antirun_puninprog) return;
	self.antirun_puninprog = true;

	self notify("stop_blackoutfade");

	if(!isDefined(self.blackscreen))
	{
		self.blackscreen = newClientHudElem(self);
		self.blackscreen.archived = false;
		self.blackscreen.horzAlign = "fullscreen";
		self.blackscreen.vertAlign = "fullscreen";
		self.blackscreen.alignX = "left";
		self.blackscreen.alignY = "top";
		self.blackscreen.x = 0;
		self.blackscreen.y = 0;
		self.blackscreen.sort = -1;
		self.blackscreen.alpha = 0;
		self.blackscreen setShader("black", 640, 480);
	}

	self.pers["antirun"]++;

	/*
	if(self.pers["antirun"] == 1)
	{
		self iprintlnbold(&"SPRINT_RUNWARNINGA");
		self iprintlnbold(&"SPRINT_RUNWARNINGB");
	}
	*/

	self.blackscreen.bsorfading = undefined;
	if(self.pers["antirun"] > 10) self.pers["antirun"] = 10;
	alpha = self.pers["antirun"] / 10;
	delay = .2;
	//logprint("ANTIRUN DEBUG: setting alpha " + alpha + " for level " + self.pers["antirun"] + " in " + delay + " seconds\n");
	self.blackscreen fadeOverTime(delay);
	self.blackscreen.alpha = alpha;
	wait( [[level.ex_fpstime]](delay + .1) );

	self.antirun_puninprog = false;
}

antirunBlackoutFade()
{
	self endon("kill_thread");
	self endon("stop_blackoutfade");

	if(isDefined(self.blackscreen))
	{
		if(isDefined(self.blackscreen.bsorfading)) return;
		self.blackscreen.bsorfading = true;

		wait( [[level.ex_fpstime]](1 + (self.pers["antirun"] * .2)) );

		if(isPlayer(self) && isAlive(self))
		{
			while(self.pers["antirun"] > 0)
			{
				self.pers["antirun"]--;
				alpha = self.pers["antirun"] / 10;
				delay = .1 + (alpha * 2);
				//logprint("ANTIRUN DEBUG: setting alpha " + alpha + " for level " + self.pers["antirun"] + " in " + delay + " seconds\n");
				self.blackscreen fadeOverTime(delay);
				self.blackscreen.alpha = alpha;
				wait( [[level.ex_fpstime]](delay + .1) );
			}

			self thread antirunBlackoutKill();
		}
	}
}

antirunBlackoutKill()
{
	if(!isPlayer(self) || (!isAlive(self) && level.ex_bsod)) return;
	if(isDefined(self.blackscreen)) self.blackscreen destroy();
}

//******************************************************************************
// eXtreme+ first aid
//******************************************************************************
firstaidDrop(origin)
{
	health_nr = RandomInt(3) + 1;

	switch(health_nr)
	{
		case 1: modeltype = "xmodel/health_small"; break;
		case 2: modeltype = "xmodel/health_medium"; break;
		default: modeltype = "xmodel/health_large"; break;
	}

	item_health = spawn("script_model", (0,0,0));	
	item_health setModel(modeltype);
	item_health.targetname = "item_healths";
	item_health hide();
	item_health.origin = origin;
	item_health.angles = (0, randomint(360), 0);
	item_health show(); 

	rotation = (randomFloat(180), randomFloat(180), randomFloat(180));
	velocity = (randomInt(4) + 4, randomInt(4) + 4, randomInt(6) + 6);

	item_health extreme\_ex_utils::bounceObject(rotation, velocity, (0,0,0), (0,0,0), 5, 0.4, undefined, undefined, "health");
	item_health thread healthThink(health_nr);
}

healthThink(health_nr)
{
	while(isDefined(self))
	{
		wait( [[level.ex_fpstime]](0.2) );

		if(!isDefined(self)) return;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isPlayer(player) && isDefined(self) && player.sessionstate == "playing" && distance(self.origin,player.origin) < 50 && (player.health < player.maxhealth || level.ex_medicsystem && level.ex_firstaid_collect && player.ex_firstaidkits < 9))
			{
				if(player.health < player.maxhealth)
				{
					player.health += health_nr * 30;
					if(player.health > player.maxhealth) player.health = player.maxhealth;

					if(health_nr == 1) player playLocalSound("health_pickup_small");
					else if(health_nr == 2) player playLocalSound("health_pickup_medium");
					else player playLocalSound("health_pickup_large");

					if(isDefined(self))
					{
						self delete();
						return;
					}
				}
				else if(level.ex_medicsystem && level.ex_firstaid_collect && player.ex_firstaidkits < level.ex_firstaid_collect)
				{
					player.ex_firstaidkits++;
					player playLocalSound("health_pickup_medium");
					player iprintln(&"FIRSTAID_PICKEDUP");
					player.ex_canheal = true;
					if(isDefined(player.ex_firstaidval))
					{
						player.ex_firstaidval setValue(player.ex_firstaidkits);
						player.ex_firstaidval.color = (1, 1, 1);
					}

					if(isDefined(self))
					{
						self delete();
						return;
					}
				}
			}
		}				
	}
}

//******************************************************************************
// eXtreme+ gametype additional routines
//******************************************************************************
swapTeams()
{
	level endon("ex_gameover");

	if(game["roundsplayed"] == 0 || !game["matchstarted"]) return;

	if(level.ex_swapteams == 2 && game["roundnumber"] > level.half_time) return;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		// don't do anything with spectators
		if(!isDefined(players[i].pers["team"]) || players[i].pers["team"] == "spectator") continue;

		if(players[i].pers["team"] == "axis") newTeam = "allies";
			else newTeam = "axis";

		players[i].pers["team"] = newTeam;
		players[i].pers["savedmodel"] = undefined;
		players[i] extreme\_ex_clientcontrol::clearWeapons();
		players[i] maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();
		//players[i] maps\mp\gametypes\_spectating::setSpectatePermissions();
	}

	tempscore = game["alliedscore"];
	game["alliedscore"] = game["axisscore"];
	game["axisscore"] = tempscore;
	setTeamScore("allies", game["alliedscore"]);
	setTeamScore("axis", game["axisscore"]);
}

exPreSpawn()
{
	self endon("kill_thread");

	// set spawn variables
	setPlayerVariables();

	// spawn protection pre-spawn settings
	if(level.ex_spwn_time)
	{
		self.ex_invulnerable = true;
		self.ex_spawnprotected = true;
		if(level.ex_spwn_invisible) self hide();
	}

	// parachute preperation (keep below spawn protection pre-spawn)
	if(level.ex_parachutes) self thread extreme\_ex_parachute::prep();

	// allow team change option on weapons menu
	self setClientCvar("ui_allow_teamchange", 0);

	// start rank monitor
	if(level.ex_ranksystem) self thread extreme\_ex_ranksystem::playerRankMonitor();

	// hide mbots until they are completely ready
	if(level.ex_mbot && isDefined(self.pers["isbot"])) self hide();
}

exPostSpawn()
{
	self endon("kill_thread");

	// wait for threads to die
	wait( [[level.ex_fpstime]](.05) );
	
	if(isDefined(self.ex_redirected)) return;

	if(isPlayer(self) && !level.ex_gameover)
	{
		// Attach head marker, used by Sprint System and LR Hitloc
		if(!isDefined(self.ex_headmarker))
		{
			self.ex_headmarker = spawn("script_origin",(0,0,0));
			//self.ex_headmarker linkto (self, "J_Head",(0,50,0),(0,0,0));
			self.ex_headmarker linkto(self, "J_Head",(0,0,0),(0,0,0));
		}
		// Attach spine marker, used by GetStance() and LR Hitloc
		if(!isDefined(self.ex_spinemarker))
		{
			self.ex_spinemarker = spawn("script_origin",(0,0,0));
			self.ex_spinemarker linkto(self, "J_Spine4",(0,0,0),(0,0,0));
		}
		// Attach eye marker, used by Range Finder and LR Hitloc
		if(!isDefined(self.ex_eyemarker))
		{
			self.ex_eyemarker = spawn("script_origin",(0,0,0));
			self.ex_eyemarker linkto(self, "tag_eye",(0,0,0),(0,0,0));
		}
		// Attach thumb marker, used by Knife and Unfixed Turrets
		if(!isDefined(self.ex_thumbmarker))
		{
			self.ex_thumbmarker = spawn("script_origin",(0,0,0));
			self.ex_thumbmarker linkto(self, "J_Thumb_ri_1",(0,0,0),(0,0,0));
		}

		if(level.ex_lrhitloc)
		{
			// Attach left ankle marker, used by LR Hitloc
			if(!isDefined(self.ex_lankmarker))
			{
				self.ex_lankmarker = spawn("script_origin",(0,0,0));
				self.ex_lankmarker linkto(self, "j_ankle_le",(0,0,0),(0,0,0));
			}
			// Attach right ankle marker, used by LR Hitloc
			if(!isDefined(self.ex_rankmarker))
			{
				self.ex_rankmarker = spawn("script_origin",(0,0,0));
				self.ex_rankmarker linkto(self, "j_ankle_ri",(0,0,0),(0,0,0));
			}
			// Attach left wrist marker, used by LR Hitloc
			if(!isDefined(self.ex_lwristmarker))
			{
				self.ex_lwristmarker = spawn("script_origin",(0,0,0));
				self.ex_lwristmarker linkto(self, "j_wrist_le",(0,0,0),(0,0,0));
			}
			// Attach right wrist marker, used by LR Hitloc
			if(!isDefined(self.ex_rwristmarker))
			{
				self.ex_rwristmarker = spawn("script_origin",(0,0,0));
				self.ex_rwristmarker linkto(self, "j_wrist_ri",(0,0,0),(0,0,0));
			}
		}

		if(level.ex_mbot)
		{
			self.mark = [];

			// keep tag_eye first, because it's being addressed as index [0] later on
			self.mark[0] = self.ex_eyemarker;

			if(level.ex_diana && isDefined(self.pers["diana"]))
			{
				self.mark[1] = spawn("script_origin", (0,0,0));
				self.mark[1] linkto(self, "j_spine2", (0,0,0),(0,0,0));
			}
			else
			{
				self.mark[1] = spawn("script_origin", (0,0,0));
				self.mark[1] linkto(self, "j_spine1", (0,0,0),(0,0,0));
			}

			self.mark[2] = spawn("script_origin", (0,0,0));
			self.mark[2] linkto(self, "j_shoulder_le", (0,0,0),(0,0,0));

			self.mark[3] = spawn("script_origin", (0,0,0));
			self.mark[3] linkto(self, "j_shoulder_ri", (0,0,0),(0,0,0));

			self.mark[4] = spawn("script_origin", (0,0,0));
			self.mark[4] linkto(self, "j_elbow_bulge_le", (0,0,0),(0,0,0));

			self.mark[5] = spawn("script_origin", (0,0,0));
			self.mark[5] linkto(self, "j_elbow_bulge_ri", (0,0,0),(0,0,0));

			if(level.ex_mbot_dev && (self.name == level.ex_mbot_devname))
				self thread extreme\_ex_mbot_dev::mainDeveloper();
		}

		self thread playerThreads();

		// remove black screen of death
		if(level.ex_bsod) self thread fadeBlackScreen();
	}
}

exPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	self endon("disconnect");

	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;

	// Activate line below if you do not want to allow shooting from the hip (only ADS)
	//if(isPlayer(eAttacker) && !isDefined(eAttacker.onturret) && sMeansOfDeath != "MOD_MELEE" && (maps\mp\gametypes\_weapons::isMainWeapon(sWeapon) || isWeaponType(sWeapon, "pistol")) && !eAttacker playerADS()) return;

	// Activate line below if you do not want panzerschreck and rpg to kill owner
	//if(isPlayer(eAttacker) && eAttacker == self && extreme\_ex_weapons::isWeaponType(sWeapon, "rl")) return;

	// Features that affect damage
	if(isDefined(self.ex_bubble_protected)) return;

	if(isPlayer(eAttacker) && isWeaponType(sWeapon, "sniperlr"))
	{
		// bubble protected attacker with LR rifle should not do damage
		if(isDefined(eAttacker.ex_bubble_protected)) return;

		// long range hitloc modifications and messages
		if(level.ex_lrhitloc && isDefined(sMeansOfDeath) && sMeansOfDeath == "MOD_PROJECTILE")
		{
			self.ex_lrhitloc_msg = true;
			aInfo = spawnstruct();
			aInfo.sMeansOfDeath = sMeansOfDeath;
			aInfo.iDamage = iDamage;
			aInfo.sHitLoc = sHitLoc;
			self extreme\_ex_longrange::main(eAttacker, sWeapon, vPoint, aInfo);
			sMeansOfDeath = aInfo.sMeansOfDeath;
			iDamage = aInfo.iDamage;
			sHitLoc = aInfo.sHitLoc;
		}
	}

	if(isPlayer(eAttacker) && isDefined(eAttacker.ex_weakenweapon) && maps\mp\gametypes\_weapons::isMainWeapon(sWeapon))
		iDamage = int(iDamage * (level.ex_stanceshoot_action / 100));

	if( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == self) ||
	    (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == self) )
	{
		if(level.ex_gunship_protect == 1) return;
		if(level.ex_gunship_protect == 2) iDamage = int(iDamage * .1);
	}

	if(level.ex_vest && isDefined(self.ex_vest_protected) && sHitLoc != "none")
	{
		while(1)
		{
			if(sMeansOfDeath != "MOD_MELEE")
			{
				if(isWeaponType(sWeapon, "mg") && !level.ex_vest_protect_mg) break;
				if(isWeaponType(sWeapon, "snipersr") && !level.ex_vest_protect_sniper) break;
				if(isWeaponType(sWeapon, "sniperlr") && !level.ex_vest_protect_sniperlr) break;
			}

			switch(sHitLoc)
			{
				case "torso_upper":
				case "torso_lower": return;
				case "head": break;
				case "helmet":  iDamage = int(iDamage * .5); break;
				default: iDamage = int(iDamage * .2); break;
			}
			break;
		}
	}

	// long range hitloc damage message
	if(isDefined(self.ex_lrhitloc_msg))
	{
		if(level.ex_lrhitloc && level.ex_lrhitloc_msg && iDamage < self.health)
			self thread extreme\_ex_longrange::hitlocMessage(eAttacker, sHitLoc);
		self.ex_lrhitloc_msg = undefined;
	}

	// freezetag checks
	if(level.ex_currentgt == "ft")
	{
		// check for freezing or unfreezing with raygun
		if(sWeapon == "raygun_mp" && isPlayer(eAttacker) && (self != eAttacker))
		{
			if(self.pers["team"] == eAttacker.pers["team"])
			{
				if(self.frozenstate == "frozen" && (level.ft_raygun == 1 || level.ft_raygun == 3))
				{
					// Make sure at least one point of unfreezing is done
					if(iDamage < 1) iDamage = 1;

					self.frozenstatus = self.frozenstatus - iDamage;
					if(self.frozenstatus < 0) self.frozenstatus = 0;

					// update status bar for frozen player
					if(isDefined(self.hud_frozen_bar))
					{
						freezebar = int(self.frozenstatus * 2);
						self.hud_frozen_bar setshader("white", freezebar, 10);
					}

					if(self.frozenstatus == 0 && !isDefined(self.unfreeze_pending))
					{
						self.unfreeze_pending = 1; // avoid multiple score registrations
						eAttacker thread maps\mp\gametypes\ft::finishUnfreeze(self, true);
					}
					return;
				}
			}
			else if(level.ft_raygun != 2 && level.ft_raygun != 3) return;
		}

		// in any other case, do no damage if already frozen
		if(self.frozenstate == "frozen") return;
	}

	if (!isDefined(vPoint)) vPoint = self.origin + (0,0,11);

	// napalm?
	napalm = false;
	if(sMeansOfDeath == "MOD_PROJECTILE" && sWeapon == "planebomb_mp") napalm = true;

	// disable or drop weapon after a fall
	if(level.ex_droponfall && sMeansOfDeath == "MOD_FALLING" && randomInt(100) < level.ex_droponfall)
		self thread weaponfall(1.5);

	// figure out if extreme damage fx should be applied
	dodamagefx = false;
	if(!level.ex_teamplay) dodamagefx = true;

	if(isPlayer(eAttacker))
	{
		if(eAttacker == self) dodamagefx = true;
			else if(level.ex_teamplay && ((self.pers["team"] != eAttacker.pers["team"]) || level.friendlyfire == "1" || level.friendlyfire == "3")) dodamagefx = true;

		if(dodamagefx && eAttacker != self)
		{
			// make mbot alert on hit
			if(level.ex_mbot) self thread extreme\_ex_bots::playerDamage(eAttacker, iDamage);

			// gunship eject
			if((level.ex_gunship || level.ex_gunship_special) && iDamage > self.health && ((level.ex_gunship_eject & 2) == 2))
			{
				if(isDefined(level.ex_gunship_player) && level.ex_gunship_player == self)
				{
					extreme\_ex_gunship::gunshipDetachPlayer(true);
					return;
				}
				else if(isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == self)
				{
					extreme\_ex_specials_gunship::gunshipSpecialDetachPlayer(true);
					return;
				}
			}

			// no damage if invulnerable
			if(self.ex_invulnerable)
			{
				// punish attacking player for attacking spawn protected players
				if(level.ex_spwn_time && level.ex_spwn_punish_attacker && !isDefined(self.ex_crybaby))
				{
					// exclude wmd, nades and satchel charges
					if(isDefined(sWeapon) && !(isWeaponType(sWeapon, "wmd") || isWeaponType(sWeapon, "fraggrenade") || isWeaponType(sWeapon, "firegrenade") || isWeaponType(sWeapon, "gasgrenade") || isWeaponType(sWeapon, "satchelcharge")))
					{
						punish = true;

						// spawn protection punishment threshold check
						if(level.ex_spwn_punish_threshold)
						{
							eAttacker.ex_spwn_punish_counter += iDamage;
							if(eAttacker.ex_spwn_punish_counter < level.ex_spwn_punish_threshold) punish = false;
						}

						if(punish)
						{
							if(isDefined(eAttacker.onturret))
								eAttacker thread extreme\_ex_spawnpro::punish("turretattack");
							else
								eAttacker thread extreme\_ex_spawnpro::punish("attacking");
						}
					}
				}

				return;
			}

			// punish protected player for abusing spawn protection
			if(level.ex_spwn_time && level.ex_spwn_punish_self && eAttacker.ex_invulnerable && eAttacker.usedweapons)
			{
				eAttacker thread extreme\_ex_spawnpro::punish("abusing");
				return;
			}

			// close kill detection
			if(level.ex_closekill)
			{
				range = int(distance(eAttacker.origin, self.origin));
				if(level.ex_closekill_units) calcdist = int(range * 0.0254); // Range in Metres
					else calcdist = int(range * 0.02778); // Range in Yards

				if(calcdist < level.ex_closekill_distance)
				{
					if(level.ex_closekill_msg)
					{
						if(level.ex_closekill_units)
						{
							eAttacker iprintlnBold(&"CLOSEKILL_RANGE_METRES", calcdist);
							eAttacker iprintlnBold(&"CLOSEKILL_MINRANGE_METRES", level.ex_closekill_range);
							if(level.ex_closekill_msg == 2) self iprintln(&"CLOSEKILL_PROTECTION");
						}
						else
						{
							eAttacker iprintlnBold(&"CLOSEKILL_RANGE_YARDS", calcdist);
							eAttacker iprintlnBold(&"CLOSEKILL_MINRANGE_YARDS", level.ex_closekill_range);
							if(level.ex_closekill_msg == 2) self iprintln(&"CLOSEKILL_PROTECTION");
						}
					}

					if(!isDefined(eAttacker.ckcount)) eAttacker.ckcount = 0;
					eAttacker.ckcount++;

					if(eAttacker.ckcount == 1)
						eAttacker shellshock("default", 5);
					else if(eAttacker.ckcount == 2)
						eAttacker shellshock("default", 10);
					else if(eAttacker.ckcount == 3)
					{
						eAttacker.ckcount = 0;
						eAttacker.ex_forcedsuicide = true;
						eAttacker suicide();
					}

					return;
				}
			}

			// firstaid disable if team mate
			if(level.ex_teamplay && level.ex_medicsystem && level.ex_medic_penalty && (self.pers["team"] == eAttacker.pers["team"]))
			{
				check_healing = true;
				if( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == eAttacker) ||
				    (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == eAttacker) ) check_healing = false;
				if(check_healing) eAttacker thread extreme\_ex_firstaid::disablePlayerHealing();
			}

			// Splatter on attacker?
			if(level.ex_bloodonscreen && (sMeansOfDeath == "MOD_MELEE" || distance(eAttacker.origin , self.origin ) < 50))
				eAttacker thread bloodonscreen();

			// bulletholes?
			if(level.ex_bulletholes && (sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET"))
				self thread extreme\_ex_bulletholes::bullethole();

			// Pain sound
			if(level.ex_painsound)
			{
				if(napalm && randomInt(100) < 25) self thread extreme\_ex_utils::playSoundOnPlayer("generic_pain", "pain");
					else if(!napalm && randomInt(100) < 50) self thread extreme\_ex_utils::playSoundOnPlayer("generic_pain", "pain");
			}
		}

		// Helmet pop (just for the fun of it, we always allow helmets to pop)
		if(level.ex_pophelmet && !self.ex_helmetpopped)
		{
			switch(sHitLoc)
			{
				case "helmet":
				case "head":
					if(randomInt(100) < level.ex_pophelmet)
					{
						self thread popHelmet(vDir, iDamage);
						if(dodamagefx) self thread bloodonscreen();
					}
					break;
			}
		}
	}
	else dodamagefx = true;

	// Damage modifiers, weapons
	if(level.ex_wdmodon && isDefined(sWeapon) && sMeansOfDeath != "MOD_MELEE")
	{
		wdmWeapon = sWeapon;
		if(isWeaponType(wdmWeapon, "fraggrenade") || isWeaponType(wdmWeapon, "fragspecial")) wdmWeapon = "fraggrenade";
			else if(isWeaponType(wdmWeapon, "smokegrenade") || isWeaponType(wdmWeapon, "smokespecial")) wdmWeapon = "smokegrenade";

		if(isDefined(level.ex_wdm[wdmWeapon])) iDamage = int((iDamage / 100) * level.ex_wdm[wdmWeapon]);
			//else logprint("WDM: no record for weapon " + wdmWeapon + " in WDM array!\n");
	}

	iDamage = int(iDamage);

	if(isAlive(self))
	{	
		switch(sHitLoc)
		{
			case "right_hand":
			case "left_hand":
			case "gun":
				if(level.ex_droponhandhit && randomInt(100) < level.ex_droponhandhit) self thread extreme\_ex_weapons::dropcurrentweapon();
				break;
			
			case "right_arm_lower":
			case "left_arm_lower":
				if(level.ex_droponarmhit && randomInt(100) < level.ex_droponarmhit) self thread extreme\_ex_weapons::dropcurrentweapon();
				break;
	
			case "right_foot":
			case "left_foot":
				if(level.ex_triponfoothit && randomInt(100) < level.ex_triponfoothit) self thread spankme(1);
				break;

			case "right_leg_lower":
			case "left_leg_lower":
				if(level.ex_triponleghit && randomInt(100)<level.ex_triponleghit) self thread spankme(1);
				break;

			case "torso_lower":
				if(isDefined(self.tankonback) && (randomInt(100) < level.ex_ft_tank_explode))
				{
					if(dodamagefx)
					{
						level thread extreme\_ex_flamethrower::tankExplosion(self, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
						return;
					}
				}
				break;
		}
	}

	if(dodamagefx && !napalm && level.ex_bleeding)
		if(self.health - iDamage < level.ex_startbleed) self thread extreme\_ex_bleeding::doPlayerBleed(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	[[level.ex_callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

exPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("disconnect");
	self notify("kill_thread");

	// black screen on death
	if(level.ex_bsod && isDefined(eAttacker) && eAttacker != self) self thread showBlackScreen();

	// clean the hud
	self extreme\_ex_hud::cleanplayer();

	// drop health packs
	if(level.ex_firstaid_drop && self.ex_firstaidkits) level thread firstaidDrop(self.origin);

	// skip the other stuff if playing freezetag
	if(level.ex_currentgt == "ft") return;

	// kamikaze (suicide bombing)
	if(sMeansOfDeath == "MOD_SUICIDE" && level.ex_kamikaze && isDefined(eAttacker) && isPlayer(eAttacker))
	{
		// suicide bomber
		if(eAttacker == self && !isDefined(self.switching_teams) && !isDefined(self.ex_forcedsuicide) && sWeapon != "dummy1_mp" && isWeaponType(self.ex_lastoffhand, "suicidebomb"))
			self thread suicideBomb(eAttacker);
	}

	// clean mbot marks
	if(level.ex_mbot) self extreme\_ex_bots::playerKilled();

 	// spawn protection punishment threshold reset
	if(level.ex_spwn_time && level.ex_spwn_punish_attacker && level.ex_spwn_punish_threshold && level.ex_spwn_punish_threshold_reset)
		self.ex_spwn_punish_counter = 0;

	// turret abuse check
	if(level.ex_turrets && level.ex_turretabuse && (extreme\_ex_weapons::isWeaponType(sWeapon,"turret") || (sWeapon == "none" && sMeansOfDeath == "MOD_RIFLE_BULLET")) && isDefined(eAttacker))
		eAttacker thread turretAbuse(sWeapon);

	// Helmet pop
	if(level.ex_pophelmet && !self.ex_helmetpopped)
	{
		switch(sHitLoc)
		{
			case "helmet":
			case "head":
				if(randomInt(100)+1 <= level.ex_pophelmet)
				{
					self thread popHelmet(vDir, iDamage);
					//if(dodamagefx) self thread bloodonscreen();
				}
				break;
		}
	}

	// attacker taunt
	if(level.ex_taunts >= 2 && isPlayer(eAttacker))
	{
		if(level.ex_teamplay && eAttacker.pers["team"] != self.pers["team"])
			eAttacker thread taunts(randomInt(9)+1);
		else
			eAttacker thread taunts(4); // DM taunts set to Got one! and Got him!
	}

	// team kill check
	if(level.ex_sinbin && level.ex_teamplay && isPlayer(eAttacker) && eAttacker != self)
	{
		if(eAttacker.pers["team"] == self.pers["team"])
		{
			eAttacker.pers["teamkill"]++;
			if(eAttacker.pers["teamkill"] > level.ex_sinbinmaxtk)
			{
				eAttacker thread extreme\_ex_sinbin::main();
				eAttacker.pers["conseckill"] = 0;
			}
		}
	}
}

showBlackScreen()
{
	self endon("disconnect");

	if(isDefined(self.skip_blackscreen)) return;

	if(level.ex_bsod_blockmenu)
	{
		self closeMenu();
		self closeInGameMenu();
		self setClientCvar("g_scriptMainMenu", game["menu_blackscreen"]);
	}

	if(!isDefined(self.blackscreen))
	{
		self.blackscreen = newClientHudElem(self);
		self.blackscreen.archived = false;
		self.blackscreen.alpha = 1;
		self.blackscreen.horzAlign = "fullscreen";
		self.blackscreen.vertAlign = "fullscreen";
		self.blackscreen.alignX = "left";
		self.blackscreen.alignY = "top";
		self.blackscreen.x = 0;
		self.blackscreen.y = 0;
		self.blackscreen.sort = -1;
		self.blackscreen setShader("black", 640, 480);
	}
	else self.blackscreen.alpha = 1; // in case black screen is already active for anti-run

	if(level.ex_bsod == 2) self thread fadeBlackScreen(5);
	else if(level.ex_bsod == 3) self thread fadeBlackScreen(10);
	else if(level.ex_bsod == 4) self thread fadeBlackScreen(level.respawndelay + 2);
}

fadeBlackScreen(delay)
{
	self endon("disconnect");

	if(!isDefined(delay)) delay = 0;
	if(delay) wait( [[level.ex_fpstime]](delay) );

	if(isDefined(self) && isDefined(self.blackscreen))
	{
		if(isDefined(self.blackscreen.fading)) return;
		self.blackscreen.fading = true;
		self.blackscreen fadeOverTime(1.3);
		self.blackscreen.alpha = 0;
		wait( [[level.ex_fpstime]](2) );
		if(isDefined(self)) self thread killBlackScreen();
	}
}

killBlackScreen()
{
	self endon("disconnect");

	if(isDefined(self))
	{
		if(!level.ex_gameover && level.ex_bsod_blockmenu) self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
		if(isDefined(self.blackscreen)) self.blackscreen destroy();
	}
}

turretAbuse(sWeapon)
{
	self endon("disconnect");

	wepname = maps\mp\gametypes\_weapons::getWeaponName(sWeapon);
	self.pers["turretkill"]++;

	if(self.pers["turretkill"] == level.ex_turretabuse_warn)
	{
		self iprintlnbold(&"TURRET_ABUSER_WARN_PMSG_0");
		self iprintlnbold(&"TURRET_ABUSER_WARN_PMSG_1");
	}
	else if(self.pers["turretkill"] >= level.ex_turretabuse_kill)
	{
		if(sWeapon == "none")
		{
			self iprintlnbold(&"TURRET_ABUSER_PMSG");
			iprintln(&"TURRET_ABUSER_OBITMSG_0", [[level.ex_pname]](self));
			iprintln(&"TURRET_ABUSER_OBITMSG_2");
		}
		else
		{
			self iprintlnbold(&"TURRET_ABUSERWEP_PMSG", wepname);
			iprintln(&"TURRET_ABUSER_OBITMSG_0", [[level.ex_pname]](self));
			iprintln(&"TURRET_ABUSER_OBITMSG_1", wepname);
		}

		wait( [[level.ex_fpstime]](2) );
		playfx(level.ex_effect["blowthefag"], self.origin);
		self playsound("mortar_explosion1");
		wait( [[level.ex_fpstime]](0.05) );
		self.pers["turretkill"] = 0;
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

exEndMap()
{
	level.ex_gameover = true;
	level notify("ex_gameover");
	wait( [[level.ex_fpstime]](0.05) );

	// Disconnect bots
	disconnectBots();

	// end-of-game music (Tnic)
	if(level.ex_endmusic || level.ex_mvmusic || level.ex_statsmusic)
		level thread extreme\_ex_utils::playSoundOnPlayers("spec_music_null");

	// announce result
	if(isDefined(level.ex_resultsound)) level thread extreme\_ex_utils::playSoundOnPlayers(level.ex_resultsound);

	// prepare players for intermission
	players = level.players;
	for(mx = 0; mx < players.size; mx++)
	{
		if(isPlayer(players[mx]))
		{
			// stop pain sounds by restoring health
			players[mx].health = 100;

			// drop flag
			players[mx] extreme\_ex_utils::dropTheFlag(true);

			players[mx] extreme\_ex_spawn::spawnSpectator();
			if(level.ex_ranksystem) players[mx] setPlayerVariables();
			players[mx] extreme\_ex_hud::cleanplayerend();
		}
	}

	// clear hud elements
	extreme\_ex_hud::cleanallhud();

	// play end music
	if(level.ex_endmusic) level thread extremeMusic();

	// launch statsboard
	if(level.ex_stbd) extreme\_ex_statsboard::main();

	// if playerbased map rotation is enabled and map voting is disabled change the rotation
	// now that the player size may have changed from the start of the game
	if(level.ex_pbrotate && !level.ex_mapvote) extreme\_ex_maprotation::pbRotation();

	// launch mapvote
	if(level.ex_mapvote) extreme\_ex_mapvote::main();
	
	// fade the end-of-game music during intermission
	level notify("endmusic");

	// save the number of players for map sizing in DRM
	setCvar("drm_players", level.players.size);
}

disconnectBots()
{
	if(level.ex_mbot)
	{
		spectateBots();
		return;
	}

	bot_entities = [];
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].pers["isbot"]))
		{
			bot_entity = players[i] getEntityNumber();
			bot_entities[bot_entities.size] = bot_entity;
			kick(bot_entity);
			wait( [[level.ex_fpstime]](0.1) );
		}
	}

	if(bot_entities.size)
	{
		entities = getEntArray();
		for(i = 0; i < level.ex_maxclients; i++)
		{
			for(j = 0; j < bot_entities.size; j++)
			{
				if(i == bot_entities[j])
					entities[i] = undefined;
			}
		}
	}
}

spectateBots()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers["isbot"]))
			player thread extreme\_ex_bots::botJoin("spectator");
	}
}

extremeMusic()
{
	// play random track
	musicplay("gom_music_" + (randomInt(10) + 1));

	// wait here till stats and mapvote are done
	level waittill("endmusic");
	
	// wait for intermission time minus music fade time
	wait( [[level.ex_fpstime]](level.ex_intermission - 5) );

	// fade music in last 5 seconds
	musicstop(5);
	wait( [[level.ex_fpstime]](5) );
}

//******************************************************************************
// eXtreme+ player additional routines
//******************************************************************************
suicideBomb(eAttacker)
{
	self endon("disconnect");

	// sEffect "none" is OK, because the exploding nade/satchel charge will have effects
	if(isWeaponType(self.ex_lastoffhand, "satchelcharge"))
	{
		iRadius = level.ex_kamikaze_satchel_radius;
		iMaxDamage = level.ex_kamikaze_satchel_damage;
		sEffect = "none"; // sEffect = "satchel";
	}
	else
	{
		iRadius = level.ex_kamikaze_frag_radius;
		iMaxDamage = level.ex_kamikaze_frag_damage;
		sEffect = "none"; // sEffect = "generic";
	}

	if(isPlayer(eAttacker)) eAttacker.kamikaze_victims = undefined;
	explosion = spawn("script_origin", self.origin);
	explosion thread extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_GRENADE_SPLASH", self.ex_lastoffhand, iRadius, iMaxDamage, iMaxDamage, sEffect, undefined, false, true, true, "kamikaze");
	explosion delete();

	if(level.ex_reward_kamikaze && isDefined(eAttacker.kamikaze_victims))
	{
		wait( [[level.ex_fpstime]](0.05) );
		kamikaze_bonus = level.ex_reward_kamikaze * eAttacker.kamikaze_victims;
		//logprint("KAMIKAZE DEBUG: " + eAttacker.name + " received " + kamikaze_bonus + " bonus for killing " + eAttacker.kamikaze_victims + " players\n");
		eAttacker.score += kamikaze_bonus;
		eAttacker.pers["bonus"] += kamikaze_bonus;
		// added for arcade style HUD points
		eAttacker notify("update_playerscore_hud");
	}
}

roundDisplay()
{
	self endon("kill_thread");

	if(!isDefined(game["roundnumber"]) || !game["roundnumber"] || game["roundnumber"] == self.pers["roundshown"] || isDefined(self.ex_roundnumber)) return;

	self.pers["roundshown"] = game["roundnumber"];

	// display the round number once each round for roundbased games
	self.ex_roundnumber = newClientHudElem(self);
	self.ex_roundnumber.archived = false;
	self.ex_roundnumber.horzAlign = "fullscreen";
	self.ex_roundnumber.vertAlign = "fullscreen";
	self.ex_roundnumber.alignX = "center";
	self.ex_roundnumber.alignY = "middle";
	self.ex_roundnumber.x = 320;
	self.ex_roundnumber.y = 100;
	self.ex_roundnumber.alpha = 0;
	self.ex_roundnumber.fontscale = 2.4;

	if(isDefined(level.roundlimit)) rlimit = level.roundlimit;
		else rlimit = 0;

	if(rlimit == game["roundnumber"]) self.ex_roundnumber setText(&"MISC_LASTROUND");
	else
	{
		self.ex_roundnumber.label = &"MISC_ROUNDNUMBER";
		self.ex_roundnumber setValue(game["roundnumber"]);
	}

	self.ex_roundnumber fadeOverTime(2);
	self.ex_roundnumber.alpha = 1;

	wait( [[level.ex_fpstime]](7) );

	if(isPlayer(self))
	{
		if(isDefined(self.ex_roundnumber))
		{
			self.ex_roundnumber fadeOverTime(2);
			self.ex_roundnumber.alpha = 0;
		}
		
		wait( [[level.ex_fpstime]](2) );
			
		if(isDefined(self.ex_roundnumber)) self.ex_roundnumber destroy();
	}
}

setPlayerVariables()
{
	self thread resetFlagVars();

	// initialize player based timed events handlers
	self.eventcatalog = [];
	self.events = [];

	// apply these stats if not defined already
	count = 1;
	for(;;)
	{
		stat = getPlayerVariable(count);
		if(stat == "") break;
		if(isPlayer(self) && !isDefined(self.pers[stat])) self.pers[stat] = 0;
		count++;
	}

	// spawn protection punishment threshold
	if(level.ex_spwn_time && level.ex_spwn_punish_attacker && level.ex_spwn_punish_threshold && !isDefined(self.ex_spwn_punish_counter))
		self.ex_spwn_punish_counter = 0;

	// reset streak variables
	self.pers["conseckill"] = 0;
	self.pers["conskillnumb"] = 0;
	self.pers["conskilltime"] = 0;
	self.pers["conskillprev"] = 0;
	self.pers["noobstreak"] = 0;
	self.pers["weaponstreak"] = 0;
	self.pers["weaponname"] = "";

	// reset turret abuse counter
	self.pers["turretkill"] = 0;

	// misc variables
	if(!isDefined(game[self.name])) game[self.name] = [];

	// clear the grenades
	if(isDefined(self.pers["fragtype"])) self setWeaponClipAmmo(self.pers["fragtype"], 0);
	if(isDefined(self.pers["smoketype"])) self setWeaponClipAmmo(self.pers["smoketype"], 0);
	if(isDefined(self.pers["enemy_fragtype"])) self setWeaponClipAmmo(self.pers["enemy_fragtype"], 0);
	if(isDefined(self.pers["enemy_smoketype"])) self setWeaponClipAmmo(self.pers["enemy_smoketype"], 0);	
}

resetPlayerVariables()
{
	self thread resetFlagVars();

	// reset the stats
	count = 1;
	for(;;)
	{
		stat = getPlayerVariable(count);
		if(stat == "") break;
		if(isPlayer(self)) self.pers[stat] = 0;
		count++;
	}

	// reset score and deaths
	self.score = 0;
	self.deaths = 0;

	// reset streak variables to 0
	self.pers["conseckill"] = 0;
	self.pers["noobstreak"] = 0;
	self.pers["weaponstreak"] = 0;
	self.pers["weaponname"] = "";

	// misc variables
	if(isDefined(game[self.name])) game[self.name] = [];

	// reset the player rank
	if(level.ex_ranksystem)
	{
		self.pers["special"] = 0;
		self.pers["rank"] = self.pers["preset_rank"];
		self.pers["newrank"] = self.pers["rank"];
	}

	// reset all weapons and firstaid
	self thread extreme\_ex_weapons::replenishWeapons(true);
	self thread extreme\_ex_weapons::replenishGrenades(true);
	self thread extreme\_ex_weapons::replenishFirstaid(true);	
}

resetFlagVars()
{
	// stop binocular weapons
	self notify("binocular_exit");

	// stop mortars
	self.ex_mortar_strike = false;
	self notify("mortar_over");
	self notify("end_mortar");

	// stop artillery
	self.ex_artillery_strike = false;
	self notify("artillery_over");
	self notify("end_artillery");

	// stop airstrikes
	self.ex_air_strike = false;
	self notify("airstrike_over");
	self notify("end_airstrike");

	// stop gunship
	self.ex_gunship = false;
	self.ex_gunship_special = false;
	self.ex_gunship_ejected = false;
	self.ex_gunship_kills = 0;
	self notify("gunship_over");
	self notify("end_gunship");

	// specials
	self.ex_vest = false;
	self.ex_vest_protected = undefined;
	self.ex_bubble = false;
	self.ex_bubble_protected = undefined;
	self.ex_missile = false;
	if(!isDefined(self.ex_insertion)) self.ex_insertion = false;
	self.ex_sentrygun = false;
	self.ex_sentrygun_action = undefined;
	self.ex_sentrygun_moving_owner = undefined;
	self.ex_sentrygun_moving_timer = undefined;
	self.ex_heli = false;

	// reset inactivity timers
	self.inactive_plyr_time = undefined;
	self.inactive_dead_time = undefined;
	self.inactive_spec_time = undefined;

	// eXtreme+
	self.ex_disabledWeapon = 0;
	self.ex_iscamper = false;
	self.ex_isonfire = undefined;
	self.ex_puked = undefined;
	if(!isDefined(self.ex_isunknown)) self.ex_isunknown = false;
	if(!isDefined(self.ex_isdupname)) self.ex_isdupname = false;
	self.ex_weakenweapon = undefined;
	self.ex_ispunished = false;
	self.ex_hasnoweapon = false;
	self.ex_sinbin = false;
	self.ex_oldweapon = undefined;
	self.ex_invulnerable = false;
	self.ex_ishealing = undefined;
	self.ex_helmetpopped = false;
	self.ex_sprinttime = 0;
	self.ex_playsprint = false;
	self.ex_sprintreco = false;
	self.ex_sprinting = false;
	self.ex_binocuse = false;
	self.ex_warningwire = undefined;
	self.ex_plantwire = false;
	self.ex_defusewire = false;
	self.ex_stopwepmon = false;
	self.ex_bleeding = false;
	self.ex_bsoundinit = false;
	self.ex_bshockinit = false;
	self.ex_pace = false;
	self.ex_checkingwmd = undefined;
	self.ex_spwn_punish = undefined;
	self.ex_firstaidkits = 0;
	self.ex_canheal = false;
	self.ex_noheal = undefined;
	self.ex_inmenu = false;
	self.ex_isparachuting = undefined;
	self.handling_mine = false;

	// some maps have drowning. Make sure we reset it on death
	self.drowning = undefined;

	// stock
	self.usedweapons = false;
	self.spamdelay = undefined;
}

taunts(tauntno)
{
	self endon("kill_thread");

	chance = randomInt(20);

	if(chance == 10)
	{
		// convert number to str
		taunt_str = "" + tauntno;

		// delay for death sound to finish
		wait( [[level.ex_fpstime]](1.5) );

		// if the attacker is still here, play the sound now
		switch(randomInt(2))
		{
			case 1: { if(isPlayer(self)) self thread maps\mp\gametypes\_quickmessages::quicktaunts(taunt_str, true); break; }
			default: { if(isPlayer(self)) self thread maps\mp\gametypes\_quickmessages::quicktauntsb(taunt_str, true); break; }
		}
	}
}

popHelmet(damageDir, damage)
{
	self.ex_helmetpopped = true;

	if(!isDefined(self.hatModel) || isDefined(self.ex_newmodel)) return;

	// if entities monitor in defcon 2, no helmet popping
	if(level.ex_entities_defcon == 2) return;

	// make sure the helmet is still there
	helmet_attached = false;
	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == self.hatModel) helmet_attached = true;
	}
	if(!helmet_attached) return;

	self detach(self.hatModel , "");

	self.ex_stance = [[level.ex_getStance]](false);

	if(isPlayer(self))
	{
		switch(self.ex_stance)
		{
			case 2: helmetoffset = (0,0,15);	break;
			case 1: helmetoffset = (0,0,44);	break;
			default: helmetoffset = (0,0,64);	break;
		}
	}
	else helmetoffset = (0,0,15);

	switch(self.hatModel)
	{
		case "xmodel/helmet_russian_trench_a_hat":
		case "xmodel/helmet_russian_trench_b_hat":
		case "xmodel/helmet_russian_trench_c_hat":
		case "xmodel/helmet_russian_padded_a":
			bounce = 0.2;
			impactsound = undefined;
			break;
		default:
			bounce = 0.7;
			impactsound = "helmet_bounce_";
			break;
	}		

	rotation = (randomFloat(360), randomFloat(360), randomFloat(360));
	offset = (0,0,3);
	radius = 6;
	velocity = maps\mp\_utility::vectorScale(damageDir, (damage/20 + randomFloat(5)) ) + (0,0,(damage/20 + randomFloat(5)));

	helmet = spawn("script_model", self.origin + helmetoffset );
	helmet setmodel( self.hatModel );
	helmet.angles = self.angles;
	helmet.targetname = "poppedhelmet";
	helmet thread extreme\_ex_utils::bounceObject(rotation, velocity, offset, (0,0,0), radius, bounce, impactsound, undefined, "helmet");
}

handleDeadBody(team, owner)
{
	//Give the body a model
	self setModel(owner.model);

	// sink body in to the ground
	switch(level.ex_deadbodyfx)
	{
		case 1: self thread bodySink(); break;
		case 2: self thread bodyRise(); break;
	}
}

bodySink()
{
	wait( [[level.ex_fpstime]](15) );
	
	for(i = 0; i < 100; i++)
	{
		if(!isDefined(self)) return;
		self.origin = self.origin - (0,0,0.2);
		wait( [[level.ex_fpstime]](0.05) );
	}
	if(isdefined(self)) self delete();
}

bodyRise()
{
	wait( [[level.ex_fpstime]](15) );

	for(i = 0; i < 150; i++)
	{
		if(!isDefined(self)) return;
		self.origin = self.origin + (0,0,0.2);
		wait( [[level.ex_fpstime]](0.05) );
	}
	if(isdefined(self)) self delete();
}

bloodonscreen()
{
	self endon("kill_thread");

	if(!isDefined(self.ex_bloodonscreen))
	{
		self.ex_bloodonscreen = newClientHudElem(self);
		self.ex_bloodonscreen.archived = false;
		self.ex_bloodonscreen.horzAlign = "fullscreen";
		self.ex_bloodonscreen.vertAlign = "fullscreen";
		self.ex_bloodonscreen.alignX = "left";
		self.ex_bloodonscreen.alignY = "top";
		self.ex_bloodonscreen.x = randomint(496);
		self.ex_bloodonscreen.y = randomint(336);
		self.ex_bloodonscreen.color = (1,1,1);
		self.ex_bloodonscreen.alpha = 1;

		self.ex_bloodonscreen1 = newClientHudElem(self);
		self.ex_bloodonscreen1.archived = false;
		self.ex_bloodonscreen1.horzAlign = "fullscreen";
		self.ex_bloodonscreen1.vertAlign = "fullscreen";
		self.ex_bloodonscreen1.alignX = "left";
		self.ex_bloodonscreen1.alignY = "top";
		self.ex_bloodonscreen1.x = randomint(496);
		self.ex_bloodonscreen1.y = randomint(336);
		self.ex_bloodonscreen1.color = (1,1,1);
		self.ex_bloodonscreen1.alpha = 1;

		self.ex_bloodonscreen2 = newClientHudElem(self);
		self.ex_bloodonscreen2.archived = false;
		self.ex_bloodonscreen2.horzAlign = "fullscreen";
		self.ex_bloodonscreen2.vertAlign = "fullscreen";
		self.ex_bloodonscreen2.alignX = "left";
		self.ex_bloodonscreen2.alignY = "top";
		self.ex_bloodonscreen2.x = randomint(496);
		self.ex_bloodonscreen2.y = randomint(336);
		self.ex_bloodonscreen2.color = (1,1,1);
		self.ex_bloodonscreen2.alpha = 1;

		self.ex_bloodonscreen3 = newClientHudElem(self);
		self.ex_bloodonscreen3.archived = false;
		self.ex_bloodonscreen3.horzAlign = "fullscreen";
		self.ex_bloodonscreen3.vertAlign = "fullscreen";
		self.ex_bloodonscreen3.alignX = "left";
		self.ex_bloodonscreen3.alignY = "top";
		self.ex_bloodonscreen3.x = randomint(496);
		self.ex_bloodonscreen3.y = randomint(336);
		self.ex_bloodonscreen3.color = (1,1,1);
		self.ex_bloodonscreen3.alpha = 1;

		bs = randomint(48);
		bs1 = randomint(48);
		bs2 = randomint(48);
		bs3 = randomint(48);

		self.ex_bloodonscreen SetShader("gfx/impact/flesh_hit2",96 + bs , 96 + bs);
		self.ex_bloodonscreen1 SetShader("gfx/impact/flesh_hitgib",96 + bs1 , 96 + bs1);
		self.ex_bloodonscreen2 SetShader("gfx/impact/flesh_hit2",96 + bs2 , 96 + bs2);
		self.ex_bloodonscreen3 SetShader("gfx/impact/flesh_hitgib",96 + bs3 , 96 + bs3);

		wait( [[level.ex_fpstime]](4) );

		if(!isDefined(self.ex_bloodonscreen)) return;

		self.ex_bloodonscreen fadeOverTime(2);
		self.ex_bloodonscreen.alpha = 0;
		self.ex_bloodonscreen1 fadeOverTime(2);
		self.ex_bloodonscreen1.alpha = 0;
		self.ex_bloodonscreen2 fadeOverTime(2);
		self.ex_bloodonscreen2.alpha = 0;
		self.ex_bloodonscreen3 fadeOverTime(2);
		self.ex_bloodonscreen3.alpha = 0;

		wait( [[level.ex_fpstime]](2) );

		if(!isDefined(self.ex_bloodonscreen)) return;

		if(isDefined(self.ex_bloodonscreen3)) self.ex_bloodonscreen3 destroy();
		if(isDefined(self.ex_bloodonscreen2)) self.ex_bloodonscreen2 destroy();
		if(isDefined(self.ex_bloodonscreen1)) self.ex_bloodonscreen1 destroy();
		if(isDefined(self.ex_bloodonscreen)) self.ex_bloodonscreen destroy();
	}
}

distortPlayerView()
{
	self endon("kill_thread");

	horiz[1] = .26;
	horiz[2] = .26;
	horiz[3] = .25;
	horiz[4] = .25;
	horiz[5] = .25;
	horiz[6] = .25;
	horiz[7] = .25;
	horiz[8] = .25;
	horiz[9] = .25;
	horiz[10] = .25;
	horiz[11] = .25;
	horiz[12] = .15;
	horiz[13] = .13;
	vert[1] = 0.0;
	vert[2] = 0.025;
	vert[3] = 0.036;
	vert[4] = 0.037;
	vert[5] = 0.053;
	vert[6] = 0.072;
	vert[7] = 0.080;
	vert[8] = 0.100;
	vert[9] = 0.11;
	vert[10] = 0.15;
	vert[11] = 0.244;
	vert[12] = 0.238;
	vert[13] = 0.085;
	
	wait( [[level.ex_fpstime]](2) );

	i = 1;
	idir = 0;
	pshift = 0;
	yshift = 0;

	if(isPlayer(self))
	{
		for(;;)
		{
			VMag = self.VaxisMag;
			YMag = self.YaxisMag;

			if(i >= 1 && i <= 13)
			{
				pShift = horiz[i]*VMag;
				yShift = (0 - vert[i])*YMag;
			}
			else if(i >= 14 && i <= 26)
			{
				j = 14 - (i -13);
				pShift = (0 - horiz[j])*VMag;
				yShift = (0 - vert[j])*YMag;
			}
			else if(i >= 27 && i <= 39)
			{
				pShift = (0-horiz[i-26])*VMag;
				yShift = (vert[i-26])*YMag;
			}
			else if(i >= 40 && i <= 52)
			{
				j = 14 - (i -39);
				pShift = (horiz[j])*VMag;
				yShift = (vert[j])*YMag;
			}

			angles = self getplayerangles();
			self setPlayerAngles(angles + (pShift, yShift, 0));

			if(randomInt(50) == 0)
			{
				if(idir == 0) idir = 1;
				else idir = 0;
				i = i + 26;
			}

			if(idir == 0) i++;
			if(idir == 1) i--;
			if( i > 52) i = i - 52;
			if( i < 0) i = 52 - i; 
			wait( [[level.ex_fpstime]](0.05) );
		}
	}
}

weaponfall(delay)
{
	self endon("kill_thread");

	// good strong healthy boy can hold weapon!
	if(self.health > 80) return;

	if(self.health > 50 && randomInt(100) < 50)
	{
		if(isPlayer(self)) self [[level.ex_dWeapon]]();
		wait( [[level.ex_fpstime]](delay) );
		if(isPlayer(self) && self.sessionstate == "playing") self [[level.ex_eWeapon]]();
	}
	else self thread extreme\_ex_weapons::dropcurrentweapon();
}

spankme(time)
{
	self endon("kill_thread");

	self notify("ex_spankme");
	self endon("ex_spankme");

	for(i = 0; i < (time*5); i++)
	{
		if(isPlayer(self))
		{
			self extreme\_ex_utils::forceto("prone");
			self thread extreme\_ex_weapons::dropcurrentweapon();
		}

		wait( [[level.ex_fpstime]](0.2) );
	}
}

handleWelcome()
{
	self endon("kill_thread");
	self endon("ex_freefall");

	if(isPlayer(self))
	{
		// Resetting the tag ex_ispunished is done in resetFlagVars()

		// Did the Name Checker already tag the player for using an unacceptable name?
		if(isDefined(self.ex_isunknown) && self.ex_isunknown)
		{
			self thread handleUnknown(false);
		}
		else
		{
			// Did the Name Checker already tag the player for using a duplicate name?
			if(isDefined(self.ex_isdupname) && self.ex_isdupname)
			{
				self thread handleDupName();
			}
			else
			{
				// If Name Checker is disabled and Unknown Soldier handling is enabled,
				// check for unacceptable names ourselves
				if (level.ex_uscheck && isUnknown(self))
				{
					self thread handleUnknown(false);
				}
				else self thread extreme\_ex_messages::welcomemsg();
			}
		}
	}
}

handleDupName()
{
	self endon("kill_thread");
	self endon("ex_freefall");

	// Tag the player to prevent the Name Checker to kick in more than once
	self.ex_isdupname = true;

	self iprintlnbold(&"NAMECHECK_DNCHECK_DUPNAME1", [[level.ex_pname]](self));
	self setClientCvar("name", "Unknown Soldier");
	self iprintlnbold(&"NAMECHECK_DNCHECK_NEWUNKNOWN");

	if(level.ex_ncskipwarning)
	{
		if(level.ex_usclanguest) self iprintlnbold(&"NAMECHECK_DNCHECK_NEXTCLANGUEST");
			else self iprintlnbold(&"NAMECHECK_DNCHECK_NEXTGUEST");
	}
	else self iprintlnbold(&"NAMECHECK_DNCHECK_NEXTUNKNOWN");

	// Wait several seconds before starting the Unknown Soldier handling code
	wait( [[level.ex_fpstime]](10) );
	if(isPlayer(self))
	{
		self thread handleUnknown(level.ex_ncskipwarning);

		// Remove the tag; the player is officially an Unknown Soldier now
		self.ex_isdupname = false;
	}
}

handleUnknown(skipwarning)
{
	self endon("kill_thread");
	self endon("ex_freefall");

	// Tag the player to prevent the Name Checker to kick in more than once
	self.ex_isunknown = true;

	usname = [];

	if(!skipwarning)
	{
		if(isPlayer(self))
		{
			// Warn them first
			if(level.ex_usclanguest)
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_UNACCEPTABLE", [[level.ex_pname]](self));
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CLANGUEST", level.ex_uswarndelay1);
			}
			else
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_UNACCEPTABLE", [[level.ex_pname]](self));
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_GUEST", level.ex_uswarndelay1);
			}
		}
		// Now give them some time to change their name
		waitWhileUnknown(level.ex_uswarndelay1);
	}

	if(isPlayer(self) && isUnknown(self))
	{
		// Get a free guest number (1 to maxclients)
		level.ex_usguestno = getFreeGuestSlot();

		if(level.ex_usclanguest)
		{
			usname = level.ex_usclanguestname + level.ex_usguestno; // Clan Guest
			self setClientCvar("name", usname);
			wait( [[level.ex_fpstime]](1) );
			if(isPlayer(self))
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_BYSERVER");
				self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_CLANGUEST", [[level.ex_pname]](self));
			}

			// Clan guests are now off the hook; show welcome messages and return
			self.ex_isunknown = false;
			wait( [[level.ex_fpstime]](3) );
			if(isPlayer(self)) self thread extreme\_ex_messages::welcomemsg();
			return;
		}
		else
		{
			// Only assign guest name if not already using an assigned guest name
			if(!isAssignedName(self))
			{
				usname = level.ex_usguestname + level.ex_usguestno; // Non-clan Guest
				self setClientCvar("name", usname);
				wait( [[level.ex_fpstime]](1) );
				if(isPlayer(self))
				{
					self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_BYSERVER");
					self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_GUEST", [[level.ex_pname]](self));
					self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_CHANGEIT", level.ex_uswarndelay2);
				}

				// After name assignment, non-clan guests get a second chance to change their name
				waitWhileUnknown(level.ex_uswarndelay2);
			}
		}
	}

	if(isPlayer(self) && isUnknown(self))
	{
		// My god, don't they understand? ok, time for punishment!
		count = 0;
		while(isPlayer(self) && isUnknown(self) && count < level.ex_uspunishcount)
		{
			if(!isDefined(self.ex_sinbin) || !self.ex_sinbin)
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_TEMPORARY", [[level.ex_pname]](self));
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
				self iprintlnbold(&"UNKNOWNSOLDIER_STILL_PUNISH");
				self thread extreme\_ex_utils::punishment("drop", "freeze");
				waitWhileUnknown(10);
				if(isPlayer(self)) self thread extreme\_ex_utils::punishment("enable", "release");
				waitWhileUnknown(20 + randomInt(20));
				count++;
			}
			else break;
		}

		// Now, if still using assigned name, allow them to play without punishment until they die
		if(isPlayer(self) && isAssignedName(self))
		{
			// Set punished-tag so Name Checker doesn't kick in again
			self.ex_ispunished = true;
			self iprintlnbold(&"UNKNOWNSOLDIER_STILL_RELIEF1");
			self iprintlnbold(&"UNKNOWNSOLDIER_STILL_RELIEF2");
			self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
		}
	}

	// Allow the Name Checker to iterate once to catch duplicate names.
	// Keep this wait statement outside the following if-block to catch players
	// that would otherwise fall through by quickly changing their name from US
	// to a valid name and back to US again (highly unlikely, but possible with key bindings)
	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self) && !self.ex_ispunished && !isUnknown(self))
	{
		// Has the Name Checker tagged him because of using a duplicate name?
		if(isPlayer(self) && !self.ex_isdupname)
		{
			// No, so thank them, and show the welcome messages
			self iprintlnbold(&"UNKNOWNSOLDIER_MSG_THANKS", [[level.ex_pname]](self));
			wait( [[level.ex_fpstime]](3) );
			if(isPlayer(self)) self thread extreme\_ex_messages::welcomemsg();
		}
		else self thread handleDupName();
	}

	// Remove the tag; the player is either renamed, punished or dupname-tagged
	self.ex_isunknown = false;
}

waitWhileUnknown(seconds)
{
	// Wait for x seconds as long as player has unacceptable name
	for(i = 0; i < seconds; i++)
	{
		if(isPlayer(self) && !isUnknown(self)) return;
			else wait( [[level.ex_fpstime]](1) );
	}
}

isUnknownSoldier(player)
{
	self endon("kill_thread");

	// Check if player is Unknown Soldier
	// Color codes are removed. Name is lowercased, so it will reject any case combination
	playernorm = "";
	if(isPlayer(player)) playernorm = extreme\_ex_utils::monotone(player.name);
	playernorm = extreme\_ex_utils::lowercase(playernorm);

	if(playernorm == "" || playernorm == "unknown soldier" || playernorm == "unknownsoldier") return true;
	return false;
}

isAssignedName(player)
{
	self endon("kill_thread");

	// Check if player has an assigned guest name
	// Do NOT check for assigned clan guest names!
	for(i = 1; i <= level.ex_maxclients; i++)
	{
		chkname = level.ex_usguestname + i;
		if(player.name == chkname) return true;
	}
	return false;
}

isUnknown(player)
{
	self endon("kill_thread");

	// Check if player has unacceptable name
	if(isUnknownSoldier(player)) return true;
	if(isAssignedName(player)) return true;
	return false;
}

getFreeGuestSlot()
{
	self endon("kill_thread");

	// Get a free guest number.
	players = level.players;

	if(level.ex_usclanguest) usname = level.ex_usclanguestname;
		else usname = level.ex_usguestname;

	i = 1;
	while(i <= level.ex_maxclients)
	{
		chkname = usname + i;
		found = false;
		for(j = 0; j < players.size; j++)
		{
			if(players[j].name == chkname)
			{
				found = true;
				break;
			}
		}
		if(found) i++;
			else break;
	}
	return i;
}

getPlayerVariable(stat)
{
	switch(stat)
	{
		// kills
		case 1:  return "kill";
		case 2:  return "grenadekill";
		case 3:  return "tripwirekill";
		case 4:  return "headshotkill";
		case 5:  return "bashkill";
		case 6:  return "sniperkill";
		case 7:  return "knifekill";
		case 8:  return "mortarkill";
		case 9:  return "artillerykill";
		case 10: return "airstrikekill";
		case 11: return "napalmkill";
		case 12: return "panzerkill";
		case 13: return "spawnkill";
		case 14: return "spamkill";
		case 15: return "teamkill";
		case 16: return "flamethrowerkill";
		case 17: return "landminekill";
		case 18: return "firenadekill";
		case 19: return "gasnadekill";
		case 20: return "satchelchargekill";
		case 21: return "gunshipkill";

		// deaths
		case 22: return "death";
		case 23: return "grenadedeath";
		case 24: return "tripwiredeath";
		case 25: return "headshotdeath";
		case 26: return "bashdeath";
		case 27: return "sniperdeath";
		case 28: return "knifedeath";
		case 29: return "mortardeath";
		case 30: return "artillerydeath";
		case 31: return "airstrikedeath";
		case 32: return "napalmdeath";
		case 33: return "panzerdeath";
		case 34: return "spawndeath";
		case 35: return "planedeath";
		case 36: return "flamethrowerdeath";
		case 37: return "fallingdeath";
		case 38: return "minefielddeath";
		case 39: return "suicide";
		case 40: return "landminedeath";
		case 41: return "firenadedeath";
		case 42: return "gasnadedeath";
		case 43: return "satchelchargedeath";
		case 44: return "gunshipdeath";

		// other
		case 45: return "turretkill";
		case 46: return "noobstreak";
		case 47: return "conseckill";
		case 48: return "weaponstreak";
		case 49: return "roundshown";
		case 50: return "longdist";
		case 51: return "longhead";
		case 52: return "longspree";
		case 53: return "flagcap";
		case 54: return "flagret";
		case 55: return "bonus";

		// empty signals end
		default: return "";
	}
}
