init()
{
	if(!level.ex_landmines) return;

	level._effect["landmine_explosion"] = loadfx("fx/explosions/grenadeExp_dirt.efx");

	// Delete all landmines
	MineDelete(-1);

	// Mine identifier memory (team based)
	if(level.ex_teamplay)
	{
		game["landmines_axis"] = 0;
		game["landmines_allies"] = 0;
	}

	level.mine_barsize = 192;
	if(level.ex_landmine_bb) level.mine_trip_distance = 100;
		else level.mine_trip_distance = 20;
	level.mine_defuse_distance = level.mine_trip_distance + 2;
	level.mine_warn_distance = level.mine_trip_distance + 150;

	level thread mineDeleteMonitor();
}

giveLandmines()
{
	self endon("disconnect");

	if(!level.ex_landmines) return;

	// Mine identifier memory (player based)
	if(!level.ex_teamplay && !isDefined(self.pers["landmines"]))
		self.pers["landmines"] = 0;

	if(level.ex_landmines_loadout) self.mine_ammo_max = getRankBasedMineCount(self.pers["rank"]);
		else self.mine_ammo_max = getWeaponBasedMineCount(self.pers["weapon"]);
	self.mine_ammo = self.mine_ammo_max;

	if(!isDefined(self.ex_moving)) self.ex_moving = false;
	self.mine_inrange = 0;
	self.handling_mine = 0;
	self.mine_plantprotection = 0;

	// mbots do not get landmines
	if(level.ex_mbot && isDefined(self.pers["isbot"]))
	{
		self.mine_ammo = 0;
		return;
	}

	self thread mineWarningMonitor();
	if(self.mine_ammo) self thread minePlantMonitor();
}

updateLandmines(landmines)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return;

	plantMonitorIsRunning = self.mine_ammo;
	self.mine_ammo_max = landmines;
	self.mine_ammo = self.mine_ammo_max;
	if(!plantMonitorIsRunning) self thread minePlantMonitor();
		else self thread mineShowHUD();
}

mineShowHUD()
{
	hudX = 488;
	if(level.ex_medicsystem) hudY = 470;
		else hudY = 67;
	
	if(!isDefined(self.mine_hud_icon))
	{
		// HUD landmine icon
		self.mine_hud_icon = newClientHudElem(self);
		self.mine_hud_icon.horzAlign = "fullscreen";
		self.mine_hud_icon.vertAlign = "fullscreen";
		self.mine_hud_icon.alignX = "center";
		self.mine_hud_icon.alignY = "middle";
		self.mine_hud_icon.x = hudX ;
		self.mine_hud_icon.y = hudY;
		self.mine_hud_icon.alpha = 1;
		self.mine_hud_icon setShader("gfx/custom/bblandhud2.tga", 20, 20);
	}

	if(!isDefined(self.mine_hud_ammo))
	{
		// HUD landmine ammo
		self.mine_hud_ammo = newClientHudElem(self);
		self.mine_hud_ammo.horzAlign = "fullscreen";
		self.mine_hud_ammo.vertAlign = "fullscreen";
		self.mine_hud_ammo.alignX = "center";
		self.mine_hud_ammo.alignY = "middle";
		self.mine_hud_ammo.x = hudX -3;
		self.mine_hud_ammo.y = hudY;
		self.mine_hud_ammo.fontScale = 1;
		self.mine_hud_ammo.alpha = .94;
	}

	if(self.mine_ammo == 0) self.mine_hud_ammo.color = (1, 0, 0);
		else self.mine_hud_ammo.color = (1, 1, 1);

	self.mine_hud_ammo setValue(self.mine_ammo);
}

mineDestroyHUD()
{
	// Destroy landmine HUD
	if(isDefined(self.mine_hud_icon)) self.mine_hud_icon destroy();
	if(isDefined(self.mine_hud_ammo)) self.mine_hud_ammo destroy();
}

mineDeleteMonitor()
{
	for(;;)
	{
		wait( [[level.ex_fpstime]](1) );

		mines = getentarray("item_mine", "targetname");
		for(i = 0; i < mines.size; i++)
		{
			// Make sure the mine is still there
			if(isDefined(mines[i])) mine = mines[i];
				else continue;

			// Delete mines from player who left or switched to spectators
			if(!isPlayer(mine.owner) || !isDefined(mine.owner.pers["team"]) || mine.owner.pers["team"] == "spectator" || mine.owner.sessionteam == "spectator")
			{
				thread mineDeleteFrom(mine.owner);
				break;
			}
		}
	}
}

