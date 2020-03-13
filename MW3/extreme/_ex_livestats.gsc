
init()
{
	if(!level.ex_livestats || !level.ex_teamplay || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "rbctf") return;
	thread start();
}

start()
{
	while(!isDefined(game["precachedone"]) || !game["precachedone"]) wait( [[level.ex_fpstime]](1) );
	color = (1,1,0);
	deadcolor = (1,0,0);
	statalpha = 0.8;

	if(!isDefined(level.ex_axisicon))
	{
		level.ex_axisicon = newHudElem();
		level.ex_axisicon.archived = false;
		level.ex_axisicon.horzAlign = "fullscreen";
		level.ex_axisicon.vertAlign = "fullscreen";
		level.ex_axisicon.alignX = "center";
		level.ex_axisicon.alignY = "middle";
		level.ex_axisicon.x = 624;
		level.ex_axisicon.y = 20;
		level.ex_axisicon.alpha = statalpha;
		level.ex_axisicon setShader(game["headicon_axis"],16,16);
	}
	if(!isDefined(level.ex_axisnumber))
	{
		level.ex_axisnumber = newHudElem();
		level.ex_axisnumber.archived = false;
		level.ex_axisnumber.horzAlign = "fullscreen";
		level.ex_axisnumber.vertAlign = "fullscreen";
		level.ex_axisnumber.alignX = "center";
		level.ex_axisnumber.alignY = "middle";
		level.ex_axisnumber.x = 624;
		level.ex_axisnumber.y = 36;
		level.ex_axisnumber.alpha = statalpha;
		level.ex_axisnumber.fontscale = 1.0;
		level.ex_axisnumber.color = color;
		level.ex_axisnumber setValue(0);
	}
	if(!isDefined(level.ex_deadaxisicon))
	{
		level.ex_deadaxisicon = newHudElem();
		level.ex_deadaxisicon.archived = false;
		level.ex_deadaxisicon.horzAlign = "fullscreen";
		level.ex_deadaxisicon.vertAlign = "fullscreen";
		level.ex_deadaxisicon.alignX = "center";
		level.ex_deadaxisicon.alignY = "middle";
		level.ex_deadaxisicon.x = 592;
		level.ex_deadaxisicon.y = 52;
		level.ex_deadaxisicon.alpha = statalpha;
		level.ex_deadaxisicon setShader("hud_status_dead",16,16);
	}
	if(!isDefined(level.ex_deadaxisnumber))
	{
		level.ex_deadaxisnumber = newHudElem();
		level.ex_deadaxisnumber.archived = false;
		level.ex_deadaxisnumber.horzAlign = "fullscreen";
		level.ex_deadaxisnumber.vertAlign = "fullscreen";
		level.ex_deadaxisnumber.alignX = "center";
		level.ex_deadaxisnumber.alignY = "middle";
		level.ex_deadaxisnumber.x = 624;
		level.ex_deadaxisnumber.y = 52;
		level.ex_deadaxisnumber.alpha = statalpha;
		level.ex_deadaxisnumber.fontscale = 1.0;
		level.ex_deadaxisnumber.color = deadcolor;
		level.ex_deadaxisnumber setValue(0);
	}
	if(!isDefined(level.ex_alliedicon))
	{
		level.ex_alliedicon = newHudElem();
		level.ex_alliedicon.archived = false;
		level.ex_alliedicon.horzAlign = "fullscreen";
		level.ex_alliedicon.vertAlign = "fullscreen";
		level.ex_alliedicon.alignX = "center";
		level.ex_alliedicon.alignY = "middle";
		level.ex_alliedicon.x = 608;
		level.ex_alliedicon.y = 20;
		level.ex_alliedicon.alpha = statalpha;
		level.ex_alliedicon setShader(game["headicon_allies"],16,16);
	}
	if(!isDefined(level.ex_alliednumber))
	{
		level.ex_alliednumber = newHudElem();
		level.ex_alliednumber.archived = false;
		level.ex_alliednumber.horzAlign = "fullscreen";
		level.ex_alliednumber.vertAlign = "fullscreen";
		level.ex_alliednumber.alignX = "center";
		level.ex_alliednumber.alignY = "middle";
		level.ex_alliednumber.x = 608;
		level.ex_alliednumber.y = 36;
		level.ex_alliednumber.alpha = statalpha;
		level.ex_alliednumber.fontscale = 1.0;
		level.ex_alliednumber.color = color;
		level.ex_alliednumber setValue(0);
	}
	if(!isDefined(level.ex_deadalliednumber))
	{
		level.ex_deadalliednumber = newHudElem();
		level.ex_deadalliednumber.archived = false;
		level.ex_deadalliednumber.horzAlign = "fullscreen";
		level.ex_deadalliednumber.vertAlign = "fullscreen";
		level.ex_deadalliednumber.alignX = "center";
		level.ex_deadalliednumber.alignY = "middle";
		level.ex_deadalliednumber.x = 608;
		level.ex_deadalliednumber.y = 52;
		level.ex_deadalliednumber.alpha = statalpha;
		level.ex_deadalliednumber.fontscale = 1.0;
		level.ex_deadalliednumber.color = deadcolor;
		level.ex_deadalliednumber setValue(0);
	}

	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	level endon("ex_gameover");

	axis = 0;
	deadaxis = 0;

	allies = 0;
	deadallies = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]))
		{
			player = players[i];

			if(!isDefined(player.pers["team"])) continue;
			if(player.pers["team"] == "spectator" || player.sessionteam == "spectator") continue;

			if(player.sessionstate == "playing")
			{
				if(player.pers["team"] == "allies") allies++;
					else axis++;
			}
			else
			{
				if(player.pers["team"] == "allies") deadallies++;
					else deadaxis++;
			}
		}
	}

	if(isDefined(level.ex_axisnumber)) level.ex_axisnumber setValue(axis);
	if(isDefined(level.ex_deadaxisnumber)) level.ex_deadaxisnumber setValue(deadaxis);
	if(isDefined(level.ex_alliednumber)) level.ex_alliednumber setValue(allies);
	if(isDefined(level.ex_deadalliednumber)) level.ex_deadalliednumber setValue(deadallies);
}
