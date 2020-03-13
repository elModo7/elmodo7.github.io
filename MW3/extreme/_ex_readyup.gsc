init()
{
	if(!level.ex_readyup) return;

	if(!isDefined(game["readyup_done"]))
	{
		[[level.ex_PrecacheString]](&"READYUP_WAIT_FOR_NEXT_ROUND");

		if(level.ex_readyup_graceperiod)
		{
			[[level.ex_PrecacheShader]]("white");
			[[level.ex_PrecacheString]](&"READYUP_GRACE_PERIOD");
		}

		if(level.ex_readyup == 1) // simple mode
		{
			[[level.ex_PrecacheString]](&"READYUP_WAITING_FOR_PLAYERS");
			[[level.ex_PrecacheString]](&"READYUP_MATCH_BEGINS");

			level thread levelGTSDelay();
		}
		else // enhanced mode
		{
			[[level.ex_PrecacheString]](&"READYUP_READYUP");
			[[level.ex_PrecacheString]](&"READYUP_WAITING_FOR");
			[[level.ex_PrecacheString]](&"READYUP_MORE_PLAYERS");
			[[level.ex_PrecacheString]](&"READYUP_HOWTO");
			[[level.ex_PrecacheString]](&"READYUP_READY");
			[[level.ex_PrecacheString]](&"READYUP_NOTREADY");
			[[level.ex_PrecacheString]](&"READYUP_MATCH_BEGINS");
			if(!level.ex_rank_statusicons)
			{
				[[level.ex_PrecacheStatusIcon]]("hud_status_ready");
				[[level.ex_PrecacheStatusIcon]]("hud_status_notready");
			}

			// [ 0: ready-up init, 1: waiting for players, 2: ready-up done ], 3: in grace period, 4: grace period done
			level.ex_readyup_status = 0;
			level.ex_readyup_players = [];

			level thread onPlayerConnected();
			level thread levelReadyup();
		}
	}
	else
	{
		if(level.ex_readyup == 2 && level.ex_readyup_graceperiod)
		{
			// 0: ready-up init, 1: waiting for players, 2: ready-up done, [ 3: in grace period, 4: grace period done ]
			level.ex_readyup_status = 3;

			level thread levelGracePeriod();
		}
		else level.ex_readyup_status = 2;
	}
}

onPlayerConnected()
{
	level endon("readyup_done");

	for(;;)
	{
		level waittill("connected", player);

		lpselfnum = player getEntityNumber();
		level.ex_readyup_players[lpselfnum] = spawnstruct();
		level.ex_readyup_players[lpselfnum].name = player.name;
		level.ex_readyup_players[lpselfnum].status = "spectating";

		player thread onPlayerSpawned(lpselfnum);
		player thread onPlayerDisconnected(lpselfnum);
		player thread onJoinedSpectators(lpselfnum);
	}
}

onPlayerSpawned(lpselfnum)
{
	level endon("readyup_done");
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		if(!level.ex_rank_statusicons) self.statusicon = "hud_status_notready";
		level.ex_readyup_players[lpselfnum].status = "notready";
		self thread playerReadyup(lpselfnum);
	}
}

onPlayerDisconnected(lpselfnum)
{
	level endon("readyup_done");

	self waittill("disconnect");
	level.ex_readyup_players[lpselfnum].status = "disconnected";
}

onJoinedSpectators(lpselfnum)
{
	level endon("readyup_done");
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");
		self notify("readyup_end");
		self.statusicon = "";
		level.ex_readyup_players[lpselfnum].status = "spectating";
	}
}