mineWarningMonitor()
{
	self endon("kill_thread");

	while(true)
	{
		wait( [[level.ex_fpstime]](0.1) );
		mine_warn = 0;
		def_warn = 0;
		mines = getentarray("item_mine", "targetname");
		for(i = 0; i < mines.size; i++)
		{
			// Make sure the mine is still there
			if(isDefined(mines[i])) mine = mines[i];
				else continue;

			// Assign local vars, but make sure the mine is still there when we address it
			mine_team = "none";
			if(level.ex_teamplay)
			{
				if(isDefined(mine)) mine_team = mine.team;
					else continue;
			}

			mine_owner = "none";
			if(isDefined(mine)) mine_owner = mine.owner;
				else continue;

			mine_identifier = 0;
			if(isDefined(mine)) mine_identifier = mine.identifier;
				else continue;

			mine_dist = 1000;
			if(isDefined(mine) && isDefined(mine.origin)) mine_dist = int(distance(self.origin, mine.origin));
				else continue;

			// Check if we should show the mine warning
			if(mine_dist < level.mine_warn_distance)
			{
				if(!level.ex_teamplay)
				{
					if(mine_owner != self || !level.ex_landmine_ownersafe) mine_warn = 1;
				}
				else
				{
					if((mine_team != self.pers["team"]) || !level.ex_landmine_teamsafe) mine_warn = 1;
				}

				if(mine_owner == self && mine_identifier == self.mine_plantprotection) mine_warn = 0;
			}
			else
				if(mine_owner == self && mine_identifier == self.mine_plantprotection) self.mine_plantprotection = 0;

			// Check if we should show defuse message
			if(mine_dist < level.mine_defuse_distance)
			{
				if(level.ex_teamplay && mine_team == self.pers["team"])
				{
					if(self stanceOK(2)) def_warn = 1;
				}
				else if(self stanceOK(3)) def_warn = 1;

			}
		}

		// Defuse warning overrules mine warning
		if(def_warn)
		{
			mine_warn = 0;
			self.mine_inrange = 1;
		}
		else self.mine_inrange = 0;
		if(mine_warn && level.ex_landmine_warning && !isDefined(self.mine_hud_warn))
		{
			self.mine_hud_warn =  newClientHudElem(self);
			self.mine_hud_warn.x = 0;
			self.mine_hud_warn.y = 125;
			self.mine_hud_warn.alignX = "center";
			self.mine_hud_warn.alignY = "middle";
			self.mine_hud_warn.horzAlign= "center_safearea";
			self.mine_hud_warn.vertAlign = "center_safearea";
			self.mine_hud_warn.fontScale = 1;
			self.mine_hud_warn.color = (1,0,0);
			self.mine_hud_warn.alpha = 1;
			self.mine_hud_warn setText(&"LANDMINES_WARNING");
	            self playsound ("land_warning");
		}
		else if(!mine_warn && isDefined(self.mine_hud_warn))
			self.mine_hud_warn destroy();


		if(def_warn && !isDefined(self.mine_hud_defuse))
		{
			self.mine_hud_defuse =  newClientHudElem(self);
			self.mine_hud_defuse.x = 0;
			self.mine_hud_defuse.y = 90;
			self.mine_hud_defuse.alignX = "center";
			self.mine_hud_defuse.alignY = "middle";
			self.mine_hud_defuse.horzAlign= "center_safearea";
			self.mine_hud_defuse.vertAlign = "center_safearea";
			self.mine_hud_defuse.fontScale = 1;
			self.mine_hud_defuse.color = (0.580,0.961,0.573);
			self.mine_hud_defuse.alpha = 1;
			self.mine_hud_defuse setText(&"LANDMINES_DEFUSE");
		}
		else if(!def_warn && isDefined(self.mine_hud_defuse))
			self.mine_hud_defuse destroy();
	}
}

