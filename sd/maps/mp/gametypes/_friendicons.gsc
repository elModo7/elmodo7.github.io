
init()
{
	// Draws a team icon over teammates
	// dvar scr_drawfriend and level.drawfriend set in _ex_gtcommon.gsc

	if(level.ex_currentgt == "hm") return;

	switch(game["allies"])
	{
	case "american":
		game["headicon_allies"] = "headicon_american";
		precacheHeadIcon(game["headicon_allies"]);
		break;

	case "british":
		game["headicon_allies"] = "headicon_british";
		precacheHeadIcon(game["headicon_allies"]);
		break;

	case "russian":
		game["headicon_allies"] = "headicon_russian";
		precacheHeadIcon(game["headicon_allies"]);
		break;
	}

	assert(game["axis"] == "german");
	game["headicon_axis"] = "headicon_german";
	precacheHeadIcon(game["headicon_axis"]);

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 5);
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
}

onRandom(eventID)
{
	drawfriend = getCvarInt("scr_drawfriend");
	if(level.drawfriend != drawfriend)
	{
		level.drawfriend = drawfriend;
		updateFriendIcons();
	}
}

onPlayerSpawned()
{
	self thread showFriendIcon();
}

onPlayerKilled()
{
	self.headicon = "";
}

showFriendIcon()
{
	if(level.drawfriend)
	{
		if(level.ex_ranksystem)
		{
			self.headicon = self thread extreme\_ex_ranksystem::getHeadIcon();
			self.headiconteam = self.pers["team"];
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self.headicon = game["headicon_allies"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = game["headicon_axis"];
				self.headiconteam = "axis";
			}
		}
	}
	else
	{
		self.headicon = "";
		self.headiconteam = "";
	}
}

updateFriendIcons()
{
	// for all living players, show the appropriate headicon
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(level.drawfriend && isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
		{
			if(level.ex_ranksystem)
			{
				player.headicon = player thread extreme\_ex_ranksystem::getHeadIcon();
				player.headiconteam = player.pers["team"];
			}
			else
			{
				if(player.pers["team"] == "allies")
				{
					player.headicon = game["headicon_allies"];
					player.headiconteam = "allies";
				}
				else
				{
					player.headicon = game["headicon_axis"];
					player.headiconteam = "axis";
				}
			}
		}
		else
		{
			player.headicon = "";
			player.headiconteam = "";
		}
	}
}