levelGTSDelay()
{
	level endon("ex_gameover");

	level.ex_readyup_status = 1;

	level.ruhud_status1 = newHudElem();
	level.ruhud_status1.archived = false;
	level.ruhud_status1.horzAlign = "fullscreen";
	level.ruhud_status1.vertAlign = "fullscreen";
	level.ruhud_status1.alignX = "center";
	level.ruhud_status1.alignY = "middle";
	level.ruhud_status1.x = 320;
	level.ruhud_status1.y = 100;
	level.ruhud_status1.fontScale = 2;
	level.ruhud_status1.color = (0,1,0);
	level.ruhud_status1.label = &"READYUP_WAITING_FOR_PLAYERS";

	for(;;)
	{
		wait( [[level.ex_fpstime]](1) );

		players = level.players;
		if(players.size == 0) continue;

		playercount = 0;
		for(i = 0; i < players.size; i++)
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator") playercount++;
		if(playercount >= 2) break;
	}

	while(isDefined(level.adding_dbots) || (level.ex_mbot && level.ex_mbot_init)) wait( [[level.ex_fpstime]](1) );

	game["readyup_done"] = true;
	level notify("readyup_done");

	level.ruhud_status1.color = (1,1,1);
	level.ruhud_status1.label = &"READYUP_MATCH_BEGINS";
	level.ruhud_status1 setTimer(5);
	wait( [[level.ex_fpstime]](3) );
	level notify("restarting");
	wait( [[level.ex_fpstime]](2) );

	if(isDefined(level.ruhud_status1)) level.ruhud_status1 destroy();

	restartMap();
}

