
init()
{
	if(!level.ex_timeannouncer || level.ex_roundbased) return;
	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	passedtime = (getTime() - level.starttime) / 1000;
	secondsleft = int( (level.timelimit*60) - passedtime + 0.5 );

	if(level.mapended || level.ex_gameover) return;
	if(secondsleft > 300 || secondsleft < 5) return;
	if(level.scorelimit != 0 && level.ex_teamplay)
	{
		alliescore = getTeamScore("allies");
		axisscore = getTeamScore("axis");
		if(axisscore >= level.scorelimit || alliescore >= level.scorelimit) return;
	}

	color = (0.705, 0.705, 0.392);
	anscore = false;
	antime = undefined;
	if(secondsleft == 300) { antime = "fivemins"; color = (0,1,1); anscore = true; }      // 5 mins
	if(secondsleft == 120) { antime = "twomins"; color = (.1,.6,.5); anscore = true; }    // 2 mins
	if(secondsleft ==  60) { antime = "onemin"; color = (.7,.2,.2); anscore = true; }     // 1 min
	if(secondsleft ==  30) { antime = "thirtysecs"; color = (.7,.7,.7); anscore = true; } // 30 secs
	if(secondsleft ==  20) { antime = "twentysecs"; color = (1,1,0); }                    // 20 secs
	if(secondsleft ==  10) { antime = "tensecs"; color = (1,0,0); anscore = true; }       // 10 secs
	if(secondsleft ==   5) { antime = "fftto"; }                                          // 5 secs

	if(level.scorelimit <= 0 || !level.ex_teamplay) anscore = false;

	if(isDefined(antime))
	{
		if(level.ex_timeannouncer != 2 && isDefined(level.clock)) level.clock.color = color;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player) || !isDefined(player.pers) || !isDefined(player.pers["team"])) continue;

			// announce time
			if(level.ex_antime) player playLocalSound(antime);

			// announce score
			if(level.ex_anscore && anscore) player thread announceScore();
		}
	}
}

announceScore()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");
	team = undefined;
	txt = undefined;
	aname = undefined;
	closetowin = false;

	if(axisscore == alliedscore)
	{
		self iprintln(&"SCORES_LEVEL");
		return;
	}

	if(axisscore < alliedscore)
	{
		ascore = level.scorelimit - alliedscore;
		team = "allies";
	}
	else
	{
		ascore = level.scorelimit - axisscore;
		team = "axis";
	}

	if(ascore > (level.scorelimit - 10))
	 	closetowin = true;
	
	if(self.pers["team"] == "allies") // if teams are not near winning, show scores
	{
		aname = &"SCORES_GERMAN";
		
		if(!closetowin)
		{
			if(alliedscore < axisscore)
				self iprintln(&"SCORES_YOUR_TEAM", (axisscore - alliedscore), &"SCORES_BEHIND", aname);
			else if(alliedscore > axisscore)
				self iprintln(&"SCORES_YOUR_TEAM", (alliedscore - axisscore), &"SCORES_AHEAD", aname);
			return;
		}
	}
	else
	{
		switch(game["allies"])
		{
			case "american":
				aname = &"SCORES_AMERICAN";
				break;
	
			case "british":
				aname = &"SCORES_BRITISH";
				break;
		
			case "russian":
				aname = &"SCORES_RUSSIAN";
				break;
		}
		
		if(!closetowin)
		{
			if(axisscore < alliedscore)
				self iprintln(&"SCORES_YOUR_TEAM", (alliedscore - axisscore), &"SCORES_BEHIND", aname);
			else if(axisscore > alliedscore)
				self iprintln(&"SCORES_YOUR_TEAM", (axisscore - alliedscore), &"SCORES_AHEAD", aname);
			return;
		}
	}

	// a team is close to winning
	if(self.pers["team"] != team) self iprintln(&"SCORES_TEAM_LOSING_MSGA", aname, &"SCORES_TEAM_LOSING_MSGB", ascore, &"SCORES_TEAM_WINNING");
		else self iprintln(&"SCORES_YOUR_TEAM", ascore, &"SCORES_TEAM_WINNING");
}
