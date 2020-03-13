
init()
{
	switch(game["allies"])
	{
		case "american": game["hudicon_allies"] = "hudicon_american"; break;
		case "british": game["hudicon_allies"] = "hudicon_british"; break;
		case "russian": game["hudicon_allies"] = "hudicon_russian"; break;
	}
	
	assert(game["axis"] == "german");
	game["hudicon_axis"] = "hudicon_german";

	precacheShader(game["hudicon_allies"]);
	precacheShader(game["hudicon_axis"]);

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
	level thread onUpdateTeamScoreHUD();
}

onPlayerSpawned()
{
	self endon("disconnect");

	if(!isdefined(self.hud_teamicon))
	{
		self.hud_teamicon = newClientHudElem(self);
		self.hud_teamicon.horzAlign = "left";
		self.hud_teamicon.vertAlign = "top";
		self.hud_teamicon.x = 280;
		self.hud_teamicon.y = 463;
		self.hud_teamicon.archived = false;
	}

	if(!isdefined(self.hud_enemyicon))
	{
		self.hud_enemyicon = newClientHudElem(self);
		self.hud_enemyicon.horzAlign = "left";
		self.hud_enemyicon.vertAlign = "top";
		self.hud_enemyicon.x = 390;
		self.hud_enemyicon.y = 463;
		self.hud_enemyicon.archived = false;
	}

	if(!isdefined(self.hud_teamscore))
	{
		self.hud_teamscore = newClientHudElem(self);
		self.hud_teamscore.horzAlign = "left";
		self.hud_teamscore.vertAlign = "top";
		self.hud_teamscore.x = 284;
		self.hud_teamscore.y = 443;
		self.hud_teamscore.font = "default";
		self.hud_teamscore.fontscale = 1.5;
		self.hud_teamscore.archived = false;
	}

	if(!isdefined(self.hud_enemyscore))
	{
		self.hud_enemyscore = newClientHudElem(self);
		self.hud_enemyscore.horzAlign = "left";
		self.hud_enemyscore.vertAlign = "top";
		self.hud_enemyscore.x = 394;
		self.hud_enemyscore.y = 443;
		self.hud_enemyscore.font = "default";
		self.hud_enemyscore.fontscale = 1.5;
		self.hud_enemyscore.archived = false;
	}

	if(self.pers["team"] == "allies")
	{
		self.hud_teamicon setShader(game["hudicon_allies"], 16, 16);
		self.hud_enemyicon setShader(game["hudicon_axis"], 16, 16);
	}
	else if(self.pers["team"] == "axis")
	{
		self.hud_teamicon setShader(game["hudicon_axis"], 16, 16);
		self.hud_enemyicon setShader(game["hudicon_allies"], 16, 16);
	}

	self thread updatePlayerScoreHUD();
}

onJoinedTeam()
{
	self thread removePlayerHUD();
}

onJoinedSpectators()
{
	self thread removePlayerHUD();
}

onUpdateTeamScoreHUD()
{
	while(!level.ex_gameover)
	{
		self waittill("update_teamscore_hud");
		level thread updateTeamScoreHUD();
	}
}

updatePlayerScoreHUD()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");
	
	if(self.pers["team"] == "allies")
	{
		self.hud_teamscore setValue(alliedscore);
		self.hud_enemyscore setValue(axisscore);
	}
	else if(self.pers["team"] == "axis")
	{
		self.hud_teamscore setValue(axisscore);
		self.hud_enemyscore setValue(alliedscore);
	}
}

updateTeamScoreHUD()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if(isdefined(player.hud_teamscore) && isdefined(player.hud_enemyscore))
		{
			if(player.pers["team"] == "allies")
			{
				player.hud_teamscore setValue(alliedscore);
				player.hud_enemyscore setValue(axisscore);
			}
			else if(player.pers["team"] == "axis")
			{
				player.hud_teamscore setValue(axisscore);
				player.hud_enemyscore setValue(alliedscore);
			}
		}
	}
}

removePlayerHUD()
{
	if(isDefined(self.hud_teamicon)) self.hud_teamicon destroy();
	if(isDefined(self.hud_enemyicon)) self.hud_enemyicon destroy();
	if(isDefined(self.hud_teamscore)) self.hud_teamscore destroy();
	if(isDefined(self.hud_enemyscore)) self.hud_enemyscore destroy();
}