minePlantMonitor()
{
	self endon("kill_thread");

	self thread mineShowHUD();

	while(self.mine_ammo)
	{
		timer = 0;
		while(self stanceOK(2) && !self.ex_moving && self useButtonPressed())
		{
			// Prevent mine plant hysteria
			if (timer < .5)
			{
				timer = timer + .05;
				wait( [[level.ex_fpstime]](0.05) );
				continue;
			}

			// Prevent planting while defusing
			if(self.mine_inrange || self.handling_mine) break;

			// Prevent planting while healing (crouched shellshock position is detected as prone).
			// Wait till healing is over and player releases USE button
			if(isDefined(self.ex_ishealing))
			{
			  while(isDefined(self.ex_ishealing)) wait( [[level.ex_fpstime]](0.05) );
			  while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
				break;
			}

			// Prevent planting landmine while planting or defusing bomb in SD or ESD
			if(isDefined(self.ex_planting) || isDefined(self.ex_defusing)) break;

			// Prevent planting too close to spawnpoints
			if(self tooCloseToSpawnpoints()) break;

			// Prevent planting while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") break;

			// Double check stance
			if(!self stanceOK(2)) break;

			// Check for correct surface type
			plant = self getPlant();
			if(level.ex_landmine_surfacecheck && !allowedSurface(plant.origin))
			{
				self iprintln(&"LANDMINES_WRONG_SURFACE");
				break;
			}

			// Check if free slot available
			if(!(self mineCount(false) < level.ex_landmines_max) && !level.ex_landmines_fifo)
			{
				self iprintln(&"LANDMINES_MAXIMUM");
				break;
			}

			self.handling_mine = 1;
			if(isDefined(self.ex_expmsg1)) self.ex_expmsg1.alpha = 0;
			if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;

			if(!isDefined(self.mine_hud_plant))
			{
				self.mine_hud_plant = newClientHudElem(self);
				self.mine_hud_plant.x = 0;
				self.mine_hud_plant.y = 90;
				self.mine_hud_plant.alignX = "center";
				self.mine_hud_plant.alignY = "middle";
				self.mine_hud_plant.horzAlign = "center_safearea";
				self.mine_hud_plant.vertAlign = "center_safearea";
				self.mine_hud_plant.fontScale = 1;
				self.mine_hud_plant.color = (0.580,0.961,0.573);
				self.mine_hud_plant.alpha = 1;
				self.mine_hud_plant setText(&"LANDMINES_PLANTING");
			}

			if(!isDefined(self.mine_hud_progress_bg))
			{
				self.mine_hud_progress_bg = newClientHudElem(self);
				self.mine_hud_progress_bg.x = 0;
				self.mine_hud_progress_bg.y = 104;
				self.mine_hud_progress_bg.alignX = "center";
				self.mine_hud_progress_bg.alignY = "middle";
				self.mine_hud_progress_bg.horzAlign = "center_safearea";
				self.mine_hud_progress_bg.vertAlign = "center_safearea";
				self.mine_hud_progress_bg.alpha = 0.5;
			}
			self.mine_hud_progress_bg setShader("black", (level.mine_barsize + 4), 12);

			if(!isDefined(self.mine_hud_progress))
			{
				self.mine_hud_progress = newClientHudElem(self);
				self.mine_hud_progress.x = int(level.mine_barsize / (-2.0));
				self.mine_hud_progress.y = 104;
				self.mine_hud_progress.alignX = "left";
				self.mine_hud_progress.alignY = "middle";
				self.mine_hud_progress.horzAlign = "center_safearea";
				self.mine_hud_progress.vertAlign = "center_safearea";
			}
			self.mine_hud_progress setShader("white", 0, 6);
			self.mine_hud_progress scaleOverTime(level.ex_landmine_plant_time, level.mine_barsize, 6);

			self playsound("moody_plant");
			self.mine_plant_sitstill = spawn("script_origin", self.origin);
			self linkTo(self.mine_plant_sitstill);
			self [[level.ex_dWeapon]]();

			progresstime = 0;
			while(isAlive(self) && self useButtonPressed() && progresstime < level.ex_landmine_plant_time && self stanceOK(2))
			{
				progresstime += level.ex_fps_frame;
				wait( [[level.ex_fpstime]](level.ex_fps_frame) );
			}

			if(progresstime >= level.ex_landmine_plant_time)
			{
				self thread mineDrop();
				self iprintln(&"LANDMINES_PLANTED");

				self.mine_ammo--;
				self thread mineShowHUD();
			}

			if(isDefined(self.mine_hud_progress_bg)) self.mine_hud_progress_bg destroy();
			if(isDefined(self.mine_hud_progress)) self.mine_hud_progress destroy();
			if(isDefined(self.mine_hud_plant)) self.mine_hud_plant destroy();

			self unlink();
			self [[level.ex_eWeapon]]();
			if(isDefined(self.mine_plant_sitstill))
				self.mine_plant_sitstill delete();

			while(isAlive(self) && self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );

			self.handling_mine = 0;
			if(isDefined(self.ex_expmsg1)) self.ex_expmsg1.alpha = 1;
			if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 1;

			if(!self.mine_ammo) break;

			timer = 0;
			wait( [[level.ex_fpstime]](0.05) );
		}

		wait( [[level.ex_fpstime]](0.1) );
	}

	self thread mineShowHUD();
}

