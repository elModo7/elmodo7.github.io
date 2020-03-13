
init()
{
	if(!level.ex_inactive_plyr && !level.ex_inactive_spec) return;
	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	level endon("ex_gameover");

	players = level.players;
	if(!players.size) return;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		// Inactivity actions depending on game status
		// 0 = no action
		// 1 = warn for moving to spectators for not moving
		// 2 = warn for moving to spectators for staying dead
		// 3 = warn for kicking from server for staying spectator
		// 4 = play sound to let player know he woke up just in time
		// 5 = move to spectators
		// 6 = disconnect from server with personalized message
		inactive_action = 0;

		if(player.pers["dontkick"] == true) continue;

		if(level.ex_inactive_plyr && player.sessionteam != "spectator" && player.sessionstate == "playing")
		{
			if(!isDefined(player.inactive_plyr_time)) player.inactive_plyr_time = level.ex_inactive_plyr_time * 60;
			if( isDefined(player.inactive_dead_time) && player.inactive_dead_time < 30) inactive_action = 4;
			player.inactive_dead_time = undefined;
			player.inactive_spec_time = undefined;

			if(isDefined(player.inactive_origin))
			{
				if(player.inactive_origin == player.origin)
				{
					player.inactive_plyr_time--;
					if(player.inactive_plyr_time == 30 || player.inactive_plyr_time == 20 || player.inactive_plyr_time == 10) inactive_action = 1;
						else if(player.inactive_plyr_time < 1) inactive_action = 5;
				}
				else
				{
					if(player.inactive_plyr_time < 30) inactive_action = 4;
					player.inactive_origin = player.origin;
					player.inactive_plyr_time = undefined;
				}
			}
			else player.inactive_origin = player.origin;
		}
		else if(level.ex_inactive_dead && player.sessionteam != "spectator" && (player.sessionstate == "dead" || player.sessionstate == "spectator"))
		{
			if(isDefined(player.WaitingOnNeutralize) || isDefined(player.spawned)) continue;

			if(!isDefined(player.inactive_dead_time)) player.inactive_dead_time = level.ex_inactive_dead_time * 60;
			player.inactive_plyr_time = undefined;
			player.inactive_spec_time = undefined;

			player.inactive_dead_time--;
			if(player.inactive_dead_time == 30 || player.inactive_dead_time == 20 || player.inactive_dead_time == 10) inactive_action = 2;
				else if(player.inactive_dead_time < 1) inactive_action = 5;
		}
		else if(level.ex_inactive_spec && player.sessionteam == "spectator" && player.sessionstate == "spectator")
		{
			if(!isDefined(player.inactive_spec_time)) player.inactive_spec_time = level.ex_inactive_spec_time * 60;
			player.inactive_plyr_time = undefined;
			player.inactive_dead_time = undefined;

			player.inactive_spec_time--;
			if(player.inactive_spec_time == 30 || player.inactive_spec_time == 20 || player.inactive_spec_time == 10) inactive_action = 3;
				else if(player.inactive_spec_time < 1) inactive_action = 6;
		}

		if(!inactive_action) continue;

		switch(inactive_action)
		{
			case 1:
				if(level.ex_inactive_msg)
				{
					iprintln(&"CLIENTCONTROL_INACTIVITY_WARN_AMOVE", [[level.ex_pname]](player));
					iprintln(&"CLIENTCONTROL_INACTIVITY_MOVE_TIMEOUT", player.inactive_plyr_time);
				}
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_WARN_PMOVE");
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_MOVE_TIMEOUT", player.inactive_plyr_time);
				player playLocalSound("move_it_" + player.inactive_plyr_time);
				break;
			case 2:
				if(level.ex_inactive_msg)
				{
					iprintln(&"CLIENTCONTROL_INACTIVITY_WARN_AMOVE", [[level.ex_pname]](player));
					iprintln(&"CLIENTCONTROL_INACTIVITY_DEAD_TIMEOUT", player.inactive_dead_time);
				}
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_WARN_PMOVE");
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_DEAD_TIMEOUT", player.inactive_dead_time);
				player playLocalSound("move_it_" + player.inactive_dead_time);
				break;
			case 3:
				if(level.ex_inactive_msg)
				{
					iprintln(&"CLIENTCONTROL_INACTIVITY_WARN_AKICK", [[level.ex_pname]](player));
					iprintln(&"CLIENTCONTROL_INACTIVITY_SPEC_TIMEOUT", player.inactive_spec_time);
				}
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_WARN_PKICK");
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_SPEC_TIMEOUT", player.inactive_spec_time);
				player playLocalSound("US_1_rank_private");
				break;
			case 4:
				if(level.ex_inactive_msg)
					iprintln(&"CLIENTCONTROL_INACTIVITY_WOKEUP", [[level.ex_pname]](player));
				player playLocalSound("US_mp_rsp_tooklongenough");
				break;
			case 5:
				iprintln(&"CLIENTCONTROL_INACTIVITY_ACTION_AMOVE", [[level.ex_pname]](player));
				player iprintlnbold(&"CLIENTCONTROL_INACTIVITY_ACTION_PMOVE");
				player thread spawnAsSpectator();
				break;
			case 6:
				iprintln(&"CLIENTCONTROL_INACTIVITY_ACTION_AKICK", [[level.ex_pname]](player));
				player setClientCvar("com_errorTitle", "eXtreme+ Message");
				player setClientCvar("com_errorMessage", "You have been disconnected due to inactivity!\nYou can reconnect to our server after you finished doing whatever you were doing prior to the disconnection.");
				wait( [[level.ex_fpstime]](1) );
				player thread extreme\_ex_utils::execClientCommand("disconnect");
				break;
		}
	}
}

spawnAsSpectator()
{
	self notify("kill_thread");
	wait( [[level.ex_fpstime]](0.05) );

	// drop flag
	self extreme\_ex_utils::dropTheFlag(false);

	self.pers["team"] = "spectator";
	self.sessionteam = "spectator";
	self thread extreme\_ex_clientcontrol::clearWeapons();
	self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();
	self thread extreme\_ex_spawn::spawnspectator();
}
