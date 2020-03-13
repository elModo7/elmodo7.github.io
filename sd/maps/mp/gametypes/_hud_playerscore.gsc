
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
	
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
}

onPlayerConnected()
{
	self thread onUpdatePlayerScoreHUD();
}

onPlayerSpawned()
{
	self endon("disconnect");

	if(!isdefined(self.hud_playericon))
	{
		self.hud_playericon = newClientHudElem(self);
		self.hud_playericon.horzAlign = "left";
		self.hud_playericon.vertAlign = "top";
		self.hud_playericon.x = 280;
		self.hud_playericon.y = 463;
		self.hud_playericon.archived = false;
	}

	if(!isdefined(self.hud_playerscore))
	{
		self.hud_playerscore = newClientHudElem(self);
		self.hud_playerscore.horzAlign = "left";
		self.hud_playerscore.vertAlign = "top";
		self.hud_playerscore.x = 284;
		self.hud_playerscore.y = 443;
		self.hud_playerscore.font = "default";
		self.hud_playerscore.fontscale = 1.5;
		self.hud_playerscore.archived = false;
	}

	assert(self.pers["team"] == "allies" || self.pers["team"] == "axis");
	if(self.pers["team"] == "allies") self.hud_playericon setShader(game["hudicon_allies"], 16, 16);
		else self.hud_playericon setShader(game["hudicon_axis"], 16, 16);

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

onUpdatePlayerScoreHUD()
{
	while(!level.ex_gameover)
	{
		self waittill("update_playerscore_hud");
		self thread updatePlayerScoreHUD();
	}
}

updatePlayerScoreHUD()
{
	if(isDefined(self.hud_playerscore)) self.hud_playerscore setValue(self.score);
}

removePlayerHUD()
{
	if(isDefined(self.hud_playericon)) self.hud_playericon destroy();
	if(isDefined(self.hud_playerscore)) self.hud_playerscore destroy();
}