mineDrop()
{
	if(!isDefined(self)) return;

	team = "both";
	if(isDefined(self.pers["team"]))
		team = self.pers["team"];

	plant = self getPlant();

	item_mine = spawn("script_model", plant.origin - (0,0,level.ex_landmine_depth));
	item_mine hide();
	item_mine.identifier = 0; // set custom vars before assigning targetname
	item_mine.being_defused = 0;
	item_mine.owner = self;
	item_mine.team = team;
	item_mine setModel("xmodel/bblandmine");
	item_mine.targetname = "item_mine";
	item_mine.angles = plant.angles + (0, 0, 90);
	item_mine show();

	if(!level.ex_teamplay)
	{
		self.pers["landmines"]++;
		item_mine.identifier = self.pers["landmines"];
	}
	else
	{
		if(self.pers["team"] == "axis")
		{
			game["landmines_axis"]++;
			item_mine.identifier = game["landmines_axis"];
		}
		else
		{
			game["landmines_allies"]++;
			item_mine.identifier = game["landmines_allies"];
		}
	}

	self.mine_plantprotection = item_mine.identifier;

	// Check if planted mines exceed maximum now
	self thread MineCheckMax();
	
	// Play Sound
	self playsound("weap_fraggrenade_pin");
	wait( [[level.ex_fpstime]](0.15) );
	self playsound("weap_fraggrenade_pin");

	item_mine thread mineTripThink();
	item_mine thread mineDefuseThink();
}

mineTripThink()
{
	self endon("kill_mine_trip_think");

	self.blow = false;
	while(true)
	{
		wait( [[level.ex_fpstime]](0.2) );

		if(!isDefined(self)) return;

		// Blow if triggered
		if(self.blow) break;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			// Make sure this player is eligible to trip the mine
			if(!isPlayer(player) || player.sessionstate != "playing" || !isDefined(player.mine_ammo)) continue;

			// player is jumping over the landmine?
			// mbots do not always pass the isOnGround test, so skip this test for them
			if(!isDefined(player.pers["isbot"]) && !player isOnGround()) continue;

			// Check
			if(!level.ex_teamplay)
			{
				if( (self.owner == player && level.ex_landmine_ownersafe) || (self.identifier == player.mine_plantprotection) ) continue;
			}
			else
			{
				if( (self.team == player.pers["team"] && level.ex_landmine_teamsafe) || (self.identifier == player.mine_plantprotection) ) continue;
			}

			// Too close! Explosion!
			if(distance(self.origin, player.origin) < level.mine_trip_distance) self.blow = true;
		}
	}

	self notify("kill_mine_defuse_think");

	// Click and explode
	self playsound ("minefield_click");
	if(level.ex_landmine_bb)
	{
		self movez(60, 0.4, 0, 0.3);
		wait( [[level.ex_fpstime]](0.4) );
	}
	else wait( [[level.ex_fpstime]](0.3) );
	self playsound("explo_mine");
	playfx(level._effect["landmine_explosion"], self getorigin());

	// Do damage
	if(isPlayer(self.owner)) eAttacker = self.owner;
		else eAttacker = self;

	if(level.ex_landmine_bb) self extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_EXPLOSIVE", "landmine_mp", 400, 600, 400, "generic", "dirt", true, true, true);
		else self extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_EXPLOSIVE", "landmine_mp", 300, 600, 400, "generic", "dirt", true, true, true);

	wait( [[level.ex_fpstime]](0.25) );
	if(isDefined(self))
	{
		origin = self.origin;
		if(isDefined(self.linkedplayer) && isPlayer(self.linkedplayer) && isAlive(self.linkedplayer)) mineReleasePlayer(self.linkedplayer);
		self delete();
		thread checkProximityLandmines(origin, level.ex_landmine_cpx);
		thread extreme\_ex_tripwires::checkProximityTrips(origin, level.ex_landmine_cpx);
		thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin, eAttacker, level.ex_landmine_cpx);
	}
}

