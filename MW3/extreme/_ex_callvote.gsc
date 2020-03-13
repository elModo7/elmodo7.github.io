
init()
{
	// We need level.ex_allowvote to remember the original setting so we know if we
	// have to send the voting vars to the client when they join.
	// level.allowvote in _serversettings.gsc will be synced to what we set here
	allowvote = getCvar("g_allowvote");
	if(allowvote != "")
	{
		level.ex_allowvote = getCvarInt("g_allowvote");
		if(level.ex_allowvote > 1) level.ex_allowvote = 1;
	}
	else level.ex_allowvote = 1;

	voteSetStatus(level.ex_allowvote, false);
	if(!level.ex_callvote_mode || !level.ex_allowvote) return;

	if(level.ex_callvote_delay)
	{
		level.ex_callvote_indelay = true;
		level.ex_callvote_timer = level.ex_callvote_delay;
		level.ex_callvote_state = false;
		voteSetStatus(level.ex_callvote_state, false);
	}
	else
	{
		level.ex_callvote_timer = level.ex_callvote_enable_time;
		level.ex_callvote_state = true;
	}

	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	level endon("ex_gameover");

	if(level.ex_callvote_delay_players)
	{
		players = level.players;
		playercount = players.size;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator")
				playercount--;
		}
		if(playercount < level.ex_callvote_delay_players) return;
		level.ex_callvote_delay_players = 0;
	}

	level.ex_callvote_timer--;
	if(!level.ex_callvote_timer)
	{
		if(isDefined(level.ex_callvote_indelay)) level.ex_callvote_indelay = undefined;
		level.ex_callvote_state = !level.ex_callvote_state;
		voteSetStatus(level.ex_callvote_state, true);
		if(level.ex_callvote_state)
		{
			if(level.ex_callvote_mode == 1) [[level.ex_disableLevelEvent]]("onSecond", eventID);
				else level.ex_callvote_timer = level.ex_callvote_enable_time;
		}
		else
		{
			if(level.ex_callvote_mode == 2) [[level.ex_disableLevelEvent]]("onSecond", eventID);
				else level.ex_callvote_timer = level.ex_callvote_disable_time;
		}
	}
}

voteSetStatus(state, showmsg)
{
	if(state) setCvar("g_allowvote", "1");
		else setCvar("g_allowvote", "0");

	if(showmsg) voteShowStatus();
}

voteShowStatus()
{
	if(isPlayer(self)) global = false;
		else global = true;

	if(!global)
	{
		// for a spawning player, only show message if in delayed callvote mode
		if(isDefined(level.ex_callvote_indelay))
		{
			if(level.ex_callvote_timer == 0)
			{
				if(level.ex_callvote_msg == 2 || level.ex_callvote_msg == 3)
					self iprintln(&"MISC_CALLVOTE_WAITDELAY");
			}
			else
			{
				if(level.ex_callvote_msg == 2 || level.ex_callvote_msg == 3)
					self iprintln(&"MISC_CALLVOTE_DELAY", level.ex_callvote_timer);
			}
		}
	}
	else
	{
		// show messages to all players (depending on msg setting)
		if(level.ex_callvote_mode == 1)
		{
			if(level.ex_callvote_msg == 1 || level.ex_callvote_msg == 3)
				iprintln(&"MISC_CALLVOTE_ENABLED");
			return;
		}

		if(level.ex_callvote_state)
		{
			if(level.ex_callvote_msg == 1 || level.ex_callvote_msg == 3)
				iprintln(&"MISC_CALLVOTE_TMPENABLED", level.ex_callvote_timer);
		}
		else
		{
			if(level.ex_callvote_mode == 2)
			{
				if(level.ex_callvote_msg == 2 || level.ex_callvote_msg == 3)
					iprintln(&"MISC_CALLVOTE_DISABLED");
			}
			else
			{
				if(level.ex_callvote_msg == 2 || level.ex_callvote_msg == 3)
					iprintln(&"MISC_CALLVOTE_TMPDISABLED", level.ex_callvote_timer);
			}
		}
	}
}
