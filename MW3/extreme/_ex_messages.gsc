
init()
{
	if(level.ex_motdrotate) [[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);

	if(level.ex_svrmsg)
	{
		level.ex_servermessages = [];
		level.ex_servermessages[0] = &"CUSTOM_SERVER_MESSAGE_1";
		level.ex_servermessages[1] = &"CUSTOM_SERVER_MESSAGE_2";
		level.ex_servermessages[2] = &"CUSTOM_SERVER_MESSAGE_3";
		level.ex_servermessages[3] = &"CUSTOM_SERVER_MESSAGE_4";
		level.ex_servermessages[4] = &"CUSTOM_SERVER_MESSAGE_5";
		level.ex_servermessages[5] = &"CUSTOM_SERVER_MESSAGE_6";
		level.ex_servermessages[6] = &"CUSTOM_SERVER_MESSAGE_7";
		level.ex_servermessages[7] = &"CUSTOM_SERVER_MESSAGE_8";
		level.ex_servermessages[8] = &"CUSTOM_SERVER_MESSAGE_9";
		level.ex_servermessages[9] = &"CUSTOM_SERVER_MESSAGE_10";
		level.ex_servermessages[10] = &"CUSTOM_SERVER_MESSAGE_11";
		level.ex_servermessages[11] = &"CUSTOM_SERVER_MESSAGE_12";
		level.ex_servermessages[12] = &"CUSTOM_SERVER_MESSAGE_13";
		level.ex_servermessages[13] = &"CUSTOM_SERVER_MESSAGE_14";
		level.ex_servermessages[14] = &"CUSTOM_SERVER_MESSAGE_15";
		level.ex_servermessages[15] = &"CUSTOM_SERVER_MESSAGE_16";
		level.ex_servermessages[16] = &"CUSTOM_SERVER_MESSAGE_17";
		level.ex_servermessages[17] = &"CUSTOM_SERVER_MESSAGE_18";
		level.ex_servermessages[18] = &"CUSTOM_SERVER_MESSAGE_19";
		level.ex_servermessages[19] = &"CUSTOM_SERVER_MESSAGE_20";

		if(level.ex_svrmsg_loop)
			[[level.ex_registerLevelEvent]]("onRandom", ::serverMessages, true, level.ex_svrmsg_delay_main, level.ex_svrmsg_delay_main, level.ex_svrmsg_delay_main / 2);
		else
			[[level.ex_registerLevelEvent]]("onRandom", ::serverMessages, true, level.ex_svrmsg_delay_main);
	}
}

onPlayerConnected()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("start_motd_rotation");
		self.ex_motd_rotate = 1;

		self thread motdStartRotation();

		self waittill("stop_motd_rotation");
		self.ex_motd_rotate = 0;
	}
}

motdStartRotation()
{
	self endon("disconnect");

	while(self.ex_motd_rotate)
	{
		for(i = 0; i < level.rotmotd.size; i++)
		{
			msg = level.rotmotd[i];
			self setClientCvar("ui_motd", msg);
			wait( [[level.ex_fpstime]](level.ex_motdrotdelay) );
		}
	}
}

welcomeMsg()
{
	self endon("kill_thread");

	if(isDefined(self.pers["welcdone"])) return;

	self.pers["welcdone"] = true;

	if(!level.ex_pwelcome) return;
		
	// welcome message line 1
	self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_ALL_MESSAGE_1");
	wait( [[level.ex_fpstime]](level.ex_pweldelay) );

	// welcome message line 2
	self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_ALL_MESSAGE_2");
	wait( [[level.ex_fpstime]](level.ex_pweldelay) );

	// voting status
	if(getCvarInt("g_allowvote") == 1)
	{
		if(level.ex_clanvoting)
		{
			if(isDefined(self.ex_name) && level.ex_clvote[self.ex_clid]) self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_VOTE_ALLOWED");
				else self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_VOTE_NOT_ALLOWED");
		}
		else self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_VOTE_ALLOWED");
	}
	else self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_VOTE_NOT_ALLOWED");

	if(level.ex_clanwelcome && isDefined(self.ex_name)) self thread clanWelcome();
	else
	{
		// welcome message - custom 1
		if(level.ex_pwelmsg >= 1)
		{
			wait( [[level.ex_fpstime]](level.ex_pweldelay) );
			self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_NONCLAN_MESSAGE_1");
		}
		else return;

		// welcome message - custom 2
		if(level.ex_pwelmsg >= 2)
		{
			wait( [[level.ex_fpstime]](level.ex_pweldelay) );
			self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_NONCLAN_MESSAGE_2");
		}
		else return;

		// welcome message - custom 3
		if(level.ex_pwelmsg == 3)
		{
			wait( [[level.ex_fpstime]](level.ex_pweldelay) );
			self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_NONCLAN_MESSAGE_3");
		}
		else return;
	}
}