checkProximityLandmines(origin, cpx)
{
	if(level.ex_landmines && level.ex_landmine_cpx)
	{
		mines = getentarray("item_mine", "targetname");
		for(i = 0; i < mines.size; i++)
		{
			mine = mines[i];
			if(!isDefined(mine)) continue;

			origin1 = mine.origin;
			cond_dist = (distance(origin, origin1) <= cpx);
			if(cond_dist) mine.blow = true;
		}
	}
}

mineDefuseThink()
{
	self endon("kill_mine_defuse_think");

	while(isDefined(self))
	{
		wait( [[level.ex_fpstime]](0.2) );
		
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			// Skip player if not an active player or if spawn procedure not completed yet
			if(!isPlayer(player) || !isDefined(player.sessionstate) || player.sessionstate != "playing" || !isDefined(player.mine_ammo)) continue;

			// Prevent defusing while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(player.frozenstate) && player.frozenstate == "frozen") continue;

			// Skip player if already carrying the max amount of landmines
			// DISABLED ON PURPOSE! NOW DEFUSING IS ALWAYS POSSIBLE
			//if(player.mine_ammo == player.mine_ammo_max) continue;

			// Skip player if stance is not right
			if(!player stanceOK(3)) continue;

			// Skip player if this player is already handling a landmine
			if(player.handling_mine) continue;

			// Defuse if distance is OK
			while(isDefined(self) && isDefined(player) && isAlive(player) && distance(self.origin,player.origin) < level.mine_defuse_distance && player useButtonPressed() == true && player stanceOK(3) && !player.ex_moving)
			{
				self.being_defused = 1;
				player.handling_mine = 1;
				if(isDefined(player.ex_expmsg1)) player.ex_expmsg1.alpha = 0;
				if(isDefined(player.ex_binocular_hint)) player.ex_binocular_hint.alpha = 0;

				if(!isDefined(player.mine_hud_progress_bg))
				{
					player.mine_hud_progress_bg = newClientHudElem(player);
					player.mine_hud_progress_bg.x = 0;
					player.mine_hud_progress_bg.y = 104;
					player.mine_hud_progress_bg.alignX = "center";
					player.mine_hud_progress_bg.alignY = "middle";
					player.mine_hud_progress_bg.horzAlign= "center_safearea";
					player.mine_hud_progress_bg.vertAlign = "center_safearea";
					player.mine_hud_progress_bg.alpha = 0.5;
				}
				player.mine_hud_progress_bg setShader("black", (level.mine_barsize + 4), 12);

				if(!isDefined(player.mine_hud_progress))
				{
					player.mine_hud_progress = newClientHudElem(player);
					player.mine_hud_progress.x = int(level.mine_barsize / (-2.0));
					player.mine_hud_progress.y = 104;
					player.mine_hud_progress.alignX = "left";
					player.mine_hud_progress.alignY = "middle";
					player.mine_hud_progress.horzAlign = "center_safearea";
					player.mine_hud_progress.vertAlign = "center_safearea";
				}
				player.mine_hud_progress setShader("white", 0, 8);
				player.mine_hud_progress scaleOverTime(level.ex_landmine_defuse_time, level.mine_barsize, 8);

				// remember player so we can unlink and clean up the HUD when the landmine blows without
				// killing the player
				self.linkedplayer = player;

				//player playsound("MP_bomb_defuse");
				player playsound("moody_plant");
				player linkTo(self);
				player [[level.ex_dWeapon]]();

				progresstime = 0;
				while(isDefined(self) && isAlive(player) && player useButtonPressed() && progresstime < level.ex_landmine_defuse_time && player stanceOK(3))
				{
					progresstime += level.ex_fps_frame;
					wait( [[level.ex_fpstime]](level.ex_fps_frame) );
				}

				if(progresstime >= level.ex_landmine_defuse_time)
				{
					self notify("kill_mine_trip_think");

					// bonus points for defusing
					if(level.ex_reward_landmine)
					{
						if( (!level.ex_teamplay && self.owner != player) || (level.ex_teamplay && self.team != player.pers["team"]) )
						{
							player.score += level.ex_reward_landmine;
							player.pers["bonus"] += level.ex_reward_landmine;
							player notify("update_playerscore_hud");
						}
					}

					self delete();
					player iprintln(&"LANDMINES_DEFUSED");

					if(player.mine_ammo < player.mine_ammo_max)
					{
						player.mine_ammo++;
						if(player.mine_ammo == 1) player thread minePlantMonitor();
						wait( [[level.ex_fpstime]](0.1) );
						player thread mineShowHUD();
					}
				}
				else
				{
					self.linkedplayer = undefined;
					self.being_defused = 0;
				}

				if(isDefined(player.mine_hud_progress_bg)) player.mine_hud_progress_bg destroy();
				if(isDefined(player.mine_hud_progress)) player.mine_hud_progress destroy();

				while(isAlive(player) && player useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );

				player unlink();
				player [[level.ex_eWeapon]]();
				player.handling_mine = 0;
				if(isDefined(player.ex_expmsg1)) player.ex_expmsg1.alpha = 1;
				if(isDefined(player.ex_binocular_hint)) player.ex_binocular_hint.alpha = 1;

				wait( [[level.ex_fpstime]](0.05) );
			}
		}
	}
}