levelReadyup()
{
	level endon("ex_gameover");

	level.ruhud_readyup = newHudElem();
	level.ruhud_readyup.archived = false;
	level.ruhud_readyup.horzAlign = "fullscreen";
	level.ruhud_readyup.vertAlign = "fullscreen";
	level.ruhud_readyup.alignX = "center";
	level.ruhud_readyup.alignY = "middle";
	level.ruhud_readyup.x = 320;
	level.ruhud_readyup.y = 100;
	level.ruhud_readyup.fontScale = 2;
	level.ruhud_readyup.color = (0,1,0);
	level.ruhud_readyup.label = &"READYUP_READYUP";

	level.ruhud_status1 = newHudElem();
	level.ruhud_status1.archived = false;
	level.ruhud_status1.horzAlign = "fullscreen";
	level.ruhud_status1.vertAlign = "fullscreen";
	level.ruhud_status1.alignX = "right";
	level.ruhud_status1.alignY = "middle";
	level.ruhud_status1.x = 300;
	level.ruhud_status1.y = 120;
	level.ruhud_status1.fontScale = 1.3;
	level.ruhud_status1.color = (1,1,1);
	level.ruhud_status1 setText(&"READYUP_WAITING_FOR");

	level.ruhud_status2 = newHudElem();
	level.ruhud_status2.archived = false;
	level.ruhud_status2.horzAlign = "fullscreen";
	level.ruhud_status2.vertAlign = "fullscreen";
	level.ruhud_status2.alignX = "center";
	level.ruhud_status2.alignY = "middle";
	level.ruhud_status2.x = 320;
	level.ruhud_status2.y = 120;
	level.ruhud_status2.fontScale = 2;
	level.ruhud_status2.color = (1,0,0);
	level.ruhud_status2 setValue(2); // xx

	level.ruhud_status3 = newHudElem();
	level.ruhud_status3.archived = false;
	level.ruhud_status3.horzAlign = "fullscreen";
	level.ruhud_status3.vertAlign = "fullscreen";
	level.ruhud_status3.alignX = "left";
	level.ruhud_status3.alignY = "middle";
	level.ruhud_status3.x = 340;
	level.ruhud_status3.y = 120;
	level.ruhud_status3.fontScale = 1.3;
	level.ruhud_status3.color = (1,1,1);
	level.ruhud_status3 setText(&"READYUP_MORE_PLAYERS");

	level.ruhud_timer = newHudElem();
	level.ruhud_timer.archived = false;
	level.ruhud_timer.horzAlign = "fullscreen";
	level.ruhud_timer.vertAlign = "fullscreen";
	level.ruhud_timer.alignX = "center";
	level.ruhud_timer.alignY = "middle";
	level.ruhud_timer.x = 320;
	level.ruhud_timer.y = 140;
	level.ruhud_timer.fontScale = 2;
	level.ruhud_timer.color = (1,1,1);
	level.ruhud_timer.alpha = 0;

	timer = 0;
	timer_started = false;
	level.ex_readyup_status = 1;

	while(level.ex_readyup_status != 2)
	{
		wait( [[level.ex_fpstime]](1) );

		if(level.ex_readyup_timer && timer_started)
		{
			timer++;
			if(timer >= level.ex_readyup_timer) level.ex_readyup_status = 2;
		}

		players = level.players;
		if(players.size == 0) continue;

		ready = 0;
		ready_allies = 0;
		ready_axis = 0;
		notready = 0;
		notready_allies = 0;
		notready_axis = 0;

		if(level.ex_teamplay) waitingfor = level.ex_readyup_minteam * 2;
			else waitingfor = level.ex_readyup_min;

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			lpselfnum = player getEntityNumber();
			if(isDefined(level.ex_readyup_players[lpselfnum]))
			{
				if(level.ex_readyup_players[lpselfnum].status == "ready")
				{
					ready++;
					if(level.ex_teamplay && isDefined(player.pers["team"]))
					{
						if(player.pers["team"] == "allies") ready_allies++;
							else if(player.pers["team"] == "axis") ready_axis++;
					}
				}
				else if(level.ex_readyup_players[lpselfnum].status == "notready")
				{
					notready++;
					if(level.ex_teamplay && isDefined(player.pers["team"]))
					{
						if(player.pers["team"] == "allies") notready_allies++;
							else if(player.pers["team"] == "axis") notready_axis++;
					}
				}
			}
		}

		if((ready + notready) > 0)
		{
			// At least one player spawned
			timer_start = false;

			if(level.ex_teamplay)
			{
				// If team based match, a minimum number of players per team must be ready
				if(ready_allies < level.ex_readyup_minteam) waitingfor_allies = level.ex_readyup_minteam - ready_allies;
					else waitingfor_allies = 0;
				if(ready_axis < level.ex_readyup_minteam) waitingfor_axis = level.ex_readyup_minteam - ready_axis;
					else waitingfor_axis = 0;
				waitingfor = waitingfor_allies + waitingfor_axis;
				if(waitingfor == 0) level.ex_readyup_status = 2;

				// Check if timer is needed
				if(level.ex_readyup_timer)
				{
					// Mode 2: start timer if the minimum number of players per team spawned (ready or not)
					if(level.ex_readyup_timermode == 2)
					{
						if( ((ready_allies + notready_allies) >= level.ex_readyup_minteam) && ((ready_axis + notready_axis) >= level.ex_readyup_minteam) )
							timer_start = true;
					}
					// Mode 1: start timer if at least one player per team spawned (ready or not)
					else if(level.ex_readyup_timermode == 1)
					{
						if( ((ready_allies + notready_allies) >= 1) && ((ready_axis + notready_axis) >= 1) )
							timer_start = true;
					}
					// Mode 0: start timer if at least one player spawned (any team; ready or not)
					else
					{
						if( (ready + notready) >= 1 )
							timer_start = true;
					}
				}
			}
			else
			{
				// If not team based match, a minimum number of players must be ready
				if(ready < level.ex_readyup_min) waitingfor = level.ex_readyup_min - ready;
					else waitingfor = 0;
				if(waitingfor == 0) level.ex_readyup_status = 2;

				// If timer enabled, start it
				if(level.ex_readyup_timer) timer_start = true;
			}

			// Start timer if enabled, needed and not started yet
			if(level.ex_readyup_timer && timer_start && !timer_started)
			{
				level.ruhud_timer setTimer(level.ex_readyup_timer);
				level.ruhud_timer.alpha = 1;
				timer = 0;
				timer_started = true;
			}
		}
		else
		{
			// Players left. Stop timer if enabled and started
			if(level.ex_readyup_timer && timer_started)
			{
				level.ruhud_timer.alpha = 0;
				timer = 0;
				timer_started = false;
			}
		}

		level.ruhud_status2 setValue(waitingfor);
	}

	while(isDefined(level.adding_dbots) || (level.ex_mbot && level.ex_mbot_init)) wait( [[level.ex_fpstime]](1) );

	game["readyup_done"] = true;
	level notify("readyup_done");

	if(isdefined(level.ruhud_status1)) level.ruhud_status1 destroy();
	if(isdefined(level.ruhud_status2)) level.ruhud_status2 destroy();
	if(isdefined(level.ruhud_status3)) level.ruhud_status3 destroy();

	// Set spawn flag for all players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		lpselfnum = player getEntityNumber();
		if(isDefined(level.ex_readyup_players[lpselfnum]))
		{
			if(level.ex_readyup_players[lpselfnum].status == "ready")
			{
				player.pers["readyup_spawnticket"] = 1;
			}
			else if(level.ex_readyup_players[lpselfnum].status == "notready")
			{
				switch(level.ex_readyup_ticketing)
				{
					case 0:
						player.pers["readyup_spawnticket"] = 1;
						break;
					case 1:
						player.pers["readyup_spawnticket"] = undefined;
						player thread moveToSpectators();
						break;
					case 2:
						player.pers["readyup_spawnticket"] = undefined;
						player thread moveToSpectators();
						break;
				}
			}
		}
	}

	// Announce match start and restart map
	level.ruhud_timer.label = &"READYUP_MATCH_BEGINS";
	level.ruhud_timer setTimer(5);
	wait( [[level.ex_fpstime]](3) );
	level notify("restarting");
	wait( [[level.ex_fpstime]](2) );

	if(isdefined(level.ruhud_readyup)) level.ruhud_readyup destroy();
	if(isdefined(level.ruhud_timer)) level.ruhud_timer destroy();

	restartMap();
}

