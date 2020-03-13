
spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");
	self notify("kill_thread");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	// clean player hud
	self thread extreme\_ex_hud::cleanplayer();

	// remove black screen on death
	if(level.ex_bsod) self thread extreme\_ex_main::killBlackScreen();

	// deleted ready-up ticket removal to avoid player lock-out

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(isDefined(self.pers["team"]) && self.pers["team"] == "spectator")
		self.statusicon = "";

	if(level.ex_currentgt != "dm" && level.ex_currentgt != "sd" && level.ex_currentgt != "lms" || level.ex_currentgt != "hm")
	{
		self.psoffsettime = 0;
		maps\mp\gametypes\_spectating::setSpectatePermissions();
	}

	if(level.ex_currentgt == "sd" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd")
	{
		if(!isdefined(self.skip_setspectatepermissions))
			maps\mp\gametypes\_spectating::setSpectatePermissions();
	}

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!level.ex_roundbased) self setClientCvar("cg_objectiveText", "");

	if(level.ex_currentgt == "hq") level maps\mp\gametypes\hq::hq_removeall_hudelems(self);
	if(level.ex_currentgt == "esd") level maps\mp\gametypes\esd::updateTeamStatus();
	if(level.ex_currentgt == "ft") level maps\mp\gametypes\ft::updateTeamStatus();
	if(level.ex_currentgt == "lts") level maps\mp\gametypes\lts::updateTeamStatus();
	if(level.ex_currentgt == "rbcnq") level maps\mp\gametypes\rbcnq::updateTeamStatus();
	if(level.ex_currentgt == "rbctf") level maps\mp\gametypes\rbctf::updateTeamStatus();
	if(level.ex_currentgt == "sd") level maps\mp\gametypes\sd::updateTeamStatus();

	thread monitorSpec();

	[[level.updatetimer]]();
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;

	if(level.ex_currentgt != "dm" && level.ex_currentgt != "lms")
	{
		self.psoffsettime = 0;
		self.friendlydamage = undefined;
	}

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(level.ex_currentgt == "hq") level maps\mp\gametypes\hq::hq_removeall_hudelems(self);

	[[level.updatetimer]]();
}

monitorSpec()
{
	self endon("disconnect");
	self endon("spawned");

	sticky_spec = false;
	sticky_valid = false;
	sticky_spec_player = -1;

	while(1)
	{
		wait( [[level.ex_fpstime]](.05) );

		if(sticky_spec)
		{
			sticky_valid = monitorSpecVerify(sticky_spec_player);

			if(self meleebuttonpressed() || !sticky_valid)
			{
				self.spectatorclient = -1;
				sticky_spec = false;
				while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
			else if(self attackbuttonpressed())
			{
				sticky_spec_player = monitorSpecNext(sticky_spec_player);
				self.spectatorclient = sticky_spec_player;
				if(sticky_spec_player == -1) sticky_spec = false;
				while(self attackbuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
			else if(self usebuttonpressed())
			{
				sticky_spec_player = monitorSpecPrevious(sticky_spec_player);
				self.spectatorclient = sticky_spec_player;
				if(sticky_spec_player == -1) sticky_spec = false;
				while(self usebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
		}
		else if(self usebuttonpressed())
		{
			if(sticky_spec_player == -1 || !monitorSpecVerify(sticky_spec_player)) sticky_spec_player = monitorSpecNext(sticky_spec_player);
			self.spectatorclient = sticky_spec_player;
			if(sticky_spec_player != -1) sticky_spec = true;
			while(self usebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}
	}
}

monitorSpecNext(spec_player)
{
	self endon("disconnect");

	// do not use level.players as we need an array sorted on entity numbers
	players = getentarray("player", "classname");

	// no need to search if there's only one player (that would be me)
	if(players.size == 1) return(-1);

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player))
		{
			entity = player getEntityNumber();
			if(entity > spec_player && player.sessionteam != "spectator") return(entity);
		}
	}

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionteam != "spectator")
		{
			entity = player getEntityNumber();
			return(entity);
		}
	}

	return(-1);
}

monitorSpecPrevious(spec_player)
{
	self endon("disconnect");

	// do not use level.players as we need an array sorted on entity numbers
	players = getentarray("player", "classname");

	// no need to search if there's only one player (that would be me)
	if(players.size == 1) return(-1);

	for(i = players.size - 1; i >= 0; i--)
	{
		player = players[i];
		if(isPlayer(player))
		{
			entity = player getEntityNumber();
			if(entity < spec_player && player.sessionteam != "spectator") return(entity);
		}
	}

	for(i = players.size - 1; i >= 0; i--)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionteam != "spectator")
		{
			entity = player getEntityNumber();
			return(entity);
		}
	}

	return(-1);
}

monitorSpecVerify(spec_player)
{
	self endon("disconnect");

	// level.players is OK as we're only validating the player we (want to) spectate
	players = level.players;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player getEntityNumber() == spec_player)
		{
			if(player.sessionteam != "spectator") return(true);
			return(false);
		}
	}

	return(false);
}