mineReleasePlayer(player)
{
	if(isDefined(player.mine_hud_progress_bg)) player.mine_hud_progress_bg destroy();
	if(isDefined(player.mine_hud_progress)) player.mine_hud_progress destroy();

	player unlink();
	player [[level.ex_eWeapon]]();
	player.handling_mine = 0;
	if(isDefined(player.ex_expmsg1)) player.ex_expmsg1.alpha = 1;
	if(isDefined(player.ex_binocular_hint)) player.ex_binocular_hint.alpha = 1;
}

// Check max ammount of mines for player (DM style game) or team (team based game)
mineCheckMax()
{
	oldestMine = self mineCount(true);
	if(oldestMine != 0) mineDelete(oldestMine);
}

// Return number of mines (parameter set to FALSE) or oldest mine (parameter set to TRUE)
// for player (DM style game) or team (team based game)
mineCount(returnOldestMine)
{
	ownMines = 0;
	oldestMine = 9999;
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && isDefined(self))
		{
			if( (!level.ex_teamplay && mines[i].owner == self) || (level.ex_teamplay && mines[i].team == self.pers["team"]) )
			{
				ownMines++;
				if(mines[i].identifier < oldestMine) oldestMine = mines[i].identifier;
			}
		}
	}

	if(returnOldestMine)
	{
		if(ownMines > level.ex_landmines_max) return oldestMine;
			else return 0;
	}
	else return ownMines;
}

// Delete mine with specific identifier, or all mines if identifier is -1
mineDelete(identifier)
{
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && (mines[i].identifier == identifier || identifier == -1))
		{
			mines[i] notify("kill_mine_defuse_think");
			mines[i] notify("kill_mine_trip_think");
			wait( [[level.ex_fpstime]](0.05) );
			if(isDefined(mines[i])) mines[i] delete();
		}
	}
}

// Delete all mines from specific owner
mineDeleteFrom(owner)
{
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && mines[i].owner == owner)
		{
			mines[i] notify("kill_mine_defuse_think");
			mines[i] notify("kill_mine_trip_think");
			wait( [[level.ex_fpstime]](0.05) );
			if(isDefined(mines[i])) mines[i] delete();
		}
	}
}

// Check if stance is allowed: 0 = stand, 1 = crouch, 2 = prone, 3 = crouch or prone
StanceOK(allowedstance)
{
	stance = self [[level.ex_getstance]](false);

	if(allowedstance == 1 && stance == 1) return true;
		else if(allowedstance == 2 && stance == 2) return true;
			else if(allowedstance == 3 && (stance == 1 || stance == 2)) return true;

	return false;
}

// Return mine count for specific weapon class
getWeaponBasedMineCount(weapon)
{
	if(!isDefined(level.weapons[weapon])) return 0;

	switch(level.weapons[weapon].classname)
	{
		case "sniper":
			return level.ex_allow_mine_sniper;

		case "boltrifle":
			return level.ex_allow_mine_boltrifle;

		case "rifle":
			return level.ex_allow_mine_rifle;

		case "semiautomatic":
			return level.ex_allow_mine_semiauto;

		case "smg":
			return level.ex_allow_mine_smg;

		case "mg":
			return level.ex_allow_mine_mg;

		case "shotgun":
			return level.ex_allow_mine_shotgun;

		default:
			return 0;
	}
}