playerReadyup(lpselfnum)
{
	level endon("ex_gameover");
	self endon("disconnect");

	self notify("readyup_end");
	waittillframeend;
	self endon("readyup_end");

	/*
	if(getsubstr(self.name, 0, 3) == "bot")
	{
		if(self.name != "bot1")
		{
			level.ex_readyup_players[lpselfnum].status = "ready";
			if(!level.ex_rank_statusicons) self.statusicon = "hud_status_ready";
			return;
		}
	}
	*/

	self.ruhud_status = newClientHudElem(self);
	self.ruhud_status.archived = false;
	self.ruhud_status.horzAlign = "fullscreen";
	self.ruhud_status.vertAlign = "fullscreen";
	self.ruhud_status.alignX = "center";
	self.ruhud_status.alignY = "middle";
	self.ruhud_status.x = 320;
	self.ruhud_status.y = 430;
	self.ruhud_status.fontScale = 1.3;
	self.ruhud_status.color = (1,1,1);
	self.ruhud_status setText(&"READYUP_NOTREADY");

	self.ruhud_howto = newClientHudElem(self);
	self.ruhud_howto.archived = false;
	self.ruhud_howto.horzAlign = "fullscreen";
	self.ruhud_howto.vertAlign = "fullscreen";
	self.ruhud_howto.alignX = "center";
	self.ruhud_howto.alignY = "middle";
	self.ruhud_howto.x = 320;
	self.ruhud_howto.y = 445;
	self.ruhud_howto.fontScale = 1.0;
	self.ruhud_howto.color = (1,1,1);
	self.ruhud_howto setText(&"READYUP_HOWTO");

	while(level.ex_readyup_status != 2)
	{
		if(isPlayer(self) && self useButtonPressed())
		{
			if(level.ex_readyup_players[lpselfnum].status == "notready")
			{
				level.ex_readyup_players[lpselfnum].status = "ready";
				if(!level.ex_rank_statusicons) self.statusicon = "hud_status_ready";
				if(isDefined(self.ruhud_status)) self.ruhud_status setText(&"READYUP_READY");
			}
			else if(level.ex_readyup_players[lpselfnum].status == "ready")
			{
				level.ex_readyup_players[lpselfnum].status = "notready";
				if(!level.ex_rank_statusicons) self.statusicon = "hud_status_notready";
				if(isDefined(self.ruhud_status)) self.ruhud_status setText(&"READYUP_NOTREADY");
			}
			while(isPlayer(self) && self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		}
		else wait( [[level.ex_fpstime]](0.05) );
	}

	if(isDefined(self.ruhud_status)) self.ruhud_status destroy();
	if(isDefined(self.ruhud_howto)) self.ruhud_howto destroy();
}

levelGracePeriod()
{
	barsize = 300;

	level.ruhud_back = newHudElem();
	level.ruhud_back.archived = false;
	level.ruhud_back.sort = 1;
	level.ruhud_back.horzAlign = "fullscreen";
	level.ruhud_back.vertAlign = "fullscreen";
	level.ruhud_back.alignX = "center";
	level.ruhud_back.alignY = "middle";
	level.ruhud_back.x = 320;
	level.ruhud_back.y = 10;
	level.ruhud_back.alpha = 0.3;
	level.ruhud_back.color = (0.2, 0.2, 0.2);
	level.ruhud_back setShader("white", barsize + 4, 13);

	level.ruhud_front = newHudElem();
	level.ruhud_front.archived = false;
	level.ruhud_front.sort = 2;
	level.ruhud_front.horzAlign = "fullscreen";
	level.ruhud_front.vertAlign = "fullscreen";
	level.ruhud_front.alignX = "center";
	level.ruhud_front.alignY = "middle";
	level.ruhud_front.x = 320;
	level.ruhud_front.y = 10;
	level.ruhud_front.color = (0, 1, 0);
	level.ruhud_front.alpha = 0.5;
	level.ruhud_front setShader("white", barsize, 11);

	level.ruhud_text = newHudElem();
	level.ruhud_text.archived = false;
	level.ruhud_text.sort = 3;
	level.ruhud_text.horzAlign = "fullscreen";
	level.ruhud_text.vertAlign = "fullscreen";
	level.ruhud_text.alignX = "center";
	level.ruhud_text.alignY = "middle";
	level.ruhud_text.x = 320;
	level.ruhud_text.y = 10;
	level.ruhud_text.alpha = 0.8;
	level.ruhud_text.color = (1, 1, 1);
	level.ruhud_text setText(&"READYUP_GRACE_PERIOD");

	level.ex_readyup_graceinit = true;
	timer = level.ex_readyup_graceperiod;
	oldbarsize = barsize;

	while(level.ex_readyup_status != 4)
	{
		timer--;
		if(isdefined(level.ruhud_front))
		{
			perc = timer / level.ex_readyup_graceperiod;
			size = int((barsize * perc) + 0.5);
			if(size < 1) size = 1;
			if(oldbarsize != size)
			{
				level.ruhud_front scaleOverTime(1, size, 11);
				oldbarsize = size;
			}
		}

		wait( [[level.ex_fpstime]](1) );
		if(timer == 0) level.ex_readyup_status = 4;
	}

	if(isDefined(level.ruhud_back)) level.ruhud_back destroy();
	if(isDefined(level.ruhud_front)) level.ruhud_front destroy();
	if(isDefined(level.ruhud_text)) level.ruhud_text destroy();
}

moveToSpectators()
{
	self notify("kill_thread");
	self notify("killed_player");
	wait( [[level.ex_fpstime]](0.1) );
	self.pers["team"] = "spectator";
	self.sessionteam = "spectator";
	self thread extreme\_ex_clientcontrol::clearWeapons();
	self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();
	self thread extreme\_ex_spawn::spawnspectator();
}

waitForNextRound()
{
	self.ruhud_status = newClientHudElem(self);
	self.ruhud_status.archived = false;
	self.ruhud_status.horzAlign = "fullscreen";
	self.ruhud_status.vertAlign = "fullscreen";
	self.ruhud_status.alignX = "center";
	self.ruhud_status.alignY = "middle";
	self.ruhud_status.x = 320;
	self.ruhud_status.y = 100;
	self.ruhud_status.fontScale = 1.3;
	self.ruhud_status.color = (1,1,1);
	self.ruhud_status setText(&"READYUP_WAIT_FOR_NEXT_ROUND");
}

restartMap()
{
	level notify("restarting");
	level.starttime = getTime();
	map_restart(true);
}