clanWelcome()
{
	self endon("kill_thread");

	switch(self.ex_clid)
	{
		case 1:
		self thread clan1msgs();
		break;

		case 2:
		self thread clan2msgs();
		break;

		case 3:
		self thread clan3msgs();
		break;

		case 4:
		self thread clan4msgs();
		break;
	}
}

clan1msgs()
{
	self endon("kill_thread");

	// clan message - custom 1
	if(level.ex_clan1msg >= 1)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN1_MESSAGE_1");
	}
	else return;

	// clan message - custom 2
	if(level.ex_clan1msg >= 2)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN1_MESSAGE_2");
	}
	else return;

	// clan message - custom 3
	if(level.ex_clan1msg == 3)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN1_MESSAGE_3");
	}
	else return;	
}

clan2msgs()
{
	self endon("kill_thread");

	// clan message - custom 1
	if(level.ex_clan2msg >= 1)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN2_MESSAGE_1");
	}
	else return;

	// clan message - custom 2
	if(level.ex_clan2msg >= 2)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN2_MESSAGE_2");
	}
	else return;

	// clan message - custom 3
	if(level.ex_clan2msg == 3)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN2_MESSAGE_3");
	}
	else return;	
}

clan3msgs()
{
	self endon("kill_thread");

	// clan message - custom 1
	if(level.ex_clan3msg >= 1)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN3_MESSAGE_1");
	}
	else return;

	// clan message - custom 2
	if(level.ex_clan3msg >= 2)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN3_MESSAGE_2");
	}
	else return;

	// clan message - custom 3
	if(level.ex_clan3msg == 3)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN3_MESSAGE_3");
	}
	else return;	
}

clan4msgs()
{
	self endon("kill_thread");

	// clan message - custom 1
	if(level.ex_clan4msg >= 1)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN4_MESSAGE_1");
	}
	else return;

	// clan message - custom 2
	if(level.ex_clan4msg >= 2)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN4_MESSAGE_2");
	}
	else return;

	// clan message - custom 3
	if(level.ex_clan4msg == 3)
	{
		wait( [[level.ex_fpstime]](level.ex_clandelay) );
		self thread extreme\_ex_utils::ex_hud_announce(&"CUSTOM_CLAN4_MESSAGE_3");
	}
	else return;	
}

goodluckMsg()
{
	self endon("kill_thread");

	if(!isdefined(self.pers["team"])) return;

	// if using the readyup system, no need to hear any intro sounds again
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	// on round based games, no need to hear any intro sounds every round
	if(level.ex_roundbased && game["roundnumber"] > 0 && isDefined(self.pers["team"])) return;

	stp = undefined;
	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self))
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
				case "american":
				stp = "us_welcome";
				break;

				case "british":
				stp = "uk_welcome";
				break;

				case "russian":
				stp = "ru_welcome";
				break;
			}
		}
		else if(self.pers["team"] == "axis")
		{
			switch(game["axis"])
			{
				case "german":
				stp = "ge_welcome";
				break;
			}
		}

		if(isdefined(stp))
		{
			self playLocalSound(stp);
			self.ex_glplay = true;
		}
	}
}

serverMessages(eventID)
{
	level endon("ex_gameover");

	for(i = 0; i < level.ex_svrmsg; i++)
	{
		iprintln(level.ex_servermessages[i]);
		wait( [[level.ex_fpstime]](level.ex_svrmsg_delay_msg) );
	}
	
	if(level.ex_svrmsg_info >= 1) extreme\_ex_maps::DisplayMapRotation();

	if(level.ex_svrmsg_loop) [[level.ex_enableLevelEvent]]("onRandom", eventID);
}

spectatorMessages()
{
	level endon("ex_gameover");
	self endon("disconnect");
	self endon("spawned");

	specmsg = [];
	specmsg[0] = &"CUSTOM_SPECTATOR_MESSAGE_1";
	specmsg[1] = &"CUSTOM_SPECTATOR_MESSAGE_2";
	specmsg[2] = &"CUSTOM_SPECTATOR_MESSAGE_3";
	specmsg[3] = &"CUSTOM_SPECTATOR_MESSAGE_4";
	specmsg[4] = &"CUSTOM_SPECTATOR_MESSAGE_5";
	specmsg[5] = &"CUSTOM_SPECTATOR_MESSAGE_6";
	specmsg[6] = &"CUSTOM_SPECTATOR_MESSAGE_7";
	specmsg[7] = &"CUSTOM_SPECTATOR_MESSAGE_8";
	specmsg[8] = &"CUSTOM_SPECTATOR_MESSAGE_9";
	specmsg[9] = &"CUSTOM_SPECTATOR_MESSAGE_10";

	while(isPlayer(self) && self.pers["team"] == "spectator")
	{
		for(i = 0; i < level.ex_specmsg; i++)
		{
			self iprintln(specmsg[i]);
			wait( [[level.ex_fpstime]](level.ex_specmsg_delay_msg) );
		}

		wait( [[level.ex_fpstime]](level.ex_specmsg_delay_main / 2) );
	}
}