// Return mine count based on rank
getRankBasedMineCount(rank)
{
	return game["rank_ammo_landmines_" + rank];
}

// Get landmine plant position
getPlant()
{
	start = self.origin + (0, 0, 10);

	range = 32;
	forward = anglesToForward(self.angles);
	forward = maps\mp\_utility::vectorScale(forward, range);

	traceorigins[0] = start + forward;
	traceorigins[1] = start;

	trace = bulletTrace(traceorigins[0], (traceorigins[0] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	trace = bulletTrace(traceorigins[1], (traceorigins[1] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	traceorigins[2] = start + (16, 16, 0);
	traceorigins[3] = start + (16, -16, 0);
	traceorigins[4] = start + (-16, -16, 0);
	traceorigins[5] = start + (-16, 16, 0);

	besttracefraction = undefined;
	besttraceposition = undefined;
	for(i = 0; i < traceorigins.size; i++)
	{
		trace = bulletTrace(traceorigins[i], (traceorigins[i] + (0, 0, -1000)), false, undefined);

		if(!isDefined(besttracefraction) || (trace["fraction"] < besttracefraction))
		{
			besttracefraction = trace["fraction"];
			besttraceposition = trace["position"];
		}
	}
	
	if(besttracefraction == 1)
		besttraceposition = self.origin;
	
	temp = spawnstruct();
	temp.origin = besttraceposition;
	temp.angles = orientToNormal(trace["normal"]);
	return temp;
}

orientToNormal(normal)
{
	hor_normal = (normal[0], normal[1], 0);
	hor_length = length(hor_normal);

	if(!hor_length)
		return (0, 0, 0);
	
	hor_dir = vectornormalize(hor_normal);
	neg_height = normal[2] * -1;
	tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
	plant_angle = vectortoangles(tangent);

	return plant_angle;
}

tooCloseToSpawnpoints()
{
	// Check for spawnpoints
	spawnpointname = undefined;

	switch(level.ex_currentgt)
	{
		case "sd":
		case "esd":
			return false;

		case "ctf":
		case "rbctf":
		case "ctfb":
			if(self.pers["team"] == "axis")
				spawnpointname = "mp_ctf_spawn_allied";
			else if(self.pers["team"] == "allies")
				spawnpointname = "mp_ctf_spawn_axis";
			break;
	
		case "dm":
		case "hm":
		case "lms":
		case "ihtf":
			spawnpointname = "mp_dm_spawn";
			break;
	
		case "tdm":
		case "cnq":
		case "rbcnq":
		case "hq":
		case "htf":
			spawnpointname = "mp_tdm_spawn";
			break;
	}

	// Check distance from all relevant spawnpoints
	if(isDefined(spawnpointname))
	{
		spawnpoints = getentarray(spawnpointname, "classname");

		for(i=0;i<spawnpoints.size;i++)
		{
			spawnpoint = spawnpoints[i];
			if(distance(self.origin,spawnpoint.origin) < 120)
			{
				self iprintln(&"LANDMINES_TOO_CLOSE_BASE");
				return true;
			}
		}
	}

	// Extra check for CTF flag zones
	flag_name = undefined;

	if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
	{
		if(self.pers["team"] == "axis")
			flag_name = "axis_flag";
		else if(self.pers["team"] == "allies")
			flag_name = "allied_flag";
	}

	if(isDefined(flag_name))
	{
		flags = getentarray(flag_name, "targetname");

		for(i = 0; i < flags.size; i++)
		{
			flag = flags[i];

			if(distance(self.origin,flag.origin) < 150)
			{
				self iprintln(&"LANDMINES_TOO_CLOSE_FLAG");
				return true;
			}
		}
	}

	return false;
}

allowedSurface(plantPos)
{
	startOrigin = plantPos + (0, 0, 100);
	endOrigin = plantPos + (0, 0, -2048);

	trace = bulletTrace(startOrigin, endOrigin, true, undefined);
	if(trace["fraction"] < 1.0) surface = trace["surfacetype"];
		else surface = "dirt";

	switch(surface)
	{
		case "beach":
		case "dirt":
		case "grass":
		case "ice":
		case "mud":
		case "sand":
		case "snow": return true;
	}

	return false;
}
